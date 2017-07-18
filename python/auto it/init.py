#coding=utf-8

from haitong import HaiTongInterface, HaiTongService
from zhaoshang import ZhaoShangInterface, ZhaoShangService
from debang import DeBangInterface, DeBangService
from dongbei import DongBeiInterface, DongBeiService
from yinhe import YinHeInterface, YinHeService
from expt import InitError


def initialize_interface(broker, account):
    if broker.lower() == 'haitong':
        return HaiTongInterface(account)
    elif broker.lower() == 'zhaoshang':
        return ZhaoShangInterface(account)
    elif broker.lower() == 'debang':
        return DeBangInterface(account)
    elif broker.lower() == 'dongbei':
        return DongBeiInterface(account)
    elif broker.lower() == 'yinhe':
        return YinHeInterface(account)
    else:
        raise InitError('%s is not registered' % (broker))


def initialize_service(broker, account):
    if broker.lower() == 'haitong':
        return HaiTongService(account)
    elif broker.lower() == 'zhaoshang':
        return ZhaoShangService(account)
    elif broker.lower() == 'debang':
        return DeBangService(account)
    elif broker.lower() == 'dongbei':
        return DongBeiService(account)
    elif broker.lower() == 'yinhe':
        return YinHeService(account)
    else:
        raise InitError('%s is not registered' % (broker))