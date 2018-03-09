################################################################################
## shfe2mysql.R
## 这是主函数:
## 读取 上期所 下载得到的日行情数据，
## 并录入 MySQL 数据库
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-10-16
## -----------------------------------------------------------------------------
## 说明：
## 从 上期所 网页爬虫得到的数据是没有 Turnover 的
## 这个很坑
## 我从历史打包的数据下载，不过只有 2011-2017.07
##
## 1、 报价单位：铜、铝、锌、螺纹钢、线材、铅、天然橡胶、燃料油为元/吨；黄金为元/克
## 2、 合约单位：铜、铝、锌、天然橡胶为5吨/手；燃料油、螺纹钢、线材为10吨/手；黄金为1000克/手
## 3、 成交量、持仓量、持仓变化单位为手，双边计算；成交金额单位为万元，双边计算
## 4、 涨跌1=收盘价-前结算； 涨跌2=结算价-前结算
################################################################################

################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("shfe2mysql.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})

################################################################################
## STEP 1: 获取对应的交易日期
################################################################################
ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
                              colClasses = list(character = c("nights","days"))) %>%
                              .[days < format(Sys.Date(),'%Y%m%d')]
exchCalendar <- ChinaFuturesCalendar[,":="(calendarYear = substr(days,1,4),
                                           calendarYearMonth = substr(days,1,6),
                                           calendarMonth = substr(days,5,6),
                                           calendarDay = substr(days,7,8))]

dataPath <- './data/Bar/Exchange/SHFE'

################################################################################
## 现在历史的数据
################################################################################
sapply(2009:2017, function(i) {
    tempDir <- paste(dataPath, 'historical/', sep = '/')
    tempURL <- paste0('http://www.shfe.com.cn/historyData/MarketData_Year_',i,'.zip')
    destFile <- paste0(tempDir, i, '.zip')

    try(download.file(tempURL, destFile, mode = 'wb'))

    ## -------------------------------------------------------------------------
    system("mkdir /tmp/fl")
    system(paste('unzip', destFile, '-d /tmp/fl'))
    system(paste("mv -f /tmp/fl/*.xls", paste0(tempDir, i, '.xls')))
    system('rm -rf /tmp/fl')
    ## -------------------------------------------------------------------------
})
################################################################################


## =============================================================================
fetchData <- function(yearID) {
    # yearID = '2011'
    tempFile <- paste0(dataPath, '/historical/', yearID, '.xls')

    res <- gdata::read.xls(tempFile) %>% as.data.table()
    colnames(res) <- c('InstrumentID','TradingDay',
                       'PreClose','preSettlementPrice',
                       'OpenPrice','HighPrice','LowPrice','ClosePrice',
                       'SettlementPrice','Delta1','Delta2',
                       'Volume','Turnover','CloseOpenInterest','Unknown')
    res <- as.data.table(res) %>%
            .[-grep('合约|单位|计算|手|元|结算|-',InstrumentID)] %>%
            .[-grep('合约|单位|计算|手|元|结算|-',TradingDay)]

    cols <-  c('PreClose','preSettlementPrice',
               'Delta1','Delta2','Unknown')
    res[, (cols) := NULL]

    cols <- colnames(res)[1:ncol(res)]
    res[, (cols) := lapply(.SD, function(x){
        gsub(',','',x)
    }), .SDcols = cols]

    notNullID <- which(nchar(res$InstrumentID) != 0)

    tempRes <- lapply(2:length(notNullID), function(j){
        x <- res[(notNullID[j-1]) : (notNullID[j]-1)]
        x[, InstrumentID := x[1,InstrumentID]]
    }) %>% rbindlist()

    return(tempRes)
}
## =============================================================================


################################################################################
## STEP 2: 开启并行计算模式
################################################################################
cl <- makeCluster(max(round(detectCores()*2/4),16), type='FORK')
dt <- parLapply(cl, 2009:2017, fetchData) %>% rbindlist(., fill = TRUE)
stopCluster(cl)

dt[, ":="(Turnover = as.numeric(Turnover) * 10000,
          ExchangeID = 'SHFE')]
## =============================================================================


## =============================================================================
mysql <- mysqlFetch('Exchange', host = '192.168.1.166')
dbSendQuery(mysql,"delete from daily where ExchangeID = 'SHFE'")
dbWriteTable(mysql, 'daily', dt, row.name　=　FALSE, append = T)
## =============================================================================


################################################################################
dbDisconnect(mysql)
for(conn in dbListConnections(MySQL()) )
  dbDisconnect(conn)
################################################################################
