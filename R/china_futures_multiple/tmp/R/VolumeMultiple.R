################################################################################
## VolumeMultiple.R
## 用于计算 china_futures 的合约乘数。
## 
## Author: fl@hicloud-investment.com
## CreateDate: 2017-10-23
################################################################################


rm(list = ls())
logMainScript <- c("VolumeMultiple.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})


################################################################################


# ------------------------------------------------------------------------------
## 从数据库下载分钟数据，用于计算，
## 主要需要下载的分钟数据，最好在这一分钟内的成交量不要太大，
## 以便准确反映出是 multiple
## 这里我设置了 50

sqlQuery <- paste0("
    SELECT TradingDay,Minute,InstrumentID,OpenPrice,HighPrice,
           LowPrice,ClosePrice,Volume,Turnover
    FROM minute
    WHERE (OpenPrice = HighPrice AND
           OpenPrice = LowPrice AND
           OpenPrice = ClosePrice)
    AND Volume < 50;")

dtAll <- dbGetQuery(mysql, sqlQuery) %>% as.data.table()
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
## 因为中金所相对而言，其成交量比较大，需要稍微增加一些
## 这里我设置了 2000

tempCFFEX <- c("IF","IH","IC","T","TF") %>%
          paste0("^",.,collapse = '[0-9]+|') %>%
          paste0(.,"[0-9]+")
sqlQuery <- paste0("
    SELECT TradingDay,Minute,InstrumentID,OpenPrice,HighPrice,
           LowPrice,ClosePrice,Volume,Turnover
    FROM minute
    WHERE (OpenPrice = HighPrice AND
         OpenPrice = LowPrice AND
         OpenPrice = ClosePrice)
    AND Volume < 5000
    AND (InstrumentID REGEXP ","'",tempCFFEX,"')" )

dtCFFEX <- dbGetQuery(mysql,sqlQuery) %>% as.data.table()
# ------------------------------------------------------------------------------

## 把所有的数据都汇合起来
dtMinute <- list(dtAll,dtCFFEX) %>% rbindlist() %>%
  .[!duplicated(.[,.(TradingDay,Minute,InstrumentID)])] %>%
  .[,":="(ProductID = gsub('[0-9]','',InstrumentID),
          Multiplier = round(Turnover / Volume / OpenPrice)
        )
  ]
################################################################################
dtMinute[, Multiplier := names(which.max(table(.SD[,Multiplier] %>% unlist() %>% .[!is.na(.) & . != 0]
                                              )
                                        )
                              ) %>% as.numeric()
   ,by = c('TradingDay','InstrumentID')]

dtMinute[,unique(Multiplier)]

fwrite(dtMinute[Multiplier ==0], './tmp/有问题的minute.csv')

####################################################################################################
####################################################################################################
dtDaily <- dtMinute[,.(multiple = unique(Multiplier))
                    ,by = c('TradingDay','InstrumentID')]

dtDaily[duplicated(dtDaily[,.(TradingDay,InstrumentID)])]

dtDaily[,paste0('lag',1:10) := lapply(1:10, function(i){
        shift(.SD[,multiple],i,type = 'lag')
      }),by = c('InstrumentID')]

dtDaily[,paste0('lead',1:10) := lapply(1:10, function(i){
        shift(multiple,i,type = 'lead')
      }),by = c('InstrumentID')]

dtDaily[,":="(meanLag  = sum(c(lag1,lag2,lag3,lag4,lag5
                              ,lag6,lag7,lag8,lag9,lag10), na.rm = TRUE)/10
             ,meanLead = sum(c(lead1,lead2,lead3,lead4,lead5
                              ,lead6,lead7,lead8,lead9,lead10), na.rm = TRUE)/10
             )
        ,by = c("TradingDay",'InstrumentID')]

####################################################################################################
####################################################################################################
dt <- dtDaily[, allMultiple := names(which.max(
                                      table(.SD[,multiple:lead10] %>% unlist() %>% .[!is.na(.) & . != 0])
                                              )
                                    ) %>% as.numeric()
  ,by = c("TradingDay",'InstrumentID')]

# dt[multiple == meanLag, multiple := multiple]
dt[multiple != meanLag | multiple == 0]
dt[multiple != meanLag | multiple == 0, multiple := allMultiple]

# 去掉所有的郑商所
dt1 <- dt[,.(TradingDay,InstrumentID,multiple)][-grep("[A-Z]",InstrumentID)]

# 加上所有的中金所
dt2 <- dt[,.(TradingDay,InstrumentID,multiple)][grep(tempCFFEX,InstrumentID)]

# 没有包含郑商所的合约乘数
DT1 <- list(dt1,dt2) %>% rbindlist() %>% .[,TradingDay := as.Date(TradingDay)]

# fwrite(DT1,paste0('instrumentID_multiplier_dce_shfe_cffex','.csv'))


####################################################################################################
####################################################################################################
dtCZCE <- lapply(list.files('./data/CZCE_VM'), function(i){
  tempDT <- read_delim(paste0('./data/CZCE_VM/',i), delim = "|",
                       locale = locale(encoding = 'GB18030'),
                       skip = 1) %>% as.data.table()

  colnames(tempDT) <- c('TradingDay','InstrumentID','LastSettlementPrice',
                        'OpenPrice','HighPrice','LowPrice','ClosePrice',
                        'TodaySettlementPrice','Change1','Change2',
                        'Volume','ShortVolume','DiffVolume','Turnover',
                        'SettlementPrice','X16')
  tempDT[,c('LastSettlementPrice','TodaySettlementPrice','Change1','Change2',
            'ShortVolume','DiffVolume','SettlementPrice','X16') := NULL]

  tempDT[,":="(InstrumentID = gsub('\\t|,| ','',InstrumentID),
               OpenPrice = gsub('\\t|,','',OpenPrice) %>% as.numeric(),
               HighPrice = gsub('\\t|,','',HighPrice) %>% as.numeric(),
               LowPrice = gsub('\\t|,','',LowPrice) %>% as.numeric(),
               ClosePrice = gsub('\\t|,','',ClosePrice) %>% as.numeric(),
               Volume = gsub('\\t|,','',Volume) %>% as.numeric(),
               Turnover = gsub('\\t|,','',Turnover) %>% as.numeric() * 10000
  )]

  return(tempDT)
}) %>% rbindlist()

dtCZCE[,":="(ProductID = gsub('[0-9]','',InstrumentID),
         multiple = round(Turnover / Volume / ((OpenPrice + HighPrice + LowPrice +
                                              ClosePrice)/4)
                          )
         )
  ]

dtCZCE[is.na(multiple) | is.infinite(multiple), multiple := 0]

dtCZCE[,paste0('lag',1:50) := lapply(1:50, function(i){
        shift(.SD[,multiple],i,type = 'lag')
      }),by = c('InstrumentID')]

dtCZCE[,paste0('lead',1:50) := lapply(1:50, function(i){
        shift(multiple,i,type = 'lead')
      }),by = c('InstrumentID')]

dtCZCE[,":="(meanLag  = sum(c(lag1,lag2,lag3,lag4,lag5,lag6,lag7,lag8
                             ,lag9,lag10,lag11,lag12,lag13,lag14,lag15
                             ,lag16,lag17,lag18,lag19,lag20,lag21,lag22
                             ,lag23,lag24,lag25,lag26,lag27,lag28,lag29,lag30
                             ,lag31,lag32,lag33,lag34,lag35,lag36,lag37,lag38
                             ,lag39,lag40,lag41,lag42,lag43,lag44,lag45,lag46,lag47
                             ,lag48,lag49,lag50), na.rm = TRUE)/50
            ,meanLead = sum(c(lead1,lead2,lead3,lead4,lead5,lead6,lead7,lead8,lead9
                              ,lead10,lead11,lead12,lead13,lead14,lead15
                              ,lead16,lead17,lead18,lead19,lead20,lead21
                              ,lead22,lead23,lead24,lead25,lead26,lead27
                              ,lead28,lead29,lead30,lead31,lead32,lead33,lead34,lead35
                              ,lead36,lead37,lead38,lead39,lead40
                              ,lead41,lead42,lead43,lead44,lead45,lead46
                              ,lead47,lead48,lead49,lead50), na.rm = TRUE)/50
             )
        ,by = c("TradingDay",'InstrumentID')]


roundDigit <- function(x){
  if(is.na(x)){
    tempRes <- NA
  }else{
  # ------------------------------------------------------------------------------------------------
  if(nchar(x) == 1){
    if(x == 9){
      tempRes <- 10
    }else{
      tempRes <- x
    }
  }
  # ------------------------------------------------------------------------------------------------
  if(nchar(x) == 2){
    temp <- strsplit(as.character(x),'')[[1]]

    if(temp[1] == 9){
      tempRes <- 100
    }else{
      if(as.numeric(temp[2]) >= 8){
        tempRes <- ( as.numeric(temp[1]) + 1 )* 10
      }else{
        if(abs(as.numeric(temp[2]) - 5) <= 1){
          tempRes <-  ( as.numeric(temp[1]) + 0 )* 10 + 5
        }else{
          tempRes <-  ( as.numeric(temp[1]) + 0 )* 10
        }
    }
    }
  }

  # ------------------------------------------------------------------------------------------------
  if(nchar(x) == 3){
    tempAll <- strsplit(as.character(x),'')[[1]]
    temp <-  tempAll[-1]

    if(as.numeric(temp[1]) == 9){
      tempRes <- ( as.numeric(temp[1]) + 1 )* 10
    }else{
      if(as.numeric(temp[1]) == 0){
        tempRes <- ( as.numeric(temp[1]) + 0 )* 10
      }else{
        if(as.numeric(temp[2]) >= 8){
      tempRes <- ( as.numeric(temp[1]) + 1 )* 10
    }else{
      if(abs(as.numeric(temp[2]) - 5) <= 2){
        tempRes <-  ( as.numeric(temp[1]) + 0 )* 10 + 5
      }else{
        tempRes <-  ( as.numeric(temp[1]) + 0 )* 10
      }
    }
      }
    }

    tempRes <- as.numeric(tempAll[1]) * 100 + tempRes
  }
  }


  # ------------------------------------------------------------------------------------------------
  return(tempRes)
}

roundDigit(NA)
roundDigit(26)
roundDigit(97)
roundDigit(98)
roundDigit(101)
roundDigit(198)

# x <- dt[,unique(multiple)] %>% .[!is.na(.)]
# sapply(x, roundDigit)
dtCZCE[,unique(multiple)] -> y
y
sapply(y,roundDigit)
dtCZCE[,multiple := sapply(multiple,roundDigit)]
dtCZCE[,unique(multiple)]

# ==================================================================================================
dt <- dtCZCE[, allMultiple := names(which.max(
                                      table(.SD[,multiple:lead50] %>% unlist() %>% .[!is.na(.) & . != 0])
                                              )
                                    ) %>% as.numeric()
  ,by = c("TradingDay",'InstrumentID')]
dt[,c(paste0('lag',1:50)) := NULL]
dt[,c(paste0('lead',1:50)) := NULL]
# dt[multiple == meanLag, multiple := multiple]
dt[multiple != meanLag | multiple == 0 | is.na(multiple), multiple := allMultiple]

tempdt <- dt[,.SD]
tempdt2 <- tempdt[,multiple := names(which.max(
                                      table(.SD[,multiple] %>% unlist() %>% .[!is.na(.) & . != 0])
                                              )
                                    ) %>% as.numeric()
   ,by = c("TradingDay","ProductID")]
tempdt2[multiple == 0 | is.na(multiple)][,unique(ProductID)]
tempdt2[multiple == 0 | is.na(multiple)][ProductID == 'JR']

DT2 <- tempdt2[,.(TradingDay,InstrumentID,multiple)]
DT2[,multiple := sapply(multiple,roundDigit)]
DT2[,unique(multiple)]
DT2[is.na(multiple) | multiple == 0][,unique(InstrumentID)]
# fwrite(DT2,paste0('instrumentID_multiplier_czce','.csv'))


####################################################################################################
####################################################################################################
DT <- list(DT1,DT2) %>% rbindlist()
setnames(DT, 'multiple', 'VolumeMultiple')
fwrite(DT,paste0('./output/VolumeMultiple','.csv'))


####################################################################################################
####################################################################################################

mysql <- dbConnect(MySQL(), dbname = "china_futures_info"
  ,host="192.168.1.106"
  ,user = 'fl'
  ,password = 'abc@123')

sqlQuery <- "SELECT TradingDay,InstrumentID,VolumeMultiple
             FROM Instrument_info
             WHERE TradingDay >= 20170101;"
tempDT <- dbGetQuery(mysql, sqlQuery) %>% as.data.table() %>%
          .[,":="(TradingDay = as.Date(TradingDay))]

# --------------------------------------------------------------------
dbSendQuery(mysql, "DROP TABLE IF EXISTS VolumeMultiple")
dbSendQuery(mysql,"
    CREATE TABLE VolumeMultiple(
        TradingDay    DATE        NOT NULL,
        InstrumentID  varchar(20) NOT NULL,
        VolumeMultiple INT        NOT NULL,
        PRIMARY KEY(TradingDay,InstrumentID)
      )
  ")
dbListTables(mysql)

tempAll <- list(DT[TradingDay < '2017-01-01'],tempDT) %>% rbindlist()
tempAll[duplicated(tempAll[,.(TradingDay,InstrumentID)])][nchar(InstrumentID) <= 8]

dbWriteTable(mysql,'VolumeMultiple',tempAll
            , row.names = FALSE, append = TRUE)
