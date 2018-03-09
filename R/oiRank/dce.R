################################################################################
## dce.R
##
## 从　大商所 下载 oiRank 持仓排名数据
##
## Author   : fl@hicloud-investment.com
## Date     : 2018-10-17
##
################################################################################

################################################################################
ROOT_PATH <- '/home/fl/myData'
SAVE_PATH <- './data/oiRank/data'

setwd(ROOT_PATH)
source('./R/Rconfig/myInit.R')
library(httr)

allYears <- ChinaFuturesCalendar[, unique(substr(days, 1, 4))]
sapply(allYears, function(i){
    tempDir <- paste0(SAVE_PATH, '/DCE/', i)
    if (!dir.exists(tempDir)) dir.create(tempDir, recursive = T)
})
ChinaFuturesCalendar <- ChinaFuturesCalendar[days <= format(Sys.Date(), '%Y-%m-%d')]
################################################################################

## =============================================================================
# d <- 2199
# tradingDay <- ChinaFuturesCalendar[d, gsub('-','',days)]

fetchDCE <- function(tradingDay) {
    ## -------------------------------------------------------------------------
    ## 计算日期，传入参数
    tradingDay <- gsub('-','',tradingDay)
    dceYear <- substr(tradingDay, 1, 4)
    dceMonth <- as.character(as.numeric(substr(tradingDay, 5, 6)) - 1)
    dceDay <- substr(tradingDay, 7, 8)
    DATA_PATH <- paste0(SAVE_PATH, '/DCE/', dceYear, '/', tradingDay)
    if (file.exists(paste0(DATA_PATH, '.csv'))) {
        print('文件已经下载')
        return(fread(paste0(DATA_PATH, '.csv')))
    }
    ## -------------------------------------------------------------------------

    tryNo <- 0
    ## -------------------------------------------------------------------------
    while (!file.exists(paste0(DATA_PATH, '.zip')) & tryNo < 10) {
        payload <- list(
            year                            = dceYear,       ##　年度
            month                           = dceMonth,　　　　　　## 月份，从 0 开始计算
            day                             = dceDay,        ## 日期
            batchExportFlag                 = "batch"        ## 下载模式
            )

        url <- "http://www.dce.com.cn/publicweb/quotesdata/exportMemberDealPosiQuotesBatchData.html"
        r <- POST(url, body = payload)

        if (r$status_code == '200' & grepl('DCE',r$headers['content-disposition'])) {
            destFile <- paste0(DATA_PATH, '.zip')
            writeBin(content(r, 'raw'), destFile)
            break
        } else {
            print(paste(tradingDay, "数据获取失败"))
            Sys.sleep(3)
        }
    }
    ## -------------------------------------------------------------------------

    ## -------------------------------------------------------------------------
    ## zip 解压可能有问题，会出现中文乱码
    ## 需要使用参数  -O cp936
    tarCommand <- paste('unzip -oO cp936',
                      paste0(destFile),
                      '-d', DATA_PATH)
    suppressWarnings({
        suppressMessages({
            try(
                system(tarCommand, show.output.on.console = FALSE)
                )
        })
    })
    ## -------------------------------------------------------------------------

    ## =========================================================================
    ## 清理数据
    dataFiles <- list.files(DATA_PATH, pattern = '\\.txt')

    dt <- lapply(dataFiles, function(f) {
        # print(f)
        tempFile <-paste(DATA_PATH, f, sep = '/')

        ## 先把数据读进来
        if (class(try(
                    data <- readLines(tempFile) %>%
                        .[nchar(.) != 0]
                    , silent = TRUE,
                    outFile = getOption("try.outFile", default = stdout()))) == 'try-error') {
            df <- suppressMessages({
                    readr::read_tsv(tempFile, locale = locale(encoding = 'GB18030')) %>%
                                    as.data.table()
                    })
            colnames(df) <- c("X1")
            df <- df[nchar(X1) != 0]
            data <- c()
            for (i in 1:nrow(df)) {
                data[i] <- df[i,X1] %>% gsub(' ', '\t', .)
            }
        }

        ##　获取合约代码
        id <- data[grep('合约代码', data)] %>%
            strsplit(., "\\t") %>%
            unlist() %>%
            .[nchar(.) != 0] %>%
            .[!grepl('Date',.)] %>%
            gsub('合约代码：','',.)
        data <- data[!grepl('交易所|期货公司会员|合约代码', data)]

        ## 用于切分表格
        tbl <- grep('名次|总计', data)

        res <- lapply(seq(1, length(tbl), by = 2), function(k) {
            k1 <- k
            k2 <- k+1
            temp <- data[tbl[k1]:tbl[k2]]
            ## -------------------------------------------------
            ## 只有两个，包括 名次和总计
            ## 说明没有数据
            if (length(temp) == 2) return(data.table())
            ## -------------------------------------------------
            classID <- strsplit(temp[1], '\\t') %>% unlist() %>%
                        .[nchar(.) != 0] %>%
                        .[3]
            if (classID == "成交量") {
                classID <- 'turnover'
            } else {
                if (classID == "持买单量") {
                    classID <- 'long'
                } else {
                    classID <- 'short'
                }
            }
            ## -------------------------------------------------
            temp <- temp[!grepl('名次|总计',temp)]

            res <- lapply(1:length(temp), function(j){
                x <- temp[j] %>% strsplit(., '\\t') %>% unlist() %>% .[nchar(.) != 0]
                data.table(Rank        = x[1],
                           BrokerID    = x[2],
                           ClassID     = classID,
                           Volume      = x[3],
                           DeltaVolume = x[4])
            }) %>% rbindlist()
        }) %>% rbindlist()
        if (nrow(res) != 0) {
            res[, ":="(TradingDay = tradingDay,
                      InstrumentID = id,
                      Volume = gsub(',', '', Volume) %>% as.numeric(),
                      DeltaVolume = gsub(',', '', DeltaVolume) %>% as.numeric())]
        }
        return(res)
    }) %>% rbindlist()
    dt[, ":="(Volume = gsub(',', '', Volume) %>% as.numeric(),
              DeltaVolume = gsub(',', '', DeltaVolume) %>% as.numeric())]
    dt <- dt[, .(TradingDay, InstrumentID, Rank, BrokerID,
                 ClassID, Volume, DeltaVolume)]
    ## ------------------------------------
    ## 删除解压后的文件
    rmCommand <- paste("rm -rf", DATA_PATH)
    system(rmCommand)
    destFile <- paste0(DATA_PATH, '.csv')
    fwrite(dt, destFile)
    return(dt)
    ## ------------------------------------
}

# d <- 1
# tradingDay <- ChinaFuturesCalendar[d, gsub('-','',days)]
# dt <- fetchDCE(tradingDay)

tradingDay <- currTradingDay[, gsub('-', '', days)]
dt <- fetchDCE(tradingDay)

## =============================================================================
# pb <- txtProgressBar(min = 1, max = 100, style = 3)
# for (i in 1:100) {
#     setTxtProgressBar(pb, i)
#     try(fetchDCE(ChinaFuturesCalendar[i, days]))
# }

# cl <- makeCluster(8, type = "FORK")
# parSapply(cl, ChinaFuturesCalendar[, days], fetchDCE)
# stopCluster(cl)
## =============================================================================

## =============================================================================
colnames(dt) <- c('TradingDay', 'InstrumentID', 'Rank', 'BrokerID', 'ClassID',
                   'Amount', 'DiffAmount')
dt[ClassID == 'turnover', ClassID := 'Turnover']
dt[ClassID == 'short', ClassID := 'shortPos']
dt[ClassID == 'long', ClassID := 'longPos']

mysql <- mysqlFetch('china_futures_bar')
dbWriteTable(mysql, 'oiRank', dt, row.names = F, append = T)
dbDisconnect(mysql)
## =============================================================================
