from Vector3D import Vector3D
#this class will handle the interpolation and other stuff with the medical image data
#one mm is one unit within this object
class ContinousImage3D:
    def __init__(self,data,x_scale=1,y_scale=1,z_scale=1,location=Vector3D(0,0,0)):
        self.data = data
        self.shape = [data.shape[2],data.shape[1],data.shape[0]]
        
        #scale is mm/voxel
        self.x_scale = x_scale
        self.y_scale = y_scale
        self.z_scale = z_scale
        
        #sizes in mm
        self.x_size = self.shape[0] * x_scale
        self.y_size = self.shape[1] * y_scale
        self.z_size = self.shape[2] * z_scale
        
        self.size = Vector3D(self.x_size,self.y_size,self.z_size)
        
        #offset of the image in mm (first voxel)
        self.location = location
    
    def is_in(self,vector):
        v = vector - self.location
        
        x = v.x
        y = v.y
        z = v.z
        
        #normalize the x,y,z to voxel distance
        abs_x = x * 1/self.x_scale
        abs_y = y * 1/self.y_scale
        abs_z = z * 1/self.z_scale
        
        #index of the upper left voxel of the needed cube for interpolation
        x_index = int(abs_x)        
        y_index = int(abs_y)        
        z_index = int(abs_z)
        
        #out of bounds
        if x_index < 0 or y_index < 0 or z_index < 0 or \
            x_index >= self.shape[0] - 1 or y_index >= self.shape[1] - 1 or z_index >= self.shape[2] - 1:
            return False
        else:
            return True
        
    def get_value(self,vector):
        #first subtract the offset of the image
        v = vector - self.location
        
        x = v.x
        y = v.y
        z = v.z
        
        #normalize the x,y,z to voxel distance
        abs_x = x * 1/self.x_scale
        abs_y = y * 1/self.y_scale
        abs_z = z * 1/self.z_scale
        
        #index of the upper left voxel of the needed cube for interpolation
        x_index = int(abs_x)
        y_index = int(abs_y)        
        z_index = int(abs_z)
        
        #out of bounds, everything defaults to 0
        if x_index < 0 or y_index < 0 or z_index < 0 \
            or x_index >= self.shape[0] - 1 or y_index >= self.shape[1] - 1 or z_index >= self.shape[2] - 1:
            return 0
        
        #since we transform the data in a unit system, alpha/beta/gamma are equal to the remaining distance in each axis
        alpha = abs_x - x_index
        beta = abs_y - y_index
        gamma = abs_z - z_index
        
        #trilinear interpolation according to slide of M.Tessmann
        f_000 = self.data[z_index][y_index][x_index]
        f_001 = self.data[z_index][y_index][x_index+1]
        f_010 = self.data[z_index][y_index+1][x_index]
        f_011 = self.data[z_index][y_index+1][x_index+1]
        f_100 = self.data[z_index+1][y_index][x_index]
        f_101 = self.data[z_index+1][y_index][x_index+1]
        f_110 = self.data[z_index+1][y_index+1][x_index]
        f_111 = self.data[z_index+1][y_index+1][x_index+1]
        
        f_00 = alpha * f_001 + (1-alpha) * f_000
        f_01 = alpha * f_011 + (1-alpha) * f_010
        f_10 = alpha * f_101 + (1-alpha) * f_100
        f_11 = alpha * f_111 + (1-alpha) * f_110
        
        f_0 = beta * f_01 + (1-beta) * f_00
        f_1 = beta * f_11 + (1-beta) * f_10
        
        return gamma * f_1 + (1-gamma) * f_0
