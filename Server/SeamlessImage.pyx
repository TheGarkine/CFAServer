#Another Helper Class we will need, that makes things with the images a bit easier and prevents out of bounds access
class SeamlessImage:
    def __init__(self,img):
        self.img = img
        self.x_width = len(img[0])
        self.y_width = len(img)
    
    def get_value(self,x,y):
        if x < 0 or x >= self.x_width or y < 0 or y >= self.y_width:
            return None
        else:
            return self.img[y][x]