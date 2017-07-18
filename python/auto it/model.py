#coding=utf-8

from datetime import datetime
import time


class Balance(object):
    def __init__(self, raw_data):
        self.remaining_cash = float(raw_data['rc'])
        self.available_cash = float(raw_data['ac'])
        self.reference_market_value = float(raw_data['mv'])
        self.total_asset = float(raw_data['ta'])


class Position(object):
    def __init__(self, raw_data):
        self.stock_code = raw_data['sc']
        self.volume = int(float(raw_data['vo']))
        self.available_volume = int(float(raw_data['av']))


class Entrust(object):
    def __init__(self, raw_data):
        self.order_no = raw_data['on']
        self.stock_code = raw_data['sc']
        order_type = raw_data['ot']
        self.order_type = 'buy' if (order_type == 'b') else ('sell' if order_type == 's' else 'unknown')
        self.trade_volume = int(float(raw_data['tv']))
        self.trade_price = float(raw_data['tp'])
        self.volume = int(float(raw_data['vo']))
        self.price = float(raw_data['pr'])
        self.status = raw_data['st']


class FilledResult(object):
    def __init__(self, raw_data):
        self.order_no = raw_data['on']
        self.stock_code = raw_data['sc']
        order_type = raw_data['ot']
        self.order_type = 'buy' if (order_type == 'b') else ('sell' if order_type == 's' else 'unknown')
        timestamp = raw_data['ts']
        if timestamp.find(':') != -1:
            self.timestamp = datetime.strptime(time.strftime('%Y%m%d',time.localtime(time.time())) + timestamp, '%Y%m%d%H:%M:%S')
        else:
            self.timestamp = datetime.strptime(time.strftime('%Y%m%d',time.localtime(time.time())) + timestamp, '%Y%m%d%H%M%S')
        self.filled_volume = int(float(raw_data['fv']))
        self.filled_price = float(raw_data['fp'])
