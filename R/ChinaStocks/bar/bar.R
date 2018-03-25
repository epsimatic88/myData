## =============================================================================
## bar.R
##
## 调整 daily bar 数据的 后复权因子
##
## Author : fl@hicloud-investment.com
## Date   : 2018-03-20
##
## Ref：
## - 新浪股改方案汇总数据：http://biz.finance.sina.com.cn/stock/company/stk_distrall.php
## - 中国资本证券网股改方案：http://stockhq.ccstock.cn/pages/profiles/reform/000001.html
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

## ----------------------------------------------------
## Wind 的 sharaRatio 和 cashRatio 在股权分置改革期间
## 已经去掉转送顾的情况
## 也就是不需要在重新计算了
## 
## 原来的计算公示是，需要在转送增的基础上计算支付比例的，即 (10+S)
## F / (10+S)
## ----------------------------------------------------
dtWindBonus <- paste0(WIND_PATH, "wind_bonus.csv") %>% 
    fread() %>% 
    .[, stockID := substr(stockID, 1, 6)] %>%
    .[, remarks := NA]
dtWindBonus[nchar(exClass) < 2 & grepl('股改', exDescription), exClass := '股改']
dtWindBonus[nchar(exClass) < 2 & 
            (shareRatio + cashRatio + conversedRatio) != 0,
            exClass := '分红']
## 更正 Wind 数据错误的问题
## 1. 000010
##    链接：http://www.chinastock.com.cn/yhwz_about.do?methodCall=getDetailInfo&docId=3581564
##    方案：当天实行 10 送 30 的送转方案
dtWindBonus[stockID == '000010' &
            exDay == '2013-07-19', ':='(
                exClass = '股改',
                exDescription = "股改对价：每10股送30股",
                shareRatio = 3
                )]
## =============================================================================


## =============================================================================
dtSinaBar <- mysqlQuery(db = 'china_stocks',
                      query = 'select * from daily_from_sina')
dtSinaBonus <- '/home/fl/myData/data/ChinaStocks/Reform/FromSina.csv' %>% 
    fread()
setnames(dtSinaBonus, "每10股支付股数(对价)", "每10股支付对价")

for (i in 1:nrow(dtSinaBonus)) {
    if (dtSinaBonus[i, 每10股支付对价] != 0) {
        tmp <- dtWindBonus[exClass == '股改' & stockID == dtSinaBonus[i, 证券代码]]
        if (nrow(tmp) != 0) {
            for (k in 1:nrow(tmp)) {
                if (tmp[k, is.na(shareRatio) | abs(shareRatio - 0) < 0.000001 ]) {
                    print(dtSinaBonus[i])
                    print(tmp)
                    print("--------------------------------------------------------")
                    tbl <- dtWindBonus[exClass == '股改' & 
                                stockID == dtSinaBonus[i, 证券代码] &
                                exDay == tmp[k,exDay]]
                    if (nrow(tbl) != 0 &
                        grepl('送([0-9]{1,})股', tbl$exDescription)) {
                        dtWindBonus[exClass == '股改' & 
                                    stockID == dtSinaBonus[i, 证券代码] &
                                    exDay == tmp[k,exDay],
                                    ":="(
                                        exDescription = paste0(exClass, "送",
                                            dtSinaBonus[i, 每10股支付对价], "股"),
                                        shareRatio = dtSinaBonus[i, 每10股支付对价]/10,
                                        remarks = "FromSina")]
                    }
                }
                # else if (abs(dtSinaBonus[i, 每10股支付对价] - 
                #             tmp[1,shareRatio * 10]) > .000001) {
                #     print(dtSinaBonus[i])
                #     print(tmp)
                #     print("--------------------------------------------------------")
                # }
            }
        }
    }
}
## =============================================================================


## =============================================================================

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
                           startDate = '2014-01-01', 
                           endDate = '2018-03-01') {
    ## ----------
    id <- stockID
    ## ----------

    ## =========================================================================
    dt163 <- dt163Bar[stockID == id][TradingDay %between% 
                                     c(startDate, endDate)]
    if (nrow(dt163) <= 1) return(data.table())

    dt163 <- merge(dt163,
                   ChinaStocksCalendar[days %between%
                                       c(dt163[1, TradingDay], dt163[.N, TradingDay])],
        , by.x = 'TradingDay', by.y = 'days', all = T) %>% 
        .[!is.na(stockID)]
    ## =========================================================================


    ## =========================================================================
    ## FromEastmoney
    ## -------------
    dividendFile <- paste0(DATA_PATH_FromEastmoney, '/', id, "/dividend.csv")
    if (file.exists(dividendFile)) {
        dividendEastmoney <- fread(dividendFile, colClasses = c(股票代码 = 'character')) %>%
            .[!grepl('-',总股本)] %>%
            .[, .(股票代码
                  # , 股票简称
                  , 转送总比例, 现金分红比例
                  # , 送股比例, 转股比例, 总股本
                  # , 报告期, 预案公告日, 披露时间
                  # , 分配预案, 方案进度
                  ,股权登记日, 除息除权日)] %>%
            .[order(除息除权日)]
        # cols <- c("报告期","预案公告日","披露时间","股权登记日","除息除权日")
        cols <- c("股权登记日","除息除权日")
        dividendEastmoney[, (cols) := lapply(.SD, function(x){
            gsub("(.*)T.*", '\\1', x)
        }), .SDcols = cols]

        cols <- c('转送总比例', '现金分红比例')
        dividendEastmoney[, (cols) := lapply(.SD, function(x){
            ifelse(grepl('-', x), 0, x)
        }), .SDcols = cols]       
        cols <- c('转送总比例', '现金分红比例')
        dividendEastmoney[, (cols) := lapply(.SD, function(x){
            as.numeric(x)
        }), .SDcols = cols]   

        for (i in 1:nrow(dividendEastmoney)) {
            if (nchar(dividendEastmoney[i, 除息除权日]) < 4 &
                nchar(dividendEastmoney[i, 股权登记日]) > 4 ) {
                dividendEastmoney[i, 除息除权日 := ChinaStocksCalendar[days > dividendEastmoney[i, 股权登记日]][1, days]]
            }
        }

        dividendEastmoney <- dividendEastmoney[nchar(股权登记日) > 4 & 
                                               nchar(除息除权日) > 4 ] %>%
            .[股权登记日 %between% c(dt163[1, TradingDay], dt163[.N, TradingDay])]
    } else {
        dividendEastmoney <- data.table()
    }


    ## -----------------------------------------------------------------------------
    allotmentFile <- paste0(DATA_PATH_FromEastmoney, '/', id, "/allotment.csv")
    if (file.exists(allotmentFile)) {
        allotmentFile <- readLines(allotmentFile)
        sp <- grep(paste0(".*", id, ".*", "配股详细资料.*"), allotmentFile) %>%
            c(., length(allotmentFile))
        allotmentEastmoney <- lapply(2:length(sp), function(kk){
            tmp <- allotmentFile[sp[kk-1] : (sp[kk] - 1)]
            info <- grep('配股比例', tmp, value = T) %>%
                gsub("\"", '', .) %>%
                strsplit(., ' ') %>%
                unlist()
            allotmentRatio <- info[2]
            allotmentPrice <- info[4]

            info <- grep('股权登记日', tmp, value = T) %>%
                gsub("\"", '', .) %>%
                strsplit(., ' ') %>%
                unlist()
            allotmentStart <- info[2]

            info <- grep('除权基准日', tmp, value = T) %>%
                gsub("\"", '', .) %>%
                strsplit(., ' ') %>%
                unlist()
            allotmentEnd <- info[2]

            res <- data.table(配股比例 = as.numeric(allotmentRatio),
                              配股价格 = as.numeric(allotmentPrice),
                              股权登记日 = allotmentStart,
                              配股除权日 = allotmentEnd)
        }) %>% rbindlist() %>%
            .[, 股票代码 := id]
    } else {
        allotmentEastmoney <- data.table()
    }
    ## =========================================================================



    ## =========================================================================
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
            ## 
            for (k in 1:nrow(dividendSina)) {
                if (nchar(dividendSina[k, 除权除息日]) < 4) {
                    if (nchar(dividendSina[k, 股权登记日]) > 4) {
                        dividendSina[k,  除权除息日 := 
                                 ChinaStocksCalendar[days > dividendSina[k, 股权登记日]][1, days]]
                    } else {
                        dividendSina[k,  除权除息日 := 
                                 ChinaStocksCalendar[days > dividendSina[k, 股权登记日]][1, days]] 
                    }
                }
            }
            ##
            dividendSina <- dividendSina[除权除息日 > startDate]

            if (nrow(dividendSina) != 0) {
                ## -------------------------------------------------------------
                for (k in 1:nrow(dividendSina)) {
                    if (!dividendSina[k, 除权除息日] %in% dt163$TradingDay) {
                        dividendSina[k, 除权除息日 := dt163[TradingDay > dividendSina[k, 股权登记日]][1, TradingDay]]
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

                if (nrow(dividendEastmoney) != 0) {
                    for (k in 1:nrow(dividendSina)) {
                        # print(k)
                        tmp <- dividendEastmoney[除息除权日 == dividendSina[k, 除权除息日]]
                        ## ---------------------------------------------------------
                        if (nrow(tmp) != 0) {
                            if ((dividendSina[k, round(转送总比例 + 0.000001, 3)] 
                                 != tmp[1, round(转送总比例 + 0.000001, 3)]) |
                                (dividendSina[k, round(现金分红比例 + 0.000001, 3)] 
                                    != tmp[1, round(现金分红比例 + 0.000001, 3)])) {
                                    msg <- paste(id, " dividend :==> 新浪数据与东方财富数据不一致")
                                    cat('\ndividendEastmoney:\n')
                                    print(dividendEastmoney[order(除息除权日)])

                                    cat('\ndividendSina:\n')
                                    print(dividendSina[order(除权除息日)])

                                    ## =================================================
                                    ## 新浪在统计 600317 历史分红的时候出现错误
                                    ## 需要改正
                                    if (id %in% c('600317')) {
                                        dividendSina[k, 现金分红比例 := tmp[1, 现金分红比例]]
                                    } else {
                                        stop(msg)
                                    }
                                    ## =================================================
                                }
                        }
                        ## ---------------------------------------------------------
                    }  
                }
                ## -------------------------------------------------------------
            }
        }
    } else {
        dividendSina <- data.table()
    }
    
    allotmentFile <- paste0(DATA_PATH_FromSina, '/', id, "/share_bonus_2.csv")
    if (file.exists(allotmentFile)) {
        allotmentSina <- fread(allotmentFile)
        colnames(allotmentSina) <- paste0("X", 1:ncol(allotmentSina))
        if (any(grepl('没有数据', allotmentSina$X1))) {
            allotmentSina <- data.table()
        } else {
            allotmentSina <- allotmentSina[!grepl("\\(|\\)", X2)] %>% 
                .[, .(股票代码 = id, 
                      配股比例 = as.numeric(X2),
                      配股价格 = as.numeric(X3),
                      股权登记日 = X6,
                      配股除权日 = X5)] %>% 
                .[配股除权日 > startDate]
            ## -----------------------------------------------------------------
            if (nrow(allotmentSina) != 0) {
                for (k in 1:nrow(allotmentSina)) {
                    if (!allotmentSina[k, 股权登记日] %in% dt163$TradingDay) {
                        allotmentSina[k, 股权登记日 := dt163[TradingDay < allotmentSina[k, 股权登记日]][.N, TradingDay]]
                    }
                }
            }
            ## -----------------------------------------------------------------
        }

    } else {
        allotmentSina <- data.table()
    }
    ## =========================================================================


    ## =========================================================================
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

    ## =========================================================================
    reformWind <- dtWindBonus[stockID == id] %>% 
        .[exClass == '股改' | grepl('股改', exDescription)] %>%  ## 有时候万得写错行了
        .[exDay %between% c(startDate, endDate)] %>% 
        .[, .(stockID, exDay
              , shareRatio = as.numeric(gsub(".*送([0-9]{1,})股", "\\1", exDescription))/10
              , cashRatio)]

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
    ## =========================================================================

    ## =========================================================================
    dt <- merge(dt163, bonus,
                by.x = c('stockID', 'TradingDay'),
                by.y = c('股票代码', '除权除息日'),
                all.x = T)

    cols <- c('转送总比例', '现金分红比例', '配股比例', '配股价格'
              ,'shareRatio','cashRatio')
    dt[, (cols) := lapply(.SD, function(x){
        ifelse(is.na(x), 0, as.numeric(x))
    }), .SDcols = cols]

    if (dt[1, close == 0]) {
        dt[1, close := preClose]
    }

    pb <- txtProgressBar(min = 0, max = nrow(dt), style = 1)
    cat(paste("\nStarting calculate adjust factor for stockID:", id, "\n"))

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
            if (dt[i, open != 0 & high != 0 & low != 0] |
                dt[i, open == 0 & high == 0 & low == 0 & 
                      (is.na(preClose) | preClose == 0)]) {
                ## 如果是正常的交易,
                ## 进行除权除息处理
                dt[i, close := round(
                                    (dt[i-1, close] + dt[i, 配股价格 * 配股比例 /10]
                                                    - dt[i, 现金分红比例 /10]) / 
                                        (1 + dt[i, 转送总比例 /10 + 配股比例 /10])
                                    , 2)]  
            } else if (dt[i, !is.na(preClose) & preClose != 0]) {
                ## 如果是停牌的情况,
                ## 则直接使用　PreClose
                if (dt[i, (转送总比例 + 现金分红比例 + 配股比例) == 0]) {
                    dt[i, close := preClose]
                } else {
                    tmpPreClose <- dt[i, round((dt[i-1,preClose] - 现金分红比例 /10) / 
                                          (1 + 转送总比例 /10),2) ]
                    if (dt[i, preClose < dt[i-1, close]]) {
                        dt[i, close := preClose]
                    } else {
                        dt[i, close := tmpPreClose]
                    }
                }
            }
            ##
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
        ##
        ## ----------------------------------------------------
        ## Wind 的 sharaRatio 和 cashRatio 在股权分置改革期间
        ## 已经去掉转送顾的情况
        ## 也就是不需要在重新计算了
        ## 
        ## 原来的计算公示是，需要在转送增的基础上计算支付比例的，即 (10+S)
        ## F / (10+S)
        ## ----------------------------------------------------
        ## =====================================================================

        if (dt[i, shareRatio == 0 & cashRatio == 0]) {
            ## ------------------------------------------------------
            if (dt[i, open != 0 & high != 0 & low != 0] |
                dt[i, open == 0 & high == 0 & low == 0 & 
                      (is.na(preClose) | preClose == 0)]) {
                beta <- dt[i-1, close] / 
                        (round(
                            (dt[i-1, close] + dt[i, 配股价格 * 配股比例 /10]
                                        - dt[i, 现金分红比例 /10]) / 
                            (1 + dt[i, 转送总比例 /10 + 配股比例 /10]) + 0.000001
                               , 2))
                ## ------------------------------------------------------
                # beta <- dt[i-1, close] / 
                #         (
                #             (dt[i-1, close] + dt[i, 配股价格 * 配股比例 /10]
                #                         - dt[i, 现金分红比例 /10]) / 
                #             (1 + dt[i, 转送总比例 /10 + 配股比例 /10])
                #         )
            } else if (dt[i, !is.na(preClose) & preClose != 0]) {
                beta <- dt[i-1, close] / dt[i, close]
            }
            ## --------------------------------------------------------
        } else {
            ## 处理股改的股票分红问题
            tmp <- dt[1:(i-1)][(max(which(open != 0 & !is.na(open))) + 1) : .N] %>% 
                rbind(., dt[i]) %>% 
                .[!is.na(TradingDay) & !is.na(stockID)]
            
            ## -------------------------------------------------
            ## Wind 的　sharｅRatio 已经在 转送增 的基础上处理过了
            # v <- tmp[, sum(shareRatio * 10 / (10 + 转送总比例))]
            ## -------------------------------------------------
            
            if (all(is.na(tmp$remarks))) {
                u <- tmp[, sum(cashRatio)]
                v <- tmp[, sum(shareRatio)]
            } else {
                u <- tmp[, sum(cashRatio)]
                v <- tmp[, sum(shareRatio * 10 / (10 + 转送总比例))]
            }
            
            if (tmp[.N, (转送总比例 + 现金分红比例 + 配股比例 + 配股价格) == 0]) {
                ## 已经在停牌期间除权除息了
                ## ---------------------------------
                beta <- dt[i-1, close] / 
                        (round(
                            (dt[i-1, close] - u) /
                            (1 + v)  + 0.000001
                            , 2))
                ## ---------------------------------
                # beta <- dt[i-1, close] / 
                #         (
                #             (dt[i-1, close] - u) /
                #             (1 + v)
                #         )
            } else {
                ## 上一个交易日是正常交易，没有停牌的
                ## 先除权除息
                closeX <- (dt[i-1, close] + dt[i, 配股价格 * 配股比例 /10]
                              - dt[i, 现金分红比例 /10]) / 
                          (1 + dt[i, 转送总比例 /10 + 配股比例 /10])
                ## 再计算支付后的价格
                closeX <- round(
                                (closeX - u) / (1 + v) + 0.000001
                                ,2)
                beta <- dt[i-1, close] / closeX
            }
        }

        dt[i, bAdj := round(beta, 6)]
    }

    cat('\nFinished.\n\n')
    dt[1, bAdj := 1]
    dt[, bAdj := round(cumprod(bAdj), 6)]

    ## 前复权价格
    # dt[, closeFadj := round(close * bAdj / dt[, max(bAdj)], 2)]

    ## 后复权价格
    # dt[, closeBadj := round(close * bAdj, 2)]

    ## 显示交易状态
    ## 1. ‘交易’
    ## 2. '停牌'
    dt[, status := '交易']
    dt[open == 0 & high == 0 & low == 0, ":="(
        open = close,
        high = close,
        low = close
        ,status = '停牌'
        )]

    return(dt[, .(TradingDay, stockID
                  , open, high, low, close
                  , volume, turnover
                  , bAdj, status)])
}
## =============================================================================

unStockID <- c("000520"   ## 当天的分红万得没有计算
               , "000536" ## 计算转增的时候有不一样的
               , "002132" ## 细微差别
               , "002506" ## 计算转增的时候有不一样的
               , "002634" ## 细微差别
               , "002682" ## 细微差别
               )

for (id in allStocks$stockID) {
    # if (id %in% max(unStockID)) next
    if (id < max(unStockID)) next

    ## =========================================================================
    dt <- cal_adj_factor(id)
    if (nrow(dt) <= 1) next
    
    dt <- dt[TradingDay %between% c('2014-01-01', '2016-09-12')]
    if (nrow(dt) <= 1) next
    dt[, closeBadj := round(close * bAdj, 2)]
    ## =========================================================================


    ## =========================================================================
    dtWind <- dtWindBar[stockID == id] %>% 
        .[TradingDay %between% c(dt[,min(TradingDay)], dt[,max(TradingDay)])] 
    dtWind[, bAdj2 := round(bAdj / dtWind[1, bAdj], 6)]
    dtWind[, closeBadj := round(close * bAdj2, 2)]
    ## =========================================================================

    tmp <- merge(dt, dtWind,
                 by = c('TradingDay','stockID'),
                 all = T)
    res <- tmp[abs(closeBadj.x / closeBadj.y - 1) > .005] %>% 
    .[,.(TradingDay, stockID,
         bAdj.x, closeBadj.x,
         bAdj.y, closeBadj.y, bAdj2,
         status.x, status.y)]

    if (! id %in% unStockID) {
        if (nrow(res) / nrow(dt) > .1) {
            print(id)
            print(res)
            stop()
        }
    }
}
