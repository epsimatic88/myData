## =============================================================================
## process_sina_bAdj.R
##
## 用于处理 新浪财经 后复权因子
##
## Author : fl@hicloud-investment.com
## Date   : 2018-01-15
## =============================================================================

## =============================================================================
setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
## =============================================================================

## -----------------------------------------------------------------------------
allStocks <- mysqlQuery(db = 'china_stocks_info',
                        query = 'select * from stocks_list') %>%
            .[order(stockID)]
DATA_PATH <- "/home/fl/myData/data/ChinaStocks/Bar/FromSina/historical"
SAVE_PATH <- "/home/fl/myData/data/ChinaStocks/Bar/FromSina/all"
## -----------------------------------------------------------------------------

## =============================================================================
check_files <- function(code) {
    seasonAll <- calSeason(allStocks[stockID == code, gsub('-', '', listingDate)])
    dataFiles <- paste0(DATA_PATH, '/', code) %>%
        list.files(., pattern = '\\.csv')
    if (length(dataFiles) < nrow(seasonAll)) {
        print(paste(code, "数据文件缺失."))
        seasonAll <- seasonAll[, paste(yearID, seasonID, sep = '-')]
        dataFiles <- gsub('\\.csv', '', dataFiles)
        missingData <- seasonAll[!seasonAll %in% dataFiles]
        print(missingData)
    }
}

for (i in allStocks$stockID) check_files(i)
## =============================================================================


## =============================================================================
cl <- makeCluster(8, type = "FORK")
parSapply(cl, 1:nrow(allStocks), function(i){ # nrow(allStocks)
    stockID <- allStocks[i, stockID]

    destFile <- paste0(SAVE_PATH, '/', stockID, '.csv')

    dataFiles <- paste0(DATA_PATH, '/', stockID) %>%
        list.files(., pattern = '\\.csv', full.names = T)

    res <- lapply(dataFiles, function(f){
            fread(f)
        }) %>% rbindlist() %>%
        .[!is.na(TradingDay) | !is.na(close)] %>%
        .[order(TradingDay)]
    fwrite(res, destFile)
})
stopCluster(cl)
## =============================================================================


## =============================================================================
cl <- makeCluster(8, type = "FORK")
daily <- parLapply(cl, 1:nrow(allStocks), function(i){ # nrow(allStocks)
    stockID <- allStocks[i, stockID]
    dataFiles <- paste0(SAVE_PATH, '/', stockID, '.csv')

    res <- fread(dataFiles) %>%
        .[, ":="(volume = as.numeric(volume),
                 turnover = as.numeric(turnover))] %>%
        .[, ":="(stockID = stockID)]
}) %>% rbindlist()
stopCluster(cl)
## =============================================================================


## =============================================================================
mysql <- mysqlFetch('china_stocks')
dbSendQuery(mysql, "truncate table daily_from_sina")
dbWriteTable(mysql, 'daily_from_sina', daily, row.names = F, append = T)
dbDisconnect(mysql)
## =============================================================================
