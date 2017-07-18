#coding=utf-8

import logging
from functools import wraps


def log_call(f):
    @wraps(f)
    def call(*args):
        (ret_code, ret_value, error_msg, log_path) = f(*args)
        param_desc = ', '.join(list(map(lambda x:str(x), args)))
        if ret_code == 0:
            logging.info('(%i) %s.%s(%s)' % (ret_code, f.__module__, f.__name__, param_desc), log_path)
        else:
            logging.error('(%i) %s.%s(%s) : %s' % (ret_code, f.__module__, f.__name__, param_desc, error_msg), log_path)
        return (ret_code, ret_value)
    return call

def log_call_error(f):
    @wraps(f)
    def call(*args):
        (ret_code, ret_value, error_msg, log_path) = f(*args)
        param_desc = ', '.join(list(map(lambda x:str(x), args)))
        if ret_code != 0:
            logging.error('(%i) %s.%s(%s) : %s' % (ret_code, f.__module__, f.__name__, param_desc, error_msg), log_path)
        return (ret_code, ret_value)
    return call