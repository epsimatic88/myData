################################################################################
## ChinaFuturesInfo2mysql_02_process_Instrument_info.R
## 
## 处理合约信息
## 
## Inputs:
## @sector: 处理合约信息，Instrument_info
## 
## Outputs:
## 
################################################################################


## =============================================================================
## Instrument:合约属性
sector <- 'Instrument'
## =============================================================================


## =============================================================================
for(k in 1:nrow(futuresCalendar)){
  #-------------------------------------------------------------------------------
  temp1 <- allDataFiles[sectorID == sector & requestDay == futuresCalendar[k,nights] &
                            !(requestTime %between% c(8,16))]
  temp2 <- allDataFiles[sectorID == sector & requestDay == futuresCalendar[k,days] &
                            requestTime %between% c(8,16)]
  temp <- rbind(temp1,temp2)

  ## ===========================================================================
  if(nrow(temp) != 0){
    dt <- lapply(1:nrow(temp), function(ii){
      read_csv(temp[ii,dataFile],
               locale = locale(encoding = 'GB18030')) %>%
        as.data.table() %>%
        .[,.(InstrumentID, ExchangeID, ProductID, VolumeMultiple, PriceTick,
             LongMarginRatio, ShortMarginRatio)]
    }) %>% rbindlist() %>%
      .[! duplicated(.[,.SD])] %>%
      .[,":="(TradingDay = futuresCalendar[k,days]
              ## ,Account    = gsub('.*Info\\/','',getwd())                    
              ## 看看是否需要添加 Account
      )]

    setcolorder(dt, c('TradingDay',colnames(dt)[1:(ncol(dt)-1)]))          
    ## 如果添加 Account，记得修改这里为 [1:(ncol(dt)-2)]
    ##--------------------------------------------------------------------------
    
    ## -------------------------------------------------------------------------
    ## 写入数据库
    dbWriteTable(mysql_info, paste0(sector,"_info"), 
                 dt, row.name = FALSE, append = T)
    ## -------------------------------------------------------------------------

    ## -------------------------------------------------------------------------
    ## 同时把数据更新到 VolumeMultiple
    dbWriteTable(mysql_info, 'VolumeMultiple', 
                dt[,.(TradingDay,InstrumentID,VolumeMultiple)]
                , row.name = FALSE, append = T)
    ## -------------------------------------------------------------------------

    ##----------------------------------------------------------------------------
    info <- data.table(TradingDay = futuresCalendar[k,days],
                       Account    = gsub('.*Info\\/','',dataPath),
                       Sector     = sector,
                       Results    = ifelse(nrow(dt) != 0,
                                           paste("[读入数据]:==> Rows:", nrow(dt),"/ Columns:", ncol(dt)),
                                           '没有数据'),
                       Remarks    = NA)
    dbWriteTable(mysql_dev, "info_log", info, row.name = FALSE, append = T)
    ## -------------------------------------------------------------------------
  }else{
    info <- data.table(TradingDay = futuresCalendar[k,days],
                       Account    = gsub('.*Info\\/','',dataPath),
                       Sector     = sector,
                       Results    = '没有数据',
                       Remarks    = NA)
    dbWriteTable(mysql_dev, "info_log", info, row.name = FALSE, append = T)
    ## -------------------------------------------------------------------------
  }
  ## ===========================================================================
}
