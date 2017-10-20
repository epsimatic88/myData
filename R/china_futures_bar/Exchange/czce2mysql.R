################################################################################
## czce2mysql.R
## 这是主函数:
## 读取 郑商所 下载得到的日行情数据，
## 并录入 MySQL 数据库
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-10-16
## -----------------------------------------------------------------------------
## 说明： 
## (1) 价格：元/吨 
## (2) 成交量、空盘量：手
## (3) 成交额：万元
## (4) 涨跌一：今收盘-昨结算
## (5) 涨跌二：今结算-昨结算
################################################################################


################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("czce2mysql.R")

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
# ChinaFuturesCalendar <- ChinaFuturesCalendar[-((.N-2):.N)]
exchCalendar <- ChinaFuturesCalendar[,":="(calendarYear = substr(days,1,4),
                                           calendarYearMonth = substr(days,1,6),
                                           calendarMonth = substr(days,5,6),
                                           calendarDay = substr(days,7,8))]

dataPath <- './data/Bar/Exchange/CZCE'
## =============================================================================


## =============================================================================
fetchData <- function(i) {
    tempTradingDay <- exchCalendar[i,days]
    tempFile <- paste0(dataPath, '/', 
                       exchCalendar[i, calendarYear], '/',
                       exchCalendar[i, days],
                       ifelse(tempTradingDay < '20151001', '.txt', '.xls'))
    if (! file.exists(tempFile)) return(data.table())

    if (tempTradingDay < '20151001') {
      tempData <- readLines(tempFile)

      if (!any(grepl('行情表|总计|小计',tempData))) {
        tempData <- readLines(con <- file(tempFile, encoding = "GB18030")) %>% 
                .[-grep('行情表|总计|小计',.)] %>% 
                .[-which(nchar(.) == 0)]
        close(con)
      } else {
        tempData <- readLines(tempFile) %>% 
                .[-grep('行情表|总计|小计',.)]
      }

      res <- lapply(1:length(tempData), function(k){
        temp <- tempData[k] %>% strsplit(.,',') %>% unlist()
        data.table(InstrumentID       = temp[1],
                   preSettlementPrice = temp[2],
                   OpenPrice          = temp[3],
                   HighPrice          = temp[4],
                   LowPrice           = temp[5],
                   ClosePrice         = temp[6],
                   SettlementPrice    = temp[7],
                   Delta1             = temp[8],
                   Delta2             = temp[8],
                   Volume             = temp[10],
                   CloseOpenInterest  = temp[11],
                   DeltaOpenInterest  = temp[12],
                   Turnover           = temp[13],
                   DeliveryPrice      = temp[14])
      }) %>% rbindlist()
    } else {
      res <- suppressWarnings(gdata::read.xls(tempFile, verbose = FALSE)) %>% 
              as.data.table()

      colnames(res) <- c('InstrumentID','preSettlementPrice','OpenPrice','HighPrice','LowPrice','ClosePrice','SettlementPrice','Delta1','Delta2','Volume','CloseOpenInterest','DeltaOpenInterest ','Turnover','DeliveryPrice')
      res <- res[-grep('品种月份|小计|总计', InstrumentID)]

      cols <- colnames(res)[2:ncol(res)]
      res[, (cols) := lapply(.SD, function(x){
        gsub(',','',x)
      }), .SDcols = cols]
    }
    ## -------------------------------------------------------------------------
    return(res[,.(
      TradingDay = tempTradingDay,
      InstrumentID, 
      OpenPrice, HighPrice, LowPrice, ClosePrice,
      Volume, Turnover,CloseOpenInterest, SettlementPrice
    )])
}
## =============================================================================

# for (i in 1:nrow(ChinaFuturesCalendar)) {
#   print(i)
#   fetchData(i)
# }


################################################################################
## STEP 2: 开启并行计算模式
################################################################################
cl <- makeCluster(max(round(detectCores()*3/4),4), type='FORK')
dt <- parLapply(cl, 1:nrow(ChinaFuturesCalendar), fetchData) %>% rbindlist(., fill = TRUE)
stopCluster(cl)

dt[, ":="(Turnover = as.numeric(Turnover) * 10000,
          ExchangeID = 'CZCE')]
## =============================================================================


## =============================================================================
mysql <- mysqlFetch('Exchange', host = '192.168.1.166')
dbWriteTable(mysql, 'daily',
             dt, row.name　=　FALSE, append = T)
## =============================================================================


################################################################################
dbDisconnect(mysql)
for(conn in dbListConnections(MySQL()) )
  dbDisconnect(conn)
################################################################################
