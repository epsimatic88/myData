## =============================================================================
## bar.R
##
## 调整 daily bar 数据的 后复权因子
##
## Author : fl@hicloud-investment.com
## Date   : 2018-03-20
##
## =============================================================================

## =============================================================================
suppressMessages({
  source('/home/fl/myData/R/Rconfig/myInit.R')
})

## =============================================================================
allStocks <- mysqlQuery(db = 'china_stocks_info',
                        query = 'select * from stocks_list') %>%
            .[order(stockID)]
DATA_PATH_FromEastmoney <- "/home/fl/myData/data/ChinaStocks/Fundamental/FromEastmoney"
DATA_PATH_FromSina <- "/home/fl/myData/data/ChinaStocks/Fundamental/FromSina"
DATA_PATH_FromCninfo <- "/home/fl/myData/data/ChinaStocks/Fundamental/FromCninfo"
## =============================================================================


## =============================================================================
WIND_PATH <- "/home/fl/myData/data/ChinaStocks/Wind/"
dtWindBar <- paste0(WIND_PATH, "wind_bar.csv") %>% fread()
dtWindBar[, stockID := substr(stockID, 1, 6)]
dtWindBonus <- paste0(WIND_PATH, "wind_bonus.csv") %>% 
    fread() %>% 
    .[, stockID := substr(stockID, 1, 6)]
## =============================================================================


## =============================================================================
# dtSinaBar <- mysqlQuery(db = 'china_stocks',
#                       query = 'select * from daily_from_sina')
## =============================================================================

## =============================================================================
dt163Bar <- fread('/home/fl/myData/data/ChinaStocks/Bar/163_bar.csv',
                  colClasses = c(stockID = 'character')) %>% 
            .[mcap != 0]
## =============================================================================




## =============================================================================
## 利用 163 数据计算后复权因子
## ----------------------
cal_adj_factor <- function(stockID, 
                           startDate = '2015-01-01', 
                           endDate = '2016-09-12') {
    ## ----------
    id <- stockID
    ## ----------

    ## =============================================================================
    dt163 <- dt163Bar[stockID == id][TradingDay %between% 
                                     c(startDate, endDate)] %>%
        merge(.,
        ChinaStocksCalendar[days %between%
                                 c(.[1, TradingDay], .[.N, TradingDay])],
        , by.x = 'TradingDay', by.y = 'days', all = T) %>% 
        .[!is.na(stockID)]
    ## =============================================================================


    ## =============================================================================
    ## FromSina
    ## ---------
    dividendFile <- paste0(DATA_PATH_FromSina, '/', id, "/share_bonus_1.csv")
    if (file.exists(dividendFile)) {
        dividendSina <- fread(dividendFile)
        colnames(dividendSina) <- c('公告日期', '送股', '转增', '派息', '进度',
                                    '除权除息日', '股权登记日', '红股上市日', '查看详细')
        dividendSina <- dividendSina[!grepl("\\(|\\)|没有", 送股)][进度 == '实施']
        if (nrow(dividendSina) == 0) {
            dividendSina <- data.table()
        } else {

            for (k in 1:nrow(dividendSina)) {
                if (nchar(dividendSina[k, 股权登记日]) < 4 &
                    nchar(dividendSina[k, 除权除息日]) > 4 ) {
                    dividendSina[k, 股权登记日 := 
                                 ChinaStocksCalendar[days < dividendSina[k, 除权除息日]][.N, days]]
                }
            }
            dividendSina <- dividendSina[除权除息日 > startDate]

            if (nrow(dividendSina) != 0) {

                for (k in 1:nrow(dividendSina)) {
                    if (!dividendSina[k, 股权登记日] %in% dt163$TradingDay) {
                        dividendSina[k, 股权登记日 := dt163[TradingDay < dividendSina[k, 股权登记日]][.N, TradingDay]]
                    }
                }

                dividendSina[, ":="(
                    股票代码 = id,
                    转送总比例 = as.numeric(送股) + as.numeric(转增),
                    现金分红比例 = as.numeric(派息)
                    )]
                dividendSina[, ":="(
                    公告日期 = NULL,
                    送股 = NULL,
                    转增 = NULL,
                    派息 = NULL,
                    进度 = NULL,
                    红股上市日 = NULL,
                    查看详细 = NULL
                    )]
            }
        }
    } else {
        dividendSina <- data.table()
    }


    allotmentFile <- paste0(DATA_PATH_FromSina, '/', id, "/share_bonus_2.csv")
    if (file.exists(allotmentFile)) {
        allotmentSina <- fread(allotmentFile)
        colnames(allotmentSina) <- paste0("X", 1:ncol(allotmentSina))
        allotmentSina <- allotmentSina[!grepl("\\(|\\)", X2)] %>% 
            .[, .(股票代码 = id, 
                  配股比例 = as.numeric(X2),
                  配股价格 = as.numeric(X3),
                  股权登记日 = X6,
                  配股除权日 = X5)] %>% 
            .[配股除权日 > startDate]
        if (nrow(allotmentSina) != 0) {
            for (k in 1:nrow(allotmentSina)) {
                if (!allotmentSina[k, 股权登记日] %in% dt163$TradingDay) {
                    allotmentSina[k, 股权登记日 := dt163[TradingDay < allotmentSina[k, 股权登记日]][.N, TradingDay]]
                }
            }
        }
    } else {
        allotmentSina <- data.table()
    }

    reformWind <- dtWindBonus[stockID == id] %>% 
        .[exClass == '股改' | grepl('股改', exDescription)] %>%  ## 有时候万得写错行了
        .[exDay %between% c(startDate, endDate)] %>% 
        .[, .(stockID, exDay
              , shareRatio = as.numeric(gsub(".*送(.*)股", "\\1", exDescription))/10
              , cashRatio)]
    ## =============================================================================



    ## =============================================================================
    ## 所有的 bonus
    ## -----------
    if (nrow(dividendSina) != 0 & nrow(allotmentSina) != 0) {
        bonus <- merge(dividendSina, allotmentSina,
                       by.x = c('股票代码', '除权除息日'),
                       by.y = c('股票代码', '配股除权日'), all = T)
    } else if (nrow(dividendSina) != 0 & nrow(allotmentSina) == 0) {
        bonus <- dividendSina
        bonus[, ":="(配股比例 = 0,
                     配股价格 = 0,
                     配股除权日 = NA)]
    } else if (nrow(dividendSina) == 0 & nrow(allotmentSina) != 0) {
        bonus <- allotmentSina
        bonus[, ":="(除权除息日 = NA,
                     转送总比例 = 0,
                     现金分红比例 = 0)]
    } else {
        bonus <- data.table(除权除息日 = '',
                            股票代码 = id,
                            转送总比例 = 0,
                            现金分红比例 = 0,
                            配股比例 = 0,
                            配股价格 = 0)
    }

    if (nrow(reformWind) != 0) {
        bonus <- merge(bonus, reformWind, 
                  by.x = c('股票代码', '除权除息日'),
                  by.y = c('stockID', 'exDay'),
                  all = T)
    } else {
        bonus[, ":="(
                shareRatio = 0
                , cashRatio = 0
            )]
    }
    ## =============================================================================

    ## =============================================================================
    dt <- merge(dt163, bonus,
                by.x = c('stockID', 'TradingDay'),
                by.y = c('股票代码', '除权除息日'),
                all.x = T)

    cols <- c('转送总比例', '现金分红比例', '配股比例', '配股价格'
              ,'shareRatio','cashRatio')
    dt[, (cols) := lapply(.SD, function(x){
        ifelse(is.na(x), 0, as.numeric(x))
    }), .SDcols = cols]

    pb <- txtProgressBar(min = 1, max = nrow(dt), style = 1)
    cat(paste("\nStaring calculate adjust factor for stockID:", id, "\n"))
    # for (i in 2:nrow(dt)) {
    #     setTxtProgressBar(pb, i)
    #     # if (dt[i, is.na(close)]) {
    #     #     dt[i, ":="(
    #     #             open = dt[i-1, open],
    #     #             high = dt[i-1, high],
    #     #             low  = dt[i-1, low],
    #     #             close = dt[i-1, close],
    #     #             status = '停牌'
    #     #         )]
    #     # }

    #     if (dt[i, is.na(close)]) {    
    #         dt[i, ":="(
    #                 # open = dt[i-1, open],
    #                 # high = dt[i-1, high],
    #                 # low  = dt[i-1, low],
    #                 close = dt[i-1, close],
    #                 status = '停牌'
    #             )]

    #         if (!is.na(dt[i, 除权除息日])) {
    #             ## 处理停牌期间分红的股票
    #             u <- dt[i, (配股价格 * 配股比例 / 10 - 现金分红比例 / 10)]
    #             v <- dt[i, (1 + 转送总比例 / 10 + 配股比例 / 10)]

    #             dt[i, ":="(
    #                     openX = round((open + u) / v, 2),
    #                     highX = round((high + u) / v, 2),
    #                     lowX = round((low + u) / v, 2),
    #                     closeX = round((close + u) / v, 2)
    #                 )]
    #         } else {
    #             dt[i, ":="(
    #                     openX = dt[i-1, openX],
    #                     highX = dt[i-1, highX],
    #                     lowX = dt[i-1, lowX],
    #                     closeX = dt[i-1, closeX]
    #                 )]
    #         }
    #     } else {
    #         dt[i, ":="(
    #                 openX = open,
    #                 highX = high,
    #                 lowX = low,
    #                 closeX = close
    #             )]
    #     }

    #     ## =========================================================================
    #     ## 跑循环，我使用新的算法，
    #     ## 所以就先不用这个循环了，速度太慢
    #     ## -------------------------------------------------------------------------
    #     ## 单次除权出息 closeAdj
    #     # dt[i, closeAdj := round(
    #     #                          (close - 现金分红比例 / 10 + 配股价格 * 配股比例 / 10) /
    #     #                           (1 + 转送总比例 / 10 + 配股比例 / 10)
    #     #                         ,2)]

    #     # ## 复权后价格：dt[i-1, bAdj] * close
    #     # ## 除以复权前价格，
    #     # ## 得到 后复权因子
    #     # dt[i, bAdj := round(
    #     #                     dt[i-1, bAdj] * close / closeAdj
    #     #                     ,6)]
    #     ## =========================================================================

    # }
    for (i in 2:nrow(dt)) {
        setTxtProgressBar(pb, i)

        if (dt[i, is.na(close) | close == 0] &
            dt[i, (转送总比例 + 现金分红比例 + 配股比例 + 配股价格) == 0] &
            dt[i, (shareRatio + cashRatio) == 0]) {
            dt[i, close := dt[i-1, close]]
        } else if (dt[i, is.na(close) | close == 0] &
                   dt[i, (转送总比例 + 现金分红比例 + 配股比例 + 配股价格) != 0] &
                   dt[i, (shareRatio + cashRatio) == 0]) {
            ## 需要除权除息
            dt[i, close := round(
                                (dt[i-1, close] + dt[i, 配股价格 * 配股比例 /10]
                                                - dt[i, 现金分红比例 /10]) / 
                                    (1 + dt[i, 转送总比例 /10 + 配股比例 /10])
                                , 2)]
        }

        ## =====================================================================
        ## 复权处理方法
        ## 
        ## - 如果不属于股改（股权分置改革）
        ##   beta_t = (P_{t-1} + 配股价格 × 配股比例 / 10 - 现金分红数量 / 10) /
        ##            (1 + 配股比例 / 10 + 转送总比例 / 10)
        ##            
        ## - 如果是在股改期间，取得分红的
        ##   + 交易所会先处理除权除息，这里我们模拟交易所在停牌期间的除权除息
        ##   + 如果股改期间有
        ##                1. 非流通股东支付股票给流通股东
        ##                2. 非流通股东支付现金给流通股东
        ##     则需要再计算获得实际收益的比例
        ##     beta_t = (P_{t-1} - 每股支付的现金额度) /
        ##              (1 + 支付的股份数量 / (停牌期间送转的股份数量 + 10))
        ##     其中，后面的是需要考虑包含期间送转股份的稀释，不是原来公式的 10，需要多家 S+10
        ## =====================================================================

        if (dt[i, shareRatio == 0 & cashRatio == 0]) {
            ## ------------------------------------------------------
            beta <- dt[i-1, close] / 
                    (round(
                        (dt[i-1, close] + dt[i, 配股价格 * 配股比例 /10]
                                    - dt[i, 现金分红比例 /10]) / 
                        (1 + dt[i, 转送总比例 /10 + 配股比例 /10])
                           , 2))
            ## ------------------------------------------------------
            # beta <- dt[i-1, close] / 
            #         (
            #             (dt[i-1, close] + dt[i, 配股价格 * 配股比例 /10]
            #                         - dt[i, 现金分红比例 /10]) / 
            #             (1 + dt[i, 转送总比例 /10 + 配股比例 /10])
            #         )
        } else {
            ## 处理股改的股票分红问题
            tmp <- dt[1:(i-1)][(max(which(open != 0 & !is.na(open))) + 1) : .N] %>% 
                rbind(., dt[i]) %>% 
                .[!is.na(TradingDay) & !is.na(stockID)]

            u <- tmp[, sum(cashRatio)] /10
            v <- tmp[, sum(shareRatio * 10 / (10 + 转送总比例/10))]
            ## ---------------------------------
            beta <- dt[i-1, close] / 
                    (round(
                        (dt[i-1, close] - u) /
                        (1 + v)
                        , 2))
            ## ---------------------------------
            # beta <- dt[i-1, close] / 
            #         (
            #             (dt[i-1, close] - u) /
            #             (1 + v)
            #         )
        }

        dt[i, bAdj := beta]
    }

    cat('\nFinished.\n')
    dt[1, bAdj := 1]
    dt[, bAdj := round(cumprod(bAdj), 6)]

    # ## 当日除权出息价格
    # dt[, closeAdj := round(
    #     (closeX + 配股价格 * 配股比例 / 10 - 现金分红比例 / 10) /
    #     (1 + 转送总比例 / 10 + 配股比例 / 10), 2
    #     )]

    # ## 后复权因子
    # dt[, bAdj := lag(
    #     round(cumprod(closeX / closeAdj), 6)
    #     )]
    # dt[1, bAdj := 1]

    ## 前复权价格
    # dt[, closeFadj := round(close * bAdj / dt[, max(bAdj)], 2)]

    ## 后复权价格
    # dt[, closeBadj := round(close * bAdj, 2)]

    ## 显示交易状态
    ## 1. ‘交易’
    ## 2. '停牌'
    dt[, status := '交易']
    dt[open == 0 & high == 0 & low == 0, status := '交易']

    return(dt[, .(TradingDay, stockID
                  , open, high, low, close
                  , volume, turnover
                  , bAdj, status)])
}
## =============================================================================


for (id in allStocks$stockID) {

    ## =============================================================================
    dt <- cal_adj_factor(id)
    ## =============================================================================


    ## =============================================================================
    dtWind <- dtWindBar[stockID == id] %>% 
        .[TradingDay %between% c('2015-01-01', '2016-09-12')] 
    dtWind[, bAdj2 := round(bAdj / dtWind[1, bAdj], 6)]
    dtWind[, closeBadj := round(close * bAdj2, 2)]
    ## =============================================================================

    dt[, closeBadj := round(close * bAdj, 2)]
    tmp <- merge(dt, dtWind,
                 by = c('TradingDay','stockID'),
                 all = T)
    res <- tmp[abs(closeBadj.x / closeBadj.y - 1) > .002] %>% 
    .[,.(TradingDay, stockID,
         bAdj.x, closeBadj.x,
         bAdj.y, closeBadj.y, bAdj2,
         status.x, status.y)]
    # tmp[abs(bAdj.x / bAdj2 - 1) > .001] %>% 
    # .[,.(TradingDay, stockID,
    #      bAdj.x, closeBadj.x,
    #      bAdj.y, closeBadj.y, bAdj2)]

    if (nrow(res) / nrow(dt) > .1) {
        print(i)
        print(res)
        stop()
    }
}
