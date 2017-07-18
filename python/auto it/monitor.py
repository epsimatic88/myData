#coding=utf-8

import time, os
import tools

#------------------------------------------------------------------

def get_err_linenum(start, path):
    lines = []
    begin = 0
    end = 0
    try:
        f = open(path, 'r')
        lines = f.readlines()
        f.close()
    except IOError:
        return (begin, end)
    row = 0
    for line in lines:
        row += 1
        if row < start: continue
        if begin == 0 and line.find('[ERR]') != -1:
            begin = row
        if begin != 0:
            end = row
    return (begin, end)

#------------------------------------------------------------------

def diff_seconds(hhmmss1, hhmmss2, day_offset = 0):
    return to_seconds(hhmmss1) - to_seconds(hhmmss2) + 24 * 3600 * day_offset

#------------------------------------------------------------------

def to_seconds(hhmmss):
    return int(hhmmss[0:2]) * 3600 + int(hhmmss[2:4]) * 60 + int(hhmmss[4:6])

#------------------------------------------------------------------

def mtime_overtime(path, overtime_sec):
    modify_time = time.strftime('%H%M%S',time.localtime(os.stat(path).st_mtime))
    local_time = time.strftime('%H%M%S',time.localtime(time.time()))    
    diff = diff_seconds(local_time, modify_time)
    if diff > overtime_sec:
        ret = True
    else:
        ret = False
    return ret

#------------------------------------------------------------------
