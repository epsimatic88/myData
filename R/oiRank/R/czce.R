################################################################################
ROOT_PATH <- '/home/fl/myData'
DATA_PATH <- './data/oiRank/data'

setwd(ROOT_PATH)
source('./R/Rconfig/myInit.R')
library(httr)
library(rjson)
################################################################################

ChinaFuturesCalendar[, nights := gsub('-', '', nights)]
ChinaFuturesCalendar[, days := gsub('-', '', days)]
ChinaFuturesCalendar <- ChinaFuturesCalendar[days <= format(Sys.Date(), '%Y%m%d')]

allYears <- ChinaFuturesCalendar[, unique(substr(days, 1, 4))]
sapply(allYears, function(i){
    tempDir <- paste0(DATA_PATH, '/CZCE/', i)
    if (!dir.exists(tempDir)) dir.create(tempDir, recursive = T)
})



## -----------------------------------------------------------------------------
for (d in 1:nrow(ChinaFuturesCalendar)) { # nrow(ChinaFuturesCalendar)
    ## -------------------------------------------------------------------------
    tradingDay <- '20180110'
    # tradingDay <- ChinaFuturesCalendar[d, days]
    czceYear <- substr(tradingDay, 1, 4)
    destFile <- paste0(DATA_PATH, '/CZCE/', czceYear, '/', tradingDay, '.csv')

    if (file.exists(destFile)) next
    ## -------------------------------------------------------------------------

    tryNo <- 0

    ## =========================================================================
    while (tryNo < 10 & !file.exists(destFile)) {
        url <- ifelse(tradingDay < '20151001',
            paste0('http://www.czce.com.cn/portal/exchange/', czceYear, "/datatradeholding/", tradingDay),
            paste0('http://www.czce.com.cn/portal/DFSStaticFiles/Future/', czceYear, "/",tradingDay, "/FutureDataHolding"))  %>% 
            paste0(., '.htm')

        r <- GET(url, add_headers("User-Agent" = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36","Accept-Encoding" = "gzip, deflate", "Accept-Language" = "zh-CN,en-US;q=0.8,zh;q=0.6,en;q=0.4,zh-TW;q=0.2"))
        page <- content(r, 'text', encoding = 'GB18030')
        print(page)

    resTable <- page %>% 
                read_html(encoding = 'GB18030') %>% 
                html_nodes('table') %>% 
                html_table(fill = T) %>%
                .[[2]] %>%
                as.data.table()
    print(resTable)

        jsonFile <- fromJSON(page)
        ## summary(jsonFile)
        #             Length Class  Mode     
        # o_cursor    759    -none- list        :查询得到的数据
        # o_code        1    -none- numeric     :查询结果状态
        # o_msg         1    -none- character   :查询信息: "成交、持仓排名查询成功"
        # report_date   1    -none- character   :交易日期
        # update_date   1    -none- character   :更新时间
        # print_date    1    -none- character   :打印时间
        rankData <- jsonFile$o_cursor

        dt <- lapply(1:length(rankData), function(i){
            as.data.table(rankData[[i]])
            }) %>% rbindlist()
        dt[, INSTRUMENTID := gsub(' ', '', INSTRUMENTID)]
        dt[nchar(PARTICIPANTABBR1) == 0 & nchar(PARTICIPANTABBR2) == 0 & nchar(PARTICIPANTABBR3) == 0, 
           ":="(PARTICIPANTABBR1 = "合计",
                PARTICIPANTABBR2 = "合计",
                PARTICIPANTABBR3 = "合计")]
        dt[, ":="(PARTICIPANTID1 = NULL, 
                  PARTICIPANTID2 = NULL, 
                  PARTICIPANTID3 = NULL,
                  PRODUCTSORTNO = NULL,
                  PRODUCTNAME = NULL)]
        names(dt) <- c('合约代码','名次',
                       '期货公司会员简称','成交量','比上交易日增减',
                       '期货公司会员简称','持买单量','比上交易日增减',
                       '期货公司会员简称','持卖单量','比上交易日增减')
        print(dt)
        if (nrow(dt) != 0) fwrite(dt, destFile)
    }
    ## =========================================================================
}
