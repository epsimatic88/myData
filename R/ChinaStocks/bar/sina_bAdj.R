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

headers_ip <- c(
  "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
  "Accept-Encoding" = "gzip, deflate",
  "Accept-Language" = "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6",
  "Cache-Control" = "max-age=0",
  "Connection" = "keep-alive",
  "DNT" = "1",
  "Host" = "www.xicidaili.com",
  "Referer" = "http://www.xicidaili.com/nn",
  "Upgrade-Insecure-Requests" = "1",
  "User-Agent" = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.84 Safari/537.36"
  )

headers_goubanjia <- c(
    "Accept"                    = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
    "Accept-Encoding"           = "gzip, deflate",
    "Accept-Language"           = "zh-CN,en-US;q=0.8,zh;q=0.6,en;q=0.4,zh-TW;q=0.2",
    "Cache-Control"             = "max-age=0",
    "Connection"                = "keep-alive",
    "DNT"                       = "1",
    "Host"                      = "www.goubanjia.com",
    "Referer"                   = "http://www.goubanjia.com/free/index2.shtml",
    "Upgrade-Insecure-Requests" = "1",
    "User-Agent"                = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
    )
## =============================================================================
headers <- c(
            "Accept"                    = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
            "Accept-Encoding"           = "gzip, deflate",
            "Accept-Language"           = "zh-CN,en-US;q=0.8,zh;q=0.6,en;q=0.4,zh-TW;q=0.2",
            "Connection"                = "keep-alive",
            "DNT"                       = "1",
            "Host"                      = "vip.stock.finance.sina.com.cn",
            "Referer"                   = "http://vip.stock.finance.sina.com.cn/corp/go.php/vMS_FuQuanMarketHistory/stockid/600482.phtml?year=2004&jidu=2",
            "Upgrade-Insecure-Requests" = "1",
            "User-Agent"                = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
            )
## =============================================================================

getIpTables <- function(url) {
      if (class(try(r <- GET(url))) == 'try-error') {
        ip <- data.table()
      } else {
        page <- content(r, 'text')
        ip <- page %>%
          read_html() %>%
          html_nodes('table') %>%
          html_table() %>%
          .[[1]] %>%
          as.data.table()
      }
      return(ip)
}



fetchIp <- function(x) {
    ipTables_xici <- lapply(1:x, function(i){
      url <- paste0('http://www.xicidaili.com/nn/',i)

      ip <- getIpTables(url)
      return(ip)
    }) %>% rbindlist()
    ipTables_xici <- ipTables_xici[, .(url = IP地址,
                                       port = 端口)]

    url <- "https://www.kuaidaili.com/free/inha/"
    ip <- getIpTables(url)
    if (nrow(ip) != 0) {
        ipTables_kuaidaily1 <- ip[,.(url = IP, port = PORT)]
    } else {
        ipTables_kuaidaily1 <- data.table()
    }
    # Sys.sleep(3)
    # url <- "https://www.kuaidaili.com/free/inha/2"
    # ipTables_kuaidaily2 <- getIpTables(url) %>% 
    #     .[,.(url = IP, port = PORT)]
    # Sys.sleep(3)
    # url <- "https://www.kuaidaili.com/free/inha/3"
    # ipTables_kuaidaily3 <- getIpTables(url) %>% 
    #     .[,.(url = IP, port = PORT)]
    # ipTables_kuaidaily <- list(ipTables_kuaidaily1, 
    #                            ipTables_kuaidaily2,
    #                            ipTables_kuaidaily3) %>% 
    #                            rbindlist()
    ipTables_kuaidaily <- ipTables_kuaidaily1

    ipTables_goubanjia <- lapply(1:x, function(i){
        url <- paste0("http://www.goubanjia.com/free/index",i, ".shtml")
        if (class(try(
            r <- GET(url, add_headers(headers_goubanjia))
            )) == 'try-error'){
            ip <- list()
        } else {
            page <- content(r, 'text')
            ip <- page %>% 
                read_html() %>% 
                html_nodes('table') %>% 
                html_table() %>% 
                .[[1]]
            temp <- strsplit(ip[, "IP:PORT"],":")
            tempUrl <- rep('',length(temp))
            tempPort <- rep('',length(temp))
            for (i in 1:length(temp)) {
                tempUrl[i] <- temp[[i]][1]
                tempPort[i] <- temp[[i]][2]
            }
            ip <- data.table(url = tempUrl, port = tempPort)
        }
        return(ip)
    }) %>% rbindlist()

    url <- "http://www.66ip.cn/nmtq.php?getnum=512&isp=0&anonymoustype=0&start=&ports=&export=&ipaddress=&area=0&proxytype=2&api=66ip"
    if (class(try(r <- GET(url))) != 'try-error') {
        page <- content(r, 'text', encoding = "GB18030")
        ip <- read_html(page) %>% 
            html_nodes('p') %>% 
            html_text() %>% 
            strsplit(., "\r\n\\t") %>% unlist() %>% 
            .[-c(1:2, length(.))] %>% 
            gsub('\\t', '', .)
        ipTables_66 <- lapply(1:length(ip), function(i){
                temp <- unlist(strsplit(ip[i],":"))
                data.table(url = temp[1], port = temp[2])
            }) %>% rbindlist()  
        } else {
            ipTables_66 <- data.table()
        }

    url <- "http://www.ip181.com/"
    r <- GET(url)
    page <- content(r, 'text', encoding = "GB18030")
    ip <- page %>% 
        read_html() %>% 
        html_nodes('table') %>% 
        html_table() %>% 
        .[[1]] %>% 
        as.data.table()
    ipTables_181 <- ip[, .(url = X1, port = X2)]

    ipTables <- list(ipTables_xici, ipTables_kuaidaily, 
                     ipTables_goubanjia, ipTables_66,
                     ipTables_181) %>% 
        rbindlist() %>% 
        .[!duplicated(url)] %>%
        .[!is.na(url) | !is.na(port)] %>% 
        .[, port := as.numeric(port)] %>% 
        .[!is.na(url) & !is.na(port)]

    # ipTables <- ipTables_xici

    cl <- makeCluster(10, type = 'FORK')
    ipAvailable <- parSapply(cl, 1:nrow(ipTables), function(i){
      ip <- ipTables[i]
      # print(i)
      # print(ip)
      if (class(try(r <- GET('http://vip.stock.finance.sina.com.cn/corp/go.php/vMS_FuQuanMarketHistory/stockid/002540.phtml',
                        query = list(year = '2018',
                                     jidu = '1'),
                        add_headers(headers),
                        use_proxy(ip[1, url], ip[1, as.numeric(port)]),
                        timeout(3))
      )) != "try-error") {
        return(i)
      }
    }) %>% unlist()
    stopCluster(cl)

    ipTables <- ipTables[ipAvailable]
    ipTables[, tryNo := 0]
    return(ipTables)
}

ipTables <- suppressMessages({
    suppressMessages({
        fetchIp(3)
    })
})

ipUseful <- FALSE


## =============================================================================

# if (format(Sys.Date(), '%Y-%m-%d') != currTradingDay[1, days]) stop('Not TradingDay !!!')

## -----------------------------------------------------------------------------
allStocks <- mysqlQuery(db = 'china_stocks_info',
                        query = 'select * from stocks_list') %>%
            .[order(stockID)]
DATA_PATH <- "/home/fl/myData/data/ChinaStocks/BarData/FromSina/historical"
## -----------------------------------------------------------------------------


while(TRUE){
for (i in 1:nrow(allStocks)) { #nrow(allStocks)
    ## -------------------------------------------------------------------------
    print(i)
    print(allStocks[i, stockID])
    if (nrow(ipTables) == 0) {
        ipTables <- fetchIp(2)
        Sys.sleep(3)
    }

    ipTables <- ipTables[tryNo < 5]

    stockID <- allStocks[i, stockID]

    if (!ipUseful) ip <- ipTables[sample(1:nrow(ipTables),1)]

    tempDir <- paste0(DATA_PATH, '/', stockID)
    if (!dir.exists(tempDir)) dir.create(tempDir, recursive = T)

    # destFile <- paste0(DATA_PATH, '/', stockID, '.csv')
    # if (file.exists(destFile)) next

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
    while ( tryNo < 5) {
        ## ---------------
        tryNo <- tryNo + 1
        ## ---------------
        for (k in 1:nrow(seasonID)) {
          destFile <- paste0(DATA_PATH, '/', stockID, '/', seasonID[k,yearID], '-', seasonID[k,seasonID], '.csv')
            if (file.exists(destFile)) next

            url <- paste0("http://vip.stock.finance.sina.com.cn/corp/go.php/vMS_FuQuanMarketHistory/stockid/", stockID, ".phtml")

            if (class(try(
                r <- GET(url, 
                        query = list(year = seasonID[k,yearID],
                                     jidu = seasonID[k,seasonID]),
                        add_headers(headers),
                        use_proxy(ip[1, url], ip[1, port]),
                        timeout(5))
            )) == 'try-error') {
              page <- NA
              ipTables[url == ip[1,url], tryNo := tryNo + 1]
            } else {
              page <- content(r, 'text', encoding = 'GB18030')
            }

            if (!grepl('复权历史交易',page) | is.na(page)) {
                if (ipTables[url == ip[1,url], tryNo] >= 5) {
                    ipTables <- ipTables[tryNo < 5]
                    if (nrow(ipTables) == 0) {
                        ipTables <- fetchIp(2)
                        Sys.sleep(30)
                        ip <- ipTables[sample(1:nrow(ipTables),1)]
                    }
                }
              ip <- ipTables[sample(1:nrow(ipTables),1)]
              ipUseful <- FALSE
            } else {
                data <- page %>%
                    read_html(encoding = 'GB18030') %>%
                    html_nodes('table') %>%
                    html_table(fill = TRUE) %>%
                    .[[18]] %>%
                    as.data.table()

                if (nrow(data) != 0) {
                    colnames(data) <- c('TradingDay',
                                      'open','high','low','close',
                                      'volume','turnover','bAdj')
                    data <- data[!grepl("日期", TradingDay)]
                    print(stockID)
                    print(data)
                    # return(data)
                    # daily[[k]] <- data
                    if (nrow(data) != 0)  fwrite(data, destFile)
                }
                ipUseful <- TRUE
            }

        }
    }

}}
