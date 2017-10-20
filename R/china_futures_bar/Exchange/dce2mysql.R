################################################################################
## dce2mysql.R
## 这是主函数:
## 读取 大商所 下载得到的日行情数据，
## 并录入 MySQL 数据库
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-10-16
## -----------------------------------------------------------------------------
## 说明：
## (1) 价格：元/吨
## (2) 成交量、持仓量：手（按双边计算）
## (3) 成交额：万元（按双边计算）
## (4) 涨跌＝收盘价－前结算价
## (5) 涨跌1=今结算价-前结算价
## (6) 合约系列：具有相同月份标的期货合约的所有期权合约的统称
## (7) 隐含波动率：根据期权市场价格，利用期权定价模型计算的标的期货合约价格波动率
################################################################################


################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("dce2mysql.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})

################################################################################
## STEP 1: 获取对应的交易日期
################################################################################
ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
                              colClasses = list(character = c("nights","days"))) %>% 
                              .[days < format(Sys.Date(),'%Y%m%d')]
exchCalendar <- ChinaFuturesCalendar[,":="(calendarYear = substr(days,1,4),
                                           calendarYearMonth = substr(days,1,6),
                                           calendarMonth = substr(days,5,6),
                                           calendarDay = substr(days,7,8))]

dataPath <- './data/Bar/Exchange/DCE'

productInfo <- data.table(productID = c('a','b','m','y','p','c','cs','jd',
                                      'fb','bb','l','v','pp','j','jm','i'),
                          productName = c('豆一','豆二','豆粕','豆油','棕榈油','玉米','玉米淀粉','鸡蛋',
                                     '纤维板','胶合板','聚乙烯','聚氯乙烯','聚丙烯','焦炭','焦煤','铁矿石')
                          )

## =============================================================================
fetchData <- function(i) {
    tempTradingDay <- exchCalendar[i,days]
    tempFile <- paste0(dataPath, '/', 
                       exchCalendar[i, calendarYear], '/',
                       exchCalendar[i, days], '.xlsx')
    if (! file.exists(tempFile)) return(data.table())

    res <- readxl::read_excel(tempFile) %>% 
            as.data.table()
    colnames(res) <- c('productName','deliverMonth',
                       'OpenPrice','HighPrice','LowPrice','ClosePrice',
                       'preSettlementPrice','SettlementPrice',
                       'Delta1','Delta2',
                       'Volume','CloseOpenInterest',
                       'DeltaOpenInterest','Turnover')
    cols <- colnames(res)[2:ncol(res)]
    res[, (cols) := lapply(.SD, function(x){
        gsub(',','',x) %>% gsub('-','0',.)
    }), .SDcols = cols]

    res <- merge(res, productInfo, by = 'productName') %>% 
            .[, ':='(
                InstrumentID = paste0(productID, deliverMonth),
                TradingDay   = tempTradingDay
            )]

    cols <- c('productName','deliverMonth',
              'preSettlementPrice',
              'Delta1','Delta2',
              'DeltaOpenInterest',
              'productID')
    res[, (cols) := NULL]
}
## =============================================================================

################################################################################
## STEP 2: 开启并行计算模式
################################################################################
cl <- makeCluster(max(round(detectCores()*3/4),4), type='FORK')
dt <- parLapply(cl, 1:nrow(ChinaFuturesCalendar), fetchData) %>% rbindlist(., fill = TRUE)
stopCluster(cl)

dt[, ":="(Turnover = as.numeric(Turnover) * 10000,
          ExchangeID = 'DCE')]
## =============================================================================


## =============================================================================
mysql <- mysqlFetch('Exchange', host = '192.168.1.166')
dbWriteTable(mysql, 'daily',
             dt, row.name　=　FALSE, append = T)
## =============================================================================


################################################################################
dbDisconnect(mysql)
for(conn in dbListConnections(MySQL()) )
  dbDisconnect(conn)
################################################################################
