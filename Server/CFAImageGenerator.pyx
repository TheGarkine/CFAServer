import random
import statistics
import math
from matplotlib import pyplot as plt
import numpy as np

from Vector3D import Vector3D
from SeamlessImage import SeamlessImage

class CFAImageGenerator:
    #available aggregation functions
    agg_functions = {
        "MIP": max,
        "MINIP": min,
        "AVGIP": statistics.mean,
        "MEDIP": statistics.median
    }
    
    def __init__(self, cont_img, cline, 
                 left="MIP",right="MINIP", 
                 sample_strategy="const_angle", sample_frequency=math.pi/4,
                 circle_delta=1, cline_step_distance = 1, max_radius = 10, 
                 context = None,stability = None):
        #copy all arguments to respective fields
        #set the aggregation functions for later
        self.left = left
        self.right = right
        self.left_agg = self.agg_functions[left]
        self.right_agg = self.agg_functions[right]
        
        self.context = None
        if context:
            if type(context) == dict and "side" in context and "samples" in context:
                if not (type(context["samples"]) == int and context["samples"] > 1):
                    raise Exception("Context samples must be a postive integer greater 1")
                views = {"feet","head","posterior","anterior","left","right"}
                if not context["side"] in views:
                    raise Exception("Side must be within the Set " + str(views))
                self.context = context
            else:
                raise Exception ("Context must be a dictionary containing a 'side' and a number of 'samples'")
        
        self.stability = None
        if stability:
            if type(stability) == dict and "w" in stability and 'percentile' in stability:
                if not (type(stability["w"]) == int and stability["w"] > 0):
                    raise Exception("Stability kernel w must be a postive integer greater 0")
                if not (stability["percentile"] > 0 and stability["percentile"] < 100):
                    raise Exception("Stability percentile must be between 0 and 100")
                self.stability = stability
            else:
                raise Exception ("stability must be a dictionary containing the kernel size 'w' and a 'percentile' between 0 and 100")
            
        #we need this of course
        self.cimg = cont_img
        self.cline = cline
        
        #sample_frequency is angle/arc length/absolute number, depending on the strategy
        self.sample_frequency = sample_frequency
        self.sample_strategy = sample_strategy
        if sample_strategy not in ('const_angle','const_arc','const_num'): 
            raise Exception("Unknown sample type, use 'const_num','const_angle' or 'const_arc'")
        
        #max circle ray radius in mm
        self.max_radius = max_radius
        #the delta in which the circles increase in size in mm
        self.circle_delta = circle_delta
        #at which distances should samples on the centerline be taken in mm
        self.cline_step_distance = cline_step_distance
        
        self.max_measured_value = 0
        self.ctx = None
        self.cfa = None
        self.sta = None
        self.cline_values = None
        self.img = None
        
    def calculate_cfa(self):
        self.cfa_left_img = list()
        self.cfa_right_img = list()
        
        steps = int(self.cline.length / self.cline_step_distance)
        circles = int(self.max_radius / self.circle_delta)
        self.cline_values = np.zeros(steps)
        
        for c in range(steps):
            cfa_left_values = np.zeros(circles)
            cfa_right_values = np.zeros(circles)
            
            # this is the current cener point on the cline
            center_point, normal = self.cline.get_point_and_direction_by_distance(c*self.cline_step_distance)
            self.cline_values[c] = self.cimg.get_value(center_point)
            # we need to find two vectors for the plane
            # find random vector which is not parallel to the original
            v = Vector3D(1,0,0)
            while abs(v & normal) > 0.999:
                rand1 = random.uniform(0,1)
                rand2 = random.uniform(0,1)
                rand3 = random.uniform(0,1)
                v = Vector3D(rand1,rand2,rand3)
                
            #we normalize the vectors
            s = (normal ** v).normal()
            r = (normal ** s).normal()
            
            #CFA
            for x in range(circles):
                radius = self.circle_delta * (x+1)
                num_samples = 0
                if self.sample_strategy == "const_angle":
                    num_samples = int(2 * math.pi/self.sample_frequency)
                elif self.sample_strategy == "const_arc":
                    num_samples = int(2 * math.pi * radius / self.sample_frequency) + 1
                elif self.sample_strategy == "const_num":
                    num_samples = int(self.sample_frequency)
                else:
                    raise Exception("Unknown sample type, use 'const_num','const_angle' or 'const_arc'")
                samples = np.zeros(num_samples)
                for i in range(num_samples):
                    angle = i* math.pi * 2 / num_samples
                    sample_point = center_point + radius * (math.cos(angle) * r + math.sin(angle) * s)
                    samples[i] = self.cimg.get_value(sample_point)
                
                cfa_left_values[x] = self.left_agg(samples)
                cfa_right_values[x] = self.right_agg(samples)
                
            self.cfa_left_img.append(cfa_left_values)
            self.cfa_right_img.append(cfa_right_values)
    
        #aggregate the data to one matrix
        self.cfa = list()
        for s in range(steps):
            row = list()
            for i in range(circles):
                row.append(self.cfa_left_img[s][circles-i-1])
            row.append(self.cline_values[s])
            for i in range(circles):
                row.append(self.cfa_right_img[s][i])
            self.cfa.append(row)
        self.max_measured_value = max(max([max(x) for x in self.cfa]),self.max_measured_value)

    #This function calculates the context data of the image
    def calculate_ctx(self):
        #return startpoint, and cube projecting vectors with direction
        def get_view_projecting_vectors(cimg,side):
            if side == "feet":
                return (cimg.location + (Vector3D(0,0,0) | self.cimg.size),
                        Vector3D(1,0,0)|self.cimg.size,
                        Vector3D(0,1,0)|self.cimg.size,
                        Vector3D(0,0,1)|self.cimg.size)
            if side == "head":
                return (cimg.location + (Vector3D(1,0,1) | self.cimg.size),
                        Vector3D(-1,0,0)|self.cimg.size,
                        Vector3D(0,1,0)|self.cimg.size,
                        Vector3D(0,0,-1)|self.cimg.size)
            if side == "anterior":
                return (cimg.location + (Vector3D(0,0,1) | self.cimg.size),
                        Vector3D(1,0,0)|self.cimg.size,
                        Vector3D(0,0,-1)|self.cimg.size,
                        Vector3D(0,1,0)|self.cimg.size)
            if side == "posterior":
                return (cimg.location + (Vector3D(1,1,1) | self.cimg.size),
                        Vector3D(-1,0,0)|self.cimg.size,
                        Vector3D(0,0,-1)|self.cimg.size,
                        Vector3D(0,-1,0)|self.cimg.size)
            if side == "left":
                return (cimg.location + (Vector3D(1,0,1) | self.cimg.size),
                        Vector3D(0,1,0)|self.cimg.size,
                        Vector3D(0,0,-1)|self.cimg.size,
                        Vector3D(-1,0,0)|self.cimg.size)
            if side == "right":
                return (cimg.location + (Vector3D(0,1,1) | self.cimg.size),
                        Vector3D(0,-1,0)|self.cimg.size,
                        Vector3D(0,0,-1)|self.cimg.size,
                        Vector3D(1,0,0)|self.cimg.size)
    
        if not self.context:
            raise Exception("Tried to calculate context data without context field set")
        side = self.context["side"]
        sampling_z =self.context["samples"]
        
        start, xv, yv, zv = get_view_projecting_vectors(self.cimg,side)
        sampling_x_half = int(xv.magnitude()/(self.circle_delta*2))
        sampling_y = int(self.cline.length / self.cline_step_distance) #same as steps in CFA
        
        xv /= sampling_x_half*2-1
        yv /= sampling_y-1
        zv /= sampling_z-1
        self.ctx = list()
        for y in range(sampling_y):
            row = list()
            for x in range(sampling_x_half*2):
                samples = list()
                for z in range(sampling_z):
                    samples.append(self.cimg.get_value(start + xv * x + yv * y + zv * z))
                row.append(self.left_agg(samples) if x < sampling_x_half else self.right_agg(samples))
            self.ctx.append(row)
        self.max_measured_value = max(self.max_measured_value,max([max(x) for x in self.ctx]))
        
    def calculate_stability(self):
        if not self.stability:
            raise Exception("Tried to calculate stability without stability field set")
        if not self.cfa:
            raise Exception("Tried to calculate stability without previously calculating CFA")
        simg = SeamlessImage(self.cfa)
        helper = list()
        for y in range(simg.y_width):
            row = list()
            for x in range(simg.x_width): 
                samples = list()
                for nx in range(-self.stability["w"],self.stability["w"]+1):
                    for ny in range(-self.stability["w"],self.stability["w"]+1):
                        v = simg.get_value(x+nx,y+ny)
                        if v is not None: samples.append(v)
                row.append(statistics.variance(samples))
            helper.append(row)
        #normalize (0,1)
        max_variance = max([max(x) for x in helper])
        self.sta = list()
        for row in helper:
            n_row = list()
            for col in row:
                n_row.append(col/max_variance)
            self.sta.append(n_row)

    def calculate_all(self):
        self.calculate_cfa()
        if self.context:
            self.calculate_ctx()
        if self.stability:
            self.calculate_stability()
    
    def render_image(self):
        if not self.cfa:
            raise Exception("Can't render without CFA img calculated first")
        self.img = list()
        height = len(self.cfa)
        cfa_width = len(self.cfa[0])
        width = cfa_width if not self.ctx else len(self.ctx[0])
        radius_pixel = int(self.max_radius / self.circle_delta)
        
        for y in range(height):
            row = list()
            for x in range(width):
                if(abs(int(x-width/2)) <= radius_pixel):
                    row.append(self.cfa[y][int(x - (width-cfa_width)/2)]/self.max_measured_value)
                else:
                    row.append(self.ctx[y][x]/self.max_measured_value)
            self.img.append([[int(255*v),int(255*v),int(255*v)] for v in row])
        
        if self.sta:
            #since we got the vector class already, lets use it
            red = Vector3D(255,0,0)
            blue = Vector3D(0,0,255)
            threshold = np.percentile(np.array(self.sta),self.stability["percentile"])
            for x in range(cfa_width):
                for y in range(height):
                    if self.sta[y][x] > threshold:
                        #calculate the value between threshold and 1
                        v = (self.sta[y][x]-threshold)/(1-threshold)
                        #calculate the color value
                        c = (red-blue) * v + blue
                        self.img[y][x+int((width-cfa_width)/2)] = [int(c.x),0,int(c.z)]    
    
    def plot(self,filename,dpi=320):
        if not self.img:
            raise Exception("Tried to plot, without rendering image")
        
        #plt.figure(figsize=(self.context["width"]*2/10,self.cline.length/10))
        radius = self.max_radius if not self.ctx else len(self.ctx[0])*self.circle_delta
        length = self.cline.length
        
        plt.figure(figsize=(radius*2/10,length/10))
        plt.imshow(self.img,
                   extent=[-radius,radius,length,0],
                   cmap="Greys_r",
                   aspect='equal')
        plt.savefig(filename,bbox_inches="tight",dpi=dpi)