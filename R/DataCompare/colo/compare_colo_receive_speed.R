################################################################################
##! compare_colo_receive_speed.R
##
## 用于对比 Colo 接受 ctp 数据的快慢
##
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-01-16
## UpdateDate: 2017-01-16
################################################################################
#
################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
source('/home/fl/William/Codes/Rsettings/myInitial.R')
source('/home/fl/William/Codes/Rsettings/myDay.R')

library(zoo)
library(scales)
library(lubridate)
library(RcppRoll)

colo <- "Colo1"
ctp  <- 'ctp1'
id_code <- "cu1703" # colo1 ctp1, colo5 ctp1
# id_code <- "jm1705" # colo5 ctp2
setwd(paste0("/data/ChinaFuturesTickData/",colo))

comp_schedule <- CJ(comp_date = paste0("2017010", 5:6),
                 comp_time = c("day", "night"))
################################################################################

myFread <- function(x, id = id_code){
  temp <- strsplit(x,"\\.") %>% unlist() %>% .[2] %>% substr(.,9,10) %>% as.numeric()
  source('/home/fl/William/Codes/myDay.R')

  if( temp %between% c(9, 21) ){##---- 日盘 ----------------##
    myDay <- myDay[trading_period >= "09:00:00" &
                     trading_period <= "15:15:00"]
  }else{##------------------------------------------------------------ 夜盘 ----------------##
    myDay <- myDay[(trading_period >= "00:00:00" &
                      trading_period <= "02:30:00") |
                     (trading_period >= "21:00:00" &
                        trading_period <= "24:00:00")
                   ]
  }



  dt <- x %>%
    fread(., showProgress = TRUE, fill=TRUE, blank.lines.skip = TRUE,
          select = c("Timestamp", "TradingDay",
                     "InstrumentID", "UpdateTime",
                     "UpdateMillisec")) %>%
    .[grep("^[0-9]{8}:[0-9]{2}:[0-9]{2}:[0-9]{2}:[0-9]{6}$", Timestamp)] %>%
    .[InstrumentID == id] %>%
    .[UpdateTime %in% myDay$trading_period | is.na(UpdateTime)]
  #-------------------------------------------------------------------------------
  temp <- dt$Timestamp
  v1 <- substr(temp,10,11) %>% as.numeric() * 3600
  v1[v1 > 18*3600] <- (v1[v1 > 18*3600] - 86400)
  v2 <- substr(temp,13,14) %>% as.numeric() * 60
  v3 <- substr(temp,16,17) %>% as.numeric() * 1
  v4 <- substr(temp,19,24) %>% as.numeric() / 1000000
  v <- v1 + v2 + v3 + v4
  dt[, NumericRecvTime := v]

  #-------------------------------------------------------------------------------
  temp <- dt$UpdateTime
  v1 <- substr(temp,1,2) %>% as.numeric() * 3600
  v1[v1 > 18*3600] <- (v1[v1 > 18*3600] - 86400)
  v2 <- substr(temp,4,5) %>% as.numeric() * 60
  v3 <- substr(temp,7,8) %>% as.numeric() * 1
  v4 <- dt$UpdateMillisec  %>% as.numeric() / 1000
  v <- v1 + v2 + v3 + v4
  dt[, NumericExchTime := v]

  #-------------------------------------------------------------------------------
  dt <- dt[abs(NumericRecvTime - NumericExchTime) <= 1*60]
  dt[, diff_time := NumericRecvTime - NumericExchTime]
  return(dt)
}

comp_hist <- function(comp_date, comp_time,ctp_from, showP = FALSE,
                      lowerQ = 0.005,upperQ = 0.995){

  dt_ctp <- list.files() %>% .[grep(paste0("^(",ctp_from,")","\\."),.)] %>%
    .[grep(comp_date,.)]
  temp <- strsplit(dt_ctp,"\\.") %>% unlist() %>% .[c(2,5)] %>% substr(., 9, 10) %>% as.numeric()
  if(comp_time == "day"){
    dt_ctp <- dt_ctp[!(is.na(temp)) & (temp %between% c(9, 21))]  ##------------- 在 c(9,18) ----------##
  }else{
    dt_ctp <- dt_ctp[!(is.na(temp)) & !(temp %between% c(9, 21))]  ##------------- 在 c(9,18) ----------##
  }

  dt_ctp <- dt_ctp %>% myFread()

  ##------------------------------------------------------------------------------
  dt_md  <- list.files() %>% .[grep(paste0("^(",
                                           ifelse(ctp_from == 'ctp1','ctpmdprod1)',"ctpmdprod2)"),
                                           "\\."),.)] %>%
    .[grep(comp_date,.)]
  temp <- strsplit(dt_md,"\\.") %>% unlist() %>% .[c(2,5)] %>% substr(., 9, 10) %>% as.numeric()
  if(comp_time == "day"){
    dt_md <- dt_md[!(is.na(temp)) & (temp %between% c(9, 21))]  ##------------- 在 c(9,18) ----------##
  }else{
    dt_md <- dt_md[!(is.na(temp)) & !(temp %between% c(9, 21))]  ##------------- 在 c(9,18) ----------##
  }

  dt_md <- dt_md %>% myFread()

  dt <- dt_ctp[dt_md, on = .(NumericExchTime)] %>%
    .[!is.na(Timestamp)] %>%
    .[, diff_ctp_md := NumericRecvTime - i.NumericRecvTime]

  p <- ggplot(dt[diff_ctp_md %between% c(quantile(diff_ctp_md,lowerQ),
                                         quantile(diff_ctp_md,upperQ))],
              aes(diff_ctp_md)) +
    geom_histogram(alpha = 0.5, binwidth = .0000005, fill = 'steelblue2')+
    geom_vline(xintercept = 0, color = 'hotpink', linetype = 'dashed',
               line) +
    scale_x_continuous(labels=comma) +
    ggtitle(paste("Histogram Plot of diff_time:==>",colo,ctp,":==>",comp_date,":",
                  comp_time)
    ) +
    labs(x = "Difference of NumericRecvTime between <ctp> and <mdprod>")

  if(showP == TRUE) p

}

################################################################################
for(i in 1:nrow(comp_schedule )){
  print(i)
  pdf(paste0("/home/fl/William/Files/comp_hist/",
                     paste0(colo,"_",ctp,"_",comp_schedule[i,comp_date],comp_schedule[i,comp_time]),
                     '.pdf')
      ,width = 16, height = 9
      )
  print(
    comp_hist(comp_date = comp_schedule[i,comp_date],
            comp_time = comp_schedule[i,comp_time],
            ctp_from = ctp)
  )

  dev.off()
}

########################################################################################
comp_schedule[i,comp_date := '20170105']
comp_schedule[i,comp_time := 'day']

 pdf(paste0("/home/fl/William/Files/comp_hist/",
                     paste0(colo,"_",ctp,"_",comp_schedule[i,comp_date],"_",comp_schedule[i,comp_time]),
                     '.pdf')
      ,width = 16, height = 9
      )
  print(
    comp_hist(comp_date = comp_schedule[i,comp_date],
            comp_time = comp_schedule[i,comp_time],
            ctp_from = ctp, showP = T,lowerQ = 0.005, upperQ = 0.995)
  )

  dev.off()


########################################################################################
a <- dt_ctp
b <- dt_md
u <- a[b, on = .(NumericExchTime)] %>%
  .[!is.na(Timestamp)] %>%
  .[, diff_ctp_md := NumericRecvTime - i.NumericRecvTime]

hist(u$diff_ctp_md) #越小越好
options(digits = 6)

library(scales)
ggplot(u[diff_ctp_md %between% c(quantile(diff_ctp_md,.001),quantile(diff_ctp_md,.999))],
       aes(diff_ctp_md)) +
  geom_histogram(alpha = 0.5, binwidth = .0000005, fill = 'steelblue2')+
  geom_vline(xintercept = 0, color = 'hotpink', linetype = 'dashed') +
  scale_x_continuous(labels=comma)


####################

if(0){
  if(nrow(dt_ctp) >= nrow(dt_md)){
    temp <- dt_ctp[UpdateTime %in% dt_md$UpdateTime]
    dt   <- data.table(ctp = temp$diff_time,
                       md  = dt_md$diff_time)
  }else{
    temp <- dt_md[UpdateTime %in% dt_ctp$UpdateTime]
    dt   <- data.table(ctp = dt_ctp$diff_time,
                       mdprod  = temp$diff_time)
  }


  dt <- dt %>%
    gather(., key, value) %>%
    as.data.table()

  p <- ggplot(dt, aes(value, fill = key, alpha = .2)) +
    geom_histogram(alpha = 0.4, binwidth = .005
                   ,position = "identity") +
    scale_fill_manual(values=c("hotpink", "steelblue")) +
    ggtitle(paste("Histogram Plot of diff_time:==>",colo,ctp,":==>",comp_date,":",comp_time
                  ,"\n NumericRecvTime - NumericExchTime"))
}


plot(dt[diff_ctp_md %between% c(quantile(diff_ctp_md,lowerQ),
                                quantile(diff_ctp_md,upperQ)),diff_ctp_md],
     xaxt = 'n', col = 'steelblue', type = 'p')
axis(1, at = seq(1,nrow(dt), by = 1500),
     labels = dt[seq(1,nrow(dt), by = 1500),UpdateTime])
abline(h = 0, col = 'hotpink', lwd = 3, lty = 'dashed')

