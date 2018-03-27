## =============================================================================
## from163_market_capital
##
## 处理股票市值
##
## Author : fl@hicloud-investment.com
## Date   : 2018-03-26
##
## =============================================================================

## =============================================================================
suppressMessages({
  source('/home/fl/myData/R/Rconfig/myInit.R')
})

dt163 <- mysqlQuery(db = 'china_stocks',
                    query = 'select TradingDay,
                                    stockID, stockName,
                                    mcap as fcap,
                                    tcap
                             from daily_from_163')
mysqlWrite(db = 'china_stocks', tbl = 'market_capital_from_163',
           data = dt163)
