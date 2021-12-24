# cython: language_level=3

cdef extern from "<stdint.h>":
    ctypedef void plthook_t

from libc.stdint cimport uintptr_t

cdef extern from "plthook_c/plthook.h":
    cdef int PLTHOOK_SUCCESS
    cdef int plthook_open(plthook_t **plthook_out, const char *filename);
    cdef int plthook_open_by_handle(plthook_t **plthook_out, void *handle);
    cdef int plthook_open_by_address(plthook_t **plthook_out, void *address);
    cdef int plthook_enum(plthook_t *plthook, unsigned int *pos, const char **name_out, void ***addr_out);
    cdef int plthook_replace(plthook_t *plthook, const char *funcname, void *funcaddr, void **oldfunc);
    cdef void plthook_close(plthook_t *plthook);
    cdef const char *plthook_error();

def tryDecode(bmsg):
    try:
        return bmsg.decode('utf-8')
    except UnicodeDecodeError:
        pass
    try:
        return bmsg.decode('gbk')
    except UnicodeDecodeError:
        pass
    return bmsg


import _ctypes

class PLTHookInternalException(Exception):
    pass

class _plthook_t:
    def __init__(self, name, *args):
        cdef plthook_t *innerPtr = NULL;
        openers = {
            'plthook_open': lambda filename: plthook_open(&innerPtr, filename),
            'plthook_open_by_handle': lambda hndl: plthook_open_by_handle(&innerPtr, <void *>hndl),
            'plthook_open_by_address': lambda address: plthook_open_by_address(&innerPtr, <void *>address),
        }
        assert(name in ['plthook_open', 'plthook_open_by_handle', 'plthook_open_by_address'])
        
        #opener = eval(name)
        #status = opener(&innerPtr, *args)
        
        opener = openers[name]
        status = opener(*args)
        if status != PLTHOOK_SUCCESS:
            errmsg = plthook_error()
            raise PLTHookInternalException("status: %d, msg: %s" % (status, tryDecode(errmsg)))
        self._plthook_obj = <uintptr_t>innerPtr
    
    def __del__(self):
        # convert to uintptr_t beforehand, so that Cython won't think it's string
        cdef uintptr_t _innerPtr = int(self._plthook_obj)
        if _innerPtr != 0:
            plthook_close(<plthook_t *>_innerPtr)
            self._plthook_obj = 0
    
    @staticmethod
    def open(filename):
        if isinstance(filename, str):
            filename = filename.encode()
        return _plthook_t('plthook_open', filename)
    
    @staticmethod
    def open_by_handle(hndl):
        try:
            hndl = long(hndl)
        except ValueError:
            try:
                hndl = int(hndl)
            except ValueError:
                raise ValueError("Cannot convert hndl to int")
        return _plthook_t('plthook_open_by_handle', hndl)

    
    @staticmethod
    def open_by_address(address):
        return _plthook_t('plthook_open_by_address', address)

    def replace(self, funcname, funcaddr):
        if not isinstance(funcname, bytes):
            raise ValueError("funcname must in bytes!")
        try:
            funcaddr = long(funcaddr)
        except ValueError:
            try:
                funcaddr = int(funcaddr)
            except ValueError:
                raise ValueError("Cannot convert funcaddr to int")
        
        cdef void *oldFunc = NULL;
        # convert to uintptr_t beforehand, so that Cython won't think it's string
        cdef uintptr_t _innerPtr = int(self._plthook_obj)
        cdef uintptr_t _funcaddr = int(funcaddr)
        
        #print(_innerPtr, funcname, _funcaddr)
        status = plthook_replace(<plthook_t *>_innerPtr, funcname, <void *>_funcaddr, &oldFunc)
        if status != PLTHOOK_SUCCESS:
            errmsg = plthook_error()
            raise PLTHookInternalException("status: %d, msg: %s" % (status, tryDecode(errmsg)))
        
        return <uintptr_t>oldFunc