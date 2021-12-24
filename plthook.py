__all__ = ("plthook_base", "PLTHookInternalException")

import _plthook
from _plthook import PLTHookInternalException
from ctypes import *
import _ctypes

class plthook_base(object):
    """ Base class for PLTHook """
    PROTOTYPE = CFUNCTYPE(c_int, c_int, use_errno=False, use_last_error=False)
    HOOK_TARGET = "test.dll"
    HOOK_FUNC = "foo"
    
    def __init__(self, verbose=False):
        assert isinstance(self.PROTOTYPE(), _ctypes.CFuncPtr)
        self._ph = _plthook._plthook_t.open(self.HOOK_TARGET)
        self.origFun = None
        self.hookPtr = None
        self.verbose = verbose
    
    def __del__(self):
        self._ph = None
    
    def _log(self, msg):
        if self.verbose:
            print(msg)

    def install(self):
        self.hookPtr = self.PROTOTYPE(self.hook)
        _ptr = cast(self.hookPtr, c_void_p)
        hookFun = self.HOOK_FUNC
        if isinstance(hookFun, str):
            hookFun = hookFun.encode('utf-8')
        origFunc = self._ph.replace(hookFun, _ptr.value)
        self._log("replacing %s, got orig %x" % (hookFun, origFunc))
        if origFunc == 0:
            t = CDLL(None)
            t.dlsym.restype = c_void_p
            t.dlsym.argtypes = (c_void_p, c_char_p)
            origFunc = t.dlsym(0, self.HOOK_FUNC)
        
        if origFunc == 0:
            raise Exception("Failed to find original function!")
        self.origFun = self.PROTOTYPE(origFunc)

    def hook(self, *args, **kwargs):
        raise NotImplementedError(self.HOOK_FUNC + "'s hook() not implemented!")

    def orig(self, *args, **kwargs):
        return self.origFun(*args, **kwargs)
