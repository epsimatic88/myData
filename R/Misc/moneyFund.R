rm(list = ls())

library(data.table)
library(magrittr)
library(RSelenium)
library(RMySQL)
library(rvest)
options(width = 150, digits = 10, scipen = 10)

Sys.setenv(R_ZIPCMD = "C:/Rtools/bin/zip")

Sys.setlocale(category = 'LC_ALL', locale = 'us')

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


###############################################################################

##------------------------------------------------------------------------------
# setwd("/myCodes/ExchDataFetch")
setwd("Y:/myData/")
##------------------------------------------------------------------------------

## =============================================================================
ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
                              colClasses = list(character = c("nights","days")))
if (!format(Sys.Date(),"%Y%m%d") %in% ChinaFuturesCalendar[,days]) stop('NOT TradingDay!')
currTradingDay <- ChinaFuturesCalendar[days <= format(Sys.Date(), '%Y%m%d')][nights < format(Sys.Date(), '%Y%m%d')][.N]
## =============================================================================

accountInfo <- data.table(accountSecurity = c('xingye'),
                          accountID  = c('320076588'),
                          accountPwd = c('218226'))

## =============================================================================
#remDr <- remoteDriver(remoteServerAddr ='localhost'
#                      ,port = 4444
#                      ,browserName = 'internet explorer')
remDr <- remoteDriver(browserName = 'internet explorer')


remDr$getStatus()

URL <- "https://estock.xyzq.com.cn/account/login/index"

remDr$open(silent = F)
Sys.sleep(3)
remDr$refresh()
remDr$navigate(URL)
Sys.sleep(3)
remDr$refresh()
Sys.sleep(3)
## =============================================================================


while (class(try(remDr$findElements("id", "a_myOwnItem")[[1]])) == "try-error") {

  tempClick <- remDr$findElements('id', 'rtab')[[1]]
  tempClick$highlightElement()
  for (i in 1:2) tempClick$clickElement()
  Sys.sleep(1)

  id <- remDr$findElements('id', 'txtUserName')[[1]]
  #id$highlightElement()
  for (i in 1:2) id$clickElement()
  Sys.sleep(1)
  id$sendKeysToElement(list('320076588'))
  Sys.sleep(1)

  pwd <- remDr$findElements('id', 'txtPassword2')[[1]]
  #pwd$highlightElement()
  pwd$clickElement()
  Sys.sleep(1)

  pwd <- remDr$findElements('id', 'txtPassword')[[1]]
  #pwd$highlightElement()
  #for (i in 1:2) pwd$clickElement()
  Sys.sleep(1)
  pwd$sendKeysToElement(list('218226'))
  Sys.sleep(1)

  if (FALSE) {
    tempLogin <- remDr$findElements("xpath", "//*/*[text()='登录']")[[3]]
    #tempLogin$highlightElement()
    tempLogin$clickElement()
    Sys.sleep(10)
  }

  tempLogin <- remDr$findElements("class", "z-btn")[[1]]
  #tempLogin$highlightElement()
  tempLogin$clickElement()
  Sys.sleep(10)


  if (class(try(remDr$findElements("id", "a_myOwnItem")[[1]])) != "try-error") {
    break
  } else {
    remDr$close()
    Sys.sleep(3)
    remDr$open(silent = F)
    remDr$navigate(URL)
    Sys.sleep(5)
  }
}
Sys.sleep(1)

if (FALSE) {
temp <- remDr$findElements("xpath", "//*/*[text()='我的专属']")[[1]]
#temp$highlightElement()
temp$clickElement()
Sys.sleep(5)

temp <- remDr$findElements("xpath", "//*/*[text()='我的财富']")[[1]]
#temp$highlightElement()
temp$clickElement()
Sys.sleep(5)
}

temp <- remDr$findElements("id", "a_myOwnItem")[[1]]
#temp$highlightElement()
temp$clickElement()
Sys.sleep(5)

temp <- remDr$findElements("class", "tubiao-4")[[1]]
#temp$highlightElement()
temp$clickElement()
Sys.sleep(10)

for (i in 1:2) {
  tempUpdate <- remDr$findElements('id','imgref')[[1]]
  tempUpdate$highlightElement()
  Sys.sleep(3)
  tempUpdate$doubleclick()
  Sys.sleep(3)
}
Sys.sleep(3)

tempHTML <- remDr$findElements('class', 'Wealth01')

tempData <- tempHTML[[1]]$getElementAttribute('outerHTML')[[1]] %>%
  read_html('utf8') %>%
  html_nodes('table') %>%
  html_table(fill = TRUE) %>%
  as.data.table()

webData <- tempData[1, X4] %>%
  gsub('\\n|\\t','',.) %>%
  strsplit(., ' ') %>%
  .[[1]] %>%
  .[nchar(.) != 0] %>%
  .[2] %>%
  gsub(' |,','',.) %>%
  as.numeric()
print(webData)
try(
    remDr$close()
)

## =============================================================================
# mysql <- mysqlFetch('HiCloud')
mysql <- mysqlFetch('YunYang1')
reportAccount <- dbGetQuery(mysql, "
                            select *
                            from report_account_history
                            order by TradingDay
                            ") %>% as.data.table()
fee <- dbGetQuery(mysql, "
                        select *
                        from fee
                        order by TradingDay
                        ") %>% as.data.table()
if (nrow(fee) != 0) {
  for (j in 1:nrow(fee)) {
    tempTradingDay <- fee[j, TradingDay]
    reportAccount[TradingDay >= tempTradingDay, 
          totalMoney := totalMoney + fee[TradingDay == tempTradingDay, sum(Amount)]]
  }
}

nav <- dbGetQuery(mysql, "
                  select * from nav
                  order by TradingDay
                  ") %>% as.data.table()

nav[, Assets := (Futures + Currency + Bank)]
addInfo <- data.table(TradingDay = currTradingDay[1,as.character(as.Date(days,'%Y%m%d'))],
                      Futures = reportAccount[.N, totalMoney],
                      Currency = webData,
                      Bank = 10000,
                      Assets = reportAccount[.N, totalMoney] + webData + 10000,
                      Shares = 2000000,
                      NAV = (reportAccount[.N, totalMoney] + webData + 10000) / 2000000
)

navUpdate <- rbind(nav[TradingDay != currTradingDay[1,as.character(as.Date(days,'%Y%m%d'))]], addInfo, fill = TRUE)
if (nrow(navUpdate) > 1) {
  navUpdate[, NAV := (Assets / Shares)]
  navUpdate[, GrowthRate := c(0, navUpdate[,diff(NAV)] / navUpdate[1:(.N-1), NAV])]
} else {
  navUpdate[1, GrowthRate := 0]
}
navUpdate[, GrowthRate := round(GrowthRate,4)]

dbSendQuery(mysql, 'truncate table nav')
dbWriteTable(mysql, 'nav', navUpdate, row.names = F, append = T)
## =============================================================================
