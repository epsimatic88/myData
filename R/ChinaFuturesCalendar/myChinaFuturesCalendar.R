## =============================================================================
## myChinaFuturesCalendar.R
##
## 生成中国期货交易日
## 1. days  :日盘时间
## 2. nights:夜盘时间
##
## =============================================================================
rm(list = ls())
setwd('/home/fl/myData')

## =============================================================================
## 需要安装的 package: bizdays
pkgs <- c("data.table",'magrittr')

if (length(pkgs[!pkgs %in% installed.packages()]) != 0) {
  sapply(pkgs[!pkgs %in% installed.packages()], install.packages)
}

sapply(pkgs, require, character.only = TRUE)

## -----------------------------------------------------------------------------
## 这里需要做选择
## 对于周末的时间，日盘和夜盘的间隔不应该超过 3 天
## 但是，如果是节假日，有可能超过 3 天，那么夜盘就是 NA 了。
## 这个应该很好理解。
setNights <- function(x) {
    for (i in 1:nrow(x)) {
        if (is.na(x$nights[i])) next

        if( (x$days[i] - x$nights[i]) > 3){
          #-- 如果有休假，则日盘与夜盘差超过 3 天
          x$nights[i] <- NA
        }
    }
    x[, ":="(
        nights = gsub('-','', nights),
        days   = gsub('-','', days))]
    return(x)
}
## =============================================================================

## =============================================================================
## 查询交易所对节假日的安排
## http://www.shfe.com.cn/news/
## =============================================================================


## =============================================================================
## http://www.shfe.com.cn/news/notice/811236812.html
yearID <- 2009
daysInYear <- as.numeric(as.Date(paste0(yearID, '-12-31')) -
                         as.Date(paste0(yearID, '-01-01')))
days <- as.Date(0:daysInYear, origin = paste0(yearID, '-01-01')) %>%
        .[-which(weekdays(.) %in% c("Saturday", "Sunday"))] %>%
        .[-c(which(. >= "2009-01-01" & . <= "2009-01-03"),
             which(. >= "2009-01-25" & . <= "2009-01-31"),
             which(. >= "2009-04-04" & . <= "2009-04-06"),
             which(. >= "2009-05-01" & . <= "2009-05-03"),
             which(. >= "2009-05-28" & . <= "2009-05-30"),
             which(. >= "2009-10-01" & . <= "2009-10-08")
          )]
nights <- NA

calendar2009 <- data.table(nights, days) %>% setNights()
## =============================================================================


## =============================================================================
## http://www.shfe.com.cn/news/notice/911232224.html
yearID <- 2010
daysInYear <- as.numeric(as.Date(paste0(yearID, '-12-31')) -
                         as.Date(paste0(yearID, '-01-01')))
days <- as.Date(0:daysInYear, origin = paste0(yearID, '-01-01')) %>%
        .[-which(weekdays(.) %in% c("Saturday", "Sunday"))] %>%
        .[-c(which(. >= "2010-01-01" & . <= "2010-01-03"),
             which(. >= "2010-02-13" & . <= "2010-02-19"),
             which(. >= "2010-04-03" & . <= "2010-04-05"),
             which(. >= "2010-05-01" & . <= "2010-05-03"),
             which(. >= "2010-06-14" & . <= "2010-06-16"),
             which(. >= "2010-09-22" & . <= "2010-09-24"),
             which(. >= "2010-10-01" & . <= "2010-10-07")
          )]
nights <- NA

calendar2010 <- data.table(nights, days) %>% setNights()
## =============================================================================


## =============================================================================
## http://www.shfe.com.cn/news/notice/11272678.html
yearID <- 2011
daysInYear <- as.numeric(as.Date(paste0(yearID, '-12-31')) -
                         as.Date(paste0(yearID, '-01-01')))
days <- as.Date(0:daysInYear, origin = paste0(yearID, '-01-01')) %>%
        .[-which(weekdays(.) %in% c("Saturday", "Sunday"))] %>%
        .[-c(which(. >= "2011-01-01" & . <= "2011-01-03"),
             which(. >= "2011-02-02" & . <= "2011-02-08"),
             which(. >= "2011-04-03" & . <= "2011-04-05"),
             which(. >= "2011-04-30" & . <= "2011-05-02"),
             which(. >= "2011-06-04" & . <= "2011-06-06"),
             which(. >= "2011-09-10" & . <= "2011-09-12"),
             which(. >= "2011-10-01" & . <= "2011-10-07")
          )]
nights <- NA

calendar2011 <- data.table(nights, days) %>% setNights()
## =============================================================================


## =============================================================================
## http://www.shfe.com.cn/news/notice/111211125.html
yearID <- 2012
daysInYear <- as.numeric(as.Date(paste0(yearID, '-12-31')) -
                         as.Date(paste0(yearID, '-01-01')))
days <- as.Date(0:daysInYear, origin = paste0(yearID, '-01-01')) %>%
        .[-which(weekdays(.) %in% c("Saturday", "Sunday"))] %>%
        .[-c(which(. >= "2012-01-01" & . <= "2012-01-03"),
             which(. >= "2012-01-22" & . <= "2012-01-28"),
             which(. >= "2012-04-02" & . <= "2012-04-04"),
             which(. >= "2012-04-29" & . <= "2012-05-01"),
             which(. >= "2012-06-22" & . <= "2012-06-24"),
             which(. >= "2012-09-30" & . <= "2012-10-07")
          )]
nights <- NA

calendar2012 <- data.table(nights, days) %>% setNights()
## =============================================================================



## =============================================================================
## http://www.shfe.com.cn/news/notice/211216642.html
yearID <- 2013
daysInYear <- as.numeric(as.Date(paste0(yearID, '-12-31')) -
                         as.Date(paste0(yearID, '-01-01')))
days <- as.Date(0:daysInYear, origin = paste0(yearID, '-01-01')) %>%
        .[-which(weekdays(.) %in% c("Saturday", "Sunday"))] %>%
        .[-c(which(. >= "2013-01-01" & . <= "2013-01-03"),
             which(. >= "2013-01-01" & . <= "2013-01-03"),
             which(. >= "2013-02-09" & . <= "2013-02-15"),
             which(. >= "2013-04-04" & . <= "2013-04-06"),
             which(. >= "2013-04-29" & . <= "2013-05-01"),
             which(. >= "2013-06-10" & . <= "2013-06-12"),
             which(. >= "2013-09-19" & . <= "2013-09-21"),
             which(. >= "2013-10-01" & . <= "2013-10-07")
          )]
nights <- c(NA, days[-length(days)]) %>% as.Date(., origin = "1970-01-01")
nights[which(nights < "2013-07-05")] <- NA

calendar2013 <- data.table(nights, days) %>% setNights()
## =============================================================================


## =============================================================================
## http://www.shfe.com.cn/news/notice/211216642.html
yearID <- 2014
daysInYear <- as.numeric(as.Date(paste0(yearID, '-12-31')) -
                         as.Date(paste0(yearID, '-01-01')))
days <- as.Date(0:daysInYear, origin = paste0(yearID, '-01-01')) %>%
        .[-which(weekdays(.) %in% c("Saturday", "Sunday"))] %>%
        .[-c(which(. >= "2014-01-01" & . <= "2014-01-01"),
             which(. >= "2014-01-31" & . <= "2014-02-06"),
             which(. >= "2014-04-05" & . <= "2014-04-07"),
             which(. >= "2014-05-01" & . <= "2014-05-03"),
             which(. >= "2014-05-31" & . <= "2014-06-02"),
             which(. >= "2014-09-06" & . <= "2014-09-08"),
             which(. >= "2014-10-01" & . <= "2014-10-07")
          )]
nights <- c(NA, days[-length(days)]) %>% as.Date(., origin = "1970-01-01")

calendar2014 <- data.table(nights, days) %>% setNights()
## =============================================================================


## =============================================================================
## http://www.shfe.com.cn/news/notice/211216642.html
yearID <- 2014
daysInYear <- as.numeric(as.Date(paste0(yearID, '-12-31')) -
                         as.Date(paste0(yearID, '-01-01')))
days <- as.Date(0:daysInYear, origin = paste0(yearID, '-01-01')) %>%
        .[-which(weekdays(.) %in% c("Saturday", "Sunday"))] %>%
        .[-c(which(. >= "2014-01-01" & . <= "2014-01-01"),
             which(. >= "2014-01-31" & . <= "2014-02-06"),
             which(. >= "2014-04-05" & . <= "2014-04-07"),
             which(. >= "2014-05-01" & . <= "2014-05-03"),
             which(. >= "2014-05-31" & . <= "2014-06-02"),
             which(. >= "2014-09-06" & . <= "2014-09-08"),
             which(. >= "2014-10-01" & . <= "2014-10-07")
          )]
nights <- c(NA, days[-length(days)]) %>% as.Date(., origin = "1970-01-01")

calendar2014 <- data.table(nights, days) %>% setNights()
## =============================================================================


## =============================================================================
## http://www.shfe.com.cn/news/notice/911321768.html
yearID <- 2015
daysInYear <- as.numeric(as.Date(paste0(yearID, '-12-31')) -
                         as.Date(paste0(yearID, '-01-01')))
days <- as.Date(0:daysInYear, origin = paste0(yearID, '-01-01')) %>%
        .[-which(weekdays(.) %in% c("Saturday", "Sunday"))] %>%
        .[-c(which(. >= "2015-01-01" & . <= "2015-01-03"),
             which(. >= "2015-02-18" & . <= "2015-02-24"),
             which(. >= "2015-04-05" & . <= "2015-04-06"),
             which(. >= "2015-05-01" & . <= "2015-05-01"),
             which(. >= "2015-06-20" & . <= "2015-06-22"),
             which(. >= "2015-09-03" & . <= "2015-09-05"),
             which(days>="2015-09-27"&days<="2015-09-27"),
             which(. >= "2015-10-01" & . <= "2015-10-07")
          )]
nights <- c(NA, days[-length(days)]) %>% as.Date(., origin = "1970-01-01")
nights[which(nights == '2015-09-25')] <- NA

calendar2015 <- data.table(nights, days) %>% setNights()
## =============================================================================


## =============================================================================
## http://www.shfe.com.cn/news/notice/911323994.html
yearID <- 2016
daysInYear <- as.numeric(as.Date(paste0(yearID, '-12-31')) -
                         as.Date(paste0(yearID, '-01-01')))
days <- as.Date(0:daysInYear, origin = paste0(yearID, '-01-01')) %>%
        .[-which(weekdays(.) %in% c("Saturday", "Sunday"))] %>%
        .[-c(which(. >= "2016-01-01" & . <= "2016-01-03"),
             which(. >= "2016-02-07" & . <= "2016-02-13"),
             which(. >= "2016-04-02" & . <= "2016-04-04"),
             which(. >= "2016-04-30" & . <= "2016-05-02"),
             which(. >= "2016-06-09" & . <= "2016-06-11"),
             which(. >= "2016-09-15" & . <= "2016-09-17"),
             which(. >= "2016-10-01" & . <= "2016-10-07")
          )]
nights <- c(NA, days[-length(days)]) %>% as.Date(., origin = "1970-01-01")

calendar2016 <- data.table(nights, days) %>% setNights()
## =============================================================================



## =============================================================================
## http://www.shfe.com.cn/news/notice/911326468.html
yearID <- 2017
daysInYear <- as.numeric(as.Date(paste0(yearID, '-12-31')) -
                         as.Date(paste0(yearID, '-01-01')))
days <- as.Date(0:daysInYear, origin = paste0(yearID, '-01-01')) %>%
        .[-which(weekdays(.) %in% c("Saturday", "Sunday"))] %>%
        .[-c(which(. >= "2017-01-01" & . <= "2017-01-02"),
             which(. >= "2017-01-27" & . <= "2017-02-02"),
             which(. >= "2017-04-02" & . <= "2017-04-04"),
             which(. >= "2017-04-29" & . <= "2017-05-01"),
             which(. >= "2017-05-28" & . <= "2017-05-30"),
             which(. >= "2017-10-01" & . <= "2017-10-08"),
             which(. == "2017-12-31")
          )]
nights <- c(NA, days[-length(days)]) %>% as.Date(., origin = "1970-01-01")

calendar2017 <- data.table(nights, days) %>% setNights()
## =============================================================================


## =============================================================================
## http://www.shfe.com.cn/news/notice/911329106.html
yearID <- 2018
daysInYear <- as.numeric(as.Date(paste0(yearID, '-12-31')) -
                           as.Date(paste0(yearID, '-01-01')))
days <- as.Date(0:daysInYear, origin = paste0(yearID, '-01-01')) %>%
  .[-which(weekdays(.) %in% c("Saturday", "Sunday"))] %>%
  .[-c(which(. >= "2018-01-01" & . <= "2018-01-01"),
       which(. >= "2018-02-15" & . <= "2018-02-21"),
       which(. >= "2018-04-05" & . <= "2018-04-07"),
       which(. >= "2018-04-29" & . <= "2018-05-01"),
       which(. >= "2018-06-16" & . <= "2018-06-18"),
       which(. >= "2018-09-22" & . <= "2018-09-24"),
       which(. >= "2018-10-01" & . <= "2018-10-07")
  )]
nights <- c(NA, days[-length(days)]) %>% as.Date(., origin = "1970-01-01")

calendar2018 <- data.table(nights, days) %>% setNights()
## =============================================================================

calendar <- rbind(calendar2009, calendar2010, calendar2011, calendar2012,
                  calendar2013, calendar2014, calendar2015, calendar2016,
                  calendar2017, calendar2018)
fwrite(calendar, './data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv')

## =============================================================================
## 录入 MySQL 数据库
library(RMySQL)
mysql <-   dbConnect(MySQL(),
                     dbname   = 'dev',
                     host     = '192.168.1.166',
                     port     = 3306,
                     user     = 'fl',
                     password = 'abc@123')
dbSendQuery(mysql, "
            CREATE TABLE IF NOT EXISTS dev.ChinaFuturesCalendar(
              nights Date,
              days Date NOT NULL
            )
            ")
dbSendQuery(mysql,"truncate table ChinaFuturesCalendar")
dbWriteTable(mysql, "ChinaFuturesCalendar",
             calendar, row.names=FALSE, append=TRUE)
## =============================================================================

