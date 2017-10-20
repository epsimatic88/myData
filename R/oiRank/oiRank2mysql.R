################################################################################
## oiRank2mysql.R
## 这是主函数:
## 读取 oiRank 下载得到的日行情数据，
## 并录入 MySQL 数据库
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-10-20
################################################################################


################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("oiRank2mysql.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
library(readxl)
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

dataPath <- './data/oiRank'
## =============================================================================


## =============================================================================
# 1. CFFEX
## =============================================================================
exchID <- 'CFFEX'
productID <- c('IC','IF','IH','T','TF')


## =============================================================================
fetchData <- function(i) {
    # i <- 1
    ## =========================================================================
    lapply(productID, function(id) {
        tempFile <- paste0(dataPath, '/', exchID, '/', 
                           exchCalendar[i,calendarYear], '/',
                           exchCalendar[i,days], '_', id, '.csv')
        if (!file.exists(tempFile)) return(data.table())

        ## ---------------------------------------------------------------------
        con <- file(tempFile, encoding = 'GB18030')
        tempData <- readLines(con) %>% 
                .[(grep('量排名',.)+2) : length(.)]
        close(con)
        ## ---------------------------------------------------------------------

        ## ---------------------------------------------------------------------
        lapply(1:length(tempData), function(l){
            temp <- tempData[l] %>% strsplit(.,',') %>% unlist() %>% 
                    gsub('\\s', '', .)
            data.table(TradingDay = temp[1],
                       InstrumentID = temp[2],
                       Rank       = temp[3],
                       BrokerID   = c(temp[c(4,7,10)]),
                       ClassID    = c('Turnover','longPos','shortPos'),
                       Amount     = c(temp[c(5,8,11)]),
                       DiffAmount = c(temp[c(6,9,12)])
                       )
        }) %>% rbindlist()
        ## ---------------------------------------------------------------------
    }) %>% rbindlist()
    ## =========================================================================
}
## =============================================================================


## =============================================================================
cl <- makeCluster(max(round(detectCores()*3/4),4), type='FORK')
dt <- parLapply(cl, 1:nrow(ChinaFuturesCalendar), fetchData) %>% rbindlist(., fill = TRUE)
stopCluster(cl)
fwrite(dt, paste0(dataPath, '/', exchID, '.csv'))
## =============================================================================




## =============================================================================
# 2. CZCE
## =============================================================================
exchID <- 'CZCE'

fetchData <- function(i) {
    tempTradingDay <- exchCalendar[i,days]
    tempFile <- paste0(dataPath, '/', exchID, '/',
                       exchCalendar[i, calendarYear], '/',
                       exchCalendar[i, days],
                       ifelse(tempTradingDay < '20151001', '.txt', '.xls'))
    if (!file.exists(tempFile)) return(data.table())

    if (tempTradingDay < '20151001') {
      tempData <- readLines(tempFile)

      ## -----------------------------------------------------------------------
      if (!any(grepl('排行表|总计|合计|小计|名次',tempData))) {
        con <- file(tempFile, encoding = "GB18030")
        tempData <- readLines(con) %>% .[-1]
        close(con)
      }
      ## -----------------------------------------------------------------------

      tempData <- tempData %>% 
                .[-grep('排行表|总计|合计|小计|名次',.)] %>% 
                .[grep('[0-9]|\\w|\\d',.)] %>% 
                .[grep('合约',.)[1] : length(.)]

      tempLine <- grep('合约',tempData)

      ## -----------------------------------------------------------------------
      res <- lapply(2:length(tempLine),function(kk){
          tempdt <- tempData[tempLine[kk-1] : (tempLine[kk]-1)]
          tempInstrumentID <- gsub('.*([a-zA-Z]{2}[0-9]{3}).*','\\1',tempdt[1])
          tempTradingDay <- gsub('.*([0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{8}).*','\\1',tempdt[1])
          
          ## 去掉首尾行
          tempdt <- tempdt[-c(1,length(tempdt))]
          ## -------------------------------------------------------------------
          lapply(1:length(tempdt),function(tt){
            temp <- tempdt[tt] %>% strsplit(.,',') %>% unlist() %>% 
                      gsub('\\s','',.)
            temp[which(nchar(temp) == 0)] <- 0
            if (length(temp) < 10) temp[10] <- 0
            data.table(TradingDay = tempTradingDay,
                       InstrumentID = tempInstrumentID,
                       Rank       = temp[1],
                       BrokerID   = c(temp[c(2,5,8)]),
                       ClassID    = c('Turnover','longPos','shortPos'),
                       Amount     = as.numeric(c(temp[c(3,6,9)])),
                       DiffAmount = as.numeric(c(temp[c(4,7,10)]))
                       )
          }) %>% rbindlist()
          ## -------------------------------------------------------------------
      }) %>% rbindlist()
      ## -----------------------------------------------------------------------
    } else {
      tempData <- suppressWarnings(gdata::read.xls(tempFile, verbose = FALSE)) %>% 
              as.data.table()
      colnames(tempData) <- paste0('X',1:ncol(tempData))
      tempData <- tempData[grep('合约',X1)[1] : .N]
      cols <- colnames(tempData)
      tempData[, (cols) := lapply(.SD, function(x){
        as.character(x) %>% 
        gsub(',','',.)
      }), .SDcols = cols]

      ## -----------------------------------------------------------------------
      res <- lapply(seq(1,length(grep('合约|合计', tempData$X1)), by = 2),function(kk){
        #-----------------------------------------------------------------------
        tempdt <- tempData[grep('合约|合计', tempData$X1)[kk] :
                             grep('合约|合计', tempData$X1)[kk+1]]
        tempInstrumentID <- gsub('.*([a-zA-Z]{2}[0-9]{3}).*','\\1',tempdt[1,X1])
        tempTradingDay <- gsub('.*([0-9]{4}-[0-9]{2}-[0-9]{2}).*','\\1',tempdt[1,X1])
        
        ## 去掉首尾行
        tempdt <- tempdt[-c(1:2,.N)]
        lapply(1:nrow(tempdt),function(tt){
          temp <- tempdt[tt]
          data.table(TradingDay   = tempTradingDay,
                     InstrumentID = tempInstrumentID,
                     Rank         = temp[1,X1],
                     BrokerID     = c(temp[1,c(X2,X5,X8)]),
                     ClassID      = c('Turnover','longPos','shortPos'),
                     Amount       = c(temp[1,c(X3,X6,X9)]),
                     DiffAmount   = c(temp[1,c(X4,X7,X10)])
                     )
        }) %>% rbindlist()
        #-----------------------------------------------------------------------
      }) %>% rbindlist()
      ## -----------------------------------------------------------------------
    }
    ## =========================================================================
    return(res)
    ## =========================================================================
}
## =============================================================================

# for (i in 1:nrow(ChinaFuturesCalendar)) {
#   print(i)
#   fetchData(i)
# }


## =============================================================================
cl <- makeCluster(max(round(detectCores()*3/4),4), type='FORK')
dt <- parLapply(cl, 1:nrow(ChinaFuturesCalendar), fetchData) %>% rbindlist(., fill = TRUE)
stopCluster(cl)
fwrite(dt, paste0(dataPath, '/', exchID, '.csv'))
## =============================================================================




## =============================================================================
# 3. DCE
## =============================================================================
exchID <- 'DCE'

fetchData <- function(i) {
    # i <- 1
    tempTradingDay <- exchCalendar[i, days]

    tempFile <- paste0(dataPath, '/', 
                       exchID, '/',
                       exchCalendar[i,calendarYear]) %>% 
                list.files() %>% 
                .[grep(paste0('^', tempTradingDay, '.*\\.xlsx'),.)]
    if (length(tempFile) == 0) return(data.table())

    ## -------------------------------------------------------------------------
    lapply(tempFile, function(f){
      tempInstrumentID <- gsub('[0-9]{8}_([a-zA-Z]{1,2}[0-9]*)\\.xlsx', '\\1', f)
      tempTradingDay <- gsub('^([0-9]{8}).*', '\\1', f)
      tempData <- read_excel(paste0(dataPath, '/',
                                  exchID, '/',
                                  exchCalendar[i,calendarYear], '/',
                                  f)) %>% as.data.table()
      colnames(tempData) <- paste0('X', 1:ncol(tempData))

      tempData <- tempData[-grep('总计',X1)]
      cols <- c('X3','X4','X7','X8','X11','X12')
      tempData[, (cols) := lapply(.SD, function(x){
        gsub(',','',x) %>% as.numeric()
      }), .SDcols = cols]

      ## -----------------------------------------------------------------------
      lapply(1:nrow(tempData),function(tt){
        temp <- tempData[tt]
        data.table(TradingDay   = tempTradingDay,
                   InstrumentID = tempInstrumentID,
                   Rank         = temp[1,c(X1,X5,X9)],
                   BrokerID     = temp[1,c(X2,X6,X10)],
                   ClassID      = c('Turnover','longPos','shortPos'),
                   Amount       = temp[1,c(X3,X7,X11)],
                   DiffAmount   = temp[1,c(X4,X8,X12)]
                   )
      }) %>% rbindlist() %>% .[!is.na(Rank)]
      ## -----------------------------------------------------------------------
    }) %>% rbindlist() 
    ## -------------------------------------------------------------------------
}


## =============================================================================
cl <- makeCluster(max(round(detectCores()*3/4),4), type='FORK')
dt <- parLapply(cl, 1:nrow(ChinaFuturesCalendar), fetchData) %>% rbindlist(., fill = TRUE)
stopCluster(cl)
fwrite(dt, paste0(dataPath, '/', exchID, '.csv'))
## =============================================================================




## =============================================================================
# 4. SHFE
## =============================================================================
exchID <- 'SHFE'

fetchData <- function(i) {
    # i <- 1
    tempTradingDay <- exchCalendar[i, days]
    tempFile <- paste0(dataPath, '/', exchID, '/',
                       exchCalendar[i, calendarYear], '/',
                       exchCalendar[i, days],'.xlsx')

    if (!file.exists(tempFile)) return(data.table())

    tempData <- readxl::read_excel(tempFile, col_names = FALSE) %>% 
                as.data.table
    colnames(tempData) <- paste0('X', 1:ncol(tempData))

    if (any(grepl("商品名称|会员|期货公司|注|加总|合计|名次",tempData$X1))) {
      tempData <- tempData[-grep("商品名称|会员|期货公司|注|加总|合计|名次",X1)]
    }

    tempLine <- grep("合约代码",tempData$X1)

    ## -------------------------------------------------------------------------
    lapply(2:length(tempLine), function(l){
        tempTable <- tempData[tempLine[l-1] : (tempLine[l]-1)]
        temp <- strsplit(tempTable[1,X1],"：| ") %>% unlist() %>%
                .[-which(nchar(.) == 0)]

        tempInstrumentID <- temp[grep('[a-zA-Z]',temp)]

        if (length(tempInstrumentID) > 1 | nchar(tempInstrumentID) > 7) return(data.table())

        ## 正则匹配寻找 TradingDay
        tempTradingDay <- temp[grep('.*([0-9]{4}-[0-9]{2}-[0-9]{2}).*',temp)]

        ## 去掉首尾行
        tempTable <- tempTable[-1]

        ## ---------------------------------------------------------------------
        lapply(1:nrow(tempTable), function(tt){
          temp <- tempTable[tt]
          data.table(TradingDay   = tempTradingDay,
                     InstrumentID = tempInstrumentID,
                     Rank         = temp[1,c(X1,X5,X9)],
                     BrokerID     = c(temp[1,c(X2,X6,X10)]),
                     ClassID      = c('Turnover','longPos','shortPos'),
                     Amount       = c(temp[1,c(X3,X7,X11)]),
                     DiffAmount   = c(temp[1,c(X4,X8,X12)])
                     )
        }) %>% rbindlist()
        ## ---------------------------------------------------------------------
    }) %>% rbindlist()
    ## -------------------------------------------------------------------------
}


## =============================================================================
cl <- makeCluster(max(round(detectCores()*3/4),4), type='FORK')
dt <- parLapply(cl, 1:nrow(ChinaFuturesCalendar), fetchData) %>% rbindlist(., fill = TRUE)
stopCluster(cl)
fwrite(dt, paste0(dataPath, '/', exchID, '.csv'))
## =============================================================================



