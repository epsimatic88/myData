################################################################################
ROOT_PATH <- '/home/fl/myData'
DATA_PATH <- './data/oiRank/data'

setwd(ROOT_PATH)
source('./R/Rconfig/myInit.R')
library(httr)
################################################################################

ChinaFuturesCalendar[, nights := gsub('-', '', nights)]
ChinaFuturesCalendar[, days := gsub('-', '', days)]
ChinaFuturesCalendar <- ChinaFuturesCalendar[days <= format(Sys.Date(), '%Y%m%d')]

allYears <- ChinaFuturesCalendar[, unique(substr(days, 1, 4))]
sapply(allYears, function(i){
    tempDir <- paste0(DATA_PATH, '/DCE/', i)
    if (!dir.exists(tempDir)) dir.create(tempDir, recursive = T)
})

## -----------------------------------------------------------------------------
url <- "http://www.dce.com.cn/publicweb/quotesdata/memberDealPosiQuotes.html"
dceProduct <- data.table(productID  = c('a','b','m','y',
                                        'p','c','cs','jd',
                                        'fb','bb','l','v',
                                        'pp','j','jm','i'),
                         productName = c('豆一','豆二','豆粕','豆油',
                                         '棕榈油','玉米','玉米淀粉','鸡蛋',
                                         '纤维板','胶合板','聚乙烯','聚氯乙烯',
                                         '聚丙烯','焦炭','焦煤','铁矿石')
                         )

headers = c(
            "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
            "Accept-Encoding" = "gzip, deflate",
            "Accept-Language" = "zh-CN,en-US;q=0.8,zh;q=0.6,en;q=0.4,zh-TW;q=0.2",
            "Connection" = "keep-alive",
            "DNT" = "1",
            "Host" = "www.dce.com.cn",
            "Referer" = "http://www.dce.com.cn/publicweb/quotesdata/memberDealPosiQuotes.html",
            "Upgrade-Insecure-Requests" = "1",
            "User-Agent" = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
            )
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## 获取数据内容
fetchData <- function(instrument) {
    postData <- list(memberDealPosiQuotes.variety = gsub('\\d','',instrument),
                    memberDealPosiQuotes.trade_type = "0",
                    year = dceYear,
                    month = dceMonth,
                    day = dceDay,
                    contract.contract_id = instrument,
                    contract.variety_id = gsub('\\d','',instrument),
                    contract = ""
                    )

    destFile <- paste0(DATA_PATH, '/DCE/', dceYear, '/',tradingDay, '_', instrument, '.csv')

    if (file.exists(destFile)) return(NA)

    if (class(try(r <- POST(url, body = postData),
                            add_headers(headers))) == 'try-error') return(NA)
    page <- content(r, 'text')
    resTable <- page %>% 
                read_html(encoding = 'utf8') %>% 
                html_nodes('table') %>% 
                html_table() %>% 
                .[[2]] %>% 
                as.data.table()
    # print(instrument)
    # print(resTable)
    # return(resTable)
    if (nrow(resTable) != 0) {
        fwrite(resTable, file = destFile)
    }
}
## -----------------------------------------------------------------------------


cl <- makeCluster(8, type="FORK")

parSapply(cl, 1:nrow(ChinaFuturesCalendar), function(d){
## =============================================================================
    # tradingDay <- ChinaFuturesCalendar[d, gsub('-', '', days)]
    tradingDay <- ChinaFuturesCalendar[d,days]
    # tradingDay <- '20180109'
    dceYear <- substr(tradingDay, 1, 4)
    dceMonth <- as.character(as.numeric(substr(tradingDay, 5, 6)) - 1)
    dceDay <- substr(tradingDay, 7, 8)
    ## -----------------------------------------------------------------------------

    ## -----------------------------------------------------------------------------
    ## 获取合约代码
    sapply(dceProduct[,productID], function(product){
        # product <- 'a'

        postData <- list(memberDealPosiQuotes.variety = product,
                        memberDealPosiQuotes.trade_type = "0",
                        year = dceYear,
                        month = dceMonth,
                        day = dceDay,
                        contract.contract_id = "all",
                        contract.variety_id = product,
                        contract = ""
                        )

        tryNo <- 0
        resInstrumentNo <- 12
        filesNo <- 0

        while (tryNo < 3 & filesNo < resInstrumentNo) {
            ## ---------------
            tryNo <- tryNo + 1
            ## ---------------
            if (class(try(r <- POST(url, body = postData,
                                    add_headers(headers)))) == 'try-error') next

            page <- content(r, 'text')
            resInstrument <- page %>% 
                        read_html(encoding = 'utf8') %>% 
                        html_nodes('.selBox') %>% 
                        html_text() %>% 
                        .[3] %>% 
                        gsub('\t|\n|\r', '', .) %>%
                        strsplit(., ' ') %>%
                        unlist() %>%
                        .[nchar(.) != 0] %>%
                        .[!grepl("全部",.)]
            if (length(resInstrument) == 0) next
            
            sapply(resInstrument, function(instrument) {
                try(fetchData(instrument))
            })

            ## ---------------------------------------------------------------------
            resInstrumentNo <- length(resInstrument)
            filesNo <- list.files(paste0(DATA_PATH, '/DCE/', dceYear, '/'), 
                                  pattern = 'csv') %>% 
                        .[grepl(tradingDay, .)] %>% 
                        .[grepl(product, .)] %>% 
                        length(.)
            ## ---------------------------------------------------------------------
        }
    })
## =============================================================================
})

stopCluster(cl)
