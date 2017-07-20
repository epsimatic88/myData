################################################################################
##! fromMySQL.R
##
## 从　MySQL 数据库提取数据
## 并保存为 fst 格式
##
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-07-20
################################################################################

################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("vnpyData2mysql_00_main.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})

## =============================================================================
if(! 'fst' %in% installed.packages()) install.packages('fst')
library(fst)
## =============================================================================

## =============================================================================
dataPath <- "./data/FromMySQL"
allDataBases <- c(#'china_futures_HFT',
                  'china_futures_bar', 'china_futures_info',
                  'dev', 'jydb', 'HiCloud', 'vnpy', 'YY_SimNow')
for (i in allDataBases) {
    if (! dir.exists(paste(dataPath, i, sep = '/'))) {
        dir.create(paste(dataPath, i, sep = '/'))
    }
}
## =============================================================================


## =============================================================================
## 开始写入数据
## 格式为 fst
## 读取命令: read.fst(file, as.data.table = TRUE)
## =============================================================================
for (i in allDataBases) {
    print(i)
    ## -------------------------------------------------------------------------
    mysql <- mysqlFetch(i)
    allTables <- dbListTables(mysql)
    ## -------------------------------------------------------------------------

    ## -------------------------------------------------------------------------
    for (k in 1:length(allTables)) {
        print(k)
        dt <- dbGetQuery(mysql, paste("
                        SELECT * FROM", allTables[k]))
        ## ---------------------------------------------------------------------
        if (nrow(dt) == 0) {
            dt[1, colnames(dt)] <- NA
        } else {
            write.fst(dt, path = paste0(dataPath, '/', i, '/', allTables[k], '.fst'))
        }
        ## ---------------------------------------------------------------------
    }
    ## -------------------------------------------------------------------------
    for( conns in dbListConnections(MySQL()) ){
      dbDisconnect(conns)
    }
}

## =============================================================================
## china_futures_HFT
## =============================================================================
dataPath <- "./data/FromMySQL"
if (! dir.exists(paste(dataPath, 'china_futures_HFT', sep = '/'))) {
    dir.create(paste(dataPath, 'china_futures_HFT', sep = '/'))
}
mysql <- mysqlFetch('china_futures_HFT')
allTables <- dbListTables(mysql)

for (k in allTables) {
    mysql <- mysqlFetch('china_futures_HFT')
    print(k)
    dt <- dbGetQuery(mysql, paste("
            SELECT * FROM", k,
            "WHERE YEAR(TradingDay) >=", 2016))
    ## -------------------------------------------------------------------------
    if (nrow(dt) == 0) {
        dt[1, colnames(dt)] <- NA
    } else {
        write.fst(dt, path = paste0(dataPath, '/', 'china_futures_HFT', '/', k, '.fst'))
    }
    ## -------------------------------------------------------------------------
    for( conns in dbListConnections(MySQL()) ){
      dbDisconnect(conns)
    }
}
