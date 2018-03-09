################################################################################
##
## 这是主函数:
## 对比 oiRank 与原先的 china_futures_bar 数据的质量
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-11-
################################################################################


################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
options(width = 150)

dataPath <- 'data/oiRank/data'
################################################################################
## STEP 1: 获取对应的交易日期
################################################################################
ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
                              colClasses = list(character = c("nights","days")))

## =============================================================================
## dtRank
mysql <- mysqlFetch('china_futures_bar', host = '192.168.1.166')
dtRank <- dbGetQuery(mysql, "
  select * from oiRank
") %>% as.data.table() %>%
.[, TradingDay := gsub('-','',TradingDay)] %>%
.[, Rank := as.character(Rank)]

## dtOI
allDataFiles <- list.files(paste0(getwd(), '/', dataPath), pattern = '.csv')
dtOI <- lapply(allDataFiles, function(i){
  res <- paste0(getwd(), '/', dataPath, '/', i) %>%
          fread()
}) %>% rbindlist()
dtOI[, ':='(TradingDay = gsub('-','',TradingDay),
            Rank = as.character(Rank),
            Amount = as.numeric(Amount),
            DiffAmount = as.numeric(DiffAmount))]
## =============================================================================
x <- dtRank[TradingDay %between% c('20110101','20171101')]
y <- dtOI[TradingDay %between% c('20110101','20171101')]
dt <- merge(x,
            y,
            by = c('TradingDay', 'InstrumentID', 'ClassID', 'Rank'),
            all = TRUE)


dt[, ":="(
    errAmount = Amount.x - Amount.y,
    errDiffAmount = DiffAmount.x - DiffAmount.y
)]
dt[, errBrokerID := ifelse(BrokerID.x != BrokerID.y, 1, 0)]

dt[is.na(errAmount)][!is.na(Amount.x)]
dt[is.na(errDiffAmount)][!is.na(DiffAmount.x)]

dt[is.na(errAmount)][!is.na(Amount.y)]
dt[is.na(errDiffAmount)][!is.na(DiffAmount.y)]


dt[, summary(errAmount)]

dt[, summary(errDiffAmount)]

##
dt[errBrokerID == 1][,unique(TradingDay)]
dt[errBrokerID == 1][,unique(InstrumentID)]

## =============================================================================
mysql <- mysqlFetch('china_futures_bar', host = '192.168.1.166')
dbWriteTable(mysql, "oiRank",
             dtOI, row.name=FALSE, append = T)
