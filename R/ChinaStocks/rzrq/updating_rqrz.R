## =============================================================================
## updating_rzrq.R
## 每日更新 股票融资融券 数据
## 
## AUTHOR   : fl@hicloud-investment.com
## DATE     : 2018-04-12
## =============================================================================

suppressMessages({
    suppressMessages({
        source("/home/fl/myData/R/Rconfig/myInit.R")
    })
})

## ----------------------------------
## 18:00 更新数据
tradingDay <- lastTradingDay[1, days]
## ----------------------------------

## =======================
fetch_rzrq_data(tradingDay)
## =======================
