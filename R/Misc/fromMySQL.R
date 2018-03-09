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


dtMonth <- data.table(beginMonth = c(20170101,20170201,20170301,20170401,20170501,20170601,20170701),
                      endMonth   = c(20170131,20170228,20170331,20170430,20170531,20170630,20170731))


for (k in allTables) {
    print(k)

    ## =========================================================================
    for (j in 1:nrow(dtMonth)) {
      mysql <- mysqlFetch('china_futures_HFT')

      beginDay <- dtMonth[j, beginMonth]
      endDay   <- dtMonth[j, endMonth]
      print(paste(beginDay, endDay, sep = ' :==> '))

      tempFile <- paste0(dataPath, '/', 'china_futures_HFT', '/',
                         k, '_', substr(beginDay,1,6), '.fst')

      if (file.exist(tempFile)) next

      dt <- dbGetQuery(mysql, paste("
                      SELECT * FROM", k,
                      "WHERE TradingDay BETWEEN",
                      beginDay, "AND", endDay))

      ## -----------------------------------------------------------------------
      if (nrow(dt) == 0) {
        dt[1, colnames(dt)] <- NA
      } else {
        write.fst(dt, path = tempFile)
      }
      ## -----------------------------------------------------------------------

      ## =========================================================================
      for( conns in dbListConnections(MySQL()) ){
        dbDisconnect(conns)
      }
      ## =========================================================================
    }
    ## =========================================================================
}
