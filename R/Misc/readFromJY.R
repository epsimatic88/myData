## =============================================================================
setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
## =============================================================================

dataFile <- '/home/fl/temp/【甜蜜1号期货净值】.xlsx'
dt <- readxl::read_excel(dataFile, sheet = 2) %>% as.data.table()
dt <- dt[, .(TradingDay = as.character(日期),
             Futures = 期货,
             Currency = 现金,
             Bank = 银行存款,
             Assets = 总资产,
             Shares = 基金份数,
             NAV = 0, GrowthRate = 0, Remarks = NA)]

dtAccount <- mysqlQuery(db = 'TianMi1', 
                        query = 'select * from report_account_history')
dtNav <- mysqlQuery(db = 'TianMi1',
                    query = 'select * from nav')


# temp <- dt[TradingDay < dtAccount[1,TradingDay]]
# temp <- temp[, .(vtAccountID = dtAccount[1,vtAccountID],
#                  TradingDay, datetime = '15:00:00',
#                  preBalance = 0, Balance = 0, deltaBalancePct = 0,
#                  marginPct = 0, positionProfit = 0, closeProfit = 0,
#                  availableMoney = 0, totalMoney = 0, flowMoney = temp[,Assets],
#                  allMoney = temp[,Assets], commission = 0)]
# dtAccount <- list(temp, dtAccount) %>% rbindlist()


temp <- dtAccount[TradingDay > dt[.N, TradingDay], .(
    TradingDay, Futures = totalMoney,
    Currency = dtNav[as.character(TradingDay) >= dt[.N,TradingDay]][1, Currency], 
    Bank = dt[1, Bank], 
    Assets = 0, 
    Shares = dt[1, Shares], 
    NAV = 0, GrowthRate = 0, Remarkts = NA
    )]

dtNav <- list(dt, temp) %>% rbindlist()

dtNav[, Bank := dtNav[1, Bank]]
dtNav[, ":="(Assets = Futures + Currency + Bank,
             Shares = dtNav[1, Shares])]
dtNav[, ":="(NAV = round(Assets / Shares),6)]
dtNav[, ":="(GrowthRate = round(c(0, dtNav[, diff(NAV)] / dtNav[1:(.N-1), NAV]),6)
             )]

mysql <- mysqlFetch('TianMi1')
dbSendQuery(mysql, 'truncate table nav')
dbWriteTable(mysql, 'nav', dtNav, row.names = F, append = T)
dbDisconnect(mysql)
