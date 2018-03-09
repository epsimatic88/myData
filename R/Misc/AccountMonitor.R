################################################################################
## AccountMonitor.R
##
## 配置账户监控
##
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2018-01-10
################################################################################

################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})

## =============================================================================
accountInfo <- data.table(accountID = c('99154275','99153449','99144979','99090279','99154381'),
                          accountName = c('杨文部','王炳晨','刘家勇','林传茂','池琼')
                          )
logPath <- "/home/fl/myData/log/AccountMonitor"

tempFile <- paste0(logPath,'/',currTradingDay[1, gsub('-', '', days)],'.txt')
if (file.exists(tempFile)) file.remove(tempFile)
sink(tempFile, append = TRUE)
## =============================================================================


## =============================================================================
dtAccount <- mysqlQuery(db = 'Broker',
                        query = 'select * from accountInfo')
dtPosition <- mysqlQuery(db = 'Broker',
                         query = 'select * from positionInfo')

for (i in 1:nrow(accountInfo)) {
  id <- accountInfo[i, accountID]
  temp <- dtAccount[accountID == id, .(BrokerID, accountName, 
                                       total, capital, leverage,
                                       profit, stock, nav)]
  if (nrow(temp) != 0) {
    cat("\n## ----------------------------------- ##\n")
    cat(paste(accountInfo[i, accountName], "账户净值统计\n"))
    print(t(temp))
    cat("## ----------------------------------- ##\n")
  }

  temp <- dtPosition[accountID == id, .(BrokerID, accountName, 
                                        stockName, stockAvailable,
                                        stockLastPrice,
                                        stockProfitPct = paste0(stockProfitPct, '%'))]
  if (nrow(temp) != 0) {
    cat("\n## ----------------------------------- ##\n")
    cat(paste(accountInfo[i, accountName], "证券持仓统计\n"))
    print(t(temp))
    cat("## ----------------------------------- ##\n")
  }

  if (i == nrow(accountInfo)) {
    cat("\n## ----------------------------------- ##\n")
    cat("## @william")
  }
}
## =============================================================================

