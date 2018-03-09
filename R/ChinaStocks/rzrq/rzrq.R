## =============================================================================
## rzrq.R
## 处理 融资融券 数据
## 并导入到 MySQL 数据库
## 
## AUTHOR   : fl@hicloud-investment.com
## DATE     : 2018-03-05
## =============================================================================

source("/home/fl/myData/R/Rconfig/myInit.R")
options(width = 150)
DATA_PATH <- "/home/fl/myData/data/ChinaStocks/RZRQ"


## =============================================================================
## from Sina
## ---------
DATA_SOURCE <- 'FromSina'
allDirs <- paste0(DATA_PATH, '/', DATA_SOURCE) %>% 
    list.files(., full.names = T)

cl <- makeCluster(8, type = 'FORK')
dt <- parLapply(cl, allDirs, function(d){
    allFiles <- list.files(d, full.names = T)
    res <- lapply(allFiles, function(f){
        temp <- fread(f, colClasses = c('character'))
        colnames(temp) <- c('stockID','stockName',
                            'rzye','rzmre','rzche',
                            'rqye','rqyl','rqmcl','rqchl','rzrqye')
        temp[, TradingDay := gsub(".*([0-9]{4}-[0-9]{2}-[0-9]{2}).*", "\\1", f)]
        setcolorder(temp, c('TradingDay', colnames(temp)[1:(ncol(temp)-1)]))
        return(temp)
    }) %>% rbindlist()
}) %>% rbindlist()
stopCluster(cl)

dt[, stockName := gsub(' ', '', stockName)]
dt[, stockName := gsub('Ａ', 'A', stockName)]

cols <- c('rzche','rqye','rqchl','rzrqye')
dt[, (cols) := lapply(.SD, function(x){
    ifelse(grepl("-", x), NA, x)
}), .SDcols = cols]

mysql <- mysqlFetch('china_stocks')
dbSendQuery(mysql, 'truncate table rzrq_from_sina')
dbWriteTable(mysql, 'rzrq_from_sina',
             dt, row.names = F, append = T)
dbDisconnect(mysql)
## =============================================================================


## =============================================================================
## from Sina
## ---------
DATA_SOURCE <- 'FromEastmoney'
allDirs <- paste0(DATA_PATH, '/', DATA_SOURCE) %>% 
    list.files(., full.names = T)
cl <- makeCluster(8, type = 'FORK')
dt <- parLapply(cl, allDirs, function(d){
    allFiles <- list.files(d, full.names = T)
    res <- lapply(allFiles, function(f){
        temp <- fread(f, colClasses = c('character'))
        colnames(temp) <- c('stockID','stockName',
                            'rzye','rzmre','rzche', 'rzjmre',
                            'rqye','rqyl','rqmcl','rqchl','rqjmcl',
                            'rzrqye', 'rzrqyecz')
        temp[, ":="(
            rzjmre = NULL,
            rqjmcl = NULL,
            rzrqyecz = NULL
            )]
        temp[, TradingDay := gsub(".*([0-9]{4}-[0-9]{2}-[0-9]{2}).*", "\\1", f)]
        setcolorder(temp, c('TradingDay', colnames(temp)[1:(ncol(temp)-1)]))
        return(temp)
    }) %>% rbindlist()
}) %>% rbindlist()
stopCluster(cl)

dt[, stockName := gsub(' ', '', stockName)]
dt[, stockName := gsub('Ａ', 'A', stockName)]

cols <- c('rzche','rqye','rqchl','rzrqye')
dt[, (cols) := lapply(.SD, function(x){
    ifelse(grepl("-", x), NA, x)
}), .SDcols = cols]

mysql <- mysqlFetch('china_stocks')
dbSendQuery(mysql, 'truncate table rzrq_from_eastmoney')
dbWriteTable(mysql, 'rzrq_from_eastmoney',
             dt, row.names = F, append = T)
dbDisconnect(mysql)
## =============================================================================
