################################################################################
## czce.R
##
## 从　郑商品所 下载 oiRank 持仓排名数据
##
## Author   : fl@hicloud-investment.com
## Date     : 2018-10-17
##
################################################################################

################################################################################
ROOT_PATH <- '/home/fl/myData'
SAVE_PATH <- './data/oiRank/data'

setwd(ROOT_PATH)
source('./R/Rconfig/myInit.R')
library(httr)

allYears <- ChinaFuturesCalendar[, unique(substr(days, 1, 4))]
sapply(allYears, function(i){
    tempDir <- paste0(SAVE_PATH, '/CZCE/', i)
    if (!dir.exists(tempDir)) dir.create(tempDir, recursive = T)
})
ChinaFuturesCalendar <- ChinaFuturesCalendar[days <= format(Sys.Date(), '%Y-%m-%d')]
################################################################################

## 在 2015-10-01 之前
exchURL1 <- "http://www.czce.com.cn/portal/exchange/"

## 在 2015-10-01 之后
exchURL2 <- "http://www.czce.com.cn/portal/DFSStaticFiles/Future/"


## =============================================================================
fetchCZCE <- function(tradingDay) {
    tradingDay <- gsub('-','',tradingDay)
    czceYear <- substr(tradingDay, 1, 4)
    tempURL <- ifelse(tradingDay < '20151001',
                      paste0(exchURL1, czceYear, '/datatradeholding/', tradingDay, '.txt'),
                      paste0(exchURL2, czceYear, '/', tradingDay, '/FutureDataHolding.xls'))
    destFile <- paste0(SAVE_PATH, '/CZCE/', czceYear, '/', tradingDay,
                       ifelse(tradingDay < '20151001', '.txt', '.xls'))
    ## --------------------------
    if (file.exists(destFile)) {
        print('数据文件已经下载')
    } else {
        while (!file.exists(destFile) | file.size(destFile) < 10000) {
          try(
            download.file(tempURL, destFile, mode = 'wb')
          )
        }
    }

    ## -------------------------------------------------------------------------
    data <- gdata::read.xls(destFile) %>%
        as.data.table()
    colnames(data) <- paste0('X',1:ncol(data))
    cols <- colnames(data)
    data[, (cols) := lapply(.SD, function(x){
      as.character(x)
    }), .SDcols = cols]
    ## 只取具体的合约数据
    data <- data[grep('合约',X1)[1] : .N]
    tbl <- data[, grep('合约|合计', X1)]

    ## -------------------------------------------------------------------------
    dt <- lapply(seq(1,length(tbl), by = 2), function(k){
      #-------------------------------------------------------------------------
      tempdt <- data[grep('合约|合计', data$X1)[k] :
                           grep('合约|合计', data$X1)[k+1]]
      tempContractID <- gsub('.*([a-zA-Z]{2}[0-9]{3}).*','\\1',tempdt[1,X1])
      tempTradingDay <- gsub('.*([0-9]{4}-[0-9]{2}-[0-9]{2}).*','\\1',tempdt[1,X1])

      ## 去掉首尾行
      tempdt <- tempdt[!grepl('合约|日期|名次|合计',X1)]
      res <- lapply(1:nrow(tempdt),function(tt){
        temp <- tempdt[tt]
        tempRes <- data.table(TradingDay = tempTradingDay,
                              InstrumentID = tempContractID,
                              Rank = rep(temp[1,gsub(' ', '', X1)],3),
                              BrokerID = c(temp[1,as.character(X2)], temp[1,X5], temp[1,X8]),
                              ClassID = c('Turnover','longPos','shortPos'),
                              Amount = c(temp[1,X3], temp[1,X6], temp[1,X9]),
                              DiffAmount = c(temp[1,X4], temp[1,X7], temp[1,X10])
        )
      }) %>% rbindlist()
      res <- res[!grepl('-',BrokerID) & !is.na(Amount) & !is.na(DiffAmount)]
      res[, ":="(BrokerID = gsub(' ', '', BrokerID),
                Amount = gsub(',', '', Amount) %>% as.numeric(),
                DiffAmount = gsub(',', '', DiffAmount) %>% as.numeric())]
      return(res)
      #-------------------------------------------------------------------------
    }) %>% rbindlist()

    return(dt)
    ## -------------------------------------------------------------------------
}

tradingDay <- currTradingDay[, gsub('-', '', days)]
dt <- fetchCZCE(tradingDay)

## =====================================================================
mysql <- mysqlFetch('china_futures_bar')
dbWriteTable(mysql, 'oiRank', dt, row.names = F, append = T)
dbDisconnect(mysql)
## =====================================================================
