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

allStocks <- mysqlQuery(db = 'china_stocks_info',
                        query = 'select * from stocks_list') %>%
            .[order(stockID)]



