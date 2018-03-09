################################################################################
## productInfo.R
## 这是主函数:
## 从 CTP 接收的文件提取合约相关信息
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-10-16
################################################################################

################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("dce2mysql.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})

################################################################################
## STEP 1: 获取对应的交易日期
################################################################################
ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
                              colClasses = list(character = c("nights","days")))
dataPath <- '/data/ChinaFuturesTickData/FromPC/vn.data/XiFu/ContractInfo'

## 获得最新的数据文件
dataFile <- dataPath %>% 
            list.files() %>% 
            .[which.max(gsub('\\.csv','',.))]


################################################################################
## STEP 2: 提取信息
################################################################################
dt <- fread(paste(dataPath,dataFile, sep = '/'))

dtProductInfo <- dt[,.SD] %>%
                    .[nchar(vtSymbol) < 8] %>% 
                    .[, ':='(

                    )]

