################################################################################
## FromDC2mysql_01_read_data.R
################################################################################

# ## =============================================================================
# readDataFile <- function(xDay) {
#     if ( xDay %in% list.files(paste0(dataPath,'/',yearID)) ) {
#         allDataFile <- list.files(paste(dataPath, yearID, xDay, sep='/')) %>%
#                         .[grep("\\.txt || \\.csv", .)]
#         ## ---------------------------------------------------------------------
#         res <- lapply(1:length(allDataFile), function(i){
#                 tempDataPath <- paste(dataPath, yearID, xDay, allDataFile[i], sep='/')
#                 if (yearID == '2010') {
#                     tempInstrumentID <- gsub('\\.csv','',allDataFile[i])
#                     # suppressWarnings(
#                     #     suppressMessages({
#                     #         tempRes <- read_csv(tempDataPath, locale=locale(encoding='GB18030'),
#                     #                             progress = FALSE) %>% as.data.table()
#                     #     })
#                     # )
#                     if (any(class(try(
#                         tempRes <- suppFunction(fread(tempDataPath, 
#                                                       encoding = 'unknown'))
#                         )) == 'try-error')) {
#                                 tempRes <- suppFunction(read_csv(tempDataPath, 
#                                   locale = locale(encoding='GB18030'),
#                                   progress = FALSE)) %>% as.data.table()
#                     }
#                     tempRes[, InstrumentID := tempInstrumentID]
#                 } else {
#                     tempRes <- myFreadFromDC(tempDataPath)
#                     ## ---------------------------------------------------------
#                     ## 郑商所有时候会抽风，以下代码专治郑商所
#                     ## eg, 2013-05-30 把第二天的数据放在了昨天
#                     ## eg, 2012-09-21
#                     if (length(unique(tempRes$TradingDay)) == 1) {
#                       if (length(unique(tempRes$UpperLimitPrice)) == 2) {
#                         if (nrow(tempRes[UpperLimitPrice == unique(tempRes$UpperLimitPrice)[1]]) >=
#                             nrow(tempRes[UpperLimitPrice == unique(tempRes$UpperLimitPrice)[2]])) {
#                           tempRes <- tempRes[UpperLimitPrice == unique(tempRes$UpperLimitPrice)[1]]
#                         } else {
#                           tempRes <- tempRes[UpperLimitPrice == unique(tempRes$UpperLimitPrice)[2]]
#                         }
#                       }
#                     } else {
#                       if (length(unique(tempRes$TradingDay)) == 2) {
#                         if (nrow(tempRes[TradingDay == unique(tempRes$TradingDay)[1]]) >=
#                             nrow(tempRes[TradingDay == unique(tempRes$TradingDay)[2]])) {
#                           tempRes <- tempRes[TradingDay == unique(tempRes$TradingDay)[1]]
#                         } else {
#                           tempRes <- tempRes[TradingDay == unique(tempRes$TradingDay)[2]]
#                         }
#                       }
#                     }
#                     ## ---------------------------------------------------------
#                 }
#                 if (yearID == '2010') {
#                     if (nrow(tempRes) != 0 & 'V11' %in% colnames(tempRes)) {
#                       tempRes[, ":="(V10 = as.numeric(V10),
#                                      V11 = as.numeric(V11))]
#                       try(tempRes[, V19 := NULL])
#                     } else {
#                       tempRes <- data.table()
#                     }
#                 }
#                 return(tempRes)
#                 }) %>% rbindlist()
#         ## ---------------------------------------------------------------------
#         if (as.numeric(yearID) == 2010) {
#             colnames(res) <- c('TradingDay','Date','UpdateTime',
#                                'LastPrice','OpenPrice','HighestPrice','LowestPrice',
#                                'PreClosePrice',
#                                'Volume','DeltaVolume',
#                                'Turnover','DeltaTurnover',
#                                'OpenInterest','DeltaOpenInterest',
#                                'BidPrice1','BidVolume1',
#                                'AskPrice1','AskVolume1',
#                                'InstrumentID')
#             res[, ':='(
#                 PreClosePrice = NULL,
#                 Date = NULL,
#                 DeltaVolume = NULL,
#                 DeltaTurnover = NULL,
#                 DeltaOpenInterest = NULL,
#                 UpdateTime = paste(sprintf("%09.f", as.numeric(UpdateTime)) %>% substr(.,1,2),
#                                    sprintf("%09.f", as.numeric(UpdateTime)) %>% substr(.,3,4),
#                                    sprintf("%09.f", as.numeric(UpdateTime)) %>% substr(.,5,6),
#                                    sep=':'),
#                 UpdateMillisec = sprintf("%09.f", as.numeric(UpdateTime)) %>% substr(.,7,9),
#                 ClosePrice = 0,
#                 SettlementPrice = 0,
#                 UpperLimitPrice = 0,
#                 LowerLimitPrice = 0,
#                 ## -----------------------------
#                 BidPrice2 = 0, BidVolume2 = 0,
#                 BidPrice3 = 0, BidVolume3 = 0,
#                 BidPrice4 = 0, BidVolume4 = 0,
#                 BidPrice5 = 0, BidVolume5 = 0,
#                 ## -----------------------------
#                 AskPrice2 = 0, AskVolume2 = 0,
#                 AskPrice3 = 0, AskVolume3 = 0,
#                 AskPrice4 = 0, AskVolume4 = 0,
#                 AskPrice5 = 0, AskVolume5 = 0
#                 )]
#             setcolorder(res,
#                 c('TradingDay','UpdateTime','UpdateMillisec','InstrumentID',
#                   'LastPrice','OpenPrice','HighestPrice','LowestPrice','ClosePrice',
#                   'Volume','Turnover','OpenInterest','SettlementPrice',
#                   'UpperLimitPrice','LowerLimitPrice',
#                   'BidPrice1','BidVolume1',
#                   'BidPrice2','BidVolume2',
#                   'BidPrice3','BidVolume3',
#                   'BidPrice4','BidVolume4',
#                   'BidPrice5','BidVolume5',
#                   'AskPrice1','AskVolume1',
#                   'AskPrice2','AskVolume2',
#                   'AskPrice3','AskVolume3',
#                   'AskPrice4','AskVolume4',
#                   'AskPrice5','AskVolume5'
#                   ))
#         }
#         ## ---------------------------------------------------------------------
#     } else {
#         res <- data.table()
#     }
#     ## -------------------------------------------------------------------------
#     return(res)
#     ## -------------------------------------------------------------------------
# }
# ## =============================================================================

dtNight <- readDataFile(dataNightPath)

dtDay <- readDataFile(dataDayPath)

dt <- list(dtNight, dtDay) %>% rbindlist()
#-------------------------------------------------------------------------------
print(paste0("#---------- Data file has been loaded! ---------------------------#"))
#-------------------------------------------------------------------------------
