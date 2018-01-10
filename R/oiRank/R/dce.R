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

    if (class(try(r <- POST(url, body = postData))) == 'try-error') return(NA)
    page <- content(r, 'text')
    resTable <- page %>% 
                read_html(encoding = 'utf8') %>% 
                html_nodes('table') %>% 
                html_table() %>% 
                .[[2]] %>% 
                as.data.table()
    print(instrument)
    print(resTable)
    # return(resTable)
    if (nrow(resTable) != 0) {
        fwrite(resTable, file = destFile)
    }
}
## -----------------------------------------------------------------------------


for (d in 1:nrow(ChinaFuturesCalendar) ){
## =============================================================================
    # tradingDay <- ChinaFuturesCalendar[d, gsub('-', '', days)]
    tradingDay <- ChinaFuturesCalendar[d,days]
    # tradingDay <- '20180109'
    dceYear <- substr(tradingDay, 1, 4)
    dceMonth <- as.character(as.numeric(substr(tradingDay, 5, 6)) - 1)
    dceDay <- substr(tradingDay, 7, 8)
    ## -----------------------------------------------------------------------------

    # mysql <- mysqlFetch('china_futures_bar')
    # allInstrumentNo <- dbGetQuery(mysql, paste("
    #     select distinct InstrumentID
    #     from minute
    #     where tradingday = ", tradingDay,
    #     "and (volume != 0 or closeopeninterest != 0)")) %>% as.data.table() %>%
    #   .[,":="(productID = gsub("[0-9]","",InstrumentID))] %>%
    #   merge(.,dceProduct, by = 'productID')
    # ## ====================================
    # dbDisconnect(mysql)
    # ## ====================================

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
        # allNo <- ifelse(nrow(allInstrumentNo) == 0, 0,
        #                allInstrumentNo[productID == product] %>% nrow())


        # while (tryNo < 10 & filesNo < max(resInstrumentNo, allNo)) {
        while (tryNo < 10 & filesNo < resInstrumentNo) {
            ## ---------------
            tryNo <- tryNo + 1
            ## ---------------
            if (class(try(r <- POST(url, body = postData))) == 'try-error') next

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
                sapply(resInstrument, try(fetchData))

            ## ---------------------------------------------------------------------
            resInstrumentNo <- length(resInstrument)
            filesNo <- list.files(paste0(DATA_PATH, '/DCE/', dceYear, '/'), pattern = 'csv') %>% 
                        .[grepl(tradingDay, .)] %>% 
                        .[grepl(product, .)] %>% 
                        length(.)
            ## ---------------------------------------------------------------------
        }
    })
## =============================================================================
}
