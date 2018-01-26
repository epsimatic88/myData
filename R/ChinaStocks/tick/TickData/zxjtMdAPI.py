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

BrokerID = u'中信建投'
currTradingDay = datetime.now().strftime("%Y%m%d")
DATA_PATH = '/data/ChinaStocks/TickData/FromZXJT/%s' % currTradingDay


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
# currTradingDay = datetime.now().strftime("%Y%m%d")

if not os.path.exists(DATA_PATH):
    os.makedirs(DATA_PATH)
## =============================================================================


## =============================================================================
## 获取交易数据
## 实际上为 一档 行情数据的成交情况
## 600000 -> /3/%s/1/1/
## 000000 -> /3/%s/2/1/
## 
## 900000 -> /4/%s/1/1/
## 200000 -> /4/%s/2/1/
## 
## 002000 -> /5/%s/2/1/
## 300000 -> /6/%s/2/1/
## 
def fetchTrade(code):
    ## -------------------------------------------------------------------------
    code = str(code)

    ## -------------------------------------------------------------------------
    destFile = DATA_PATH + '/%s.csv' %code
    if os.path.isfile(destFile):
        print u'%s 数据文件已下载' %code
        return
    ## -------------------------------------------------------------------------

    if code[:2] in ['60','90']:
        market = '1'
    elif code[:3] in ['000','001','002','200','300']:
        market = '2'

    if (code[:2] in ['60'] or code[:3] in ['000','001']):
        site = '3'
    elif code[:2] in ['90','20']:
        site = '4'
    elif code[:3] in ['002']:
        site = '5'
    elif code[:3] in ['300']:
        site = '6'
        ## -------------------------------------------------------------------------
    url = 'https://e.csc108.com/hq/resource/symbols/%s/%s/%s/1/trades?query={"toNo":100000,"fromNo":1}' %(site, code, market)

    try:
        r = requests.get(url)
    except:
        print u"%s 连接服务器失败" %code
        return

    soup = BeautifulSoup(r.content, 'lxml')
    temp = json.loads(soup.findAll('p')[0].string)
    if temp[u'total'] == 0:
        return

    data = pd.DataFrame(temp['symbolTrades'])

    for i in range(len(data)):
        data.at[i, 'updateTime'] = datetime.fromtimestamp(data.at[i, 'time']/1000).strftime("%Y-%m-%d %H:%M:%S")

    data['code'] = code

    cols = ['code','updateTime','presentPrice','bs','ask','bid','volume','largeOrder']
    data = data[cols]

    with open(destFile, 'wb') as f:
        data.to_csv(f, index = False)
    # print data
    print u'%s 数据文件下载成功' %code
    return data
## =============================================================================


# data = fetchTrade('600516')
# data = fetchTrade('000004')
# data = fetchTrade('002001')
# data = fetchTrade('300005')


symbolList = fetchMySQL(db = 'china_stocks_info', 
                        query = "select * from stocks_list")

## =============================================================================
t1 = datetime.now()
for i in range(5):
    pool = multiprocessing.Pool(processes = 8)
    pool.map(fetchTrade, symbolList.stockID.values)
t2 = datetime.now()
print (t2 -t1).total_seconds()
## =============================================================================

# t1 = datetime.now()
# for i in range(len(symbolList)):
#     code = symbolList.at[i, 'stockID']
#     print code
#     fetchTrade(code)
# t2 = datetime.now()

