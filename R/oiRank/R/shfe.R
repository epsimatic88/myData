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
    tempDir <- paste0(DATA_PATH, '/SHFE/', i)
    if (!dir.exists(tempDir)) dir.create(tempDir, recursive = T)
})



## -----------------------------------------------------------------------------
for (d in 1:nrow(ChinaFuturesCalendar)) { # nrow(ChinaFuturesCalendar)
    ## -------------------------------------------------------------------------
    # tradingDay <- '20180110'
    tradingDay <- ChinaFuturesCalendar[d, gsub('-', '', days)]
    shfeYear <- substr(tradingDay, 1, 4)
    destFile <- paste0(DATA_PATH, '/SHFE/', shfeYear, '/', tradingDay, '.csv')

    if (file.exists(destFile)) next
    ## -------------------------------------------------------------------------

    tryNo <- 0

    ## =========================================================================
    while (tryNo < 10 & !file.exists(destFile)) {
        url <- paste0("http://www.shfe.com.cn/data/dailydata/kx/pm", tradingDay, ".dat")

        if (class(try(r <- GET(url))) == 'try-error') next

        page <- content(r, 'text')

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
