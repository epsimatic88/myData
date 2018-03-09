################################################################################
ROOT_PATH <- '/home/fl/myData'
DATA_PATH <- './data/oiRank/data'

setwd(ROOT_PATH)
source('./R/Rconfig/myInit.R')
library(httr)
library(rjson)
################################################################################


################################################################################
allYears <- ChinaFuturesCalendar[, unique(substr(days, 1, 4))]
sapply(allYears, function(i){
    tempDir <- paste0(DATA_PATH, '/SHFE/', i)
    if (!dir.exists(tempDir)) dir.create(tempDir, recursive = T)
})
ChinaFuturesCalendar <- ChinaFuturesCalendar[days <= format(Sys.Date(), '%Y-%m-%d')]
################################################################################
includeHistory <- FALSE
if (!includeHistory) ChinaFuturesCalendar <- ChinaFuturesCalendar[.N]

## -----------------------------------------------------------------------------
fetchSHFE <- function(tradingDay) {
    ## -------------------------------------------------------------------------
    # tradingDay <- '20180110'
    tradingDay <- gsub('-','',tradingDay)
    shfeYear <- substr(tradingDay, 1, 4)
    destFile <- paste0(DATA_PATH, '/SHFE/', shfeYear, '/', tradingDay, '.csv')
    if (file.exists(destFile)) {
        print('数据文件已经下载')
        return(fread(destFile))
    }

    if (file.exists(destFile)) next
    ## -------------------------------------------------------------------------

    tryNo <- 0

    ## =========================================================================
    while (tryNo < 10 & !file.exists(destFile)) {
        url <- paste0("http://www.shfe.com.cn/data/dailydata/kx/pm", tradingDay, ".dat")

        if (class(try(r <- GET(url))) == 'try-error') next

        page <- content(r, 'text')

        try(
            jsonFile <- fromJSON(page)
            )
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
        return(dt)
    }
    ## =========================================================================
}

tradingDay <- currTradingDay$days
dt <- fetchSHFE(tradingDay)


## =====================================================================
names(dt) <- c('合约代码','名次',
               '期货公司会员简称1','成交量','比上交易日增减1',
               '期货公司会员简称2','持买单量','比上交易日增减2',
               '期货公司会员简称3','持卖单量','比上交易日增减3')
dt <- dt[!grepl('all',合约代码)]
tbl1 <- dt[, .(InstrumentID = 合约代码, Rank = 名次, BrokerID = 期货公司会员简称1,
               ClassID = 'Turnover', Amount = 成交量, DiffAmount = 比上交易日增减1)]
tbl2 <- dt[, .(InstrumentID = 合约代码, Rank = 名次, BrokerID = 期货公司会员简称2,
               ClassID = 'longPos', Amount = 持买单量, DiffAmount = 比上交易日增减2)]
tbl3 <- dt[, .(InstrumentID = 合约代码, Rank = 名次, BrokerID = 期货公司会员简称3,
               ClassID = 'shortPos', Amount = 持卖单量, DiffAmount = 比上交易日增减3)]
dt <- list(tbl1, tbl2, tbl3) %>% rbindlist()
dt[, ":="(Amount = gsub(',', '', Amount) %>% as.numeric(),
          DiffAmount = gsub(',', '', DiffAmount) %>% as.numeric())]
dt[, TradingDay := tradingDay]
dt <- dt[, .(TradingDay, InstrumentID, Rank, BrokerID,
             ClassID, Amount, DiffAmount)]
dt <- dt[!grepl('合计', BrokerID)][!is.na(Amount)]
mysql <- mysqlFetch('china_futures_bar')
dbWriteTable(mysql, 'oiRank', dt, row.names = F, append = T)
dbDisconnect(mysql)
## =====================================================================
