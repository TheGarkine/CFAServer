import numpy as np
#This class will help us sample the center line in regular distances and directions
class CLine:
    def __init__(self,cline):
        self.cline = cline
        self.directions = list()
        self.lengths = list()
        
        for i in range(len(self.cline)-1):
            delta = self.cline[i+1]-self.cline[i]
            l = delta.magnitude()
            self.lengths.append(l)
            self.directions.append(delta / l) # direction is normalized
        
        #the last length is 0 since there are no more points following
        self.lengths.append(0)
        #the last direction is copied for the last sample of the cline
        self.directions.append(self.directions[len(self.directions) -1])
        
        # calculate the total length of the centerline:
        self.length = sum(self.lengths)
            
    def get_point_and_direction_by_distance(self,distance):
        if distance > self.length or distance < 0:
            raise Exception("Accessed center line out of limits")
        
        index = 0
        
        while(distance > 0):
            distance -= self.lengths[index]
            index += 1
        
        #the last point was the last one before the distance was reached
        #from here we need to go the remaining distance in the direction of the next point
        return (self.cline[index-1] + (distance + self.lengths[index])*self.directions[index-1],self.directions[index-1])