################################################################################
## shfe.R
## 用于下载上期所期货公司持仓排名数据
##
## Author: William Fang
## Date  : 2017-08-21
################################################################################
rm(list = ls())
library(data.table)
library(magrittr)

file <- "/home/william/Documents/updateIndex/data/南华商品指数.xlsx"

dt <- readxl::read_excel(file) %>% as.data.table() %>% 
        .[!is.na(日期)]
colnames(dt) <- c('TradingDay','open','high','low','close',
                  'turnover','volume')
dt <- dt[, .(TradingDay, close)]

## =============================================================================
source('myInit.R')
mysql <- mysqlFetch('MarketIndex')
dbWriteTable(mysql, 'Nanhua', dt, append = T, row.names = F)




