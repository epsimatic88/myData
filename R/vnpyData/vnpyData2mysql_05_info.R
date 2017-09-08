################################################################################
##! vnpyData2mysql_05_info.R
## 这是主函数:
## 用于录入 vnpyData 的数据到 MySQL 数据库
##
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-08-24
################################################################################

################################################################################
## 读取合约信息
################################################################################

dataPathInfo <- dataPath  %>% 
    gsub('TickData$', 'ContractInfo', .)
allDataFilesInfo <- list.files(dataPathInfo, pattern = '\\.csv')

dtInfo <- grep(futuresCalendar[k,days], allDataFilesInfo, value = T) %>%
    paste(dataPathInfo, ., sep = '/') %>% 
    fread() %>% 
    .[, ":="(
      vtSymbol = NULL,
      gatewayName = NULL,
      TradingDay = logTradingDay)]

colnames(dtInfo) <- c('InstrumentID','InstrumentName','ProductClass','ExchangeID',
                      'PriceTick','VolumeMultiple','ShortMarginRatio','LongMarginRatio',
                      'OptionType','Underlying','StrikePrice','TradingDay')
setcolorder(dtInfo, c('TradingDay',colnames(dtInfo)[1:(ncol(dtInfo)-1)]))

## =============================================================================
mysql <- mysqlFetch('vnpy')
dbSendQuery(mysql,paste0("DELETE FROM info
            WHERE TradingDay = ", logTradingDay))
dbWriteTable(mysql,"info",
             dtInfo, row.name　=　FALSE, append = T)
## =============================================================================
