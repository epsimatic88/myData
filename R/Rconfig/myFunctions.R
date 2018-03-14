## =============================================================================
## myFunctions.R
##
## 个人构造的函数
##
## Author   : fl@hicloud-investment.com
## Date     : 2018-01-15
## MODIFIED : 2018-03-05
## =============================================================================



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
## =============================================================================

getIpTables <- function(url) {
  if (class(try(
        r <- GET(url, timeout(10))
        )) == 'try-error') {
    ip <- data.table()
  } else {
    page <- content(r, 'text')
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
  if (class(try(r <- GET(url,timeout(10)))) != 'try-error') {
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

  ipTables_66ip_main <- lapply(1:x, function(i){
      if (i < 3) return(data.table())
      url_66ip_main <- paste0("http://www.66ip.cn/", i, ".html")

      if (class(try(
                    r <- GET(url_66ip_main, add_headers(headers_66ip_main), timeout(10))
          )) != 'try-error') {
          p <- content(r, as = 'text', encoding = 'GB18030')
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

  ipTables_181 <- lapply(1:x, function(i){
    url <- paste0("http://www.ip181.com/daili/", i, ".html")

    if (class(try(
                  r <- GET(url, add_headers(headers_181),timeout(10))
                  )) != 'try-error') {
      page <- content(r, 'text', encoding = "GB18030")
      ip <- page %>%
        read_html() %>%
        html_nodes('table') %>%
        html_table(fill = TRUE) %>%
        .[[1]] %>%
        as.data.table()
      res <- ip[, .(url = X1, port = X2)] %>%
        .[!grepl("地址", url)]
    } else {
      res <- data.table()
    }
    Sys.sleep(1)
    return(res)
  }) %>% rbindlist()
  
  ## ===========================================================================

  ## ===========================================================================
  url <- "http://lab.crossincode.com/proxy/"
  if (class(try(r <- GET(url,timeout(10)))) != 'try-error') {
    page <- content(r, 'text')
    ipTables_crossincode <- page %>%
      read_html() %>%
      html_nodes('table') %>%
      html_table(fill = T) %>%
      .[[1]] %>%
      as.data.table() %>%
      .[, .(url = Addr, port = Port)]
  } else {
    ipTables_crossincode <- data.table()
  }
  ## ===========================================================================

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
      )) == 'try-error') {
      res <- data.table()
    }
    Sys.sleep(1)
    return(res)
  }) %>% rbindlist()

  ## ===========================================================================
  url_data5u <- "http://www.data5u.com/free/index.shtml"

  if (class(try(
                r <- GET(url_data5u, add_headers(header_data5u), timeout(5))
      )) != 'try-error') {
      p <- content(r, 'text')
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
  } else {
      ipTables_data5u <- data.table()
  }
  ## ===========================================================================

  ## ===========================================================================
  url_feilongip <- "http://www.feilongip.com/"

  if (class(try(
                r <- GET(url_feilongip, add_headers(headers_feilongip), timeout(30))
      )) != 'try-error') {
      p <- content(r, 'text')
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
  } else {
      ipTables_feilongip <- data.table()
  }
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


  ipTables <- list(ipTables_xici
                   ,ipTables_kuaidaily
                   # ,ipTables_goubanjia  ## 已经失效
                   ,ipTables_crossincode
                   ,ipTables_66
                   ,ipTables_181
                   ,ipTables_ip3366
                   ,ipTables_data5u
                   ,ipTables_feilongip
                   ,ipTables_66ip_main) %>%
    rbindlist() %>%
    .[!duplicated(url)] %>%
    .[!is.na(url) | !is.na(port)] %>%
    .[, port := as.numeric(port)] %>%
    .[!is.na(url) & !is.na(port)]


  ## ===========================================================================
  cl <- makeCluster(min(detectCores()/4, 8), type = 'FORK')
  ipAvailable <- parSapply(cl, 1:nrow(ipTables), function(i){
    ip <- ipTables[i]
    if (class(try(r <- GET('http://vip.stock.finance.sina.com.cn/corp/go.php/vMS_FuQuanMarketHistory/stockid/000001.phtml',
                           query = list(year = '2018',
                                        jidu = '1'),
                           add_headers(headers),
                           use_proxy(ip[1, url], ip[1, as.numeric(port)]),
                           timeout(5))
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
