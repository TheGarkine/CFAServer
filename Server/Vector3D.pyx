#original code from: https://gist.github.com/davidnuon/3816736
#modified
class Vector3D:
    def __init__(self, x, y, z):
        self.x = float(x)
        self.y = float(y)
        self.z = float(z)

    # String representation
    def __str__(self):
        return '<%s, %s, %s>' % (self.x, self.y, self.z)

    # Produce a copy of itself
    def __copy(self):
        return Vector3D(self.x, self.y, self.z)

    # Signing
    def __neg__(self):
        return Vector3D(-self.x, -self.y, -self.z)

    # Scalar Multiplication
    def __mul__(self, number):
        return Vector3D(self.x * number, self.y * number, self.z * number)

    def __rmul__(self, number):
        return self.__mul__(number)

    # Division
    def __truediv__(self, number):
        return self.__copy() * (number**-1)

    # Arithmetic Operations
    def __add__(self, operand):
        return Vector3D(self.x + operand.x, self.y + operand.y, self.z + operand.z)

    def __sub__(self, operand):
        return self.__copy() + -operand

    # Cross product
    # cross = a ** b
    def __pow__(self, operand):
        return Vector3D(self.y*operand.z - self.z*operand.y, 
                            self.z*operand.x - self.x*operand.z, 
                            self.x*operand.y - self.y*operand.x)

    # Dot Project
    # dp = a & b
    def __and__(self, operand):
        return (self.x * operand.x) + \
               (self.y * operand.y) + \
               (self.z * operand.z)
    #SCALE        
    def __or__ (self,operand):
        return Vector3D(self.x * operand.x,self.y * operand.y,self.z*operand.z)
    
    #index [0] 
    def __getitem__(self,key):
        if(key == 0): return self.x
        if(key == 1): return self.y
        if(key == 2): return self.z
        raise Exception("For the indexer, only use 0,1,2 to get the values of x,y and z respectively.")
    # Operations

    def normal(self):
        return self.__copy() / self.magnitude()

    def magnitude(self):
        return (self.x**2 + self.y**2 + self.z**2)**(.5)

ZERO = Vector3D(0,0,0)
