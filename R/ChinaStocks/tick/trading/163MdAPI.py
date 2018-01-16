#!/usr/bin/env python
# -*- coding:utf-8 -*- 

## =============================================================================
import sys
import os
reload(sys)
sys.setdefaultencoding('utf8')

import requests
from bs4 import BeautifulSoup
import pandas as pd
pd.options.display.float_format = '{:,.2f}'.format
from pprint import pprint
from datetime import datetime
from time import sleep
import json
import MySQLdb
import csv

import ast
import re
import multiprocessing

pd.set_option('display.width', 200)
## =============================================================================

BrokerID = u'网易'
currTradingDay = datetime.now().strftime("%Y%m%d")
# DATA_PATH = '/media/william/William/tmp/From163/%s' % currTradingDay
DATA_PATH = '/home/fl/myData/data/ChinaStocks/TradingData/From163/%s' % currTradingDay

################################################################################
## william
## 从 MySQL 数据库查询数据
################################################################################
#-------------------------------------------------------------------------------
def fetchMySQL(db, query):
    """ 从 MySQL 中读取数据 """
    try:
        conn = MySQLdb.connect(
            db = db, 
            host = '192.168.1.166', 
            port = 3306, 
            user = 'fl', 
            passwd = 'abc@123', 
            use_unicode = True, 
            charset = "utf8")
        cursor = conn.cursor()
        mysqlData = pd.read_sql(query, conn)
        return mysqlData
    except (MySQLdb.Error, MySQLdb.Warning, TypeError) as e:
        print e
        return None
    finally:
        conn.close()
#-------------------------------------------------------------------------------


## =============================================================================
calendar  = fetchMySQL(db = 'dev',
                       query = 'select * from ChinaFuturesCalendar')
## -----------------------------------------------------------------------------
if datetime.now().date() not in calendar.days.values:
    sys.exit('Not TradingDay!!!')
## -----------------------------------------------------------------------------

if not os.path.exists(DATA_PATH):
    os.makedirs(DATA_PATH)
## =============================================================================

headers = {
            "Accept"         : "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
            "Accept-Encoding": "gzip, deflate",
            "Accept-Language": "zh-CN,en-US;q=0.8,zh;q=0.6,en;q=0.4,zh-TW;q=0.2",
            "Connection"     : "keep-alive",
            "DNT"            : "1",
            "Host"           : "quotes.money.163.com",
            "Referer"        : "",
            "User-Agent"     : "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
            }

def fetchTrade(code):
    """获取分笔交易数据"""
    code = str(code)

    ## -------------------------------------------------------------------------
    destFile = DATA_PATH + '/%s.xls' %code
    if os.path.isfile(destFile):
        print u'%s 数据文件已下载' %code
        return
    ## -------------------------------------------------------------------------

    ## ----------------------------------------
    if code[:2] in ['60']:
        market = '0'
    elif code[:3] in ['000','001','002','300']:
        market = '1'
    ## ----------------------------------------

        ## -------------------------------------------------------------------------
    url = "http://quotes.money.163.com/cjmx/%s/%s/%s.xls" %(
           currTradingDay[:4], currTradingDay, market + code)
    headers['Referer'] = "http://quotes.money.163.com/trade/lsjysj_%s.html" %code
    ## -------------------------------------------------------------------------
    try:
        r = requests.get(url, headers = headers)
    except:
        print u"%s 连接服务器失败" %code
        return
    ## -------------------------------------------------------------------------

    ## -------------------------------------------------------------------------
    with open(destFile, 'wb') as f:
        f.write(r.content)
    print u'%s 数据文件下载成功' %code



# data = fetchTrade('600516')
# data = fetchTrade('000004')
# data = fetchTrade('002001')
# data = fetchTrade('300005')


symbolList = fetchMySQL(db = 'china_stocks_info', 
                        query = "select * from stocks_list")

## =============================================================================
t1 = datetime.now()
for i in range(2):
    pool = multiprocessing.Pool(processes = 8)
    pool.map(fetchTrade, symbolList.stockID.values)
t2 = datetime.now()
print (t2 -t1).total_seconds()
## =============================================================================
