################################################################################
## FundReporting.R
##
## 用于 基金交易 汇报
##
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-11-14
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
ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
                              colClasses = list(character = c("nights","days")))
currTradingDay <- ChinaFuturesCalendar[days <= format(Sys.Date(), '%Y%m%d')][nights < format(Sys.Date(), '%Y%m%d')][.N]
## =============================================================================

accountInfo <- data.table(accountID = c('TianMi2','TianMi3','YunYang1',
                                        'SimNow_YY','SimNow_LXO'),
                          accountCapital = c(1300000,1000000, 2000000,
                                             1000000, 1000000),
                          accountName = c('甜蜜2号','甜蜜3号','云扬1号',
                                          'SimNow_YY', 'SimNow_LXO')
                          )
logPath <- "/home/fl/myData/log/FundReporting"

tempFile <- paste0(logPath,'/',currTradingDay[1, days],'_fund.txt')
if (file.exists(tempFile)) file.remove(tempFile)
  tempFile <- paste0(logPath,'/',currTradingDay[1, days],'.txt')
if (file.exists(tempFile)) file.remove(tempFile)


## =============================================================================
## i = 1
fetchFund <- function(i, author = FALSE) {
  mysql <- mysqlFetch(accountInfo[i,accountID], host = '192.168.1.135')

  reportAccount <- dbGetQuery(mysql,
    "select * from report_account_history
     order by TradingDay") %>%
    as.data.table()

  if (nrow(reportAccount) == 0) return(NULL)

  fee <- dbGetQuery(mysql, 'select * from fee') %>% as.data.table()

  if (nrow(fee) != 0) {
    for (j in 1:nrow(fee)) {
      tempTradingDay <- fee[j, TradingDay]
      reportAccount[TradingDay >= tempTradingDay,
            totalMoney := totalMoney + fee[TradingDay == tempTradingDay, sum(Amount)]]
    }
  }

  nav <- dbGetQuery(mysql,"select * from nav order by TradingDay") %>%
    as.data.table()

  ## ---------------------------------------------------------------------------
  if (nrow(nav) != 0) {
    if (! currTradingDay[1, as.character(ymd(days))] %in% nav[,TradingDay]) return(NULL)
    currNav <- nav[TradingDay == currTradingDay[1, ymd(days)]]
    fund <- data.table(基金名称 = accountInfo[i, accountName]
                       #,基金经理 = accountInfo[i, managerID]
                       ,期货金额 = currNav[1, Futures],
                       现货金额 = currNav[1, Currency],
                       银行存款 = currNav[1, Bank],
                       账户总额 = currNav[1, Assets],
                       今日盈亏 = ifelse(nrow(nav) > 1,
                                         nav[.N, Assets] -
                                         nav[.N-1, Assets],
                                         0),
                       收益波动 = currNav[1, paste0(as.character(GrowthRate * 100),'%')],
                       基金净值 = currNav[1, NAV]
    )
  } else {
    fundingInfo <- dbGetQuery(mysql,"select * from funding") %>%
                as.data.table()

    if (nrow(fundingInfo) == 0) {
        fundChg <- ifelse(nrow(reportAccount) > 1,
                          round((reportAccount[.N, allMoney] -
                                   reportAccount[.N-1, allMoney]) /
                                  reportAccount[.N-1, allMoney], 4),
                          0)
    } else {
        fundChg <- ifelse(nrow(reportAccount) > 1,
                          (reportAccount[.N, allMoney] / fundingInfo[, sum(shares)]) / 
                          (reportAccount[.N-1, allMoney] / 
                            fundingInfo[TradingDay < reportAccount[.N-1, TradingDay], sum(shares)]) - 1
                          0)
    }

    fund <- data.table(基金名称 = accountInfo[i, accountName]
                           #,基金经理 = accountInfo[i, managerID]
                           ,期货金额 = reportAccount[.N, totalMoney],
                           理财金额 = reportAccount[.N, flowMoney],
                           银行存款 = '--',
                           账户总额 = reportAccount[.N, allMoney],
                           今日盈亏 = ifelse(nrow(reportAccount) > 1,
                                         reportAccount[.N, allMoney] -
                                           reportAccount[.N-1, allMoney],
                                         0),
                           收益波动 = paste0(as.character(round(fundChg,4) * 100),'%'),
                           基金净值 = round(reportAccount[.N, allMoney] /
                                          accountInfo[i, accountCapital], 4)
    )
  }

  # print(t(fund))
  ## ---------------------------------------------------------------------------

  ## ---------------------------------------------------------------------------
  positionInfo <- dbGetQuery(mysql,
    "select * from positionInfo") %>% as.data.table() %>%
    .[, .(volume = .SD[, sum(volume)])
      , by = c('strategyID','InstrumentID', 'direction')] %>%
    .[order(InstrumentID)]
  # print(positionInfo)
  ## ---------------------------------------------------------------------------

  ## ---------------------------------------------------------------------------
  tradingInfo <- dbGetQuery(mysql, paste(
    "select * from tradingInfo
    where TradingDay = ", currTradingDay[1, days])) %>%
    as.data.table() %>%
    .[, TradingDay := NULL]
  # print(tradingInfo)
  ## ---------------------------------------------------------------------------


  ## ---------------------------------------------------------------------------
  failedInfo <- dbGetQuery(mysql,
    "select * from failedInfo") %>% as.data.table()
  failedInfo[offset == '平仓', direction := ifelse(direction == 'long','short','short')]
  failedInfo[, offset := NULL]
  setcolorder(failedInfo, c('TradingDay', 'strategyID', 'InstrumentID', 'direction','volume'))
  # print(positionInfo)
  ## ---------------------------------------------------------------------------

  ## ---------------------------------------------------------------------------
  ## 写入 log
  tempFile <- paste0(logPath,'/',currTradingDay[1, days],'_fund.txt')
  if (!grepl('SimNow', accountInfo[i,accountID])) {
    sink(tempFile, append = TRUE)
    cat("## ----------------------------------- ##")
    cat('\n')
    write.table(as.data.frame(t(fund)), tempFile
                , append = TRUE, col.names = FALSE
                , sep = ' :==> ')
    if (!is.na(grep('SimNow', accountInfo$accountID)[1])) {
      if (i == grep('SimNow', accountInfo$accountID)[1]-1) {
        cat("## ----------------------------------- ##\n")
        cat("\n## ----------------------------------- ##\n")
        cat("## @william")
      }
    }
  }

  ## ===========================================================================
  tempFile <- paste0(logPath,'/',currTradingDay[1, days],'.txt')
  sink(tempFile, append = TRUE)
  cat("## ----------------------------------- ##")
  cat('\n')
  cat(paste0('## >>>>>>>>> ',accountInfo[i,accountName]))
  cat('\n')
  cat("## ----------------------------------- ##")
  cat('\n')
  write.table(as.data.frame(t(fund)), tempFile
              , append = TRUE, col.names = FALSE
              , sep = ' :==> ')
  cat('\n')
  if (nrow(positionInfo) != 0) {
    # write.table("## ---------------------------------- ##", tempFile
    #             , append = TRUE, col.names = FALSE, row.names = FALSE)
    cat("## ----------------------------------- ##")
    cat("\n## 今日持仓信息 ##")
    cat('\n')
    print(positionInfo)
    cat('\n')
  }

  if (nrow(failedInfo) != 0) {
    # write.table("## ---------------------------------- ##", tempFile
    #             , append = TRUE, col.names = FALSE, row.names = FALSE)
    cat("## ----------------------------------- ##")
    cat("\n## 未平仓信息 ##")
    cat('\n')
    print(failedInfo)
    cat('\n')
  }

  ## ===========================================================================
  ## 不看交易记录
  # if (nrow(tradingInfo) != 0) {
  #   write.table("## -------------------------------------- ##", tempFile
  #               , append = TRUE, col.names = FALSE, row.names = FALSE)
  #   cat("## 今日交易记录 ##")
  #   cat('\n')
  #   print(tradingInfo)
  #   cat('\n')
  # }
  cat("## ----------------------------------- ##\n")
  ## ===========================================================================
  if (author) {
    cat("\n## ----------------------------------- ##\n")
    cat("## @william")
  }
}
## =============================================================================

for (i in 1:nrow(accountInfo)) {
  # print(i)
  if (i < nrow(accountInfo)) {
    fetchFund(i)
  } else {
    fetchFund(i, author = TRUE)
  }
}
