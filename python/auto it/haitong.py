#coding=utf-8

import autoit

from wrapper import log_call, log_call_error
from interface import Interface
from tdx import TDX
from expt import InitError, ParseError
import tools, monitor

from datetime import datetime
import time, traceback, winsound, codecs, json

#==================================================================

BROKER = 'HaiTong'
ACCOUNTS = ['QJ2', 'PanShi3']
LOCAL_BASE_DIR = 'c:\\logs\\autohook\\stock\\haitong'
EXPORT_BASE_DIR = '\\\\192.168.1.66\\public\\hotdata\\stock\\haitong'
#LOCAL_BASE_DIR = 'c:\\logs\\autohook\\stock\\test'
#EXPORT_BASE_DIR = '\\\\192.168.1.66\\public\\hotdata\\stock\\test'

#==================================================================

class HaiTongTDX(TDX):
    def __init__(self, broker, account, local_base_dir, export_base_dir):
        super(HaiTongTDX, self).__init__(broker, account, local_base_dir, export_base_dir)
        self.wid_prompt = u'[CLASS:#32770; TITLE:提示]'
        self.cid_prompt_ok = '[CLASS:Button; INSTANCE:1]'
        self.cid_buy_code = '[CLASS:Edit; INSTANCE:1]'
        self.cid_buy_price = '[CLASS:Edit; INSTANCE:2]'
        self.cid_buy_volume = '[CLASS:Edit; INSTANCE:5]'
        self.cid_buy_entrust = '[CLASS:Button; INSTANCE:23]'
        self.cid_buy_able = '[CLASS:Static; INSTANCE:12]'
        self.cid_sell_code = '[CLASS:Edit; INSTANCE:15]'
        self.cid_sell_price = '[CLASS:Edit; INSTANCE:16]'
        self.cid_sell_volume = '[CLASS:Edit; INSTANCE:19]'
        self.cid_sell_entrust = '[CLASS:Button; INSTANCE:44]'
        self.cid_sell_able = '[CLASS:Static; INSTANCE:102]'
        self.cid_cancel_refresh = '[CLASS:Button; INSTANCE:60]'
        self.cid_cancel_selectall = '[CLASS:Button; INSTANCE:62]'
        self.cid_cancel_do = '[CLASS:Button; INSTANCE:59]'
        self.wid_export = u'[CLASS:#32770; TITLE:输出]'
        self.cid_export_edit = '[CLASS:Edit; INSTANCE:1]'
        self.cid_export_ok = '[CLASS:Button; INSTANCE:9]'
        self.cid_property_refresh = '[CLASS:Button; INSTANCE:45]'
        self.cid_property_export = '[CLASS:Button; INSTANCE:51]'
        self.cid_entrust_refresh = '[CLASS:Button; INSTANCE:89]'
        self.cid_entrust_export = '[CLASS:Button; INSTANCE:95]'
        self.cid_trade_refresh = '[CLASS:Button; INSTANCE:133]'
        self.cid_trade_export = '[CLASS:Button; INSTANCE:139]'

#==================================================================

class HaiTongInterface(HaiTongTDX, Interface):
    def __init__(self, account):
        if account not in ACCOUNTS:
            raise InitError('account %s is not registered' % (account))
        super(HaiTongInterface, self).__init__(BROKER, account, LOCAL_BASE_DIR, EXPORT_BASE_DIR)

#------------------------------------------------------------------

    def get_reg_accounts(self):
        return ACCOUNTS[:]

#------------------------------------------------------------------

    def buy(self, code, price, volume):
        return self._entrust_0('b', code, price, volume)

#------------------------------------------------------------------

    def sell(self, code, price, volume):
        return self._entrust_0('s', code, price, volume)

#------------------------------------------------------------------

    def cancel_all(self):
        return self._cancel_all()

#------------------------------------------------------------------

    def get_balance(self, **kwargs):
        if 'day' in kwargs:
            return self._get_balance_byday(kwargs['day'])
        else:
            return self._get_balance_today()

#------------------------------------------------------------------

    def get_position(self, **kwargs):
        if 'day' in kwargs:
            return self._get_position_byday(kwargs['day'])
        else:
            return self._get_position_today()

#------------------------------------------------------------------

    def get_entrust(self, **kwargs):
        if 'day' in kwargs:
            return self._get_entrust_byday(kwargs['day'])
        else:
            return self._get_entrust_today()

#------------------------------------------------------------------

    def get_filled_result(self, **kwargs):
        if 'day' in kwargs:
            return self._get_traded_byday(kwargs['day'])
        else:
            return self._get_traded_today()

#==================================================================

class HaiTongService(HaiTongTDX):
    def __init__(self, account):
        if account not in ACCOUNTS:
            raise InitError('account %s is not registered' % (account))
        super(HaiTongService, self).__init__(BROKER, account, LOCAL_BASE_DIR, EXPORT_BASE_DIR)

#------------------------------------------------------------------

    def get_reg_accounts(self):
        return ACCOUNTS[:]

#------------------------------------------------------------------

    @log_call_error
    def _export(self, type):
        ret_code = -1
        ret_value = None
        error_msg = ''
        if type == 'property':
            cid_refresh = self.cid_property_refresh
            cid_export = self.cid_property_export
            export_path = self.src_property_path
        elif type == 'entrust':
            cid_refresh = self.cid_entrust_refresh
            cid_export = self.cid_entrust_export
            export_path = self.src_entrust_path
        elif type == 'trade':
            cid_refresh = self.cid_trade_refresh
            cid_export = self.cid_trade_export
            export_path = self.src_trade_path
        else:
            error_msg = 'invalid type : %s' % (type)
            return (ret_code, ret_value, error_msg, self.export_log_path)
        ret_code = 1
        try:
            autoit.control_click(self.wid_main, cid_refresh)
            time.sleep(5)
            autoit.control_click(self.wid_main, cid_export)
            if autoit.win_wait(self.wid_export, timeout=3) == 1:
                ret_code = 2
                autoit.win_activate(self.wid_export)
                autoit.control_set_text(self.wid_export, self.cid_export_edit, export_path)
                autoit.control_click(self.wid_export, self.cid_export_ok)
                if autoit.win_wait(self.wid_notepad, timeout=5) == 1:
                    ret_code = 3
                    autoit.win_close(self.wid_notepad)
                    ret_code = 0
        except autoit.AutoItError:
            error_msg = traceback.format_exc()
        return (ret_code, ret_value, error_msg, self.export_log_path)

#------------------------------------------------------------------

    @log_call_error
    def _parse_property(self):
        ret_code = -1
        ret_value = None
        error_msg = ''

        src_path = self.src_property_path
        fund_path = self.dst_fund_path
        position_path = self.dst_position_path

        src_file = None
        fund_file = None
        position_file = None

        try:
            src_file = codecs.open(src_path, 'r', 'gbk')
            fund_file = open(fund_path, 'w')
            position_file = open(position_path, 'w')
        except IOError:
            if src_file : src_file.close()
            if fund_file : fund_file.close()
            if position_file : position_file.close()
            error_msg = traceback.format_exc()
            return (ret_code, ret_value, error_msg, self.export_log_path)

        ret_code = 1

        try:
            for line in src_file:
                if len(line) < 50 or line.find(u'证券代码') == 0 or line.find(u'没有相应的查询信息!') != -1 or\
                    line.find(u'美  元') == 0 or line.find(u'港  币') == 0: 
                    continue
                elif line.find('--------') == 0:
                    ret_code = 2
                elif line.find(u'人民币') == 0:
                    out = {}
                    tokens = line.strip().split(':')
                    out['rc'] = tokens[2].split()[0]
                    out['ac'] = tokens[3].split()[0]
                    out['mv'] = tokens[5].split()[0]
                    out['ta'] = tokens[6].split()[0]
                    fund_file.write(json.dumps(out) + u'\n')
                else:
                    out = {}
                    tokens = list(filter(lambda x : x != '', map(unicode.strip, line.strip().split('     '))))
                    out['sc'] = tokens[0]
                    out['vo'] = tokens[2]
                    out['av'] = tokens[3]
                    position_file.write(json.dumps(out) + u'\n') 
            position_file.close()
            fund_file.close()
            src_file.close()
            ret_code = 0
        except IOError:
            ret_code = 3
            error_msg = traceback.format_exc()            
        except ParseError:
            ret_code = 4
            error_msg = traceback.format_exc()
        return (ret_code, ret_value, error_msg, self.export_log_path)

#------------------------------------------------------------------

    @log_call_error
    def _parse_entrust(self):
        ret_code = -1
        ret_value = None
        error_msg = ''

        src_path = self.src_entrust_path
        dst_path = self.dst_entrust_path

        src_file = None
        dst_file = None

        try:
            src_file = codecs.open(src_path, 'r', 'gbk')
            dst_file = open(dst_path, 'w')
        except IOError:
            if src_file : src_file.close()
            if dst_file : dst_file.close()
            error_msg = traceback.format_exc()
            return (ret_code, ret_value, error_msg, self.export_log_path)

        ret_code = 1

        try:
            for line in src_file:
                if len(line) < 50 or line.find('-------') == 0 or line.find(u'证券名称') == 0 or \
                    line.find(u'没有相应的查询信息!') != -1:
                    continue
                else:                    
                    out = {}
                    tokens = list(filter(lambda x : x != '', map(unicode.strip, line.strip().split('     '))))
                    token = tokens[1]
                    if token == u'买':
                        out['ot'] = 'b'
                    elif token == u'卖':
                        out['ot'] = 's'
                    elif token == u'申':
                        out['ot'] = 'x'
                    else:
                        raise ParseError('invalid bs : %s' % (line))
                    out['pr'] = tokens[2]
                    out['vo'] = tokens[3]
                    out['tp'] = tokens[4]
                    out['tv'] = tokens[5]
                    token = tokens[6]
                    if token == u'未成交':
                        out['st'] = '0'
                    elif token == u'部分成交':
                        out['st'] = '3'
                    elif token == u'已成交':
                        out['st'] = '1'
                    elif token == u'部分撤单':
                        out['st'] = '4'
                    elif token == u'场内撤单' or token == u'场外撤单':
                        out['st'] = '2'
                    else:
                        raise ParseError('invalid status : %s' % (line))
                    out['on'] = tokens[8]
                    out['sc'] = tokens[9]
                    dst_file.write(json.dumps(out) + u'\n')
            src_file.close()
            dst_file.close()
            ret_code = 0
        except IOError:
            ret_code = 2
            error_msg = traceback.format_exc()
        except ParseError:
            ret_code = 3
            error_msg = traceback.format_exc()
        return (ret_code, ret_value, error_msg, self.export_log_path)

#------------------------------------------------------------------

    @log_call_error
    def _parse_trade(self):
        ret_code = -1
        ret_value = None
        error_msg = ''

        src_path = self.src_trade_path
        dst_path = self.dst_trade_path

        src_file = None
        dst_file = None

        try:
            src_file = codecs.open(src_path, 'r', 'gbk')
            dst_file = open(dst_path, 'w')
        except IOError:
            if src_file : src_file.close()
            if dst_file : dst_file.close()
            error_msg = traceback.format_exc()
            return (ret_code, ret_value, error_msg, self.export_log_path)

        ret_code = 1

        try:
            for line in src_file:
                if len(line) < 50 or line.find('-------') == 0 or line.find(u'证券名称') == 0 or\
                    line.find(u'没有相应的查询信息!') != -1:
                    continue
                else:
                    out = {}
                    tokens = list(filter(lambda x : x != '', map(unicode.strip, line.strip().split('     '))))
                    out['ts'] = tokens[1]
                    token = tokens[2]
                    if token == u'买':
                        out['ot'] = 'b'
                    elif token == u'卖':
                        out['ot'] = 's'
                    elif token == u'申':
                        bs = 'x'
                    else:
                        raise ParseError('invalid bs : %s' % (line))
                    out['fp'] = tokens[3]
                    out['fv'] = tokens[4]
                    out['on'] = tokens[7]
                    out['sc'] = tokens[8]
                    dst_file.write(json.dumps(out) + u'\n')
            src_file.close()
            dst_file.close()
            ret_code = 0
        except IOError:
            ret_code = 2
            error_msg = traceback.format_exc()
        except ParseError:
            ret_code = 3
            error_msg = traceback.format_exc()
        return (ret_code, ret_value, error_msg, self.export_log_path)

#------------------------------------------------------------------

