################################################################################
##! jydb_oiRank.R
##
## 对比 聚源数据.Fut_MemberRankByContract 与 oiRank
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-07-12
################################################################################

################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("jydb_oiRank.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})

## =============================================================================
## 从数据库读取 jydb 数据
mysql <- mysqlFetch('jydb')
dtJydb <- dbGetQuery(mysql,"
            SELECT EndDate as TradingDay,
                   ContractCode as InstrumentID,
                   RankNumber as Rank,
                   MemberAbbr as BrokerID,
                   IndicatorName as ClassID,
                   IndicatorVolume as Amount,
                   ChangeVolume as DiffAmount
            FROM Fut_MemberRankByContract;
") %>% as.data.table()
dtJydb[, ":="(
    TradingDay = substr(TradingDay,1,10),
    InstrumentID = toupper(InstrumentID),    ## 聚源的是全部大写
    BrokerID = iconv(BrokerID, from = 'GB18030', to = 'utf-8'),
    ClassID  = iconv(ClassID, from = 'GB18030', to = 'utf-8')
    )]
dtJydb[ClassID == '成交量统计', ClassID := 'Turnover']
dtJydb[ClassID == '持买仓量统计', ClassID := 'longPos']
dtJydb[ClassID == '持卖仓量统计', ClassID := 'shortPos']
## =============================================================================



## =============================================================================
## 从数据库读取 oiRank
mysql <- mysqlFetch('china_futures_bar')
dtOiRank <- dbGetQuery(mysql,paste("
            SELECT *
            FROM oiRank
            WHERE TradingDay between", dtJydb[,gsub('-','',min(TradingDay))],
            "AND ", dtJydb[,gsub('-','',max(TradingDay))])
) %>% as.data.table()
dtOiRank[,":="(
    InstrumentID = toupper(InstrumentID),    ## 聚源的是全部大写
    BrokerID = iconv(BrokerID, from = 'GB18030', to = 'utf-8')
)]
## =============================================================================


## =============================================================================
## dt
dt <- merge(dtJydb, dtOiRank,
    by = c('TradingDay', 'InstrumentID', 'ClassID', 'Rank'), all = TRUE)
dt

dt[, ":="(
    errAmount = Amount.x - Amount.y,
    errDiffAmount = DiffAmount.x - DiffAmount.y
)]
dt[, errBrokerID := ifelse(BrokerID.x != BrokerID.y, 1, 0)]

dt[, summary(errAmount)]

dt[, summary(errDiffAmount)]

##
dt[errBrokerID == 1][,unique(TradingDay)]
dt[errBrokerID == 1][,unique(InstrumentID)]

dt[TradingDay == '2017-01-03'][InstrumentID == 'C1701'][errBrokerID == 1]

dtJydb[TradingDay == '2017-01-03'][InstrumentID == 'C1703'][ClassID == 'Turnover'][order(Rank)]
dtOiRank[TradingDay == '2017-01-03'][InstrumentID == 'C1703'][ClassID == 'Turnover'][order(Rank)]
dt[TradingDay == '2017-01-03'][InstrumentID == 'C1703'][ClassID == 'Turnover'][errBrokerID ==1]

dtJydb[TradingDay == '2017-03-31'][InstrumentID == 'A1705'][ClassID == 'longPos'][order(Rank)]
dtOiRank[TradingDay == '2017-03-31'][InstrumentID == 'A1705'][ClassID == 'longPos'][order(Rank)]
dt[TradingDay == '2017-03-31'][InstrumentID == 'A1705'][ClassID == 'longPos'][errBrokerID ==1]

dtJydb[TradingDay == '2017-03-31'][InstrumentID == 'A1705'][ClassID == 'longPos'][order(Rank)][Rank %between% c(60,70)]
dtOiRank[TradingDay == '2017-03-31'][InstrumentID == 'A1705'][ClassID == 'longPos'][order(Rank)][Rank %between% c(60,70)]

dtJydb[TradingDay == '2017-03-31'][InstrumentID == 'A1705'][ClassID == 'longPos'][order(Rank)][Rank %between% c(100,102)]
dtOiRank[TradingDay == '2017-03-31'][InstrumentID == 'A1705'][ClassID == 'longPos'][order(Rank)][Rank %between% c(100,102)]

