suppressMessages({
  source('/home/fl/myData/R/Rconfig/myInit.R')
})

## 成交情况统计
dt <- mysqlQuery(db='Broker', query = 'select * from orderInfo')

dt[orderStatus != '已撤', .(total = sum(tradedVolume),
                            orderStatus = '成交')
   , by = accountName]


## 净值统计
dt <- mysqlQuery(db='Broker', query = 'select * from accountInfo')
nav <- dt[,.(TradingDay, accountName,
             total = prettyNum(total, big.mark = ','),
             capital = prettyNum(capital, big.mark = ','),
             leverage = prettyNum(leverage, big.mark = ','),
             profit = prettyNum(profit, big.mark = ','), nav)]
colnames(nav) <- c('日期','账户','总资产','初始资金','夹层资金','盈利','净值')
print(nav)



