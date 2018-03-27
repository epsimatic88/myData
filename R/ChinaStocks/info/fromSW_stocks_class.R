## =============================================================================
## fromSW_stocks_class.R
## 
## 从 申万宏远 网站下载股票行业分类
## http://www.swsindex.com/IdxMain.aspx
## 
## Author : fl@hicloud-investment.com
## Date   : 2018-01-15
## =============================================================================

## =============================================================================
suppressMessages({
  source('/home/fl/myData/R/Rconfig/myInit.R')
})
## =============================================================================

if (format(Sys.Date(), '%Y-%m-%d') != currTradingDay[1, days]) stop('Not TradignDay !!!')

## =============================================================================
headers <- c(
            "Accept"          = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
            "Accept-Encoding" = "gzip, deflate",
            "Accept-Language" = "zh-CN,en-US;q=0.8,zh;q=0.6,en;q=0.4,zh-TW;q=0.2",
            "Connection"      = "keep-alive",
            "DNT"             = "1",
            "Host"            = "www.swsindex.com",
            "Referer"         = "http://www.swsindex.com/idx0560.aspx?columnid=8905",
            "User-Agent"      = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
            )
## =============================================================================

## =============================================================================
## 申万行业分类
url <- "http://www.swsindex.com/downloadfiles.aspx"
payload <- list(
  swindexcode= "SwClass",
  type       = "530",
  columnid   = "8892")

tryNo <- 0
while(tryNo < 100) {
    tryNo <- tryNo + 1 
    if (class(try(
                  r <- GET(url, add_headers(headers), 
                          query = payload, timeout(5))
        , silent = T)) != 'try-error') {
     
        if (r$status_code == '200') {
          destFile <- paste0("/home/fl/myData/data/ChinaStocks/info/sw_class_",
                             currTradingDay[1, days], ".xls")
          writeBin(content(r, 'raw'), destFile)
          break
        }
    }
    Sys.sleep(3)
}

l <- readLines(file(destFile, encoding = 'GB18030'))

dt <- lapply(2:(length(l) - 1), function(i){
    tmp <- strsplit(l[i], 'td><td') %>% 
        unlist() %>% 
        gsub("tr.*td|\"|.*@|>|</", '', .) %>% 
        .[!grepl('td|tr', .)]
    res <- data.table(stockID = tmp[2],
                      stockName = tmp[3],
                      industryName = tmp[1],
                      startDate = unlist(strsplit(tmp[4], ' '))[1])
    return(res)
}) %>% rbindlist()
dt[, startDate := ymd(startDate)]
dt[, TradingDay := currTradingDay[1, days]]
dt[, ":="(industryLevel = '1',
          industryID = NA,
          endDate = NA)]

mysqlWrite(db = 'china_stocks', tbl = 'industry_class_from_SW',
           data = dt)
