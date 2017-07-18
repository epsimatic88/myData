################################################################################
## oiRank2mysql_04_data_mysql.R
## 
## Author: fl@hicloud-investment.com
## CreateDate: 2017-01-16
################################################################################

if (includeHistory) {
    ## =========================================================================    
    ## 如果是做历史的数据
    ## 
    ## 读取所有的数据文件
    ## -------------------------------------------------------------------------
    allDataFiles <- list.files(dataPath, pattern = "^(positionRank)") %>% 
        paste(dataPath, ., sep = '/')
    cl <- makeCluster(round(detectCores()/3), type = "FORK")
    dt <- parLapply(cl, allDataFiles, function(i){
      tempDT <- read_csv(i, locale = locale(encoding = "GB18030")) %>%
        as.data.table()
    }) %>% rbindlist()
    stopCluster(cl)
    setnames(dt,'ContractID','InstrumentID')
    #---------------------------------------------------------------------------

    #---------------------------------------------------------------------------
    mysql <- mysqlFetch('china_futures_bar')
    dbWriteTable(mysql,'oiRank', dt, row.name = FALSE, append = TRUE)
    #---------------------------------------------------------------------------
    ## =========================================================================
}else{
    ## =========================================================================    
    ## 如果是每日更新数据
    ## 
}









