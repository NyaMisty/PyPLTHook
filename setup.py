#!/usr/bin/env python
# -*- coding: utf-8 -*-

import platform

from setuptools import setup, Extension, find_packages
from distutils.extension import Extension
#from Cython.Build import cythonize
from Cython.Distutils import build_ext

MODULE_NAME = "PyPLTHook"
AUTHOR = 'NyaMisty'
AUTHOR_EMAIL = 'misty@misty.moe'
URL = 'https://github.com/NyaMisty/PyPLTHook'
DOWNLOAD_URL = 'https://github.com/NyaMisty/PyPLTHook'
DESCRIPTION = "PyPLTHook: PLTHook in Python"
exec(open('version.py').read())
VERSION = __version__

def _get_ext_modules():
    ext_modules = []
    
    _cython_src = ['_plthook.pyx']
    
    _plthook_src = []
    if platform.system() == 'Linux':
        _plthook_src.append('plthook_c/plthook_elf.c')
    elif platform.system() == 'Windows':
        _plthook_src.append('plthook_c/plthook_win32.c')
    elif platform.system() == 'Darwin':
        _plthook_src.append('plthook_c/plthook_osx.c')
    
    ext_modules += [
        Extension('_plthook', 
                    sources=_cython_src + _plthook_src, 
                    include_dirs='plthook_c/'),
    ]
    
    return ext_modules


setup(name = MODULE_NAME,
   version = VERSION,
   description = DESCRIPTION,
   author = AUTHOR,
   author_email = AUTHOR_EMAIL,
   url = URL,
   packages = find_packages(),
   cmdclass = {'build_ext': build_ext},
   ext_modules = _get_ext_modules(),
   include_dirs = [],
)