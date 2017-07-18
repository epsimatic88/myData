#coding=utf-8

import time, os, os.path


def ensure_dir(path):
    dir = os.path.dirname(path)
    if not os.path.exists(dir):
        os.makedirs(dir)


def islive():
    t = time.strftime('%H%M%S',time.localtime(time.time()))
    if t > '085000' and t < '150500':
        return True
    else:
        return False


def get_timestamp():
    return time.strftime('%H:%M:%S',time.localtime(time.time()))