################################################################################
## cffex.R
## 用于下载 中金所 期货公司持仓排名数据
##
## Author: William Fang
## Date  : 2017-11-06
################################################################################

################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("cffex.R")

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
exchURL <- "http://www.cffex.com.cn/fzjy/ccpm/"

dataPath <- '/home/william/Documents/oiRank/CFFEX/'
# dataPath <- "./data/oiRank/CFFEX/"

################################################################################
## CFFEX: 中期所 
##        
## 1. IC：中证500       --> 2015-04-16
## 2. IF：沪深300       --> 2010-04-16
## 3. IH：上证50        --> 2015-04-16
## 4. T ：10年期国债    --> 2015-03-20
## 5. TF：5年期国债     --> 2013-09-06
################################################################################

## -----------------------------------------------------------------------------
productSet <- data.table(productID = c('IC','IF','IH','T','TF'),
                         startDate = c('20150416','20100416','20150416',
                                       '20150320','20130906'))

productCalenar <- lapply(productSet[,productID], function(id) {
  res <- exchCalendar[days >= productSet[productID == id, startDate]] %>% 
        .[, productID := id]
}) %>% rbindlist()
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
cffexData <- function(calendarYear, calendarMonth, calendarDay, productID) {
    tempURL <- paste0(exchURL, paste0(calendarYear, calendarMonth), '/', calendarDay, '/',
                      productID,'_1.csv')

    destFile <-  paste0(dataPath, calendarYear, '/', 
                      paste0(calendarYear, calendarMonth, calendarDay),
                      '_',productID,'.csv')

    ## -------------------------------------------------------------------------
    while(! file.exists(destFile) | file.size(destFile) < 1000){
      try(download.file(tempURL, destFile, mode = 'wb'))
    }
    ## -------------------------------------------------------------------------
}
## -----------------------------------------------------------------------------


################################################################################
## STEP 2: 开启并行计算模式，下载数据 
################################################################################
cl <- makeCluster(max(round(detectCores()*3/4),4), type='FORK')
parSapply(cl, 1:nrow(productCalenar), function(i){
  ## ---------------------------------------------------------------------------
  tempDir <- paste0(dataPath, productCalenar[i, calendarYear])
  if (!dir.exists(tempDir)) dir.create(tempDir, recursive = TRUE)

  productCalenar[i, cffexData(calendarYear, calendarMonth, calendarDay, productID)]
  ## ---------------------------------------------------------------------------
})
stopCluster(cl)
