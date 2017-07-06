## =============================================================================
## chinaFuturesCalendar_2017.R
##
## 生成中国期货交易日
## 年度： 2017
## 1. 日盘时间
## 2. 夜盘时间
##
## Input:
## 根据交易所每年末（12月底）公布的次年交易安排
##
## Output
## ChinaFuturesCalendar_2011_2017.csv
## =============================================================================

rm(list = ls())
setwd('/home/fl/myData')
## =============================================================================
## 需要安装的 package: bizdays
pkgs <- c("data.table", 'bizdays', 'magrittr')

if(length(pkgs[!pkgs %in% installed.packages()]) != 0){
  sapply(pkgs[!pkgs %in% installed.packages()], install.packages)
}

sapply(pkgs, require, character.only = TRUE)
## =============================================================================


## =============================================================================
## 2.时间设定
startDate <- "2017-01-01"
endDate <- "2017-12-31"
## =============================================================================


## =============================================================================
## 3.休假日安排
## 需要到交易所去查询，比如：
# http://www.sse.com.cn/disclosure/announcement/general/c/c_20161222_4218613.shtml
futuresHolidays <- c("2017-01-01", "2017-01-02", "2017-01-27", "2017-01-28", "2017-01-29",
              "2017-01-30", "2017-01-31", "2017-02-01", "2017-02-02", "2017-04-02",
              "2017-04-03", "2017-04-04", "2017-04-29", "2017-04-30", "2017-05-01",
              "2017-05-28", "2017-05-29", "2017-05-30", "2017-10-01", "2017-10-02",
              "2017-10-03", "2017-10-04", "2017-10-05", "2017-10-06", "2017-10-07",
              "2017-12-31")
## =============================================================================


## =============================================================================
## 4. 开始建立交易日
##
## 4.1
## 建立 bizdays::Calendar 对象
futuresCalendar <- bizdays::Calendar(holidays = futuresHolidays, weekdays=c('sunday', 'saturday'))

## 日盘交易日期
days <- bizseq(startDate, endDate, futuresCalendar)

## 夜盘交易日期
## 正好与日盘错开一个
nights = c(NA, days[-length(days)]) %>% as.Date(., origin = "1970-01-01")

ChinaFuturesCalendar_2017 <- data.table(nights,days)

## -----------------------------------------------------------------------------
## 4.2
## 这里需要做选择
## 对于周末的时间，日盘和夜盘的间隔不应该超过 3 天
## 但是，如果是节假日，有可能超过 3 天，那么夜盘就是 NA 了。
## 这个应该很好理解。
for(i in 2:nrow(chinaFutures2017)){
  if( (ChinaFuturesCalendar_2017$days[i] - ChinaFuturesCalendar_2017$nights[i]) > 3){
    #-- 如果有休假，则日盘与夜盘差超过 3 天
    ChinaFuturesCalendar_2017$nights[i] <- NA
  }
}
## -----------------------------------------------------------------------------

## 4.3
## 统一作为字符串，方便与原来的数据进行拼接
ChinaFuturesCalendar_2017[,":="(
  nights = as.character(nights) %>% gsub('-','',.),
  days   = as.character(days) %>% gsub('-','',.)
)]
## =============================================================================


## =============================================================================
## 5.读取往年的数据
## 进行拼接
ChinaFuturesCalendar_2011_2016 <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar_2011_2016.csv") %>%
  as.data.table() %>%
  .[, ":="(
    nights = as.character(nights),
    days   = as.character(days)
  )]
## =============================================================================


## =============================================================================
##　６．合成新的交易日
##　并保存
ChinaFuturesCalendar_2011_2017 <- rbind(ChinaFuturesCalendar_2011_2016,
                              ChinaFuturesCalendar_2017)
fwrite(ChinaFuturesCalendar_2011_2017,
      "./data/ChinaFuturesCalendar/ChinaFuturesCalendar_2011_2017.csv")
## =============================================================================


## =============================================================================
## 7. 写入数据库
## 并修改时间格式为　date
mysql <- dbConnect(MySQL(), dbname = "dev", host="127.0.0.1",
                   user = "fl", password = "abc@123")
dbSendQuery(mysql,'truncate table ChinaFuturesCalendar;')

dbWriteTable(mysql,
             'ChinaFuturesCalendar',
             ChinaFuturesCalendar_2011_2017, row.name=FALSE, overwrite = T)

dbSendQuery(mysql, "alter table ChinaFuturesCalendar modify column nights date;")
dbSendQuery(mysql, "alter table ChinaFuturesCalendar modify column days date NOT NULL;")
## =============================================================================
