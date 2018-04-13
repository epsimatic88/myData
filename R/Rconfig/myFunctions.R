## =============================================================================
## myFunctions.R
##
## 个人构造的函数
##
## Author   : fl@hicloud-investment.com
## Date     : 2018-01-15
## MODIFIED : 2018-03-05
## =============================================================================

library(httr)

## =============================================================================
## 计算 股票
##     从上市日期到当前日期的各个季节
##     主要用于处理 新浪股票 历史复权数据的爬虫
## @params
##        @input listingDate: 上市日期， 格式为 “YYYYmmdd"
## -----------------------------------------------------------------------------
calSeason <- function(listingDate) {
  if (length(listingDate) > 8 | grepl('-', listingDate)) {
    print('错误的日期格式')
    return(NA)
  }
  temp <- gsub('-', '', listingDate)

  startYear <- substr(temp, 1, 4) %>% as.numeric()
  startSeason <- ceiling(as.numeric(substr(temp, 5, 6)) / 3)

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

  seasonAll <- rbindlist(seasonID) %>% .[order(yearID, seasonID)] %>%
    .[!duplicated(paste0(yearID,seasonID))]
  return(seasonAll)
}
## =============================================================================

headers_xici <- c(
  "Accept"                    = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
  "Accept-Encoding"           = "gzip, deflate",
  "Accept-Language"           = "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6",
  "Cache-Control"             = "max-age=0",
  "Connection"                = "keep-alive",
  "DNT"                       = "1",
  "Host"                      = "www.xicidaili.com",
  "Referer"                   = "http://www.xicidaili.com/nn",
  "Upgrade-Insecure-Requests" = "1",
  "User-Agent"                = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.84 Safari/537.36"
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

headers_181 <- c(
  "Accept"                    = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
  "Accept-Encoding"           = "gzip, deflate",
  "Accept-Language"           = "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6",
  "Cache-Control"             = "max-age=0",
  "Connection"                = "keep-alive",
  "DNT"                       = "1",
  "Host"                      = "www.ip181.com",
  "Upgrade-Insecure-Requests" = "1",
  "User-Agent"                = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3298.3 Safari/537.36"
)

header_data5u <- c(
'Accept' = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
'Accept-Encoding' = 'gzip, deflate',
'Accept-Language' = 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6',
'Cache-Control' = 'max-age=0',
'Connection' = 'keep-alive',
'DNT' = '1',
'Host' = 'www.data5u.com',
'Referer' = 'http://www.data5u.com/free/gngn/index.shtml',
'Upgrade-Insecure-Requests' = '1',
'User-Agent' = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3298.3 Safari/537.36'
    )

headers_feilongip <- c(
'Accept' = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
'Accept-Encoding' = 'gzip, deflate',
'Accept-Language' = 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6',
'Cache-Control' = 'max-age=0',
'Connection' = 'keep-alive',
'DNT' = '1',
'Host' = 'www.feilongip.com',
'Referer' = 'https://www.google.com/',
'Upgrade-Insecure-Requests' = '1',
'User-Agent' = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3298.3 Safari/537.36')


headers_66ip_main <- c(
'Accept' = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
'Accept-Encoding' = 'gzip, deflate',
'Accept-Language' = 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6',
'Connection' = 'keep-alive',
'DNT' = '1',
'Host' = 'www.66ip.cn',
'Referer' = 'http://www.66ip.cn/26.html',
'Upgrade-Insecure-Requests' = '1',
'User-Agent' = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3298.3 Safari/537.36')

## =============================================================================

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

url_sina <- "http://market.finance.sina.com.cn/downxls.php"
headers_sina <- c(
'Accept' = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8'
,'Accept-Encoding' = 'gzip, deflate'
,'Accept-Language' = 'zh-CN,en-US;q=0.8,zh;q=0.6,en;q=0.4,zh-TW;q=0.2'
,'Connection' = 'keep-alive'
,'DNT' = '1'
,'Host' = 'vip.stock.finance.sina.com.cn'
,'Referer' = 'http://market.finance.sina.com.cn/downxls.php'
,'Upgrade-Insecure-Requests' = '1'
,'User-Agent' = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36'
    )
## =============================================================================

getIpTables <- function(url) {
  if (class(try(
        r <- GET(url, timeout(10))
        , silent = T)) == 'try-error') {
    ip <- data.table()
  } else {
    page <- content(r, 'text')
    if (is.na(page) | nchar(page) < 1000) return(data.table())
    if (page[1] %in% c('block','-10')) return(data.table())
    ip <- page %>%
      read_html() %>%
      html_nodes('table') %>%
      html_table(fill = TRUE) %>%
      .[[1]] %>%
      as.data.table()
  }
  return(ip)
}



fetchIp <- function(x) {
  ipTables_xici <- lapply(1:x, function(i){
    url <- paste0('http://www.xicidaili.com/nn/',i)
    ip <- getIpTables(url)
    Sys.sleep(1)
    return(ip)
  }) %>% rbindlist()
  if (nrow(ipTables_xici) == 0) {
    ipTables_xici <- data.table()
  } else {
    ipTables_xici <- ipTables_xici[, .(url = IP地址,
                                       port = 端口)]
  }
  print('0')

  ## ===========================================================================
  ## 快代理
  # url <- "https://www.kuaidaili.com/free/inha/"
  # url <- "https://www.kuaidaili.com/free/intr/"
  ipTables_kuaidaily_1 <- lapply(1:x, function(i){
    # print(i)
    url <- paste0("https://www.kuaidaili.com/free/intr/", i, '/')
    res <- getIpTables(url)
    Sys.sleep(1)
    return(res)
  }) %>% rbindlist()
  print('1')

  ipTables_kuaidaily_2 <- lapply(1:x, function(i){
    # print(i)
    url <- paste0("https://www.kuaidaili.com/free/inha/", i, '/')
    res <- getIpTables(url)
    Sys.sleep(1)
    return(res)
  }) %>% rbindlist()
  ipTables_kuaidaily <- list(ipTables_kuaidaily_1, ipTables_kuaidaily_2) %>%
    rbindlist()
  if (nrow(ipTables_kuaidaily) != 0) {
    ipTables_kuaidaily <- ipTables_kuaidaily[, .(url = IP, port = PORT)]
  }
  print('2')
  ## ===========================================================================

  # ipTables_goubanjia <- lapply(1:x, function(i){
  #     url <- paste0("http://www.goubanjia.com/free/index",i, ".shtml")
  #     if (class(try(
  #         r <- GET(url, add_headers(headers_goubanjia))
  #         )) == 'try-error'){
  #         ip <- list()
  #     } else {
  #         page <- content(r, 'text')
  #         ip <- page %>%
  #             read_html() %>%
  #             html_nodes('table') %>%
  #             html_table(fill = TRUE) %>%
  #             .[[1]]
  #         temp <- strsplit(ip[, "IP:PORT"],":")
  #         tempUrl <- rep('',length(temp))
  #         tempPort <- rep('',length(temp))
  #         for (i in 1:length(temp)) {
  #             tempUrl[i] <- temp[[i]][1]
  #             tempPort[i] <- temp[[i]][2]
  #         }
  #         ip <- data.table(url = tempUrl, port = tempPort)
  #     }
  #     return(ip)
  # }) %>% rbindlist()

  ## ===========================================================================
  url <- "http://www.66ip.cn/nmtq.php?getnum=512&isp=0&anonymoustype=0&start=&ports=&export=&ipaddress=&area=0&proxytype=2&api=66ip"
  if (class(try(r <- GET(url,timeout(10)), silent = T)) != 'try-error') {
    page <- content(r, 'text', encoding = "GB18030")
    if (is.na(page)) {
      ipTables_66 <- data.table()
    } else {
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
    }

  } else {
    ipTables_66 <- data.table()
  }
  print('3')

  ipTables_66ip_main <- lapply(1:x, function(i){
      if (i < 3) return(data.table())
      url_66ip_main <- paste0("http://www.66ip.cn/", i, ".html")

      if (class(try(
                    r <- GET(url_66ip_main, add_headers(headers_66ip_main), timeout(10))
                    , silent = T)) != 'try-error') {
          p <- content(r, as = 'text', encoding = 'GB18030')
          if (is.na(p)) return(data.table())
          w <- p %>%
              read_html() %>%
              html_nodes('table') %>%
              html_table() %>%
              .[[3]] %>%
              as.data.table()
          colnames(w) <- paste0('X', 1:ncol(w))
          w <- w[grepl('\\d', X1)]
          res <- w[, .(url = X1, port = X2)]
      } else {
          res <- data.table()
      }

      return(res)
  }) %>% rbindlist()

  print('4')
  ## ===========================================================================

  ## ===========================================================================
  # url <- "http://www.ip181.com/"
  # if (class(try(
  #               r <- GET(url, add_headers(headers_181),timeout(10))
  #               )) != 'try-error') {
  #   page <- content(r, 'text', encoding = "GB18030")
  #   ip <- page %>%
  #     read_html() %>%
  #     html_nodes('table') %>%
  #     html_table(fill = TRUE) %>%
  #     .[[1]] %>%
  #     as.data.table()
  #   ipTables_181 <- ip[, .(url = X1, port = X2)] %>%
  #     .[!grepl("地址", url)]
  # } else {
  #   ipTables_181 <- data.table()
  # }

  # ipTables_181 <- lapply(1:x, function(i){
  #   url <- paste0("http://www.ip181.com/daili/", i, ".html")
  #
  #   if (class(try(
  #                 r <- GET(url, add_headers(headers_181),timeout(10))
  #                 , silent = T)) != 'try-error') {
  #     page <- content(r, 'text', encoding = "GB18030")
  #     if (is.na(page)) return(data.table())
  #     ip <- page %>%
  #       read_html() %>%
  #       html_nodes('table') %>%
  #       html_table(fill = TRUE)
  #     if (length(ip) == 0) return(data.table())
  #     ip <- ip[[1]] %>%
  #       as.data.table()
  #     res <- ip[, .(url = X1, port = X2)] %>%
  #       .[!grepl("地址", url)]
  #   } else {
  #     res <- data.table()
  #   }
  #   Sys.sleep(1)
  #   return(res)
  # }) %>% rbindlist()
  # print('5')
  ## ===========================================================================

  ## ===========================================================================
  url <- "http://lab.crossincode.com/proxy/"
  if (class(try(r <- GET(url,timeout(10)), silent = T)) != 'try-error') {
    page <- content(r, 'text')
    if (is.na(page)) {
      ipTables_crossincode <- data.table()
    } else {
      ipTables_crossincode <- page %>%
        read_html() %>%
        html_nodes('table') %>%
        html_table(fill = T) %>%
        .[[1]] %>%
        as.data.table() %>%
        .[, .(url = Addr, port = Port)]
    }

  } else {
    ipTables_crossincode <- data.table()
  }
  ## ===========================================================================
  print('6')
  ipTables_ip3366 <- lapply(1:x, function(i){
    url <- paste0("http://www.ip3366.net/free/?page=", i)
    if (class(try(
        res <- url %>%
          read_html() %>%
          html_nodes('table') %>%
          html_table(fill = T) %>%
          .[[1]] %>%
          as.data.table() %>%
          .[, .(url = IP, port = PORT)]
        , silent = T)) == 'try-error') {
      res <- data.table()
    }
    Sys.sleep(1)
    return(res)
  }) %>% rbindlist()
  print('7')
  ## ===========================================================================
  url_data5u <- "http://www.data5u.com/free/index.shtml"

  if (class(try(
                r <- GET(url_data5u, add_headers(header_data5u), timeout(5))
                , silent = T)) != 'try-error') {
      p <- content(r, 'text')
      if (is.na(p)) {
        ipTables_data5u <- data.table()
      } else {
        w <- p %>%
          read_html() %>%
          html_nodes('li') %>%
          html_text() %>%
          .[nchar(.) > 100] %>%
          strsplit(., "\r\n\t\t[ ]{1,}\r\n\t\t") %>%
          unlist()
        if (length(w) < 2) ipTables_data5u <- data.table()

        ipTables_data5u <- lapply(2:length(w), function(i){
          tmp <- w[i] %>%
            strsplit(., '\r|\n|\t') %>%
            unlist() %>%
            .[nchar(.) >= 2] %>%
            gsub(' ', '', .)
          res <- data.table(url = tmp[1],
                            port = tmp[2])
        }) %>% rbindlist() %>%
          .[!is.na(port)]
      }

  } else {
      ipTables_data5u <- data.table()
  }
  ## ===========================================================================
  print('8')
  ## ===========================================================================
  url_feilongip <- "http://www.feilongip.com/"

  if (class(try(
                r <- GET(url_feilongip, add_headers(headers_feilongip), timeout(30))
                , silent = T)) != 'try-error') {
      p <- content(r, 'text')
      if (is.na(p)) {
        ipTables_feilongip <- data.table()
      } else {
        w <- p %>%
          read_html() %>%
          html_nodes('table') %>%
          html_table() %>%
          .[[1]] %>%
          as.data.table()
        colnames(w) <- paste0('X', 1:ncol(w))
        ipTables_feilongip <- data.table(url = rep('', nrow(w)),
                                         port = rep('', nrow(w)))
        for (ii in 1:nrow(w)) {
          tmp <- w[ii, X2] %>%
            strsplit(., ':|：') %>%
            unlist()
          ipTables_feilongip[ii, ":="(url = tmp[1], port = tmp[2])]
        }
      }

  } else {
      ipTables_feilongip <- data.table()
  }
  print('9')
  ## ===========================================================================

  # url <- "http://www.ip3366.net/"
  # if (class(try(r <- GET(url,timeout(10)))) != 'try-error') {
  #   page <- content(r, 'text')
  #   if (!is.na(page)) {
  #     ipTables_ip3366 <- url %>%
  #       read_html() %>%
  #       html_nodes('table') %>%
  #       html_table(fill = T) %>%
  #       .[[1]] %>%
  #       as.data.table() %>%
  #       .[, .(url = 代理IP地址, port = 端口)]
  #   } else {
  #     ipTables_ip3366 <- data.table()
  #   }
  # } else {
  #   ipTables_ip3366 <- data.table()
  # }

  # url <- "http://www.swei360.com/"
  # if (class(try(r <- GET(url))) != 'try-error') {
  #   page <- content(r, 'text')
  #   ipTables_swei360 <- url %>%
  #     read_html() %>%
  #     html_nodes('table') %>%
  #     html_table(fill = T) %>%
  #     .[[1]] %>%
  #     as.data.table() %>%
  #     .[, .(url = 代理IP地址, port = 端口)]
  # } else {
  #   ipTables_swei360 <- data.table()
  # }

    ipTables_66_hk <- lapply(33:34, function(i){

        res <- lapply(1:5, function(j){
            url <- paste0("http://www.66ip.cn/areaindex_", i, "/1.html")
            if (class(try(
                          r <- GET(url, timeout(5))
                ,silent = T)) == 'try-error') return(data.table())

            p <- content(r, as = 'text', encoding = 'GB18030')
            w <- p %>%
                read_html() %>%
                html_nodes('table') %>%
                html_table() %>%
                .[[3]] %>%
                as.data.table() %>%
                .[!grepl('ip', X1)] %>%
                .[, .(url = X1, port = X2)]
        }) %>% rbindlist()

    }) %>% rbindlist()

  ipTables <- list(#ipTables_xici
                   ipTables_kuaidaily
                   # ,ipTables_goubanjia  ## 已经失效
                   ,ipTables_crossincode
                   ,ipTables_66
                   # ,ipTables_181
                   ,ipTables_ip3366
                   ,ipTables_data5u
                   ,ipTables_feilongip
                   ,ipTables_66ip_main
                   ,ipTables_66_hk) %>%
    rbindlist() %>%
    .[!duplicated(url)] %>%
    .[!is.na(url) | !is.na(port)] %>%
    .[, port := as.numeric(port)] %>%
    .[!is.na(url) & !is.na(port)]


  ## ===========================================================================
  print("启动并行模式验证 IP 有效性......")
  print(ipTables)
  cl <- makeCluster(8, type = 'FORK')
  ipAvailable <- parSapply(cl, 1:nrow(ipTables), function(i){
    ip <- ipTables[i]
    if (class(try(
      r <- GET('http://vip.stock.finance.sina.com.cn/corp/go.php/vMS_FuQuanMarketHistory/stockid/000001.phtml',
                           query = list(year = '2018',
                                        jidu = '1'),
                           add_headers(headers),
                           use_proxy(ip[1, url], ip[1, as.numeric(port)]),
                           timeout(3))
    )) != "try-error") {
      if (r$status_code == '200') return(i)
    }
  }) %>% unlist()
  stopCluster(cl)
  ipTables <- ipTables[ipAvailable]
  ## ===========================================================================

  ipTables[, tryNo := 0]
  return(ipTables)
}



transform_wind_code <- function(stockID) {
    if (substr(stockID, 1, 1) == '6') {
        res <- paste0(stockID, ".SH")
    } else {
        res <- paste0(stockID, ".SZ")
    }
    return(res)
}




# cl <- makeCluster(12, type = 'FORK')
# res <- parSapply(cl, 1:nrow(ipTables[1:100]), function(i){
#     ip <- ipTables[i,]
#     if (class(try(
#                 r <- GET(url_sina,
#                         query = list(
#                                      date = '2010-01-04',
#                                      symbol = 'sz000002'
#                                      ),
#                         add_headers(headers_sina),
#                         use_proxy(ip[1, url], ip[1, as.numeric(port)]),
#                         timeout(3))
#                 , silent = T)) != 'try-error') {
#         if (r$status_code == '200') {
#             p <- content(r, 'text', encoding = 'GB18030')
#             if (!grepl('html|javascript|alert|Unauthorized|当天没有数据|无效用户|rtn|msg', p)) {
#                 return(i)
#             }
#         }
#     }
# }) %>% unlist()
# stopCluster(cl)

# ipTables <- ipTables[res]



################################################################################
## daily updating function
## 每日更新数据的函数
## -----------------------
################################################################################

## =============================================================================
## fetch_lhb_data_from_sse
## 从 上交所 交易网站下载 龙虎榜 数据
## -----------------------------
url_sse <- "http://query.sse.com.cn/infodisplay/showTradePublicFile.do"
headers_sse = c(
  "Accept"          = "*/*",
  "Accept-Encoding" = "gzip, deflate",
  "Accept-Language" = "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6",
  "Connection"      = "keep-alive",
  "DNT"             = "1",
  "Host"            = "query.sse.com.cn",
  "Referer"         = "http://www.sse.com.cn/disclosure/diclosure/public/",
  "User-Agent"      = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3298.3 Safari/537.36"
  )

fetch_lhb_data_from_sse <- function(tradingDay) {
    # tradingDay <- '2018-02-27'

    payload <- list(
        dateTx = tradingDay
        )

    ## -----------------------------------------------
    tryNo <- 0
    while (tryNo <= 100) {
      tryNo <- tryNo + 1

      if (tryNo == 100) return(NA)

      if (class(try(
          r <- GET(url_sse, 
                   query = payload, 
                   add_headers(headers_sse))
        ,silent = T)) == 'try-error') {
        Sys.sleep(.5)
        next
      }

      p <- content(r, 'parsed')

      webData <- p[which.max(sapply(p, length))] %>% 
          .[[1]] %>% 
          unlist() %>% 
          .[!grepl("\\\032", .)]
      return(webData)
    }
    ## -----------------------------------------------

}
## =============================================================================



## =============================================================================
## fetch_lhb_data_from_szse
## 从 深交所 交易网站下载 龙虎榜 数据
## -----------------------------
fetch_lhb_data_from_szse <- function(tradingDay, mkt) {
  # tradingDay <- '2018-02-27'
  # mkt :
  # 1. 深交所主板:00
  # 2. 深交所中小板:02
  # 3. 深交所创业板:30
  tradingDay <- format(as.Date(tradingDay), "%y%m%d")

  if (mkt == '00') {
    url <- "http://www.szse.cn/szseWeb/common/szse/files/text/jy/jy"
  } else if (mkt == '02') {
    url <- "http://www.szse.cn/szseWeb/common/szse/files/text/smeTxt/gk/sme_jy"
  } else {
    url <- "http://www.szse.cn/szseWeb/common/szse/files/text/nmTxt/gk/nm_jy"
  }
  ## -----------------------------------
  url <- paste0(url, tradingDay, '.txt')
  ## -----------------------------------

  ## -----------------------------------------------
  tryNo <- 0
  while (tryNo <= 100) {
    tryNo <- tryNo + 1
    if (tryNo == 100) return(NA)

    ## -------------------------------
    if (class(try(
        r <- GET(url)
      , silent = T)) == 'try-error') {
      Sys.sleep(.5)
      next
    } else if (r$status_code != '200') {             ## 访问错误
      next
    } else if (grepl('html', content(r, 'text'))) {  ## 没有数据，只有网页提示错误
      next
    } else {
      return(r)
    }
    ## -------------------------------

  }
  ## -----------------------------------------------
  
}
## =============================================================================


## =============================================================================
## parse_lhb_from_sse
## 解析 上交所 龙虎榜 数据文
## ---------------------
parse_lhb_from_sse <- function(dataFile) {
    # print(dataFile)

    tradingDay <- gsub(".*([0-9]{4}-[0-9]{2}-[0-9]{2}).*", "\\1", dataFile)

    f <- readLines(dataFile)

    ## -------------------------------------------------------------------------
    ## 替换分行的上榜原因
    # sp <- grep("\"|并且该股票封闭式|在这2个交易日中同一营业部净买入|在这2个交易日中同一营业部净卖出", f)
    sp_title <- grep('[一|二|三|四|五|六|七|八|九|十]{1,}、', f)
    sp_new <- c()
    for (s in sp_title) {
        if (nchar(f[s]) > 42) sp_new <- c(sp_new, s)
    }
    

    sp_rm <- c()
    for (s in sp_new) {
        # print(s)
        if (nchar(f[s+1]) == 0) {
            f[s] <- paste0(f[s], f[s+1], f[s+2]) %>% 
                gsub("\"| ", '', .)
            sp_rm <- c(sp_rm, s+1, s+2)
        } else {
            f[s] <- paste0(f[s], f[s+1]) %>% 
                gsub("\"| ", '', .)
            sp_rm <- c(sp_rm, s+1)
        }
    }
    f <- f[-sp_rm]

    ## -------------------------------------------------------------------------

    m <- grep("、.*(:|：|%|%)", f) %>% c(., length(f))

    dt <- lapply(2:length(m), function(k){
        # print(k)
        tmp <- f[m[k-1] : (m[k]-1)]

        if (!any(grepl("证券代码", tmp))) return(data.table())

        lhbName <- tmp[1] %>%
            gsub("[一|二|三|四|五|六|七|八|九|十]{1,}、(.*)", '\\1', .) %>% 
            gsub(':|：', '', .)

        u <- grep('证券代码: [0-9]{6}', tmp)[1] 
        if (is.na(u)) return(data.table())

        v <- grep('2、B股', tmp)-1

        if (length(v) != 0) {

            if (length(u) != length(v)) {
                print(dataFile)
                print(k)
                stop("Error")
            }

            if (v <= u) return(data.table())

            info <- tmp[u:v]
        } else {
            info <- tmp[u:length(tmp)]
        }

        w <- grep('证券代码: [0-9]{6}', info) %>% c(., length(info))

        res <- lapply(2:length(w), function(kk){
            # print(kk)
            allInfo <- info[w[kk-1] : (w[kk]-1)] %>% 
                .[!is.na(.)]

            stockInfo <- grep('证券代码: [0-9]{6}', allInfo, value = T) %>%
                strsplit(., '          ') %>% 
                unlist() %>% 
                .[nchar(.) != 0] %>% 
                gsub(' ', '', .)
            stockID <- grep('[0-9]{6}', stockInfo, value = T) %>% 
                gsub('\\D', '', .)
            stockName <- grep('[0-9]{6}', stockInfo, value = T, invert = T) %>% 
                strsplit(., ':|：') %>% 
                unlist() %>% 
                grep('简称', ., value = T, invert = T)

            if (any(grep('买入', allInfo))) {
                if (!any(grepl('卖出', allInfo))) {
                    if (kk == length(w)) {
                        buy <- allInfo[grep('买入', allInfo) : (length(allInfo) - 0)] %>% 
                        grep("\\([0-9]\\)", ., value = T) 
                    } else {
                        buy <- allInfo[grep('买入', allInfo) : (length(allInfo) - 1)] %>% 
                        grep("\\([0-9]\\)", ., value = T) 
                    }
                } else {
                    buy <- allInfo[grep('买入', allInfo) : (grep('卖出', allInfo) - 1)] %>% 
                        grep("\\([0-9]\\)", ., value = T)
                }

                buyInfo <- lapply(buy, function(l){
                    y <- strsplit(l, ' ') %>% 
                        unlist() %>% 
                        .[nchar(.) != 0] %>% 
                        .[!grepl("\\([0-9]\\)", .)]
                    res <- data.table(DeptName = grep('证券|公司|营业|部|机构|专用', y, value = T),
                                      direction = 'buy',
                                      turnover = grep('证券|公司|营业|部|机构|专用', y, value = T, invert = T))
                }) %>% rbindlist()
            } else {
                buyInfo <- data.table()
            }

            if (any(grep('卖出', allInfo))) {
                sell <- allInfo[grep('卖出', allInfo) : length(allInfo)] %>% 
                    grep("\\([0-9]\\)", ., value = T)
                sellInfo <- lapply(sell, function(l){
                    y <- strsplit(l, ' ') %>% 
                        unlist() %>% 
                        .[nchar(.) != 0] %>% 
                        .[!grepl("\\([0-9]\\)", .)]
                    res <- data.table(DeptName = grep('证券|公司|营业|部|机构|专用', y, value = T),
                                      direction = 'sell',
                                      turnover = grep('证券|公司|营业|部|机构|专用', y, value = T, invert = T))
                }) %>% rbindlist()
            } else {
                sellInfo <- data.table()
            }

            res <- list(buyInfo, sellInfo) %>% rbindlist()

            res[direction == 'buy', buyAmount := turnover]
            res[direction == 'sell', sellAmount := turnover]

            res[, ":="(
                stockID = stockID,
                stockName = stockName,
                lhbName = lhbName,
                ## ---------------
                direction = NULL,
                turnover = NULL
                )]
            return(res)
        }) %>% rbindlist()
        return(res)
    }) %>% rbindlist()

    dt[, TradingDay := tradingDay]

    return(dt)
}

## =============================================================================


## =============================================================================
## parse_lhb_from_szse
## 解析 深交所 龙虎榜 数据文
## ---------------------
parse_lhb_from_szse <- function(dataFile) {

    # dataFile <- "/home/fl/myData/data/ChinaStocks/LHB/FromExch/2012/2012-12-28_szse_30.txt"

    tradingDay <- gsub(".*([0-9]{4}-[0-9]{2}-[0-9]{2}).*", "\\1", dataFile)

    ## 2006-07-01 之前的数据就不要用了
    ## 没有买入、卖出的金额
    if (tradingDay < '2006-07-01') return(data.table())

    if (class(try(
            f <- readLines(file(dataFile, encoding = 'GB18030')) %>% 
                .[grep('证券(:|：)|详细信息', .)[1] : length(.)]
        )) == 'try-error') {
        return(data.table())
    }

    sp_line <- grep('证券(:|：)|[-]{5,}', f) %>% c(., length(f))

    dt <- lapply(2:length(sp_line), function(kk){
        # print(kk)

        tmp <- f[sp_line[kk - 1] : (sp_line[kk] - 1)]

        if (length(tmp) < 5) return(data.table())

        lhbName <- grep('证券(:|：)', tmp) 
        if (lhbName != 1) {
            if (nchar(tmp[lhbName - 1]) != 0) {
                lhbName <- paste0(tmp[lhbName - 1], tmp[lhbName])
            } else {
                lhbName <- tmp[lhbName]
            }
        } else {
            lhbName <- tmp[lhbName]
        }
        lhbName <- gsub(":|：", '', lhbName)

        if (identical(lhbName, character(0))) return(data.table())
        if (grepl('无$', lhbName)) return(data.table())

        sp_stock <- grep('代码(:|：| |)[0-9]{6}', tmp) %>% c(., length(tmp))

        res <- lapply(2:length(sp_stock), function(ss){
            # ss <- 2
            allInfo <- tmp[sp_stock[ss - 1] : (sp_stock[ss] - 1)]

            stockInfo <- grep('代码(:|：| |)[0-9]{6}', allInfo, value = T) %>% 
                strsplit(., '\\)') %>% 
                unlist() %>% 
                .[1] %>%
                strsplit(., '\\(|\\)') %>% 
                unlist()
            stockName <- grep('\\d', stockInfo, value = T, invert = T)
            stockID <- grep('\\d', stockInfo, value = T) %>% 
                gsub('\\D', '', .)

            buy <- allInfo[grep('买入金额最大', allInfo) : (grep('卖出金额最大', allInfo) - 1)] %>% 
                .[(grep('营业部或', .) + 1) : length(.)] %>% 
                .[nchar(.) != 0]
            buyInfo <- lapply(buy, function(b){
                u <- strsplit(b, ' ') %>% 
                    unlist() %>% 
                    grep('\\S', ., value = T)
                data.table(DeptName = u[1],
                           buyAmount = u[2],
                           sellAmount = u[3])
            }) %>% rbindlist()

            sell <- allInfo[grep('卖出金额最大', allInfo) : length(allInfo)] %>% 
                .[(grep('营业部或', .) + 1) : length(.)] %>% 
                .[nchar(.) != 0]
            sellInfo <- lapply(sell, function(s){
                u <- strsplit(s, ' ') %>% 
                    unlist() %>% 
                    grep('\\S', ., value = T)
                data.table(DeptName = u[1],
                           buyAmount = u[2],
                           sellAmount = u[3])
            }) %>% rbindlist()

            res <- list(buyInfo, sellInfo) %>% rbindlist() %>% 
                .[, ":="(
                    stockID = stockID,
                    stockName = stockName,
                    lhbName = lhbName
                    )]
        }) %>% rbindlist()

    }) %>% rbindlist()

    if (nrow(dt) != 0) dt[, TradingDay := tradingDay]

    return(dt)
}

## =============================================================================


## =============================================================================
## parse_lhb_from_exch
## 处理 上交所+深交所 龙虎榜数据
## -----------
parse_lhb_from_exch <- function(tradingDay) {
    ## -------------------------------------------------------------------------
    tempYear <- substr(tradingDay, 1, 4)
    tempPath <- paste0("/home/fl/myData/data/ChinaStocks/LHB/FromExch/", tempYear)
    ## -------------------------------------------------------------------------

    fileSSE <- paste0(tempPath, "/", tradingDay, "_sse.txt")
    dt_sse <- parse_lhb_from_sse(fileSSE)

    dt_szse <- lapply(c('00', '02', '30'), function(mkt){
        fileSZSE <- paste0(tempPath, "/", 
                           tradingDay, 
                           "_szse_", mkt, ".txt")
        res <- parse_lhb_from_szse(fileSZSE)
    }) %>% rbindlist()

    dt <- rbind(dt_sse, dt_szse)
    dt[, stockName := gsub(' ', '', stockName) %>% 
                      gsub('Ａ', 'A', .) %>% 
                      gsub("Ｂ", "B", .)]
    dt[, netAmount := as.numeric(buyAmount) - as.numeric(sellAmount)]

    return(dt)
}
## =============================================================================


## =============================================================================
## fetch_lhb_data_from_eastmoney
## 从 东方财富 获取龙虎榜数据
## -----------------------------

## ------------------------------------------------------------------------
## 获取表格数据内容
fetch_lhb_amount_from_eatmoney <- function(x, className) {
    # className <- classInfo[k]
    # x <- data1
    colnames(x) <- paste0("X", 1:ncol(x))
    x <- x[!grepl("序号|合计", X1)]
    x[, X2 := gsub("\\\r|\\\t|\\\n| ", "", X2)]
    x[, X2 := gsub("[0-9]{1,}次.*(%|-)", "", X2)]

    res <- lapply(1:nrow(x), function(ii){
        x[ii, .(X2, X3, X5, X7)]
    }) %>% rbindlist()
    colnames(res) <- c("DeptName", "buyAmount", "sellAmount", "netAmount")
    res[, className := className]
    setcolorder(res, c("className", colnames(res)[1:(ncol(res) - 1)]))
    return(res)
}
## ------------------------------------------------------------------------

fetch_lhb_data_from_eastmoney <- function(tradingDay) {
    # tradingDay <- "2018-02-27"

    url_eatmoney <- paste0("http://data.eastmoney.com/DataCenter_V3/stock2016/TradeDetail/pagesize=200,page=1,sortRule=-1,sortType=,startDate=",
                  tradingDay, ",endDate=",
                  tradingDay, ",gpfw=0,js=var%20data_tab_1.html")
    ## ------------------------------------------
    if (class(try(
                  r <- GET(url_eatmoney)
        ,silent = T)) == 'try-error') return(data.table())
    ## ------------------------------------------

    p <- content(r, 'parsed', encoding = "GB18030")
    info <- gsub('.*\"data\":(.*),\"url\".*', "\\1", p) %>% fromJSON(.)
    if (length(info) == 0) {
        print("找不到数据")
        return(data.table())
    }

    webData <- lapply(info, as.data.table) %>% rbindlist() %>%
        .[, .(SCode, SName,
              Bmoney, Smoney, JmMoney,
              Ctypedes)] %>%
        .[!duplicated(SCode)]
    cols <- c("Bmoney", "Smoney", "JmMoney")
    webData[, (cols) := lapply(.SD, as.numeric), .SDcols = cols]

    # if (F) {
    #     { "n": "序号", "w": 30 },
    #     { "n": '代码', "s": "SCode", "w": 50 },
    #     { "n": "名称", "w": 55 },
    #     { "n": "相关", "w": 60 },
    #     { "n": '解读<img class="handle-tips" title="成功率=买方营业部在近三个月内买入的个股上榜3天后的平均上涨概率；代表买方营业部过去三个月的综合情况。" src="/Stock2016/images/tip.png"/>', "w": 180 },
    #     { "n": "收盘价", "s": "ClosePrice", "w": 50 },
    #     { "n": "涨跌幅", "s": "Chgradio", "w": 50 },
    #     { "n": '龙虎榜<img class="handle-tips" title="龙虎榜净买额=龙虎榜买入额-龙虎榜卖出额；代表龙虎榜资金的净流入情况。" src="/Stock2016/images/tip.png"/></br>净买额(万)', "s": "JmMoney", "w": 65 },//, "s": "6"
    #     { "n": '龙虎榜</br>买入额(万)', "s": "Bmoney", "w": 60 },//, "s": "2"
    #     { "n": "龙虎榜</br>卖出额(万)", "s": "Smoney", "w": 60 },
    #     { "n": "龙虎榜</br>成交额(万)", "s": "ZeMoney", "w": 80 },
    #     { "n": "市场总</br>成交额(万)", "s": "Turnover", "w": 80 },
    #     { "n": '净买额占</br>总成交比', "s": "JmRate", "w": 60 },//, "s": "3"
    #     { "n": '成交额占</br>总成交比', "s": "ZeRate", "w": 60 },

    #     { "n": '换手率', "s": "Dchratio", "w": 55 },
    #     { "n": '流通</br>市值(亿)', "s": "Ltsz", "w": 55 },
    #     { "n": '上榜原因', "w": 150 }
    # }

    pb <- txtProgressBar(min = 0, max = nrow(webData), style = 1)
    cat("开始获取 东方财富 股票龙虎榜数据.\n")
    dt <- lapply(1:nrow(webData), function(j){
        # print(j)
        setTxtProgressBar(pb, j)
        url <- paste0("http://data.eastmoney.com/stock/lhb,",
                      tradingDay, ",", webData[j,SCode], ".html")
        r <- GET(url, timeout(10))
        p <- content(r, 'text')

        htmlInfo <- read_html(p, encoding = 'GB18030')
        classInfo <- html_nodes(htmlInfo, ".con-br") %>%
            html_text() %>%
            gsub(".*类型：(.*)", "\\1", .)
        if (length(classInfo) == 0) {
            classInfo <- webData[j,Ctypedes] %>%
                gsub('有价格.*日(.*)的前.*只.*', '\\1的证券', .)
        }
        tbls <- htmlInfo %>%
            html_nodes('.content-sepe table') %>%
            html_table(fill = T) %>%
            lapply(., as.data.table)
        if (length(tbls) == 0) return(data.table())

        dt <- lapply(1:length(classInfo), function(k){
            id1 <- k*2 - 1
            id2 <- k*2
            data1 <- tbls[[id1]] %>% as.data.table() %>%
                fetch_lhb_amount_from_eatmoney (., classInfo[k])
            data2 <- tbls[[id2]] %>% as.data.table() %>%
                fetch_lhb_amount_from_eatmoney (., classInfo[k])
            res <- list(data1, data2) %>% rbindlist()
        }) %>% rbindlist()

        dt[, ":="(
            SCode = webData[j, SCode],
            SName = webData[j, SName]
            )]
        cols <- c('buyAmount','sellAmount','netAmount')
        dt[, (cols) := lapply(.SD, function(x){
            as.numeric(x) * 10000
        }), .SDcols = cols]
        setcolorder(dt, c('SCode','SName','className',
                          'DeptName', 'buyAmount','sellAmount', 'netAmount'))
        Sys.sleep(.1)
        return(dt[!is.na(DeptName)])
    }) %>% rbindlist()
    cat("\n成功获取 东方财富 股票龙虎榜数据.\n")

    colnames(dt) <- c("股票代码", "股票名称", "上榜原因", "营业部名称",
                      "买入金额(元)", "卖出金额(元)", "净额(元)")
    return(dt)
}
## =============================================================================

## =============================================================================
## 更新 股票龙虎榜 数据
## 这是对其他函数的封装
## -----------------
fetch_lhb_data <- function(tradingDay) {
    ## -------------------------------------------------------------------------
    ## tradingDay 格式为 "2018-04-13"

    tempYear <- substr(tradingDay, 1, 4)
    tempPath <- paste0("/home/fl/myData/data/ChinaStocks/LHB/FromExch/", tempYear)
    if (!dir.exists(tempPath)) dir.create(tempPath, recursive = T)

    print_msg <- function(exch, msg) {
        print(
            paste0(tradingDay, " :==> ", 
                   exch, " 龙虎榜 数据",
                   msg)
            )
    }
    ## -------------------------------------------------------------------------

    ## =========================================================================
    ## -------
    ## 上交所
    ## -------
    fileSSE <- paste0(tempPath, "/", tradingDay, "_sse.txt")
    if (file.exists(fileSSE)) {
        print_msg('上交所', '已经下载')
    } else {
        dtSSE <- fetch_lhb_data_from_sse(tradingDay)
        if (length(dtSSE) > 10) {
            fwrite(as.data.table(dtSSE), fileSSE, col.names = F)
            print_msg('上交所', '下载成功')
        } else {
            print_msg('上交所', '下载失败')
        }
    }

    ## ----------------
    ## 深交所
    ## 1. 深交所主板:00
    ## 2. 深交所中小板:02
    ## 3. 深交所创业板:30
    ## ----------------
    for (mkt in c('00', '02', '30')) {

        fileSZSE <- paste0(tempPath, "/", 
                           tradingDay, 
                           "_szse_", mkt, ".txt")
        ## -------------------------------------------------------
        if (file.exists(fileSZSE)) {
            print_msg(paste('深交所', mkt), '已经下载')
        } else {
            suppFunction({
                dtSZSE <- fetch_lhb_data_from_szse(tradingDay, mkt)
            })
        
            if (length(dtSSE) > 10) {
                writeBin(content(dtSZSE, 'raw'), fileSZSE)
                print_msg(paste('深交所', mkt), '下载成功')
            } else {
                print_msg(paste('深交所', mkt), '下载失败')
            }
        }
        ## -------------------------------------------------------

    }
    ## =========================================================================


    ## =========================================================================
    dtExch <- parse_lhb_from_exch(tradingDay)
    ## =========================================================================


    ## =========================================================================
    ## 东方财富
    tempPath <- paste0("/home/fl/myData/data/ChinaStocks/LHB/FromEastmoney/", tempYear)
    if (!dir.exists(tempPath)) dir.create(tempPath, recursive = T)

    fileEastmoney <- paste0(tempPath, "/", tradingDay, ".csv")
    if (file.exists(fileEastmoney)) {
        print_msg('东方财富', '已经下载')
    } else {
        ## ---------------------------------------------------------------------
        tryNo <- 0
        while (tryNo <= 100) {
            tryNo <- tryNo + 1

            if (class(try(
                    dtEastmoney <- fetch_lhb_data_from_eastmoney(tradingDay)
                ,silent = F))[1] == 'try-error') {
                Sys.sleep(5)
                next
            }

            if (nrow(dtEastmoney) > 10) {
                fwrite(dtEastmoney, fileEastmoney)
                print_msg('东方财富', '下载成功')
                break
            } else {
                print_msg('东方财富', '下载失败')
            }

        }
        ## ---------------------------------------------------------------------
    }

    ## =========================================================================
    dtEastmoney <- fread(fileEastmoney, colClass = (股票代码 = 'character'))
    colnames(dtEastmoney) <- c('stockID','stockName','lhbName',
                               'DeptName','buyAmount','sellAmount',
                               'netAmount')
    dtEastmoney[, TradingDay := tradingDay]
    dtEastmoney[, stockName := gsub(' ', '', stockName) %>% 
                      gsub('Ａ', 'A', .) %>% 
                      gsub("Ｂ", "B", .)]
    ## =========================================================================

    ## =========================================================================
    ## 数据对比
    x <- dtExch[! stockID %in% dtEastmoney[, unique(stockID)]]

    y <- dtEastmoney[! stockID %in% dtExch[, unique(stockID)]] %>% 
        .[!grepl('B', stockName)]

    if (nrow(x) != 0 | nrow(y) != 0) {
        print("Warning! 交易所 与 东方财富 数据不一致!")
    } else {
        mysqlWrite(db = 'china_stocks_bar', tbl = 'lhb',
                   data = dtExch)
    }
    ## =========================================================================

}
## =============================================================================

