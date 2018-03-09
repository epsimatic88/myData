## =============================================================================
## sina_bAdj.R
##
## 用于获取 新浪财经 后复权因子
## http://vip.stock.finance.sina.com.cn/corp/go.php/vMS_FuQuanMarketHistory/stockid/600008.phtml?year=2017&jidu=1
##
## Author : fl@hicloud-investment.com
## Date   : 2018-10-10
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
SAVE_PATH <- "/data/ChinaStocks/TickData/FromSina"
ChinaStocksCalendar <- ChinaStocksCalendar[days %between% c('2004-10-08', format(Sys.Date() -1,'%Y-%m-%d'))]
## -----------------------------------------------------------------------------

## =============================================================================
url <- "http://market.finance.sina.com.cn/downxls.php"
## =============================================================================



while (TRUE) {
  for (d in 1:nrow(ChinaStocksCalendar)) {
    ## ---------------------------------------------------------------------------
    # d <- 1
    tradingDay <- ChinaStocksCalendar[d, days]
    DATA_PATH <- paste0(SAVE_PATH, '/', gsub('-','',tradingDay))
    if (! dir.exists(DATA_PATH)) dir.create(DATA_PATH, recursive = T)
    ## ---------------------------------------------------------------------------

    ## ===========================================================================
    for (i in 1:nrow(allStocks)) {
      # i <- 1
      tryNo <- 0

      while (tryNo < 3) {
        tryNo <- tryNo + 1
        stockID <- allStocks[i, stockID]
        listingDate <- allStocks[i, listingDate]
        if (tradingDay < listingDate) break

        destFile <- paste0(DATA_PATH, '/', stockID, '.xls')
        if (file.exists(destFile)) {
          print(paste(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), ':==>', tradingDay, ':==>', allStocks[i, stockID], '已经下载'))
          break
        }

        ## =========================================================================
        if (class(try(
          r <- GET(url, query = list(date = tradingDay,
                                     symbol = allStocks[i, paste0(exchID, stockID)]),
                   timeout(3))
        )) == 'try-error') {
          ## -----------------------------------------------------------------------
          Sys.sleep(10)
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
            # if (file.size(destFile) < 100 & tryNo < 2) {
            #   file.remove(destFile)
            # } else {
            #   next
            # }
          } else {
            if (grepl('新浪安全部门', temp)) {
              print(paste(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), ':==>', "等待新浪解禁"))
              Sys.sleep(30)
              # next
            }
          }
          ## -------------------------------------------------------------------------
        }
        ## =========================================================================
      }
    }
    ## ===========================================================================
  }}
