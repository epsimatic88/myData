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
    tempDir <- paste0(SAVE_PATH, '/CFFEX/', i)
    if (!dir.exists(tempDir)) dir.create(tempDir, recursive = T)
})
ChinaFuturesCalendar <- ChinaFuturesCalendar[days <= format(Sys.Date(), '%Y-%m-%d')]
################################################################################

exchURL <- "http://www.cffex.com.cn/fzjy/ccpm/"

exchURL <- "http://www.cffex.com.cn/fzjy/ccpm/"

dataSet <- data.table(productID = c('IC','IF','IH','T','TF'),
                      startDate = c('20150416','20100416','20150416',
                                    '20150320','20130906'))

fetchCFFEX <- function(tradingDay) {
    ## ---------------------------------------
    tradingDay <- gsub('-', '', tradingDay)
    cffexYear <- substr(tradingDay, 1, 4)
    cffexYearMonth <- substr(tradingDay, 1, 6)
    cffexDay <- substr(tradingDay, 7, 8)
    ## ---------------------------------------

    #---------------------------------------------------------------------------
    DATA_PATH <- paste0(SAVE_PATH, '/CFFEX/', cffexYear)

    for (i in 1:nrow(dataSet)) {
      destFile <- paste0(DATA_PATH, '/', tradingDay, '_',
                         dataSet[i, productID], '.csv')
      #-------------------------------------------------------------------------
      tempURL <- paste0("http://www.cffex.com.cn/sj/ccpm/", cffexYearMonth, '/',
                        cffexDay, '/', dataSet[i, productID], '_1.csv')
      try(
        download.file(tempURL, destFile, mode = 'wb')
        )
    }
    #---------------------------------------------------------------------------
    dataFiles <- list.files(DATA_PATH, pattern = '\\.csv') %>%
        .[grep(tradingDay, .)] %>%
        paste0(DATA_PATH, '/', .)
    ## =========================================================================
    dt <- lapply(dataFiles, function(f){
        data <- readLines(f)
        data <- iconv(data, from = 'GB18030', to = 'utf8') %>%
                .[!grepl("会员|期货公司|交易日", .)] %>%
                .[!is.na(.)] %>%
                .[nchar(.) != 0]
        res <- lapply(data, function(l){
            temp <- strsplit(l, ',')  %>% unlist() %>% gsub(' ', '', .)
            tempRes <- data.table(TradingDay = rep(temp[1], 3),
                                  InstrumentID = rep(temp[2], 3),
                                  Rank = rep(temp[3], 3),
                                  BrokerID = c(temp[4], temp[7], temp[10]),
                                  ClassID = c('Turnover', 'longPos', 'shortPos'),
                                  Amount = c(temp[5], temp[8], temp[11]),
                                  DiffAmount = c(temp[6], temp[9], temp[12])
                                  )
        }) %>% rbindlist()
        }) %>% rbindlist()
    dt[, ":="(Amount = gsub(',', '', Amount) %>% as.numeric(),
              DiffAmount = gsub(',', '', DiffAmount) %>% as.numeric())]
    return(dt)
    ## =========================================================================
}

tradingDay <- currTradingDay[, gsub('-', '', days)]
dt <- fetchCFFEX(tradingDay)

## =====================================================================
mysql <- mysqlFetch('china_futures_bar')
dbWriteTable(mysql, 'oiRank', dt, row.names = F, append = T)
dbDisconnect(mysql)
## =====================================================================

