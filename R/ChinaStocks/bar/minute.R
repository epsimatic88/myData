## =============================================================================
## minute.R
##
## 处理 逐笔成交 的数据
##
## Author : fl@hicloud-investment.com
## Date   : 2018-03-25
##
## =============================================================================

## =============================================================================
suppressMessages({
  source('/home/fl/myData/R/Rconfig/myInit.R')
})

DATA_PATH <- "/home/fl/myData/data/ChinaStocks/Transaction"
## =============================================================================

sourceID <- 'FromSina'
yearID <- '2018'

allDirs <- paste0(DATA_PATH, '/', 
                  sourceID, '/',
                  yearID) %>% 
            list.files(., pattern = '.*[0-9]{6}$',
                       full.names = T)
i <- 1
d <- allDirs[i]
tradingDay <- gsub(".*([0-9]{8})", "\\1", d)
allFiles <- list.files(d, full.names = T)

cl <- makeCluster(8, type = 'FORK')
res <- parLapply(cl, allFiles, function(f){
    id <- gsub('.*([0-9]{6})\\.csv$', '\\1', f)

    info <- suppFunction(
            read_tsv(f, locale = locale(encoding = 'GB18030'),
                     col_types = cols(
                            成交时间 = col_character()
                        ))
            ) %>% 
        as.data.table() %>% 
        .[order(成交时间)] %>% 
        .[, 分钟 := substr(成交时间, 1,5)]
    setnames(info, c('成交量(手)', '成交额(元)'), c('成交量', '成交额'))

    res <- info[, .(open = .SD[1,成交价],
                    high = .SD[, max(成交价, na.rm = T)],
                    low = .SD[, min(成交价, na.rm = T)],
                    close = .SD[.N, 成交价],
                    volume = .SD[, sum(成交量, na.rm = T) * 100],
                    turnover = .SD[, sum(成交额, na.rm = T)])
                , by = '分钟']
    res[, ":="(stockID = id)]

    return(res)
}) %>% rbindlist()
stopCluster(cl)

