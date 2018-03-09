# -*- coding: UTF-8 -*-
## =============================================================================
from datetime import *
print "\n" + "-"*80
print ">> " + datetime.now().strftime('%Y-%m-%d %H:%M:%S') + " << sendMail_FundReporting.py"
print '-'*80 + '\n'

import smtplib
import urllib, urllib2
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication
from email.mime.text import MIMEText
from email.header import Header

import pandas as pd
from datetime import datetime
import csv
import time
import subprocess
import os, sys
## =============================================================================


## =============================================================================
## ChinaFuturesCalendar
## =============================================================================
################################################################################
TradingDay = []
with open('/home/fl/myData/data/ChinaFuturesCalendar/ChinaFuturesCalendar_2011_2017.csv') as f:
    ChinaFuturesCalendar = csv.reader(f)
    for row in ChinaFuturesCalendar:
        if row[1] >= '20170101':
            TradingDay.append(row[1])
TradingDay.pop(0)
if datetime.now().strftime("%Y%m%d") not in TradingDay:
    print '#'*80
    sys.exit("启禀圣上，今日赌场不开张!!!")
    print '#'*80
################################################################################

## =============================================================================
subprocess.call(["/usr/bin/Rscript", "/home/fl/myData/R/Misc/FundReporting.R"])
time.sleep(3)
subprocess.call(["/usr/bin/Rscript", "/home/fl/myData/R/Misc/moneyFund_Linux.R"])
time.sleep(3)
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
currTradingDay = ChinaFuturesCalendar.loc[ChinaFuturesCalendar.days == datetime.now().date().strftime('%Y%m%d'), 'days'].values[0]
## =============================================================================

## -----------------------------------------------------------------------------
sender = 'trader' + '@hicloud.com'

'''
receiversMain = ['fl@hicloud-investment.com','lhg@hicloud-investment.com']
receiversAttchment = ['lxo@hicloud-investment.com','jy@hicloud-investment.com']
receiversOthers = ['lcy@hicloud-investment.com','wjh@hicloud-investment.com','fl@hicloud-investment.com']
'''

#'''
receiversMain = ['fl@hicloud-investment.com']
receiversAttchment = ['lxo@hicloud-investment.com','jy@hicloud-investment.com','fl@hicloud-investment.com']
receiversOthers = ['fl@hicloud-investment.com']
#'''

## -----------------------------------------------------------------------------


################################################################################
## main
msg = MIMEMultipart()
################################################################################

## =============================================================================
fp = open("/home/fl/myData/log/FundReporting/" + currTradingDay + ".txt", "r")
puretext = MIMEText(fp.read().decode('string-escape').decode("utf-8"), 'plain', 'utf-8')
fp.close()
msg.attach(puretext)

## =============================================================================
xlsxpart = MIMEApplication(open('/home/fl/myData/data/Fund/nav_YunYang1.xlsx', 'rb').read())
xlsxpart.add_header('Content-Disposition', 'attachment', filename='nav_YunYang1.xlsx')
msg.attach(xlsxpart)


## 显示:发件人
msg['From'] = Header(sender, 'utf-8')
## 显示:收件人
msg['To'] =  Header('汉云研究员', 'utf-8')

## 主题
subject = u'修正：' + currTradingDay + u'：交易数据'
msg['Subject'] = Header(subject, 'utf-8')

try:
    smtpObj = smtplib.SMTP('localhost')
    smtpObj.sendmail(sender, receiversMain, msg.as_string())
    print "#"*80
    print "邮件发送成功：==> " + ';'.join(receiversMain)
    print "#"*80
except smtplib.SMTPException:
    print "Error: 无法发送邮件"
################################################################################




################################################################################
## attachment
msg = MIMEMultipart()
################################################################################

## =============================================================================
fp = open("/home/fl/myData/log/FundReporting/" + currTradingDay + "_fund.txt", "r")
puretext = MIMEText(fp.read().decode('string-escape').decode("utf-8"), 'plain', 'utf-8')
fp.close()
msg.attach(puretext)

## =============================================================================
xlsxpart = MIMEApplication(open('/home/fl/myData/data/Fund/nav_YunYang1.xlsx', 'rb').read())
xlsxpart.add_header('Content-Disposition', 'attachment', filename='nav_YunYang1.xlsx')
msg.attach(xlsxpart)


## 显示:发件人
msg['From'] = Header(sender, 'utf-8')
## 显示:收件人
msg['To'] =  Header('汉云交易员', 'utf-8')

## 主题
subject = u'修正：' + currTradingDay + u'：基金数据'
msg['Subject'] = Header(subject, 'utf-8')

try:
    smtpObj = smtplib.SMTP('localhost')
    smtpObj.sendmail(sender, receiversAttchment, msg.as_string())
    print "#"*80
    print "邮件发送成功：==> " + ';'.join(receiversAttchment)
    print "#"*80
except smtplib.SMTPException:
    print "Error: 无法发送邮件"
################################################################################
