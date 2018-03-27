## =============================================================================
## fromSW_industry_index.R
##
## 获取 申万一级行业指数 数据
##
## Author : fl@hicloud-investment.com
## Date   : 2018-03-27
##
## =============================================================================

## =============================================================================
suppressMessages({
  source('/home/fl/myData/R/Rconfig/myInit.R')
})
## =============================================================================

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
url <- paste0("http://www.swsindex.com/excel2.aspx?ctable=swindexhistory&where=%20%20swindexcode%20in%20(%27801010%27,%27801020%27,%27801030%27,%27801040%27,%27801050%27,%27801060%27,%27801070%27,%27801080%27,%27801090%27,%27801100%27,%27801110%27,%27801120%27,%27801130%27,%27801140%27,%27801150%27,%27801160%27,%27801170%27,%27801180%27,%27801190%27,%27801200%27,%27801210%27,%27801220%27,%27801230%27,%27801710%27,%27801720%27,%27801730%27,%27801740%27,%27801750%27,%27801760%27,%27801770%27,%27801780%27,%27801790%27,%27801880%27,%27801890%27)%20and%20%20BargainDate%3E=%27"
    # , "2000-02-01" ## 开始日期
    ,Sys.Date() - 1
    , "%27%20and%20%20BargainDate%3C=%27"
    # ,2018-03-26    ## 结束日期
    ,Sys.Date() - 1
    , "%27")
## =============================================================================


tryNo <- 0
while(tryNo < 30) {
    tryNo <- tryNo + 1 
    if (class(try(
                  r <- GET(url, timeout(120), add_headers(headers))
        , silent = T)) != 'try-error') {
     
        if (r$status_code == '200') {
            destFile <- paste0("/home/fl/myData/data/MarketIndex/SW_industry_index/",
                               "sw1_", Sys.Date() - 1, ".xls")
            writeBin(content(r, 'raw'), destFile)
            break
        }
    }
    Sys.sleep(3)
}
