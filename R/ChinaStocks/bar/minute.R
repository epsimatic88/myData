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
allYears <- seq(2007, 2018)

## =============================================================================
## 获取年度文件夹下面的所有交易日期文件夹
## -------------------------------
getDirs <- function(yearID) {
    allDirs <- paste0(DATA_PATH, '/',
                      sourceID, '/',
                      yearID) %>%
                list.files(., pattern = '.*[0-9]{6}$',
                           full.names = T)
    return(allDirs)
}
## =============================================================================

## =============================================================================
## 读取数据文件
## 处理数据
## ----------
processData <- function(dataFile) {
    # print(dataFile)
    id <- gsub('.*([0-9]{6})\\.csv$', '\\1', dataFile)

    if (class(try(
                  info <- suppFunction(
                          read_tsv(dataFile, 
                                   locale = locale(encoding = 'GB18030'),
                                   col_types = cols(
                                          成交时间 = col_character()
                                      )
                                   )
                          ) %>% as.data.table()
        , silent = T))[1] == 'try-error') {
        info <- readLines(file(dataFile, encoding = 'GB18030'))
        info <- lapply(2:length(info), function(k){
            tmp <- strsplit(info[k], '\t') %>%
                unlist()
            data.table(成交时间 = tmp[1],
                       成交价 = tmp[2],
                       价格变动 = tmp[3],
                       成交量 = tmp[4],
                       成交额 = tmp[5],
                       性质 = tmp[6])
        }) %>% rbindlist()
    } else {
        setnames(info, c('成交量(手)', '成交额(元)'), c('成交量', '成交额'))
    }

    info  <- info[order(成交时间)] %>%
            .[, Minute := substr(成交时间, 1,5)]

    res <- info[, .(open = .SD[1,成交价],
                    high = .SD[, max(成交价, na.rm = T)],
                    low = .SD[, min(成交价, na.rm = T)],
                    close = .SD[.N, 成交价],
                    volume = .SD[, sum(as.numeric(成交量), na.rm = T) * 100],
                    turnover = .SD[, sum(as.numeric(成交额), na.rm = T)])
                , by = 'Minute']
    res[, ":="(stockID = id)]

    return(res)
}

processDir <- function(dataDir) {
    tradingDay <- gsub(".*([0-9]{8})", "\\1", dataDir)

    ## -------------------------------------------------------------------------
    tempDir <- paste0('/home/fl/myData/data/ChinaStocks/Bar/FromSina/Minute/',
                       substr(tradingDay, 1, 4))
    if (!dir.exists(tempDir)) dir.create(tempDir)

    destFile <- paste0(tempDir, '/', tradingDay, '.csv')
    if (file.exists(destFile)) return(data.table())
    ## -------------------------------------------------------------------------

    ## -------------------------------------------------------------------------
    allFiles <- list.files(dataDir, full.names = T)
    if (length(allFiles) == 0) return(data.table())
    ## -------------------------------------------------------------------------
    
    ## -------------------------------------------------------------------------
    res <- lapply(allFiles, function(f){
        processData(f)
    }) %>% rbindlist()
    ## -------------------------------------------------------------------------

    res[, TradingDay := tradingDay]
    setcolorder(res, c('TradingDay', 'Minute', 'stockID',
                        colnames(res)[2:7]))

    ## ------------------
    fwrite(res, destFile)
    ## ------------------
    
    return(res)
}
## =============================================================================

## =============================================================================
for (yearID in allYears) {
    allDirs <- getDirs(yearID)

    ## -------------------------------------------------------------------------
    cl <- makeCluster(12, type = 'FORK')
    parLapply(cl, 1:length(allDirs), function(i){
        processDir(allDirs[i])
    })
    stopCluster(cl)
    ## -------------------------------------------------------------------------

}
## =============================================================================



# ## =============================================================================
# dt <- lapply(1:length(allDirs), function(i){
#     print(i)
#     d <- allDirs[i]

#     tradingDay <- gsub(".*([0-9]{8})", "\\1", d)

#     ## -------------------------------------------------------------------------
#     tempDir <- paste0('/home/fl/myData/data/ChinaStocks/Bar/FromSina/Minute/',
#                        substr(tradingDay, 1, 4))
#     if (!dir.exists(tempDir)) dir.create(tempDir)
#     destFile <- paste0(tempDir, '/', tradingDay, '.csv')
#     if (file.exists(destFile)) return(data.table())
#     ## -------------------------------------------------------------------------

#     allFiles <- list.files(d, full.names = T)
#     if (length(allFiles) == 0) return(data.table())

#     ## -------------------------------------------------------------------------
#     cl <- makeCluster(12, type = 'FORK')
#     res <- parLapply(cl, allFiles, function(f){
#         id <- gsub('.*([0-9]{6})\\.csv$', '\\1', f)

#         if (class(try(
#                       info <- suppFunction(
#                               read_tsv(f, locale = locale(encoding = 'GB18030'),
#                                        col_types = cols(
#                                               成交时间 = col_character()
#                                           ))
#                               ) %>% as.data.table()
#             , silent = T)) == 'try-error') {
#             info <- readLines(file(f, encoding = 'GB18030'))
#             info <- lapply(2:length(info), function(k){
#                 tmp <- strsplit(info[k], '\t') %>%
#                     unlist()
#                 data.table(成交时间 = tmp[1],
#                            成交价 = tmp[2],
#                            价格变动 = tmp[3],
#                            成交量 = tmp[4],
#                            成交额 = tmp[5],
#                            性质 = tmp[6])
#             }) %>% rbindlist()
#         } else {
#             setnames(info, c('成交量(手)', '成交额(元)'), c('成交量', '成交额'))
#         }

#         info  <- info[order(成交时间)] %>%
#                 .[, 分钟 := substr(成交时间, 1,5)]

#         res <- info[, .(open = .SD[1,成交价],
#                         high = .SD[, max(成交价, na.rm = T)],
#                         low = .SD[, min(成交价, na.rm = T)],
#                         close = .SD[.N, 成交价],
#                         volume = .SD[, sum(as.numeric(成交量), na.rm = T) * 100],
#                         turnover = .SD[, sum(as.numeric(成交额), na.rm = T)])
#                     , by = '分钟']
#         res[, ":="(stockID = id)]

#         return(res)
#     }) %>% rbindlist()
#     stopCluster(cl)
#     ## -------------------------------------------------------------------------

#     setnames(res, '分钟', 'Minute')
#     res[, TradingDay := tradingDay]
#     setcolorder(res, c('TradingDay', 'Minute', 'stockID',
#                         colnames(res)[2:7]))

#     ## ------------------
#     fwrite(res, destFile)
#     ## ------------------

#     return(res)
# }) %>% rbindlist()
# ## =============================================================================



# ## =============================================================================
# cl <- makeCluster(12, type = 'FORK')
# dt <- parLapply(cl, 1:length(allDirs), function(i){  # length(allDirs)
#     d <- allDirs[i]

#     tradingDay <- gsub(".*([0-9]{8})", "\\1", d)

#     ## -------------------------------------------------------------------------
#     tempDir <- paste0('/home/fl/myData/data/ChinaStocks/Bar/FromSina/Minute/',
#                        substr(tradingDay, 1, 4))
#     if (!dir.exists(tempDir)) dir.create(tempDir)
#     destFile <- paste0(tempDir, '/', tradingDay, '.csv')
#     if (file.exists(destFile)) return(data.table())
#     ## -------------------------------------------------------------------------

#     allFiles <- list.files(d, full.names = T)

#     if (length(allFiles) == 0) return(data.table())

#     ## -------------------------------------------------------------------------
#     res <- lapply(allFiles, function(f){
#         # print(f)
#         id <- gsub('.*([0-9]{6})\\.csv$', '\\1', f)

#         if (class(try(
#                       info <- suppFunction(
#                               read_tsv(f, locale = locale(encoding = 'GB18030'),
#                                        col_types = cols(
#                                               成交时间 = col_character()
#                                           ))
#                               ) %>% as.data.table()
#             , silent = T)) == 'try-error') {
#             info <- readLines(file(f, encoding = 'GB18030'))
#             info <- lapply(2:length(info), function(k){
#                 tmp <- strsplit(info[k], '\t') %>%
#                     unlist()
#                 data.table(成交时间 = tmp[1],
#                            成交价 = tmp[2],
#                            价格变动 = tmp[3],
#                            成交量 = tmp[4],
#                            成交额 = tmp[5],
#                            性质 = tmp[6])
#             }) %>% rbindlist()
#         } else {
#             setnames(info, c('成交量(手)', '成交额(元)'), c('成交量', '成交额'))
#         }

#         info  <- info[order(成交时间)] %>%
#                 .[, 分钟 := substr(成交时间, 1,5)]

#         res <- info[, .(open = .SD[1,成交价],
#                         high = .SD[, max(成交价, na.rm = T)],
#                         low = .SD[, min(成交价, na.rm = T)],
#                         close = .SD[.N, 成交价],
#                         volume = .SD[, sum(as.numeric(成交量), na.rm = T) * 100],
#                         turnover = .SD[, sum(as.numeric(成交额), na.rm = T)])
#                     , by = '分钟']
#         res[, ":="(stockID = id)]

#         return(res)
#     }) %>% rbindlist()
#     ## -------------------------------------------------------------------------

#     setnames(res, '分钟', 'Minute')
#     res[, TradingDay := tradingDay]
#     setcolorder(res, c('TradingDay', 'Minute', 'stockID',
#                         colnames(res)[2:7]))
#     ## ------------------
#     fwrite(res, destFile)
#     ## ------------------

#     return(res)
# }) %>% rbindlist()
# stopCluster(cl)
# ## =============================================================================

# ## =============================================================================
# DATA_PATH <- "/data/ChinaStocks/TickData"
# sourceID <- 'FromZXJT'
# allDirs <- paste0(DATA_PATH, '/', sourceID) %>%
#   list.files(., full.names = T)

# pb <- txtProgressBar(min = 1, max = length(allDirs), style = 1)
# for (i in 1:length(allDirs)) {
#   setTxtProgressBar(pb, i)

#   ## ===========================================
#   d <- allDirs[i]
#   tradingDay <- gsub(".*([0-9]{8})", "\\1", d)

#   tempDir <- paste0('/home/fl/myData/data/ChinaStocks/Bar/FromZXJT/',
#                      substr(tradingDay, 1, 4))
#   if (!dir.exists(tempDir)) dir.create(tempDir)
#   destFile <- paste0(tempDir, '/', tradingDay, '_daily.csv')
#   if (file.exists(destFile)) next

#   allFiles <- list.files(d, full.names = T)
#   ## ===========================================

#   ## ===========================================================================
#   cl <- makeCluster(12, type = "FORK")
#   dtMinute <- parLapply(cl, 1:length(allFiles), function(j){
#     setTxtProgressBar(pb, j)
#     ## ---------------------------------------------
#     res <- allFiles[j] %>% 
#       fread(., colClass = c(code = 'character')) %>% 
#       .[, .(Minute = substr(updateTime, 12, 16),
#             stockID = code, 
#             price = presentPrice,
#             volume = volume,
#             turnover = presentPrice * volume)] %>% 
#       .[order(Minute)] %>%
#       .[, .(open = .SD[1, price],
#             high = .SD[, max(price, na.rm = T)],
#             low = .SD[, min(price, na.rm = T)],
#             close = .SD[.N, price],
#             volume = .SD[, sum(as.numeric(volume), na.rm = T)],
#             turnover = .SD[, sum(as.numeric(turnover), na.rm = T)])
#         , by = c('Minute', 'stockID')]
#     ## ---------------------------------------------
#   }) %>% rbindlist()
#   stopCluster(cl)
#   dtMinute[, TradingDay := tradingDay]

#   ## ===========================================================================
#   destFile <- paste0(tempDir, '/', tradingDay, '_minute.csv')
#   fwrite(dtMinute, destFile)

#   dtDaily <- dtMinute[, .(open = .SD[1, open],
#                     high = .SD[, max(high, na.rm = T)],
#                     low = .SD[, min(low, na.rm = T)],
#                     close = .SD[.N, close],
#                     volume = .SD[, sum(volume, na.rm = T)],
#                     turnover = .SD[, sum(turnover, na.rm = T)])
#                 , by = c('TradingDay', 'stockID')]
#   destFile <- paste0(tempDir, '/', tradingDay, '_daily.csv')
#   fwrite(dtDaily, destFile)
#   ## ===========================================================================

#   # mysqlWrite(db = 'china_stocks', tbl = 'minute_from_zxjt',
#   #            data = dtMinute)
#   ## ===========================================================================
# }
