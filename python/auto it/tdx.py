#coding=utf-8

from abc import ABCMeta, abstractmethod
import time, traceback

from wrapper import log_call, log_call_error
from model import Balance, Position, Entrust, FilledResult
import tools, monitor

import autoit
import winsound, json

#==================================================================

class Frame(object):
    __metaclass__ = ABCMeta

    def __init__(self, broker, account, local_base_dir, export_base_dir):
        self.trading_day = time.strftime('%Y%m%d',time.localtime(time.time()))
        self.broker = broker
        self.account = account
        self.local_log_path = '%s\\%s\\%s.log' % (local_base_dir, account, self.trading_day)
        self.export_basedir = '%s\\%s' % (export_base_dir, account)
        self.export_dir = '%s\\%s\\%s' % (export_base_dir, account, self.trading_day)
        self.export_log_path = '%s\\export.log' % (self.export_dir)
        self.src_property_path = '%s\\property.txt' % (self.export_dir)
        self.src_entrust_path = '%s\\entrust.txt' % (self.export_dir)
        self.src_trade_path = '%s\\trade.txt' % (self.export_dir)
        self.dst_fund_path = '%s\\_fund.txt' % (self.export_dir)
        self.dst_position_path = '%s\\_position.txt' % (self.export_dir)
        self.dst_entrust_path = '%s\\_entrust.txt' % (self.export_dir)
        self.dst_trade_path = '%s\\_trade.txt' % (self.export_dir)
        tools.ensure_dir(self.local_log_path)
        tools.ensure_dir(self.export_log_path)

#------------------------------------------------------------------

    def _get_balance_today(self):
        return self._get_balance(self.dst_fund_path)

    def _get_balance_byday(self, day):
        return self._get_balance('%s\\%s\\%s' % (self.export_basedir, day, '_fund.txt'))

    @log_call_error
    def _get_balance(self, path):
        ret_code = 0
        ret_value = {}
        error_msg = ''
        try:
            f = open(path, 'r')
            for line in f:
                if len(line) < 10 : continue
                raw_data = json.loads(line.strip())
                ret_value['RMP'] = Balance(raw_data)
            f.close()
        except IOError:
            ret_code = 1
            error_msg = traceback.format_exc()
        except:
            ret_code = 2
            error_msg = traceback.format_exc()
        return (ret_code, ret_value, error_msg, self.local_log_path)

#------------------------------------------------------------------

    def _get_position_today(self):
        return self._get_position(self.dst_position_path)

    def _get_position_byday(self, day):
        return self._get_position('%s\\%s\\%s' % (self.export_basedir, day, '_position.txt'))

    @log_call_error
    def _get_position(self, path):
        ret_code = 0
        ret_value = []
        error_msg = ''        
        try:
            f = open(path, 'r')
            for line in f:
                if len(line) < 10 : continue
                raw_data = json.loads(line.strip())
                ret_value.append(Position(raw_data))
            f.close()
        except IOError:
            ret_code = 1
            error_msg = traceback.format_exc()
        except:
            ret_code = 2
            error_msg = traceback.format_exc()
        return (ret_code, ret_value, error_msg, self.local_log_path)

#------------------------------------------------------------------

    def _get_traded_today(self):
        return self._get_traded(self.dst_trade_path)

    def _get_traded_byday(self, day):
        return self._get_traded('%s\\%s\\%s' % (self.export_basedir, day, '_trade.txt'))

    @log_call_error
    def _get_traded(self, path):
        ret_code = 0
        ret_value = []
        error_msg = ''
        try:
            f = open(path, 'r')
            for line in f:
                if len(line) < 10 : continue
                raw_data = json.loads(line.strip())
                ret_value.append(FilledResult(raw_data))
            f.close()
        except IOError:
            ret_code = 1
            error_msg = traceback.format_exc()
        except:
            ret_code = 2
            error_msg = traceback.format_exc()
        return (ret_code, ret_value, error_msg, self.local_log_path)

#------------------------------------------------------------------

    def _get_entrust_today(self):
        return self._get_entrust(self.dst_entrust_path)

    def _get_entrust_byday(self, day):
        return self._get_entrust('%s\\%s\\%s' % (self.export_basedir, day, '_entrust.txt'))

    @log_call_error
    def _get_entrust(self, path):
        ret_code = 0
        ret_value = []
        error_msg = ''
        try:
            f = open(path, 'r')
            for line in f:
                if len(line) < 10 : continue
                raw_data = json.loads(line.strip())
                ret_value.append(Entrust(raw_data))
            f.close()
        except IOError:
            ret_code = 1
            error_msg = traceback.format_exc()
        except:
            ret_code = 2
            error_msg = traceback.format_exc()
        return (ret_code, ret_value, error_msg, self.local_log_path)

#------------------------------------------------------------------

    def run_monitor(self, type):
        if type == 'local':            
            row = 0
            while tools.islive():                
                (begin, end) = monitor.get_err_linenum(row, self.local_log_path)
                if begin != 0:
                    print '[ERR] line %i~%i : %s' % (begin, end, self.local_log_path)
                    row = end + 1
                    winsound.PlaySound('SystemHand', winsound.SND_ALIAS)
                print '%s monitor %s %s' % (time.strftime('%Y%m%d %H:%M:%S',time.localtime(time.time())), self.broker, self.account)
                time.sleep(30)

        elif type == 'export':
            overtime = 60
            row = 0
            #items = [self.src_property_path, self.src_entrust_path, self.src_trade_path,\
            #    self.dst_fund_path, self.dst_position_path, self.dst_entrust_path, self.dst_trade_path]
            items = [self.src_property_path, self.src_entrust_path, \
                self.dst_fund_path, self.dst_position_path, self.dst_entrust_path]
            while tools.islive():
                alert = False
                def monitor_mtime(path):
                    if monitor.mtime_overtime(path, overtime):
                        print 'expired : %s' % (path)
                        alert = True                
                (begin, end) = monitor.get_err_linenum(row, self.export_log_path)
                if begin != 0:
                    print '[ERR] line %i~%i : %s' % (begin, end, self.export_log_path)
                    row = end + 1
                    alert = True                
                map(monitor_mtime, items)
                if alert: winsound.PlaySound('SystemHand', winsound.SND_ALIAS)
                print '%s monitor %s %s' % (time.strftime('%Y%m%d %H:%M:%S',time.localtime(time.time())), self.broker, self.account)
                time.sleep(10)

#------------------------------------------------------------------

    def export_parse_property(self):
        self._export('property')
        self._parse_property()

    def export_parse_entrust(self):
        self._export('entrust')
        self._parse_entrust()

    def export_parse_traded(self):
        self._export('trade')
        self._parse_trade()

    #def run_export(self):
    #    while tools.islive():
    #        self._export('property')
    #        self._export('entrust')
    #        self._export('trade')
    #        self._parse_property()
    #        self._parse_entrust()
    #        self._parse_trade()
    #        print '%s export %s %s' % (time.strftime('%Y%m%d %H:%M:%S',time.localtime(time.time())), self.broker, self.account)

#------------------------------------------------------------------

    @abstractmethod
    def get_reg_accounts(self):
        pass

#==================================================================

class TDX(Frame):
    wid_notepad = '[CLASS:Notepad]'
    wid_main = '[CLASS:TdxW_MainFrame_Class]'

    def __init__(self, broker, account, local_base_dir, export_base_dir):
        return super(TDX, self).__init__(broker, account, local_base_dir, export_base_dir)

#------------------------------------------------------------------

    def clean_dlg(self):
        try:
            if autoit.win_exists(self.wid_prompt):
                autoit.win_activate(self.wid_prompt)
                autoit.control_click(self.wid_prompt, self.cid_prompt_ok)
        except autoit.AutoItError:
            pass

#------------------------------------------------------------------

    @log_call
    def _entrust_0(self, direction, code, price, volume):
        ret_code = -1
        ret_value = tools.get_timestamp()
        error_msg = ''
        
        if direction == 'b':
            cid_code = self.cid_buy_code
            cid_price = self.cid_buy_price
            cid_volume = self.cid_buy_volume
            cid_able = self.cid_buy_able
            cid_entrust = self.cid_buy_entrust
            wait_flag = True
        elif direction == 's':
            cid_code = self.cid_sell_code
            cid_price = self.cid_sell_price
            cid_volume = self.cid_sell_volume
            cid_able = self.cid_sell_able
            cid_entrust = self.cid_sell_entrust
            wait_flag = False
        else:
            error_msg = 'unexpected direction'
            return (ret_code, ret_value, error_msg, self.local_log_path)

        ret_code = 1

        try:
            autoit.win_activate(self.wid_main)
            self.clean_dlg()
            autoit.control_set_text(self.wid_main, cid_code, code)
            if wait_flag:
                for count in range(30):
                    if autoit.control_get_text(self.wid_main, cid_able) != '':
                        ret_code = 2
                        break
                    else:
                        time.sleep(0.1)
                if ret_code != 2:
                    error_msg = 'code response timeout'
                    return (ret_code, ret_value, error_msg, self.local_log_path)
        
            ret_code = 3
            
            autoit.control_set_text(self.wid_main, cid_price, price)
            autoit.control_set_text(self.wid_main, cid_volume, volume)
            #autoit.win_activate(self.wid_main)
            autoit.control_click(self.wid_main, cid_entrust)

            ret_code = 4

            if autoit.win_wait(self.wid_prompt, timeout=3) == 1:
                #autoit.win_activate(self.wid_prompt)
                autoit.control_click(self.wid_prompt, self.cid_prompt_ok)
                ret_code = 0
            
        except autoit.AutoItError:
            error_msg = traceback.format_exc()
    
        return (ret_code, ret_value, error_msg, self.local_log_path)

#------------------------------------------------------------------

    @log_call
    def _entrust_1(self, direction, code, price, volume):
        ret_code = -1
        ret_value = tools.get_timestamp()
        error_msg = ''
        
        if direction == 'b':
            cid_code = self.cid_buy_code
            cid_price = self.cid_buy_price
            cid_volume = self.cid_buy_volume
            cid_able = self.cid_buy_able
            cid_entrust = self.cid_buy_entrust
            wait_flag = True
        elif direction == 's':
            cid_code = self.cid_sell_code
            cid_price = self.cid_sell_price
            cid_volume = self.cid_sell_volume
            cid_able = self.cid_sell_able
            cid_entrust = self.cid_sell_entrust
            wait_flag = False
        else:
            error_msg = 'unexpected direction'
            return (ret_code, ret_value, error_msg, self.local_log_path)
        
        ret_code = 1

        try:
            autoit.win_activate(self.wid_main)
            self.clean_dlg()
            autoit.control_set_text(self.wid_main, cid_code, code)

            if wait_flag:
                for count in range(30):
                    if autoit.control_get_text(self.wid_main, cid_able) != '':
                        ret_code = 2
                        break
                    else:
                        time.sleep(0.1)
                if ret_code != 2:
                    error_msg = 'code response timeout'
                    return (ret_code, ret_value, error_msg, self.local_log_path)
        
            ret_code = 3

            autoit.control_set_text(self.wid_main, cid_price, price)
            autoit.control_set_text(self.wid_main, cid_volume, volume)
            #autoit.win_activate(self.wid_main)
            autoit.control_click(self.wid_main, cid_entrust)
            ret_code = 0
        except autoit.AutoItError:
            error_msg = traceback.format_exc()
    
        return (ret_code, ret_value, error_msg, self.local_log_path)

#------------------------------------------------------------------

    @log_call
    def _cancel_all(self):
        ret_code = -1
        ret_value = tools.get_timestamp()
        error_msg = ''

        try:
            autoit.win_activate(self.wid_main)
            self.clean_dlg()
            autoit.control_click(self.wid_main, self.cid_cancel_refresh)
            autoit.control_click(self.wid_main, self.cid_cancel_refresh)
            ret_code = 1
            time.sleep(5)
            autoit.control_click(self.wid_main, self.cid_cancel_selectall)
            ret_code = 2
            time.sleep(0.5)
            autoit.control_click(self.wid_main, self.cid_cancel_do)
            ret_code = 3
    
            if autoit.win_wait(self.wid_prompt, timeout=5) == 1:
                #autoit.win_activate(self.wid_prompt)
                autoit.control_click(self.wid_prompt, self.cid_prompt_ok)
                ret_code = 4

                if autoit.win_wait(self.wid_prompt, timeout=20) == 1:
                    #autoit.win_activate(self.wid_prompt)
                    autoit.control_click(self.wid_prompt, self.cid_prompt_ok)
                    ret_code = 0
        except:
            error_msg = traceback.format_exc()
    
        return (ret_code, ret_value, error_msg, self.local_log_path)

#==================================================================