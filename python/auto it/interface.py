#coding=utf-8

from abc import ABCMeta, abstractmethod

class Interface(object):
    __metaclass__ = ABCMeta

    @abstractmethod
    def buy(self, code, price, volume):
        '''
        parameter: all string type
        return: (ret_code, timestamp)
        ret_code: [0] success; [not 0] error
        '''
        pass

    @abstractmethod
    def sell(self, code, price, volume):
        '''
        parameter: all string type
        return: (ret_code, timestamp)
        ret_code: [0] success; [not 0] error
        '''
        pass

    @abstractmethod
    def cancel_all(self):
        '''
        return: (ret_code, timestamp)
        ret_code: [0] success; [not 0] error
        '''
        pass

    @abstractmethod
    def get_balance(self, **kwargs):
        '''
        return: (ret_code, ret_value)
        ret_code: [0] success; [1] IOError; [2] OtherError
        ret_value: dict, class Balance
        '''
        pass

    @abstractmethod
    def get_entrust(self, **kwargs):
        '''
        return: (ret_code, ret_value)
        ret_code: [0] success; [1] IOError; [2] OtherError
        ret_value: list, class Entrust
        '''
        pass

    @abstractmethod
    def get_position(self, **kwargs):
        '''
        return: (ret_code, ret_value)
        ret_code: [0] success; [1] IOError; [2] OtherError
        ret_value: list, class Position
        '''
        pass

    @abstractmethod
    def get_filled_result(self, **kwargs):
        '''
        return: (ret_code, ret_value)
        ret_code: [0] success; [1] IOError; [2] OtherError
        ret_value: list, class FilledResult
        '''
        pass

    @abstractmethod
    def get_reg_accounts(self):
        '''
        return: list, supported accounts
        '''
        pass
