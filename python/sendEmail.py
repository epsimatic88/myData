# -*- coding: UTF-8 -*-
## =============================================================================
import smtplib
from email.mime.text import MIMEText
from email.header import Header

import pandas as pd
from datetime import datetime
import time
import subprocess
subprocess.call(["/usr/bin/Rscript", "/home/fl/myData/R/DataMonitor.R"])
time.sleep(10)
## =============================================================================


## =============================================================================
## ChinaFuturesCalendar
## =============================================================================
ChinaFuturesCalendar = pd.read_csv('/home/fl/myData/data/ChinaFuturesCalendar/ChinaFuturesCalendar_2011_2017.csv')
## -----------------------------------------------------------------------------
ChinaFuturesCalendar = ChinaFuturesCalendar[ChinaFuturesCalendar['days'].fillna(0) >= 20170101].reset_index(drop = True)
# print ChinaFuturesCalendar.dtypes
ChinaFuturesCalendar.days = ChinaFuturesCalendar.days.apply(str)
ChinaFuturesCalendar.nights = ChinaFuturesCalendar.nights.apply(str)
for i in range(len(ChinaFuturesCalendar)):
    ChinaFuturesCalendar.at[i, 'nights'] = ChinaFuturesCalendar.at[i, 'nights'].replace('.0','')
## 当前交易日期
currTradingday = ChinaFuturesCalendar.loc[ChinaFuturesCalendar.days == datetime.now().date().strftime('%Y%m%d'), 'days'].values[0]
## =============================================================================

## -----------------------------------------------------------------------------
sender = 'MySQL' + '@hicloud.com'
# receivers = ['fl@hicloud-investment.com','lhg@hicloud-investment.com']  # 接收邮件
# receivers = ['fl@hicloud-investment.com','lhg@hicloud-investment.com']
receiversMain = ['fl@hicloud-investment.com','lhg@hicloud-investment.com']
receiversOthers = ['zgctrading@qq.com']
## -----------------------------------------------------------------------------


## -----------------------------------------------------------------------------
# 三个参数：第一个为文本内容，第二个 plain 设置文本格式，第三个 utf-8 设置编码
## 内容
# message = MIMEText('Python 邮件发送测试...', 'plain', 'utf-8')

## -----------------------------------------------------------------------------
# message = MIMEText(stratYY.strategyID, 'plain', 'utf-8')

# fp = codecs.open("/tmp/tradingRecord.txt", "r", "utf-8")
fp = open("/home/fl/myData/log/dailyDataLog_" + currTradingday + ".txt", "r")
message = MIMEText(fp.read().decode('string-escape').decode("utf-8"), 'plain', 'utf-8')
fp.close()

## 显示:发件人
message['From'] = Header(sender, 'utf-8')
## 显示:收件人
message['To'] =  Header('汉云数据员', 'utf-8')

## 主题
subject = currTradingday + u'：数据监控'
message['Subject'] = Header(subject, 'utf-8')

try:
    smtpObj = smtplib.SMTP('localhost')
    smtpObj.sendmail(sender, receiversMain, message.as_string())
    print "邮件发送成功"
except smtplib.SMTPException:
    print "Error: 无法发送邮件"

################################################################################

# fp = codecs.open("/tmp/tradingRecord.txt", "r", "utf-8")
fp = open("/home/fl/myData/log/dailyDataLog_" + currTradingday + ".txt", "r")
lines = fp.readlines()
l = lines[0:([i for i in range(len(lines)) if 'lhg_trade.fl_open_t' in lines[i]][0] - 1)]
message = MIMEText(''.join(l).decode('string-escape').decode("utf-8"), 'plain', 'utf-8')
fp.close()

## 显示:发件人
message['From'] = Header(sender, 'utf-8')
## 显示:收件人
message['To'] =  Header('汉云数据员', 'utf-8')

## 主题
subject = currTradingday + u'：数据监控'
message['Subject'] = Header(subject, 'utf-8')

try:
    smtpObj = smtplib.SMTP('localhost')
    smtpObj.sendmail(sender, receiversMain, message.as_string())
    print "邮件发送成功"
except smtplib.SMTPException:
    print "Error: 无法发送邮件"
