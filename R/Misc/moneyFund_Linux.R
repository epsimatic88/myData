rm(list = ls())

library(data.table)
library(magrittr)
library(RMySQL)
library(rvest)
library(r2excel)
library(ggplot2)
options(width = 150, digits = 10, scipen = 10)

accountInfo <- data.table(accountID = c('TianMi1', 'YunYang1'),
                          accountName = c('甜蜜１号','云扬１号'))

################################################################################
MySQL(max.con = 300)
for( conns in dbListConnections(MySQL()) ){
  dbDisconnect(conns)
}

################################################################################
mysql_user <- 'fl'
mysql_pwd  <- 'abc@123'
mysql_host <- "192.168.1.166"
mysql_port <- 3306

#---------------------------------------------------
# mysqlFetch
# 函数，主要输入为
# database
#---------------------------------------------------
mysqlFetch <- function(x){
  temp <- dbConnect(MySQL(),
                    dbname   = as.character(x),
                    user     = mysql_user,
                    password = mysql_pwd,
                    host     = mysql_host,
                    port     = mysql_port
  )
}
################################################################################


## =============================================================================
if (FALSE) {
  navTable <- readxl::read_excel(paste0('C:/Users/Administrator/Desktop','/',
                                        '云扬1号净值.xlsx'), sheet = 2) %>%
    as.data.table() %>%
    .[2:.N]
  colnames(navTable) <- paste0("X", 1:ncol(navTable))
  navTable[, ":="(X7 = NULL, X9 = NULL, X10 =NULL)]
  colnames(navTable) <- c('TradingDay',
                          'Futures',
                          'Currency',
                          'Bank',
                          'Assets',
                          'Shares',
                          'NAV')
  navTable[, TradingDay := as.Date(as.numeric(TradingDay), origin = '1899-12-30')]
  cols <- c('Futures', 'Currency', 'Bank', 'Assets', 'Shares', 'NAV')
  navTable[, (cols) := lapply(.SD, function(x){
    res <- ifelse(is.na(x), 0,as.numeric(x))
  }), .SDcols = cols]
  navTable[, ":="(Assets = Futures+Currency+Bank,
                  NAV = (Futures+Currency+Bank) / Shares)]
  navTable[, ":="(GrowthRate = round(c(0,navTable[,diff(NAV)] / navTable[1:(.N-1), NAV]),4))]

  # mysql <- mysqlFetch('HiCloud')
  mysql <- mysqlFetch('YunYang1')
  dbSendQuery(mysql, 'truncate table nav')
  dbWriteTable(mysql, 'nav', navTable, row.names = F, append = T)
}
## =============================================================================


#
#
# ## =============================================================================
# # mysql <- mysqlFetch('HiCloud')
# mysql <- mysqlFetch('YunYang1')
# nav <- dbGetQuery(mysql, "
#                   select * from nav
#                   order by TradingDay
#                   ") %>% as.data.table()
# nav[, Remarks := NULL]
# nav[, GrowthRate := GrowthRate * 100]
# nav[, GrowthRate := paste0(as.character(GrowthRate), '%')]
# colnames(nav) <- c('日期',
#                    '期货',
#                    '现货',
#                    '银行',
#                    '总资产',
#                    '份额',
#                    '净值',
#                    '收益率变动')
# print(nav)
#
# library(r2excel)
# wb <- createWorkbook(type = 'xlsx')
# sheet <- createSheet(wb, sheetName = '基金净值')
#
# xlsx.addHeader(wb, sheet, value = '云扬1号净值统计')
# xlsx.addLineBreak(sheet, 1)
# xlsx.addTable(wb, sheet, data = nav,
#               rowFill = c('white','lightblue'))
# xlsx.addLineBreak(sheet, 1)
#
# library(ggplot2)
# sheet <- createSheet(wb, sheetName = '净值曲线')
# xlsx.addHeader(wb, sheet, value = '云扬1号净值曲线')
# plotFunction <- function() {
#   temp <- nav[, .(日期 = as.Date(日期),
#                     净值 = as.numeric(净值))]
#   p <- ggplot(data = temp, aes(x = 日期, y = 净值)) +
#     geom_line(color = 'steelblue') +
#     labs(x = 'TradingDay', y = 'NAV', caption = '@HiCloud')
#   print(p)
# }
# xlsx.addPlot(wb, sheet, plotFunction())
# saveWorkbook(wb, paste0('/home/fl/myData/data/Fund','/','nav_YunYang1.xlsx'))
# ## =============================================================================

dbName <- 'TianMi1'
mysql <- mysqlFetch(dbName)
nav <- dbGetQuery(mysql, "
                  select * from nav
                  order by TradingDay
                  ") %>% as.data.table()
nav[, Remarks := NULL]
nav[, GrowthRate := GrowthRate * 100]
nav[, GrowthRate := paste0(as.character(GrowthRate), '%')]
colnames(nav) <- c('日期',
                   '期货',
                   '现货',
                   '银行',
                   '总资产',
                   '份额',
                   '净值',
                   '收益率变动')

wb <- createWorkbook(type = 'xlsx')
sheet <- createSheet(wb, sheetName = '基金净值')

xlsx.addHeader(wb, sheet, value = accountInfo[accountID == dbName, accountName])
xlsx.addLineBreak(sheet, 1)
xlsx.addTable(wb, sheet, data = nav,
              rowFill = c('white','lightblue'))
xlsx.addLineBreak(sheet, 1)

sheet <- createSheet(wb, sheetName = '净值曲线')
xlsx.addHeader(wb, sheet, value = accountInfo[accountID == dbName, paste0(accountName,'净值曲线')])
## ---------------------------------------------------------------------------
plotFunction <- function() {
  temp <- nav[, .(日期 = as.Date(日期),
                    净值 = as.numeric(净值))]
  p <- ggplot(data = temp, aes(x = 日期, y = 净值)) +
    geom_line(color = 'steelblue') +
    labs(x = 'TradingDay', y = 'NAV', caption = '@HiCloud')
  print(p)
}
## ---------------------------------------------------------------------------
xlsx.addPlot(wb, sheet, plotFunction())
saveWorkbook(wb, paste0('/home/fl/myData/data/Fund','/',
                        paste0('nav_', dbName, '.xlsx')))
dbDisconnect(mysql)
## =============================================================================




dbName <- 'YunYang1'
mysql <- mysqlFetch(dbName)
nav <- dbGetQuery(mysql, "
                  select * from nav
                  order by TradingDay
                  ") %>% as.data.table()
nav[, Remarks := NULL]
nav[, GrowthRate := GrowthRate * 100]
nav[, GrowthRate := paste0(as.character(GrowthRate), '%')]
colnames(nav) <- c('日期',
                   '期货',
                   '现货',
                   '银行',
                   '总资产',
                   '份额',
                   '净值',
                   '收益率变动')

wb <- createWorkbook(type = 'xlsx')
sheet <- createSheet(wb, sheetName = '基金净值')

xlsx.addHeader(wb, sheet, value = accountInfo[accountID == dbName, accountName])
xlsx.addLineBreak(sheet, 1)
xlsx.addTable(wb, sheet, data = nav,
              rowFill = c('white','lightblue'))
xlsx.addLineBreak(sheet, 1)

sheet <- createSheet(wb, sheetName = '净值曲线')
xlsx.addHeader(wb, sheet, value = accountInfo[accountID == dbName, paste0(accountName,'净值曲线')])
## ---------------------------------------------------------------------------
plotFunction <- function() {
  temp <- nav[, .(日期 = as.Date(日期),
                    净值 = as.numeric(净值))]
  p <- ggplot(data = temp, aes(x = 日期, y = 净值)) +
    geom_line(color = 'steelblue') +
    labs(x = 'TradingDay', y = 'NAV', caption = '@HiCloud')
  print(p)
}
## ---------------------------------------------------------------------------
xlsx.addPlot(wb, sheet, plotFunction())
saveWorkbook(wb, paste0('/home/fl/myData/data/Fund','/',
                        paste0('nav_', dbName, '.xlsx')))
dbDisconnect(mysql)
## =============================================================================

