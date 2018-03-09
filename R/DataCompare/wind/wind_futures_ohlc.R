rm(list = ls())
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
          "lubridate","zoo",'beepr','plotly','rowr')
##------------------------------------------------------------------------------
if(length(pkgs[!pkgs %in% installed.packages()]) != 0){
  sapply(pkgs[!pkgs %in% installed.packages()], install.packages)
}
##------------------------------------------------------------------------------
sapply(pkgs, require, character.only = TRUE)

##------------------------------------------------------------------------------

##------------------------------------------------------------------------------
## =============================================================================

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
mysql_host <- "192.168.1.106"
mysql_port <- 3306

#---------------------------------------------------
# mysqlFetch
# 函数，主要输入为
# database
#---------------------------------------------------
mysqlFetch <- function(x, host = mysql_host){
  dbConnect(MySQL(),
            dbname   = as.character(x),
            user     = mysql_user,
            password = mysql_pwd,
            host     = host,
            port     = mysql_port)
}
################################################################################


################################################################################
library(WindR)
w.start()
################################################################################

startDate <- '2016-01-01'
endDate   <- Sys.Date()
instrumentID <- 'CF709'
exchangeInfo   <- read_csv('C:/Users/Administrator/Desktop/ContractInfo_20170711.csv') %>% 
  as.data.table() 


################################################################################
runComp <- function(instrumentID, startDate, endDate){

  exchangeID <- exchangeInfo[symbol == instrumentID,substr(exchange,1,3)]
  if (exchangeID != 'CZC') {
    return(NULL)
  }
  
mysql <- mysqlFetch('china_futures_info')
dtVM <- dbGetQuery(mysql, paste("
                   SELECT * FROM VolumeMultiple
                   WHERE InstrumentID = ", paste0("'",instrumentID,"'"),
                   "AND TradingDay Between", gsub('-','',startDate), 
                   "AND ", gsub('-','',endDate))
                   ) %>% as.data.table()


dtWind <- w.wsd(paste0(instrumentID,".",exchangeID),
                  "open,high,low,close,volume,amt,oi,settle",
                  startDate, endDate) %>%
  .$Data %>% as.data.table() %>% .[!is.na(OPEN) & !is.na(CLOSE)]
dtWind[, TradingDay := as.character(DATETIME)]


################################################################################
mysql <- mysqlFetch('china_futures_bar')
dtMySQL <- dbGetQuery(mysql,paste("
                 SELECT TradingDay, InstrumentID,
                        OpenPrice, HighPrice, LowPrice, ClosePrice,
                        Volume, Turnover, 
                        CloseOpenInterest, SettlementPrice
                 FROM daily
                 WHERE InstrumentID = ", 
                             paste0("'",instrumentID,"'"),
                 "AND TradingDay Between", gsub('-','',startDate), 
                 "AND ", gsub('-','',endDate),
                 "AND Sector = 'allday'")
                 ) %>% as.data.table()
################################################################################



################################################################################
## 对比数据质量
dt <- merge(dtWind, dtMySQL, by = c('TradingDay')) %>% 
  merge(., dtVM, by = c('TradingDay','InstrumentID'))
if (nchar(gsub('[a-zA-z]','',instrumentID)) == 3){
  dt[, Turnover := Turnover * VolumeMultiple]
}


dtComp <- function(data, x, y, errSig = 0.00){
  tempDiff <- data[, .(err = eval(as.symbol(x)) - eval(as.symbol(y))),
                   by = 'TradingDay']
  tempDiff[, TradingDay := as.Date(TradingDay)]
  
  p <- ggplot(tempDiff[err %between% c(quantile(err, errSig), quantile(err, 1-errSig))], 
              aes(x = TradingDay, y = err)) +
    geom_point(color = 'steelblue', size = 2) +
    geom_hline(yintercept = 0, color = 'hotpink', size = 1.5) +
    labs(title = paste(instrumentID,'==> Error Term:',x, '-', y),
           caption = '@williamfang')
  print(p)
  #ggplotly(p)
}
################################################################################

dtComp(dt, 'OPEN', 'OpenPrice')

dtComp(dt, 'HIGH', 'HighPrice')

dtComp(dt, 'LOW', 'LowPrice')

dtComp(dt, 'CLOSE', 'ClosePrice')

#dtComp(dt, 'VOLUME', 'Volume', errSig = 0.05)

#dtComp(dt, 'AMT', 'Turnover', errSig = 0.05)

#dtComp(dt,'OI', 'CloseOpenInterest')

}
