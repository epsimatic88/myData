################################################################################
## ChinaFuturesInfo2mysql_01_read_data.R
## 
## 读取数据文件
## 
## Inputs:
## @dataPath
## 
## Outputs:
## @allDataFiles
## @futuresCalendar
################################################################################

## =============================================================================
## 获取所有的数据文件
## allDataFiles
## -----------------------------------------------------------------------------
allDataFiles <- list.files(dataPath) %>%
  #  .[grep(paste0("^",temp,'\\.'),.)] %>%
  data.table(dataFile = .) %>%
  .[,':='(
    sectorID = gsub('([[:alpha:]]+)\\.([0-9]+)\\.([[:alpha:]]+)', '\\1', dataFile),
    requestDay = gsub('([[:alpha:]]+)\\.([0-9]+)\\.([[:alpha:]]+)', '\\2', dataFile) %>% substr(.,1,8),
    requestTime = gsub('([[:alpha:]]+)\\.([0-9]+)\\.([[:alpha:]]+)', '\\2', dataFile) %>%
      substr(.,9,10) %>% as.numeric()
  )]
setkey(allDataFiles,sectorID,requestDay,requestTime)
allDataFiles[, dataFile := paste(dataPath, dataFile, sep = '/')]

## -----------------------------------------------------------------------------
## 计算
## 起始日期
## 最后日期
## 
startDay <- allDataFiles[-which(requestDay == min(requestDay))] %>%
  .[,min(requestDay)]
lastDay <- format(Sys.Date(), "%Y%m%d")
## =============================================================================


## =============================================================================
## 一天处理两次：夜盘一次，日盘一次
## -----------------------------------------------------------------------------
if(as.numeric(format(Sys.time(),'%H')) %between% c(8,18)){
  ## ------ 日盘一次 ------- ##
  ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar_2011_2017.csv") %>%
    .[days %between% c(startDay,lastDay)]
}else{
  ## ------ 夜盘一次 ------- ##
  ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar_2011_2017.csv") %>%
    .[nights %between% c(startDay,lastDay)]
}
## -----------------------------------------------------------------------------
if(include_history){
  ## ----- 包含历史的数据
  futuresCalendar <- ChinaFuturesCalendar
}else{
  ## ----- 不包含历史的数据，只录入最新的数据
  futuresCalendar <- ChinaFuturesCalendar[.N]
}

# guess_encoding(allDataFiles[1, paste0(dataPath,'/',dataFile)])
################################################################################
mysql_info <- mysqlFetch('china_futures_info')
mysql_dev  <- mysqlFetch('dev')

