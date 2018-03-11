## =============================================================================
## lhb.R
## dfsdfsdf 
## 
## DATE     : 2018-03-05
## AUTHOR   : fl@hicloud-investment.com
## =============================================================================

source("/home/fl/myData/R/Rconfig/myInit.R")
ChinaStocksCalendar <- ChinaStocksCalendar[days >= '2000-01-01']

DATA_PATH <- "/home/fl/myData/data/ChinaStocks/LHB"

## =============================================================================
DATA_SOURCE <- 'FromSina'
## =============================================================================
allDirs <- list.files(paste0(DATA_PATH, '/', DATA_SOURCE), full.name = T)

dt_sina <- lapply(allDirs, function(d){
    allFiles <- list.files(d, full.names = T)
    res <- lapply(allFiles, function(f){
        tmp <- fread(f, colClass = 'character')
        tmp[, TradingDay := gsub('.*([0-9]{4}-[0-9]{2}-[0-9]{2}).*', '\\1', f)]
    }) %>% rbindlist()
}) %>% rbindlist()

lhbName_sina <- dt_sina[,unique(上榜原因)]

## =============================================================================
DATA_SOURCE <- 'FromEastmoney'
## =============================================================================
allDirs <- list.files(paste0(DATA_PATH, '/', DATA_SOURCE), full.name = T)

dt_eastmoney <- lapply(allDirs, function(d){
    allFiles <- list.files(d, full.names = T)
    res <- lapply(allFiles, function(f){
        tmp <- fread(f, colClass = 'character')
        tmp[, TradingDay := gsub('.*([0-9]{4}-[0-9]{2}-[0-9]{2}).*', '\\1', f)]
    }) %>% rbindlist()
}) %>% rbindlist()

lhbName_eastmoney <- dt_eastmoney[,unique(上榜原因)]


## =============================================================================
DATA_SOURCE <- 'FromExch'
## =============================================================================
allDirs <- list.files(paste0(DATA_PATH, '/', DATA_SOURCE), full.name = T)
d <- allDirs[10]
allFiles <- list.files(d, full.names = T)

sseFiles <- grep('sse\\.txt', allFiles, value = T)

parse_sse_file <- function(dataFile) {
    # print(dataFile)

    tradingDay <- gsub(".*([0-9]{4}-[0-9]{2}-[0-9]{2}).*", "\\1", dataFile)

    f <- readLines(dataFile)

    ## -------------------------------------------------------------------------
    ## 替换分行的上榜原因
    # sp <- grep("\"|并且该股票封闭式|在这2个交易日中同一营业部净买入|在这2个交易日中同一营业部净卖出", f)
    sp_title <- grep('[一|二|三|四|五|六|七|八|九|十]{1,}、', f)
    sp_new <- c()
    for (s in sp_title) {
        if (nchar(f[s]) > 42) sp_new <- c(sp_new, s)
    }
    

    sp_rm <- c()
    for (s in sp_new) {
        print(s)
        if (nchar(f[s+1]) == 0) {
            f[s] <- paste0(f[s], f[s+1], f[s+2]) %>% 
                gsub("\"| ", '', .)
            sp_rm <- c(sp_rm, s+1, s+2)
        } else {
            f[s] <- paste0(f[s], f[s+1]) %>% 
                gsub("\"| ", '', .)
            sp_rm <- c(sp_rm, s+1)
        }
    }
    f <- f[-sp_rm]

    ## -------------------------------------------------------------------------

    m <- grep("、.*(:|：|%|%)", f) %>% c(., length(f))

    dt <- lapply(2:length(m), function(k){
        # print(k)
        tmp <- f[m[k-1] : (m[k]-1)]

        if (!any(grepl("证券代码", tmp))) return(data.table())

        lhbName <- tmp[1] %>%
            gsub("[一|二|三|四|五|六|七|八|九|十]{1,}、(.*)", '\\1', .) %>% 
            gsub(':|：', '', .)

        u <- grep('证券代码: [0-9]{6}', tmp)[1] 
        if (is.na(u)) return(data.table())

        v <- grep('2、B股', tmp)-1

        if (length(v) != 0) {

            if (length(u) != length(v)) {
                print(dataFile)
                print(k)
                stop("Error")
            }

            if (v <= u) return(data.table())

            info <- tmp[u:v]
        } else {
            info <- tmp[u:length(tmp)]
        }

        w <- grep('证券代码: [0-9]{6}', info) %>% c(., length(info))

        res <- lapply(2:length(w), function(kk){
            # print(kk)
            allInfo <- info[w[kk-1] : (w[kk]-1)] %>% 
                .[!is.na(.)]

            stockInfo <- grep('证券代码: [0-9]{6}', allInfo, value = T) %>%
                strsplit(., ' ') %>% 
                unlist() %>% 
                .[nchar(.) != 0]
            stockID <- grep('[0-9]{6}', stockInfo, value = T)
            stockName <- grep('[0-9]{6}|简称|代码', stockInfo, value = T, invert = T)

            if (any(grep('买入', allInfo))) {
                if (!any(grepl('卖出', allInfo))) {
                    if (kk == length(w)) {
                        buy <- allInfo[grep('买入', allInfo) : (length(allInfo) - 0)] %>% 
                        grep("\\([0-9]\\)", ., value = T) 
                    } else {
                        buy <- allInfo[grep('买入', allInfo) : (length(allInfo) - 1)] %>% 
                        grep("\\([0-9]\\)", ., value = T) 
                    }
                } else {
                    buy <- allInfo[grep('买入', allInfo) : (grep('卖出', allInfo) - 1)] %>% 
                        grep("\\([0-9]\\)", ., value = T)
                }

                buyInfo <- lapply(buy, function(l){
                    y <- strsplit(l, ' ') %>% 
                        unlist() %>% 
                        .[nchar(.) != 0] %>% 
                        .[!grepl("\\([0-9]\\)", .)]
                    res <- data.table(DeptName = grep('证券|公司|营业|部|机构|专用', y, value = T),
                                      direction = 'buy',
                                      turnover = grep('证券|公司|营业|部|机构|专用', y, value = T, invert = T))
                }) %>% rbindlist()
            } else {
                buyInfo <- data.table()
            }

            if (any(grep('卖出', allInfo))) {
                sell <- allInfo[grep('卖出', allInfo) : length(allInfo)] %>% 
                    grep("\\([0-9]\\)", ., value = T)
                sellInfo <- lapply(sell, function(l){
                    y <- strsplit(l, ' ') %>% 
                        unlist() %>% 
                        .[nchar(.) != 0] %>% 
                        .[!grepl("\\([0-9]\\)", .)]
                    res <- data.table(DeptName = grep('证券|公司|营业|部|机构|专用', y, value = T),
                                      direction = 'sell',
                                      turnover = grep('证券|公司|营业|部|机构|专用', y, value = T, invert = T))
                }) %>% rbindlist()
            } else {
                sellInfo <- data.table()
            }

            res <- list(buyInfo, sellInfo) %>% rbindlist()

            res[direction == 'buy', buyAmount := turnover]
            res[direction == 'sell', sellAmount := turnover]

            res[, ":="(
                stockID = stockID,
                stockName = stockName,
                lhbName = lhbName,
                ## ---------------
                direction = NULL,
                turnover = NULL
                )]
            return(res)
        }) %>% rbindlist()
        return(res)
    }) %>% rbindlist()

    dt[, TradingDay := tradingDay]

    return(dt)
}

cl <- makeCluster(16, type = 'FORK')
dt_sse <- parLapply(cl, allDirs, function(d){
    allFiles <- list.files(d, full.names = T)

    sseFiles <- grep('sse\\.txt', allFiles, value = T)

    ## -----------------------------------------------
    # lapply(sseFiles, function(f){
    #     if (class(try(
    #         res <- parse_sse_file(f)
    #         )) == 'try-error') {
    #         print(d)
    #         print(f)
    #         stop('error')
    #     } else {
    #         res <- data.table()
    #     }
    # })

    # return(res)
    ## -----------------------------------------------

    lapply(sseFiles, parse_sse_file) %>% rbindlist()
}) %>% rbindlist()
stopCluster(cl)

lhbName_sse <- dt_sse[,unique(lhbName)]

#  [1] "有价格涨跌幅限制的日收盘价格涨幅偏离值达到7%的前三只证券"                                                                                         
#  [2] "有价格涨跌幅限制的日收盘价格跌幅偏离值达到7%的前三只证券"                                                                                         
#  [3] "有价格涨跌幅限制的日价格振幅达到15%的前三只证券"                                                                                                  
#  [4] "有价格涨跌幅限制的日换手率达到20％的前三只证券"                                                                                                   
#  [5] "无价格涨跌幅限制的证券"                                                                                                                           
#  [6] "非ST和*ST证券连续三个交易日内收盘价格涨幅偏离值累计达到20%的证券"                                                                                 
#  [7] "ST和*ST证券连续三个交易日内收盘价格跌幅偏离值累计达到15%的证券"                                                                                   
#  [8] "连续三个交易日的日均换手率与前五个交易日日均换手率的比值到达30%,并且该股票封闭式基金连续三个交易累计换手率达到20%"                                
#  [9] "非ST和*ST证券连续三个交易日内收盘价格跌幅偏离值累计达到20%的证券"                                                                                 
# [10] "ST和*ST证券连续三个交易日内收盘价格涨幅偏离值累计达到15%的证券"                                                                                   
# [11] "实施特别停牌的证券"                                                                                                                               
# [12] "连续三个交易日内的日均换手率与前五个交易日日均换手率的比值到达30倍,并且该股票封闭式基金连续三个交易日内累计换手率达到20%"                         
# [13] "ST股票、*ST股票和S股连续三个交易日触及涨（跌）幅限制的"                                                                                           
# [14] "ST股票、*ST股票和S股连续三个交易日触及涨幅限制的"                                                                                                 
# [15] "ST股票、*ST股票和S股连续三个交易日触及跌幅限制的"                                                                                                 
# [16] "当日有涨跌幅限制的A股，连续2个交易日触及涨幅限制，在这2个交易日中同一营业部净买入股数占当日总成交股数的比重30％以上，且上市公司未有重大事项公告的"
# [17] "当日有涨跌幅限制的A股，连续2个交易日触及跌幅限制，在这2个交易日中同一营业部净卖出股数占当日总成交股数的比重30％以上，且上市公司未有重大事项公告的"
# [18] "当日无价格涨跌幅限制的股票，其盘中交易价格较当日开盘价上涨100％以上"                                                                              
# [19] "当日无价格涨跌幅限制的股票，其盘中交易价格较当日开盘价上涨30％以上"                                                                               
# [20] "当日无价格涨跌幅限制的股票，其盘中交易价格较当日开盘价下跌30％以上"                                                                               
# [21] "有价格涨跌幅限制的日换手率达到20%的前三只证券"                                                                                                    
# [22] "单只标的证券的当日融资买入数量达到当日该证券总交易量的50％以上"                                                                                   
# [23] "当日无价格涨跌幅限制的A股，出现异常波动停牌的"                                                                                                    
# [24] "单只标的证券的当日融券卖出数量达到当日该证券总交易量的50％以上"                                                                                   
# [25] "风险警示股票盘中换手率达到或超过30%"                                                                                                              
# [26] "非ST、*ST和S证券连续三个交易日内收盘价格涨幅偏离值累计达到20%的证券"                                                                              
# [27] "非ST、*ST和S证券连续三个交易日内收盘价格跌幅偏离值累计达到20%的证券"                                                                              
# [28] "ST、*ST和S证券连续三个交易日内收盘价格跌幅偏离值累计达到15%的证券"                                                                                
# [29] "退市整理的证券"                                                                                                  
# [30] "ST、*ST和S证券连续三个交易日内收盘价格涨幅偏离值累计达到15%的证券"                                                                                
# [31] "*ST博元风险警示期交易信息"    


## =============================================================================
DATA_SOURCE <- 'FromExch'
## =============================================================================
allDirs <- list.files(paste0(DATA_PATH, '/', DATA_SOURCE), full.name = T)
d <- allDirs[10]
allFiles <- list.files(d, full.names = T)

szseFiles <- grep('szse.*\\.txt', allFiles, value = T)

parse_szse_file <- function(dataFile) {

    # dataFile <- "/home/fl/myData/data/ChinaStocks/LHB/FromExch/2012/2012-12-28_szse_30.txt"

    tradingDay <- gsub(".*([0-9]{4}-[0-9]{2}-[0-9]{2}).*", "\\1", dataFile)

    ## 2006-07-01 之前的数据就不要用了
    ## 没有买入、卖出的金额
    if (tradingDay < '2006-07-01') return(data.table())

    if (class(try(
            f <- readLines(file(dataFile, encoding = 'GB18030')) %>% 
                .[grep('证券(:|：)|详细信息', .)[1] : length(.)]
        )) == 'try-error') {
        return(data.table())
    }

    sp_line <- grep('证券(:|：)|[-]{5,}', f) %>% c(., length(f))

    dt <- lapply(2:length(sp_line), function(kk){
        # print(kk)

        tmp <- f[sp_line[kk - 1] : (sp_line[kk] - 1)]

        if (length(tmp) < 5) return(data.table())

        lhbName <- grep('证券(:|：)', tmp) 
        if (lhbName != 1) {
            if (nchar(tmp[lhbName - 1]) != 0) {
                lhbName <- paste0(tmp[lhbName - 1], tmp[lhbName])
            } else {
                lhbName <- tmp[lhbName]
            }
        } else {
            lhbName <- tmp[lhbName]
        }
        lhbName <- gsub(":|：", '', lhbName)

        if (identical(lhbName, character(0))) return(data.table())
        if (grepl('无$', lhbName)) return(data.table())

        sp_stock <- grep('代码(:|：| |)[0-9]{6}', tmp) %>% c(., length(tmp))

        res <- lapply(2:length(sp_stock), function(ss){
            # ss <- 2
            allInfo <- tmp[sp_stock[ss - 1] : (sp_stock[ss] - 1)]

            stockInfo <- grep('代码(:|：| |)[0-9]{6}', allInfo, value = T) %>% 
                strsplit(., '\\)') %>% 
                unlist() %>% 
                .[1] %>%
                strsplit(., '\\(|\\)') %>% 
                unlist()
            stockName <- grep('\\d', stockInfo, value = T, invert = T)
            stockID <- grep('\\d', stockInfo, value = T) %>% 
                gsub('\\D', '', .)

            buy <- allInfo[grep('买入金额最大', allInfo) : (grep('卖出金额最大', allInfo) - 1)] %>% 
                .[(grep('营业部或', .) + 1) : length(.)] %>% 
                .[nchar(.) != 0]
            buyInfo <- lapply(buy, function(b){
                u <- strsplit(b, ' ') %>% 
                    unlist() %>% 
                    grep('\\S', ., value = T)
                data.table(DeptName = u[1],
                           buyAmount = u[2],
                           sellAmount = u[3])
            }) %>% rbindlist()

            sell <- allInfo[grep('卖出金额最大', allInfo) : length(allInfo)] %>% 
                .[(grep('营业部或', .) + 1) : length(.)] %>% 
                .[nchar(.) != 0]
            sellInfo <- lapply(sell, function(s){
                u <- strsplit(s, ' ') %>% 
                    unlist() %>% 
                    grep('\\S', ., value = T)
                data.table(DeptName = u[1],
                           buyAmount = u[2],
                           sellAmount = u[3])
            }) %>% rbindlist()

            res <- list(buyInfo, sellInfo) %>% rbindlist() %>% 
                .[, ":="(
                    stockID = stockID,
                    stockName = stockName,
                    lhbName = lhbName
                    )]
        }) %>% rbindlist()

    }) %>% rbindlist()

    if (nrow(dt) != 0) dt[, TradingDay := tradingDay]

    return(dt)
}


cl <- makeCluster(6, type = 'FORK')
dt_szse <- parLapply(cl, allDirs, function(d){
    allFiles <- list.files(d, full.names = T)

    szseFiles <- grep('szse_.*\\.txt', allFiles, value = T)

    ## -----------------------------------------------
    # lapply(szseFiles, function(f){
    #     if (class(try(
    #         res <- parse_szse_file(f)
    #         )) == 'try-error') {
    #         print(d)
    #         print(f)
    #         stop('error')
    #     } else {
    #         res <- data.table()
    #     }
    # })

    # return(res)
    ## -----------------------------------------------

    lapply(szseFiles, parse_szse_file) %>% rbindlist()
}) %>% rbindlist()
stopCluster(cl)

lhbName_szse <- dt_szse[,unique(lhbName)]

#  [1] "日涨幅偏离值达到7%的前三只证券"                                             
#  [2] "日振幅值达到15%的前三只证券"                                                
#  [3] "无价格涨跌幅限制的证券"                                                     
#  [4] "连续三个交易日内，涨幅偏离值累计达到20%的证券"                              
#  [5] "日跌幅偏离值达到7%的前三只证券"                                             
#  [6] "日换手率达到20%的前三只证券"                                                
#  [7] "连续三个交易日内，跌幅偏离值累计达到20%的证券"                              
#  [8] "连续三个交易日内，涨幅偏离值累计达到15%的ST证券"                            
#  [9] "连续三个交易日内，涨幅偏离值累计达到15%的ST和*ST证券"                       
# [10] "连续三个交易日内，跌幅偏离值累计达到15%的ST和*ST证券"                       
# [11] "连续三个交易日内，跌幅偏离值累计达到15%的ST证券、*ST证券和未完成股改证券"   
# [12] "连续三个交易日内，涨幅偏离值累计达到15%的ST证券、*ST证券和未完成股改证券"   
# [13] "连续三个交易日收盘价达到涨幅限制价格的ST证券、*ST证券和未完成股改证券"      
# [14] "连续三个交易日收盘价达到跌幅限制价格的ST证券、*ST证券和未完成股改证券"      
# [15] "日均换手率与前五个交易日的日均换手率的比值达到30倍，且换手率累计达20%的证券"
# [16] "连续三个交易日收盘价达到跌幅限制价格的ST证券、*ST证券"                      
# [17] "连续三个交易日收盘价达到涨幅限制价格的ST证券、*ST证券"                      
# [18] "连续三个交易日内，涨幅偏离值累计达到15%的ST证券、*ST证券"                   
# [19] "连续三个交易日内，跌幅偏离值累计达到15%的ST证券、*ST证券"                   
# [20] "日涨幅偏离值达到7%的前五只证券"                                             
# [21] "日跌幅偏离值达到7%的前五只证券"                                             
# [22] "日振幅值达到15%的前五只证券"                                                
# [23] "日换手率达到20%的前五只证券"                                                
# [24] "连续三个交易日内，涨幅偏离值累计达到12%的ST证券、*ST证券和未完成股改证券"   
# [25] "连续三个交易日内，跌幅偏离值累计达到12%的ST证券、*ST证券和未完成股改证券"   
# [26] "连续三个交易日内，跌幅偏离值累计达到12%的ST证券、*ST证券"                   
# [27] "连续三个交易日内，涨幅偏离值累计达到12%的ST证券、*ST证券"       

