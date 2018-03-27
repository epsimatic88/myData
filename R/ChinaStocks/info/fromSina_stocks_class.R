## =============================================================================
## fromSina_stocks_class.R
##
## 获取 新浪财经 股票分类
##
## Author : fl@hicloud-investment.com
## Date   : 2018-03-26
##
## =============================================================================

## =============================================================================
suppressMessages({
  source('/home/fl/myData/R/Rconfig/myInit.R')
})

## =============================================================================
## 新浪行业分类
## ----------
## Ref: http://finance.sina.com.cn/stock/sl/


## =============================================================================
## SW 二级行业分类
## - 
URL_INFO <- "http://vip.stock.finance.sina.com.cn/quotes_service/api/json_v2.php/Market_Center.getHQNodes"
r <- GET(URL_INFO, timeout(5))
p <- content(r, as = 'parsed', encoding = 'GB18030')
sw2 <- p %>% 
    gsub('\"', '', .) %>% 
    gsub('.*申万二级,(.*),,sw2_hy.*', '\\1', .)

## 一级行业
sw2_main <- strsplit(sw2, '000\\],\\[') %>% 
    unlist() %>% 
    gsub('\\[\\[.*\\]\\],,', '', .) %>% 
    gsub('\\[|\\]|000', '', .) %>% 
    gsub('[,]{1,}', ',', .)
sw2_main <- lapply(1:length(sw2_main), function(i){
    tmp <- sw2_main[i] %>% 
        strsplit(., ',') %>% 
        unlist()
    res <- data.table(industryNameMain = tmp[1],
                      industryIDMain   = paste0(tmp[2], '000'))
}) %>% rbindlist()
sw2_main[, id := substr(industryIDMain, 1, 7)]

## 二级行业
sw2_sub <- strsplit(sw2, ',\\[\\[') %>% 
    unlist() %>% 
    strsplit(., '\\],\\[') %>% 
    unlist() %>% 
    gsub('\\]\\],.*', '', .) %>%
    grep('000', ., value = T, invert = T) %>% 
    grep('sw2\\_', ., value = T) %>% 
    gsub('[,]{1,}', ',', .)
sw2_sub <- lapply(1:length(sw2_sub), function(i){
    tmp <- sw2_sub[i] %>% 
        strsplit(., ',') %>% 
        unlist()
    res <- data.table(industryNameSub = tmp[1],
                      industryIDSub   = tmp[2])
}) %>% rbindlist()
sw2_sub[, id := substr(industryIDSub, 1, 7)]

sw2 <- merge(sw2_main, sw2_sub, by = 'id', all = T)
sw2[, ":="(
    id = NULL,
    industryIDMain = gsub('sw2', 'sw1', industryIDMain)
    )]
sw2[, TradingDay := currTradingDay[1, days]]

mysqlWrite(db = 'china_stocks', tbl = 'sw_industry_class_id',
           data = sw2)
## =============================================================================


## =============================================================================
URL <- 'http://vip.stock.finance.sina.com.cn/quotes_service/api/json_v2.php/Market_Center.getHQNodeData'
pb <- txtProgressBar(min = 1, max = nrow(sw2), style = 1)

dt <- lapply(1:nrow(sw2), function(i){
    # print(i)
    setTxtProgressBar(pb, i)

    if (sw2[i, is.na(industryIDSub)]) {
        id <- sw2[i, gsub('sw1', 'sw2',industryIDMain)]
    } else {
        id <- sw2[i, industryIDSub]
    }

    payload <- list(
        page    = '1'
        ,num    = '1000'
        # ,sort   = 'symbol'
        # ,asc    = '1'
        ,node   = id
        # ,symbol = ''
    )

    r <- GET(URL, query = payload, timeout(5))
    p <- content(r, as = 'text', encoding = 'GB18030') %>% 
        gsub('\"','',.) %>%
        gsub("\\[|\\]", '', .) %>% 
        strsplit(., "\\},\\{") %>% 
        unlist() %>% 
        gsub("\\}|\\{", '', .)

    res <- lapply(1:length(p), function(i){
        tmp <- p[i] %>% 
            strsplit(., ",") %>% 
            unlist()
        res <- sapply(1:length(tmp), function(j){
            u <- tmp[j] %>% 
                strsplit(., ":") %>% 
                unlist()
            v <- paste(paste0('{\"', u[1], '\"'), 
                       paste0('\"', u[2], '\"}'), sep = ':')
            fromJSON(v)
            }) %>% 
            as.data.table()
        }) %>% rbindlist() %>% 
        .[, .(stockID = code, stockName = name,
              industryIDMain = sw2[i, industryIDMain],
              industryNameMain = sw2[i, industryNameMain],
              industryIDSub = sw2[i, industryIDSub],
              industryNameSub = sw2[i, industryNameSub]
              )]
    Sys.sleep(3)
    return(res)
}) %>% rbindlist()

dt[, TradingDay := currTradingDay[1, days]]

mysqlWrite(db = 'china_stocks', tbl = 'industry_class_from_sw2',
           data = dt)
## =============================================================================
