from distutils.core import setup
from Cython.Build import cythonize
import sys
setup(
    ext_modules = cythonize(("CFAImageGenerator.pyx","CLine.pyx","ContinousImage3D.pyx","SeamlessImage.pyx","Vector3D.pyx"),compiler_directives={'language_level' : sys.version_info[0]})
)