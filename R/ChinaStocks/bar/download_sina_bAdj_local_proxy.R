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
headers <- c(
            "Accept"                    = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
            "Accept-Encoding"           = "gzip, deflate",
            "Accept-Language"           = "zh-CN,en-US;q=0.8,zh;q=0.6,en;q=0.4,zh-TW;q=0.2",
            "Connection"                = "keep-alive",
            "DNT"                       = "1",
            "Host"                      = "vip.stock.finance.sina.com.cn",
            "Upgrade-Insecure-Requests" = "1",
            "User-Agent"                = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
            )
## =============================================================================


## =============================================================================

# if (format(Sys.Date(), '%Y-%m-%d') != currTradingDay[1, days]) stop('Not TradingDay !!!')

## -----------------------------------------------------------------------------
allStocks <- mysqlQuery(db = 'china_stocks_info',
                        query = 'select * from stocks_list') %>%
            .[order(stockID)]
DATA_PATH <- "/home/fl/myData/data/ChinaStocks/Bar/FromSina/historical"
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
temp <- format(Sys.Date(), "%m") %>% as.numeric()

if (temp %between% c(1,3)) {
    s <- '1'
} else if (temp %between% c(4,6)) {
    s <- '2'
} else if (temp %between% c(7,9)) {
    s <- '3'
} else {
    s <- '4'
}
currentSeasonID <- paste(format(Sys.Date(), "%Y"), s, sep = '-')
## -----------------------------------------------------------------------------

while (TRUE) {
for (i in 1:nrow(allStocks)) { #nrow(allStocks)
    ## -------------------------------------------------------------------------
    print(i)
    print(allStocks[i, stockID])

    stockID <- allStocks[i, stockID]

    tempDir <- paste0(DATA_PATH, '/', stockID)
    if (!dir.exists(tempDir)) dir.create(tempDir, recursive = T)

    ## -------------------------------------------------------------------------
    listingDate <- allStocks[i, listingDate]

    startYear <- substr(listingDate, 1, 4) %>% as.numeric()
    startSeason <- ceiling(as.numeric(substr(listingDate, 6, 7)) / 3)

    endYear <- format(Sys.Date(), '%Y') %>% as.numeric()
    endSeason <- ceiling(as.numeric(format(Sys.Date(), '%m')) / 3)

    if ((endYear - startYear) < 2) {
        middleYear <- 0
    } else {
        middleYear <- seq(startYear, endYear) %>% .[-c(1, length(.))]
    }

    seasonID_start <- data.table(yearID = startYear,
                                 seasonID = seq(startSeason, 4))
    seasonID_end <- data.table(yearID = endYear,
                               seasonID = seq(1, endSeason))

    if (all(middleYear == 0)) {
        seasonID_middle <- data.table()
    } else {
        seasonID_middle <- merge(x = middleYear, y = c(1,2,3,4), by = NULL)
    }

    if (nrow(seasonID_middle) == 0) {
        seasonID <- list(seasonID_start, seasonID_end)
    } else {
        seasonID <- list(seasonID_start, seasonID_middle, seasonID_end)
    }

    seasonID <- rbindlist(seasonID) %>% .[order(yearID, seasonID)]

    ## -------------------------------------------------------------------------

    tryNo <- 0
    # daily <- list()

    # while ((length(daily) < nrow(seasonID)) & (tryNo < 2)) {
    while ( tryNo < 2) {
        ## ---------------
        tryNo <- tryNo + 1
        ## ---------------
        for (k in 1:nrow(seasonID)) {
          destFile <- paste0(DATA_PATH, '/', stockID, '/', seasonID[k,yearID], '-', seasonID[k,seasonID], '.csv')
          ## ===================================================================
            if (!file.exists(destFile) | 
                seasonID[k, paste(yearID, seasonID, sep = '-')] == currentSeasonID) {

                url <- paste0("http://vip.stock.finance.sina.com.cn/corp/go.php/vMS_FuQuanMarketHistory/stockid/", stockID, ".phtml")

                if (class(try(
                    r <- GET(url,
                            query = list(year = seasonID[k,yearID],
                                         jidu = seasonID[k,seasonID]),
                            add_headers(headers),
                            timeout(3))
                )) == 'try-error') {
                      page <- NA
                } else {
                  page <- content(r, 'text', encoding = 'GB18030')
                }

                ## -----------------------------------------------------------------
                if (!grepl('复权历史交易',page) | is.na(page)) {
                    Sys.sleep(30)
                    next
                } else {
                    ## -------------------------------------------------------------
                    data <- page %>%
                        read_html(encoding = 'GB18030') %>%
                        html_nodes('table') %>%
                        html_table(fill = TRUE) %>%
                        .[[18]] %>%
                        as.data.table()

                    if (nrow(data) != 0) {
                        colnames(data) <- c('TradingDay',
                                          'open','high','close','low',
                                          'volume','turnover','bAdj')
                        data <- data[!grepl("日期", TradingDay)] %>%
                          .[, .(TradingDay, open, high, low, close,
                                volume, turnover, bAdj)]
                        print(stockID)
                        print(data)
                        # return(data)
                        # daily[[k]] <- data
                        if (nrow(data) == 0) {
                            data <- data.table(TradingDay = NA,
                                               open = NA,
                                               high = NA,
                                               low  = NA,
                                               close = NA,
                                               volume = NA,
                                               turnover = NA,
                                               bAdj = NA)

                        }
                        fwrite(data, destFile)
                    }
                    Sys.sleep(1)
                    ## -------------------------------------------------------------
                }
                ## -----------------------------------------------------------------
            }
          ## ===================================================================
        }
    }

}}
