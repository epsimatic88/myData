################################################################################
##! mysql2mysql.R
##
##  主要功能
##  从数据库转移数据到另外一个数据库
## 
##  
## Author: fl@hicloud-investment.com
## CreateDate: 2017-07-20
################################################################################

################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("mysql2mysql.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
  #source('./R/Rconfig/myFread.R')
  #source('./R/Rconfig/myDay.R')
  #source('./R/Rconfig/myBreakTime.R')
  #source('./R/Rconfig/dt2DailyBar.R')
  #source('./R/Rconfig/dt2MinuteBar.R')
})
################################################################################

mysql <- mysqlFetch('lhg_trade',
                    host = "gczhang.imwork.net",
                    port = 24572)

fl_open_t <- dbGetQuery(mysql, "
            SELECT * FROM fl_open_t
") %>% as.data.table()

fl_open_t_2 <- dbGetQuery(mysql, "
            SELECT * FROM fl_open_t_2
") %>% as.data.table()

## =============================================================================
## 写入本地数据库
mysql <- mysqlFetch('lhg_trade', host = '192.168.1.103')
# dbSendQuery(mysql, "truncate table fl_open_t")
dbWriteTable(mysql, 'fl_open_t',
             fl_open_t, row.name=FALSE, overwrite=TRUE)
dbWriteTable(mysql, 'fl_open_t_2',
             fl_open_t_2, row.name=FALSE, overwrite=TRUE)             
## =============================================================================
