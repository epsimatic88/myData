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
SAVE_PATH <- "/home/fl/myData/data/ChinaStocks/Transaction/FromSina"
ChinaStocksCalendar <- ChinaStocksCalendar[days %between% c('2004-10-08', format(Sys.Date() -1,'%Y-%m-%d'))]
## -----------------------------------------------------------------------------

## =============================================================================
URL <- "http://market.finance.sina.com.cn/downxls.php"
## =============================================================================



while (TRUE) {
  for (d in 1:nrow(ChinaStocksCalendar)) {
    ## -------------------------------------------------------------------------
    # d <- 1
    tradingDay <- ChinaStocksCalendar[d, days]

    tempYear <- substr(tradingDay, 1, 4)
    tempDir <- paste0(SAVE_PATH, '/', tempYear)
    if (!dir.exists(tempDir)) dir.create(tempDir, recursive = T)

    DATA_PATH <- paste0(tempDir, '/', gsub('-','',tradingDay))
    if (! dir.exists(DATA_PATH)) dir.create(DATA_PATH, recursive = T)
    ## -------------------------------------------------------------------------

    ## ===========================================================================
    for (i in 1:nrow(allStocks)) {
      # i <- 1
      tryNo <- 0

      while (tryNo < 3) {
        tryNo <- tryNo + 1
        stockID <- allStocks[i, stockID]
        listingDate <- allStocks[i, listingDate]
        if (tradingDay < listingDate) break

        destFile <- paste0(DATA_PATH, '/', stockID, '.csv')
        if (file.exists(destFile)) {
          l <- readLines(file(destFile, encoding = 'GB18030'))
          if (!any(grepl('html|javascript|alert|Unauthorized|当天没有数据|无效用户|rtn|msg', l)) |
               grepl("成交时间", l[1])) {
            print(paste(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), ':==>', tradingDay, ':==>', allStocks[i, stockID], '已经下载'))
            break
            # next
          } else {
            # system(paste("rm -f", destFile))
            file.remove(destFile)
          }
        }

        ## =========================================================================
        if (class(try(
          r <- GET(URL, query = list(date = tradingDay,
                                     symbol = allStocks[i, paste0(exchID, stockID)]),
                   timeout(5))
        )) == 'try-error') {
          ## -----------------------------------------------------------------------
          Sys.sleep(10)
          print(paste(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), ':==>', tradingDay, ':==>', allStocks[i, stockID], '下载失败'))
        } else {
          ## -------------------------------------------------------------------------
          temp <- suppressMessages(content(r,'text'))
          if (r$status_code == '200') {
            suppressWarnings({
              suppressMessages({
                writeBin(content(r, 'raw'), destFile)
              })
            })

            l <- readLines(file(destFile, encoding = 'GB18030'))
            if (!any(grepl('html|javascript|alert|Unauthorized|当天没有数据|无效用户|rtn|msg', l)) |
               grepl("成交时间", l[1])) {
                print(paste(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), ':==>', tradingDay, ':==>', allStocks[i, stockID], '下载成功'))
                ipUseful <- TRUE
                  break
                  # next
            } else {
                print(paste(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), ':==>', tradingDay, ':==>', allStocks[i, stockID], '无效数据'))
                # system(paste("rm -f", destFile))
                file.remove(destFile)
            }

          } else if (grepl('新浪安全部门', temp)) {
              print(paste(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), ':==>', "等待新浪解禁"))
              Sys.sleep(60)
              # next
          }
          ## -------------------------------------------------------------------------
        }
        ## =========================================================================
      }
    }
    ## ===========================================================================
  }}
