################################################################################
## 每日持仓盈亏分析
##
## Author: William
## Date  : 2017-09-10
################################################################################

rm(list = ls())

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
options(width = 150)

accountAll <- c('TianMi1', 'TianMi2', 'TianMi3', 'YunYang1', 'HanFeng')
## =============================================================================


ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv")

## 计算交易日历
if (as.numeric(format(Sys.time(),'%H')) < 20) {
    currTradingDay <- ChinaFuturesCalendar[days <= format(Sys.Date(),'%Y%m%d')][.N]
} else {
    currTradingDay <- ChinaFuturesCalendar[nights <= format(Sys.Date(),'%Y%m%d')][.N]
}
lastTradingday <- ChinaFuturesCalendar[days < currTradingDay[.N, days]][.N]
## =============================================================================



## =============================================================================
# tradingDay <- '20170914'
tradingDay <- currTradingDay[,days]
logFile <- paste0('./log/PnL/',tradingDay,'.txt')
sink(logFile, append = FALSE)
## =============================================================================


mysql <- mysqlFetch('dev', host = '192.168.1.166')
ChinaFuturesCalendar <- dbGetQuery(mysql, "
        select * from ChinaFuturesCalendar
    ") %>% as.data.table() %>%
    .[, ":="(nights = gsub('-','',nights),
             days   = gsub('-','',days))]

## =============================================================================
## 获取 bar 数据
## -----------------------------------------------------------------------------
mysql <- mysqlFetch('china_futures_bar', host = '192.168.1.166')
dtDaily <- dbGetQuery(mysql, paste("
        select TradingDay,InstrumentID,
               OpenPrice
               # ,HighPrice
               # ,LowPrice
               ,ClosePrice
        from daily
        where TradingDay = ", tradingDay,
        "and sector = 'allday'")) %>% as.data.table()

dtDailyYd <- dbGetQuery(mysql, paste("
        select TradingDay,InstrumentID,
               OpenPrice as preOpen
               # ,HighPrice
               # ,LowPrice
               ,ClosePrice as preClose
        from daily
        where TradingDay = ", ChinaFuturesCalendar[days < tradingDay][.N, days],
        "and sector = 'allday'")) %>% as.data.table()


mysql <- mysqlFetch('china_futures_info', host = '192.168.1.166')
dtMultiple <- dbGetQuery(mysql, paste("
        select TradingDay,InstrumentID,VolumeMultiple
        from VolumeMultiple
        where TradingDay = ", tradingDay)) %>%
        as.data.table()
## =============================================================================


################################################################################

calPnL <- function(accountID) {
    ## =============================================================================
    ## dtOrder
    ## -----------------------------------------------------------------------------
    cat("## ----------------------------------- ##\n")
    cat(paste0('## ',accountID, '\n'))
    # cat('## ----------- 当日盈亏分析 ------------ ##\n')
    mysql <- mysqlFetch(accountID, host = '192.168.1.166')
    # dbSendQuery(mysql, "SET NAMES utf8")
    dtOrder <- dbGetQuery(mysql, paste("
            select * from tradingInfo
            where TradingDay = ", tradingDay
        )) %>% as.data.table()

    dt <- merge(dtOrder, dtDaily, by = c('TradingDay','InstrumentID'), all.x = TRUE) %>%
            merge(., dtMultiple, by = c('TradingDay','InstrumentID'), all.x = TRUE) %>%
            .[abs(price) == 1, price := OpenPrice] %>%
            .[offset != '开仓', offset := '平仓'] %>%
            .[order(tradeTime)]
    ## =============================================================================


    ## =============================================================================
    ## dtYY
    ## YYStrategy 策略盈亏分析
    ## -----------------------------------------------------------------------------
    dtYY <- dt[strategyID == 'YYStrategy']

    temp <- dtYY[, .(volume = .SD[,sum(volume)],
                     vwap = .SD[, sum(volume * price) / sum(volume)],
                     VolumeMultiple = .SD[,unique(VolumeMultiple)],
                     open = .SD[,unique(OpenPrice)],
                     close = .SD[,unique(ClosePrice)])
                 , by = c('InstrumentID','direction','offset')] %>%
            merge(., dtDailyYd, by = c('InstrumentID'), all.x = TRUE)
    temp[, pnl := 0]

    for (i in 1:nrow(temp)) {
        tempPnl <- ifelse(temp[i,offset == '开仓'], temp[i,close - vwap],
                          temp[i,vwap - preClose])
        tempDirection <- ifelse(temp[i, (offset == '开仓' & direction == 'long') |
                                        (offset == '平仓' & direction == 'short')],
                                1, -1)
        temp$pnl[i] <- tempPnl * tempDirection * temp[i,volume] * temp[i, VolumeMultiple]
    }

    pnlTrading <- temp[, .(InstrumentID,pnl)]

    mysql <- mysqlFetch(accountID, host = '192.168.1.166')
    dtYYPos <- dbGetQuery(mysql,"
            select * from positionInfo
            where strategyID = 'YYStrategy'
        ") %>% as.data.table() %>%
        .[gsub('-','',TradingDay) != tradingDay] %>%
        .[order(TradingDay)] %>%
        .[, .(volume = .SD[,sum(volume)])
          , by = c('InstrumentID','direction')]

    temp <- merge(dtYYPos, dtDaily, by = c('InstrumentID'), all.x = TRUE) %>%
             merge(., dtDailyYd, by = c('InstrumentID'), all.x = TRUE) %>%
             merge(., dtMultiple, by = c('InstrumentID'))

    temp[, pnl := 0]
    for (i in 1:nrow(temp)) {
        tempPnl <- temp[i, ClosePrice - preClose]
        tempDirection <- ifelse(temp[i, direction == 'long'], 1, -1)
        temp$pnl[i] <- tempPnl * tempDirection * temp[i,volume] * temp[i, VolumeMultiple]
    }

    pnlPos <- temp[, .(InstrumentID,pnl)]

    if (nrow(pnlTrading) != 0) {
        cat("## ----------------------------------- ##\n")
        cat(paste0('## ','YYStrategy 当日交易的盈亏\n'))
        print(pnlTrading)
        cat("## ----------------------------------- ##\n")
    }

    if (nrow(pnlPos) != 0) {
        cat(paste0('## ','YYStrategy 当日持仓的盈亏\n'))
        print(pnlPos)
    }

    pnlAll <- rbind(pnlTrading, pnlPos) %>%
            .[, .(pnl = .SD[,sum(pnl)]), by = c('InstrumentID')]
    if (nrow(pnlAll) != 0) {
        cat("## ----------------------------------- ##\n")
        cat(paste0('## ','YYStrategy 策略的盈亏\n'))
        print(pnlAll[order(InstrumentID)])
        print(pnlAll[, sum(pnl)])
    }


    ## =============================================================================


    ## =============================================================================
    ## dtOI
    ## OIStrategy 策略盈亏分析
    ## -----------------------------------------------------------------------------
    dtOI <- dt[strategyID == 'OIStrategy']

    temp <- dtOI[, .(volume = .SD[,sum(volume)],
                     vwap = .SD[, sum(volume * price) / sum(volume)],
                     VolumeMultiple = .SD[,unique(VolumeMultiple)])
                 , by = c('InstrumentID','direction','offset')]

    pnlOI <- temp[, .(pnl = (.SD[offset == '平仓', vwap] - .SD[offset == '开仓', vwap]) *
                    .SD[,max(unique(volume))] *.SD[,unique(VolumeMultiple)] *
                    ifelse(.SD[offset == '开仓', direction == 'long'], 1, -1)
                ), by = 'InstrumentID']
    if (nrow(pnlOI) != 0) {
        cat("## ----------------------------------- ##\n")
        cat(paste0('## ','OIStrategy 策略的盈亏\n'))
        print(pnlOI[order(InstrumentID)])
        print(pnlOI[, sum(pnl)])
    }

    ## =============================================================================

    res <- rbind(pnlAll[, strategyID := 'YYStrategy'], pnlOI[, strategyID := 'OIStrategy']) %>%
        .[, TradingDay := tradingDay]
    # print('## --------------------------------------')
    # print(paste0('## ','账面 总共的盈亏'))
    # print(res[, sum(pnl)])


    mysql <- mysqlFetch(accountID, host = '192.168.1.166')
    dtCommission <- dbGetQuery(mysql, paste("
            select * from report_account_history
            where TradingDay = ", paste0("'",currTradingDay[, as.Date(as.character(days), "%Y%m%d")],"'")
        )) %>% as.data.table()
    # print('## --------------------------------------')
    # print(paste0('## ','账户 手续费为'))
    # print(dtCommission[,commission])

    # print('## --------------------------------------')
    # print(paste0('## ','账户 净盈亏'))
    # print(res[, sum(pnl)] - dtCommission[,commission])

    net <- data.table(总盈亏 = res[, round(sum(pnl),2)],
                      手续费 = dtCommission[,round(commission,2)],
                      净盈亏 = round(res[, sum(pnl)] - dtCommission[,commission],2)
                      )
    cat("## ----------------------------------- ##\n")
    cat(paste0('## ','账户统计\n'))
    print(net)
    # write.table(as.data.frame(t(net)), logFile
    #             , append = TRUE, col.names = FALSE
    #             , sep = ' :==> ')

    dbSendQuery(mysql, paste("
        delete from pnl where TradingDay = ", tradingDay))
    dbWriteTable(mysql, 'pnl',
        res, row.name = F, append = T)
################################################################################
dbDisconnect(mysql)
for(conn in dbListConnections(MySQL()) )
  dbDisconnect(conn)
cat("## ----------------------------------- ##\n\n\n")
################################################################################
}

for (accountID in accountAll) {
    calPnL(accountID)
}

