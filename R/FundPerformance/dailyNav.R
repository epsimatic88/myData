################################################################################
## 用于更新 基金的 净值
## 1. 先从网上营业厅爬虫数据
## 2. 保存到 /temp
## 3. 读取文件
## 4. 更新 nav
################################################################################

################################################################################
ROOT_PATH <- '/home/fl/myData'
setwd(ROOT_PATH)
source('./R/Rconfig/myInit.R')
################################################################################


## =============================================================================
fundID <- 'TianMi1'
brokerID <- 'citic'

mysql <- mysqlFetch(fundID)
dtNav <- dbGetQuery(mysql, 'select * from nav') %>% as.data.table() %>%
    .[TradingDay != currTradingDay[1, days]]

dtAccount <- dbGetQuery(mysql, "select * from report_account_history") %>% as.data.table() %>%
    .[TradingDay == currTradingDay[1, days]]
fee <- mysqlQuery(db = fundID,
                  query = 'select * from fee')
if (nrow(fee) != 0) {
  for (j in 1:nrow(fee)) {
    tempTradingDay <- fee[j, TradingDay]
    dtAccount[TradingDay >= tempTradingDay,
          totalMoney := totalMoney + fee[TradingDay == tempTradingDay, sum(Amount)]]
  }
}

dtCurrency <- list.files('/home/fl/temp/', pattern = ('.*Currency.csv')) %>%
    .[grepl(brokerID, .)] %>%
    paste0('/home/fl/temp/', .) %>%
    fread() %>%
    .[TradingDay == currTradingDay[1, days]]
if (nrow(dtCurrency) == 0) stop(paste0(fundID, ": ", brokerID, ": 理财数据未入库！！！"))

temp <- dtAccount[, .(TradingDay, Futures = totalMoney,
                      Currency = dtCurrency[1, 资产总值],
                      Bank = dtNav[.N, Bank],
                      Assets = totalMoney + dtCurrency[1, 资产总值] + dtNav[.N, Bank],
                      Shares = dtNav[1, Shares],
                      NAV = 0, GrowthRate = 0, Remarks = NA)]
dtNav <- list(dtNav, temp) %>% rbindlist()
dtNav[, ":="(NAV = round(Assets / Shares, 4))]
if (nrow(dtNav) == 1){
    dtNav[, GrowthRate := 0]
} else {
    dtNav[, GrowthRate := c(0, round( diff(NAV) / dtNav[1:(.N-1), NAV],4))]
}

mysql <- mysqlFetch(fundID)
dbSendQuery(mysql, 'truncate table nav')
dbWriteTable(mysql, 'nav', dtNav, row.names = F, append = T)
dbDisconnect(mysql)
## =============================================================================

