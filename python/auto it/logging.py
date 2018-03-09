#coding=utf-8

import time


def write_log_file(path, content):    
    f = open(path, 'a')
    f.write(content)
    f.close()
    
def info(content, path):
    timestamp = time.strftime('%H:%M:%S',time.localtime(time.time()))
    write_log_file(path, '%s [INF] %s\n' % (timestamp, content.strip()))

def error(content, path):
    timestamp = time.strftime('%H:%M:%S',time.localtime(time.time()))
    write_log_file(path, '%s [ERR] %s\n' % (timestamp, content.strip()))
