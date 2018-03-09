## =============================================================================
## dzjy.R
## 处理 大宗交易 数据
## 
## AUTHOR   : fl@hicloud-investment.com
## DATE     : 2018-03-08
## =============================================================================

source("/home/fl/myData/R/Rconfig/myInit.R")
DATA_PATH <- "/home/fl/myData/data/ChinaStocks/DZJY"

## =============================================================================
SOURCE <- 'FromExch'
## =============================================================================
dzjy_sse <- paste0(DATA_PATH, '/', SOURCE, '/sse.csv') %>% 
    fread()
dzjy_sse[, ":="(
    ifZc = NULL
    )]
colnames(dzjy_sse) <- c('TradingDay', 'stockID', 'stockName',
                        'price', 'volume', 'turnover',
                        'DeptBuy', 'DeptSell')
dzjy_sse[, stockName := gsub(" ", "", stockName)]
dzjy_sse[, stockName := gsub("Ａ", "A", stockName)]
dzjy_sse[, stockName := gsub("Ｂ", "B", stockName)]
mysqlWrite(db = 'china_stocks', tbl = 'dzjy_from_exch',
           data = dzjy_sse)


dzjy_szse <- paste0(DATA_PATH, '/', SOURCE, '/szse.xlsx') %>% 
    readxl::read_excel() %>% 
    as.data.table()
colnames(dzjy_szse) <- c('TradingDay', 'stockID', 'stockName',
                        'price', 'volume', 'turnover',
                        'DeptBuy', 'DeptSell')
dzjy_szse[, ":="(
    stockName = gsub(" ", "", stockName),
    volume = as.numeric(volume) * 10000,
    turnover = as.numeric(turnover) * 10000
    )]
dzjy_szse[, stockName := gsub("Ａ", "A", stockName)]
dzjy_szse[, stockName := gsub("Ｂ", "B", stockName)]

mysqlWrite(db = 'china_stocks', tbl = 'dzjy_from_exch',
           data = dzjy_szse)
## =============================================================================


## =============================================================================
SOURCE <- 'FromSina'
## =============================================================================
dzjy_sina <- paste0(DATA_PATH, '/', SOURCE, '/sse_szse.csv') %>% 
    fread(., colClass = c('character'))
colnames(dzjy_sina) <- c('TradingDay', 'stockID', 'stockName',
                         'price', 'volume', 'turnover',
                         'DeptBuy', 'DeptSell', 'exchType')
dzjy_sina[, ":="(
    exchType = NULL,
    volume = as.numeric(volume) * 10000,
    turnover = as.numeric(turnover) * 10000  
    )]
dzjy_sina[, stockName := gsub(" ", "", stockName)]
dzjy_sina[, stockName := gsub("Ａ", "A", stockName)]
dzjy_sina[, stockName := gsub("Ｂ", "B", stockName)]
mysqlWrite(db = 'china_stocks', tbl = 'dzjy_from_sina',
           data = dzjy_sina)
## =============================================================================
