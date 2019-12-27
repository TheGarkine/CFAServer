from distutils.core import setup
from Cython.Build import cythonize

setup(
    ext_modules = cythonize(("CFAImageGenerator.pyx","CLine.pyx","ContinousImage3D.pyx","SeamlessImage.pyx","Vector3D.pyx"))
)