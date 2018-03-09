#!/usr/bin/env python
# -*- coding:utf-8 -*- 

# var DetailAll_300453={
# //A1:页码,A2:页大小,A3总记录数
# Page:{A1:2,A2:120,A3:515},
# //A1:证券id,A2:证券代码,A3:证券名称,A4:昨收,A5:总成交量,A6:总成交额,A7:总成交笔数
# Summary:{A1:"sz300453",A2:"300453",A3:"三鑫医疗",A4:16.55,A5:993000,A6:1.595731E7,A7:1038},
# //A1:价,A2:量,A3:额,A4:笔,A5:明细时间,A6:买卖盘

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

BrokerID = u'金融街'
currTradingDay = datetime.now().strftime("%Y%m%d")
DATA_PATH = '/data/ChinaStocks/TickData/FromJRJ/%s' % currTradingDay

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
            "Accept"         : "*/*",
            "Accept-Encoding": "gzip, deflate",
            "Accept-Language": "zh-CN,en-US;q=0.8,zh;q=0.6,en;q=0.4,zh-TW;q=0.2",
            "Connection"     : "keep-alive",
            "DNT"            : "1",
            "Host"           : "qmx.jrjimg.cn",
            "Referer"        : "",
            "User-Agent"     : "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
            }

def fetchTrade(code):
    """获取分笔交易数据"""
code = str(code)

## -------------------------------------------------------------------------
destFile = DATA_PATH + '/%s.csv' %code
if os.path.isfile(destFile):
    print u'%s 数据文件已下载' %code
    return
## -------------------------------------------------------------------------

# ## ----------------------------------------
# if code[:2] in ['60']:
#     market = '1'
# elif code[:3] in ['000','001','002','300']:
#     market = '2'
# ## ----------------------------------------

    ## -------------------------------------------------------------------------
url = "http://qmx.jrjimg.cn/mx.do"
payload = {"code": code,
           "page": "1",
           "size": '120'}
## -------------------------------------------------------------------------
try:
r = requests.get(url, headers = headers, params = payload)
except:
    print u"%s 连接服务器失败" %code
    return
## -------------------------------------------------------------------------

r = requests.get(url, headers = headers, params = payload)
soup = BeautifulSoup(r.content, "lxml")
data = soup.findAll('p')[0].string
data = re.sub(' ', '', data)
data = data.split('\r\n')
temp = [i for i in data if 'A5' in i and 'A6' in i]



data = json.loads(data[1:-1])
    if data['total'] == 0:
        print u"%s 获取分笔交易数据失败" %code
        return
    data = data['value']['data']
    dfHeader = ['updateTime','lastPrice','volume','bs','ud','deltaVolume',
                'unknown1','unknown2']
    dfData = []
    for i in range(len(data)):
        l = data[i].split(',')
        dfData.append(l)
    df = pd.DataFrame(dfData, columns = dfHeader)
    ## -------------------------------------------------------------------------
    with open(destFile, 'wb') as f:
        df.to_csv(f, index = False)
    print u'%s 数据文件下载成功' %code
    return df

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

