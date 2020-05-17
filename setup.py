
from setuptools import setup, find_packages, Extension

try:
    from Cython.Build import cythonize

    ext_modules = cythonize([
        Extension("replacer.replacer", ["replacer/replacer.pyx"]),
    ])
    
except ImportError:
    ext_modules = None

setup(
    name='replacer',
    version='0.0.1',
    packages=find_packages(),
    description='A simple string translate, like regex, but matching multiple patterns',
    ext_modules=ext_modules
)




