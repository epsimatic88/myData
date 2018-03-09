suppressMessages({
  source('/home/fl/myData/R/Rconfig/myInit.R')
})

for (fund in c('TianMi1','TianMi2','TianMi3','YunYang1','HanFeng')) {
  dt <- mysqlQuery(db=fund, query = 'select * from orderInfo')
  dt <- dt[,.(TradingDay, InstrumentID, status,
              frontID, sessionID = as.character(sessionID), direction,
              offset, price, totalVolume, tradedVolume)]
  colnames(dt) <- c('交易日期','期货合约','订单状态',
                    '前置编号','会话编号','方向',
                    '开平','价格','下单数量','成交数量')
  xlsx::write.xlsx(dt, paste0('/home/fl/temp/orders/', fund, '.xlsx'))
}

