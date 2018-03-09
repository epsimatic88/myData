## FromDC2mysql_10_read_data.R

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# dt1
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
setwd(paste0("/data/ChinaFuturesTickData/FromDC/",as.numeric(args_input[1])))
data_file_1 <- futures_calendar[k, nights]
if(data_file_1 %in% list.files()){
  setwd(paste0("/data/ChinaFuturesTickData/FromDC/",as.numeric(args_input[1]), "/",data_file_1))
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  all_data_files <- list.files() %>%
    .[grep("\\.txt || \\.csv", .)] %>%
    .[grep("^[^(SPD || IPS)]",.)] %>%
    .[grep("[^efp]\\.(txt || csv)",.)]
  #---------------------------------------------------------------------------
  if(length(all_data_files) != 0){
    dt1 <- lapply(1:length(all_data_files), function(i){
      #-------------------------------------------------------------------------------
      myFreadFromDC(all_data_files[i])
    }) %>% rbindlist()
  }else{
    dt1 <- data.table()
  }
}else{
  dt1 <- data.table()
}
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
##
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# dt2
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
setwd(paste0("/data/ChinaFuturesTickData/FromDC/",as.numeric(args_input[1])))
data_file_2 <- futures_calendar[k, days]
if(data_file_2 %in% list.files()){
  setwd(paste0("/data/ChinaFuturesTickData/FromDC/",as.numeric(args_input[1]), "/",data_file_2))
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  all_data_files <- list.files() %>%
    .[grep("\\.txt || \\.csv", .)] %>%
    .[grep("^[^(SPD || IPS)]",.)] %>%
    .[grep("[^efp]\\.(txt || csv)",.)]
  #---------------------------------------------------------------------------
  if(length(all_data_files) != 0){
    dt2 <- lapply(1:length(all_data_files), function(i){
      #-------------------------------------------------------------------------------
      myFreadFromDC(all_data_files[i])
    }) %>% rbindlist()
  }else{
    dt2 <- data.table()
  }
}else{
  dt2 <- data.table()
}
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
##
the_data_file <- paste(data_file_1, data_file_2, sep = " ==> ")
##
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

################################################################################
print(paste(data_file_1, "==>", data_file_2,
            ":==> Data File is Initiated at", Sys.time()))
#-----------------------------------------------------------------------------
dt <- list(dt1, dt2) %>% rbindlist() %>%
  .[Turnover == 0 | is.na(Turnover), Turnover := round(Volume * AveragePrice, 0)] %>%
  .[, AveragePrice := NULL]
#-----------------------------------------------------------------------------
print(paste0("#---------- Data file has been loaded! ---------------------------#"))
#-----------------------------------------------------------------------------
################################################################################
