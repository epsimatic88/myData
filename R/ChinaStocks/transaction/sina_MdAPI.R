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
URL <- "http://market.finance.sina.com.cn/downxls.php"
## =============================================================================

ipTables <- suppressMessages({
    suppressMessages({
        fetchIp(20)
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

    while (tryNo < 5) {
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
                        use_proxy(ip[1, url], ip[1, port]),
                        timeout(10))
          )) == 'try-error') {
        ipTables[url == ip[1,url], tryNo := tryNo + 1]
        # ## -----------------------------------------------------------------------
        temp <- ipTables[url == ip[1,url]]
        if (nrow(temp) != 0) {
            ipTables <- ipTables[tryNo < 15]
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
                ipTables[url == ip[1,url], tryNo := tryNo + 1]
                # ## -----------------------------------------------------------------------
                temp <- ipTables[url == ip[1,url]]
                if (nrow(temp) != 0) {
                    ipTables <- ipTables[tryNo < 15]
                }
                if (nrow(ipTables) == 0) {
                    ipTables <- fetchIp(2)
                    Sys.sleep(1)
                }
                ip <- ipTables[sample(1:nrow(ipTables),1)]
                ipUseful <- FALSE

                print(paste(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), ':==>', tradingDay, ':==>', allStocks[i, stockID], '无效数据'))
                # system(paste("rm -f", destFile))
                file.remove(destFile)
            }

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
