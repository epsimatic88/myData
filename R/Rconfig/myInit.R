################################################################################
## myInit.R
## 初始化设置
# __1. 账号、密码__
# 2. 文件路径
# 3. 需要的软件包
# __4. 参数设置__
################################################################################
## =============================================================================
pkgs <- c("tidyverse", "data.table", "parallel",
          "RMySQL", "stringr", "bit64", "Rcpp",
          "lubridate","zoo",'rowr',
          'rvest','magrittr')
##------------------------------------------------------------------------------
if(length(pkgs[!pkgs %in% installed.packages()]) != 0){
  sapply(pkgs[!pkgs %in% installed.packages()], install.packages)
}
##------------------------------------------------------------------------------
sapply(pkgs, require, character.only = TRUE)

##------------------------------------------------------------------------------
options(digits = 8, digits.secs = 6, width　=　120,
        datatable.verbose = FALSE, scipen = 10)
##------------------------------------------------------------------------------
## =============================================================================

## =============================================================================
suppFunction <- function(x) {
  suppressWarnings({
    suppressMessages({
      x
    })
  })
}

################################################################################
## MySQL
## 链接到 MySQL 数据库，以获取数据
################################################################################

MySQL(max.con = 300)
for( conns in dbListConnections(MySQL()) ){
  dbDisconnect(conns)
}

mysql_user <- 'fl'
mysql_pwd  <- 'abc@123'
# mysql_host <- "127.0.0.1"
mysql_host <- "192.168.1.166"
mysql_port <- 3306

#---------------------------------------------------
# mysqlFetch
# 函数，主要输入为
# database
#---------------------------------------------------
mysqlFetch <- function(db,
                       host = mysql_host,
                       port = mysql_port,
                       user = mysql_user,
                       pwd  = mysql_pwd){
  dbConnect(MySQL(),
    dbname   = as.character(db),
    host     = host,
    port     = port,
    user     = user,
    password = pwd)
}

mysqlQuery <- function(db, query,
                       host = mysql_host,
                       port = mysql_port,
                       user = mysql_user,
                       pwd  = mysql_pwd) {
  mysql <- mysqlFetch(db)
  dt <- suppFunction(dbGetQuery(mysql, query)) %>% as.data.table()
  dbDisconnect(mysql)
  return(dt)
}


mysqlWrite <- function(db, tbl, 
                       data, isTruncated = FALSE,
                       host = mysql_host,
                       port = mysql_port,
                       user = mysql_user,
                       pwd  = mysql_pwd) {
  mysql <- mysqlFetch(db)

  if (isTruncated) {
    suppFunction(
      dbSendQuery(mysql, paste('truncate table', tbl))
    )
  }

  suppFunction(
    dbWriteTable(mysql, tbl,
                 data, row.names = F, append = T)
  )

  dbDisconnect(mysql)
}


## =============================================================================
## 从 MySQL 数据库提取数据
## =============================================================================
fetchData <- function(db, tbl, start, end) {
    mysql <- mysqlFetch(db)
    query <- paste("
    SELECT TradingDay, Sector,
           InstrumentID as id,
           OpenPrice as open,
           HighPrice as high,
           LowPrice as low,
           ClosePrice as close,
           Volume as volume,
           Turnover as turnover,
           SettlementPrice as stl",
    "FROM", tbl,
    "WHERE TradingDay BETWEEN", start,
    "AND", end)

    if (grepl('minute',tbl)) query <- gsub("Sector", 'Minute', query)

    tempRes <- dbGetQuery(mysql, query) %>% as.data.table() %>%
                .[order(TradingDay)]
    return(tempRes)
}

mysql <- mysqlFetch('dev')
ChinaFuturesCalendar <- dbGetQuery(mysql, "
            SELECT * FROM ChinaFuturesCalendar"
) %>% as.data.table()

if (as.numeric(format(Sys.time(),'%H')) < 17){
  currTradingDay <- ChinaFuturesCalendar[days <= format(Sys.Date(),'%Y-%m-%d')][.N]
}else{
  currTradingDay <- ChinaFuturesCalendar[days > format(Sys.Date(),'%Y-%m-%d')][1]
}
lastTradingDay <- ChinaFuturesCalendar[days < currTradingDay[1,days]][.N]

source('/home/fl/myData/R/Rconfig/myFunctions.R')

ChinaStocksCalendar <- mysqlQuery(db = 'dev',
                                  query = 'select * from ChinaStocksCalendar')
