## =============================================================================
## sina_bAdj.R
##
## 用于获取 新浪财经 股票历史交易明细
## http://vip.stock.finance.sina.com.cn/corp/go.php/vMS_FuQuanMarketHistory/stockid/600008.phtml?year=2017&jidu=1
##
## Author   : fl@hicloud-investment.com
## Date     : 2018-01-10
## Modified : 2018-03-07
## =============================================================================

## =============================================================================
setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
library(httr)
library(rjson)
## =============================================================================


## -----------------------------------------------------------------------------
allStocks <- mysqlQuery(db = 'china_stocks_info',
                        query = 'select * from stocks_list') %>%
            .[order(stockID)]
SAVE_PATH <- "/home/fl/myData/data/ChinaStocks/Transaction/FromSina"
ChinaStocksCalendar <- ChinaStocksCalendar[days %between% c('2004-10-08', format(Sys.Date() -1,'%Y-%m-%d'))]
## -----------------------------------------------------------------------------

## =============================================================================
url <- "http://market.finance.sina.com.cn/downxls.php"
## =============================================================================

ipTables <- suppressMessages({
    suppressMessages({
        fetchIp(10)
    })
})
ipUseful <- FALSE


while (TRUE) {
for (d in 1:nrow(ChinaStocksCalendar)) {
  ## ---------------------------------------------------------------------------
  # d <- 1
  tradingDay <- ChinaStocksCalendar[d, days]

  tempYear <- substr(tradingDay, 1, 4)
  tempDir <- paste0(SAVE_PATH, '/', tempYear)
  if (!dir.exists(tempDir)) dir.create(tempDir, recursive = T)

  DATA_PATH <- paste0(tempDir, '/', gsub('-','',tradingDay))
  if (! dir.exists(DATA_PATH)) dir.create(DATA_PATH, recursive = T)
  ## ---------------------------------------------------------------------------

  ## ---------------------------------------------------------------------------
  # print(paste(tradingDay, ':==>', allStocks[i, stockID]))
  if (nrow(ipTables) == 0) {
      ipTables <- fetchIp(2)
      Sys.sleep(1)
  }
  ipTables <- ipTables[tryNo < 5]
  if (!ipUseful) ip <- ipTables[sample(1:nrow(ipTables),1)]
  ## ---------------------------------------------------------------------------

  ## ===========================================================================
  for (i in 1:nrow(allStocks)) {

    if (nrow(ipTables) == 0) {
        ipTables <- fetchIp(2)
        Sys.sleep(1)
    }
    # i <- 1
    tryNo <- 0

    while (tryNo < 3) {
      tryNo <- tryNo + 1
      stockID <- allStocks[i, stockID]
      listingDate <- allStocks[i, listingDate]
      if (tradingDay < listingDate) break

      # destFile <- paste0(DATA_PATH, '/', stockID, '.xls')
      destFile <- paste0(DATA_PATH, '/', stockID, '.csv')
      if (file.exists(destFile)) {
        print(paste(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), ':==>', tradingDay, ':==>', allStocks[i, stockID], '已经下载'))
        next
      }

      ## =========================================================================
      if (class(try(
          r <- GET(url, query = list(date = tradingDay,
                                     symbol = allStocks[i, paste0(exchID, stockID)]),
                        use_proxy(ip[1, url], ip[1, port]),
                        timeout(3))
          )) == 'try-error') {
        ipTables[url == ip[1,url], tryNo := tryNo + 1]
        # ## -----------------------------------------------------------------------
        temp <- ipTables[url == ip[1,url]]
        if (nrow(temp) != 0) {
            ipTables <- ipTables[tryNo < 10]
        }
        if (nrow(ipTables) == 0) {
            ipTables <- fetchIp(2)
            Sys.sleep(1)
        }
        ip <- ipTables[sample(1:nrow(ipTables),1)]
        ipUseful <- FALSE
        ## -----------------------------------------------------------------------
        print(paste(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), ':==>', tradingDay, ':==>', allStocks[i, stockID], '下载失败'))
      } else {
        ## -------------------------------------------------------------------------
        temp <- suppressMessages(content(r,'text'))
        if (r$status_code == '200' & is.na(temp)) {
            suppressWarnings({
              suppressMessages({
                writeBin(content(r, 'raw'), destFile)
              })
            })
            print(paste(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), ':==>', tradingDay, ':==>', allStocks[i, stockID], '下载成功'))
            ipUseful <- TRUE
              # if (file.size(destFile) < 100 & tryNo < 2) {
              #   file.remove(destFile)
              # } else {
              #   next
              # }
          } else {
            if (grepl('新浪安全部门', temp)) {
              ipTables[url == ip[1,url], tryNo := tryNo + 1]
              ipUseful <- FALSE
              next
            }
          }
        ## -------------------------------------------------------------------------
      }
      ## =========================================================================
    }
  }
  ## ===========================================================================
}}
