################################################################################
## ChinaFuturesInfo2mysql_03_process_CommissionRate_info.R
## 
## 读取数据文件
## 
## Inputs:
## @sector
## 
## Outputs:
## 
################################################################################


## =============================================================================
## InstrumentCommissionRate: 手续费
sector <- 'CommissionRate'
## =============================================================================


for(k in 1:nrow(futuresCalendar)){
  #-------------------------------------------------------------------------------
  temp <- allDataFiles[sectorID == paste0('Instrument', sector) &
                           requestDay == futuresCalendar[k,days]]

  ## ===========================================================================
  if(nrow(temp) != 0){
    dt <- lapply(1:nrow(temp), function(ii){
      read_csv(temp[ii,dataFile],
               locale = locale(encoding = 'GB18030')) %>%
        as.data.table() %>%
        .[,.(InstrumentID, OpenRatioByMoney, OpenRatioByVolume, CloseRatioByMoney
             ,CloseRatioByVolume, CloseTodayRatioByMoney, CloseTodayRatioByVolume)]
    }) %>% rbindlist() %>%
      .[! duplicated(.[,.SD])] %>%
      .[,":="(TradingDay = futuresCalendar[k,days],
              Account    = gsub('.*Info\\/','',dataPath))]

    setcolorder(dt, c('TradingDay','Account', colnames(dt)[1:(ncol(dt)-2)]))
    ##----------------------------------------------------------------------------
    dbWriteTable(mysql_info, paste0(sector,"_info"), 
                dt, row.name=FALSE, append = T)

    ##----------------------------------------------------------------------------
    info <- data.table(TradingDay = futuresCalendar[k,days],
                       Account    = gsub('.*Info\\/','',dataPath),
                       Sector     = sector,
                       Results    = ifelse(nrow(dt) != 0,
                                           paste("[读入数据]:==> Rows:", nrow(dt),"/ Columns:", ncol(dt)),
                                           '没有数据'),
                       Remarks    = NA)
    ##----------------------------------------------------------------------------
    dbWriteTable(mysql_dev, "info_log", info, row.name=FALSE, append = T)
    #-------------------------------------------------------------------------------
  }else{
    info <- data.table(TradingDay = futuresCalendar[k,days],
                       Account    = gsub('.*Info\\/','',dataPath),
                       Sector     = sector,
                       Results    = '没有数据',
                       Remarks    = NA)
    ##----------------------------------------------------------------------------
    dbWriteTable(mysql_dev, "info_log", info, row.name=FALSE, append = T)
  }
  ## ===========================================================================
}
