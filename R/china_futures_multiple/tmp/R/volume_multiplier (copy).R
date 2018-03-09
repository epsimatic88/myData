library(RMySQL)
library(data.table)
library(magrittr)


################################################################################
mysql <- dbConnect(MySQL(), dbname = "china_futures_bar"
	,host="192.168.1.106"
	,user = 'fl'
	,password = 'abc@123')

# dbListTables(mysql)

dt <- dbGetQuery(mysql,"
		SELECT TradingDay,Minute,InstrumentID,OpenPrice,HighPrice,
			     LowPrice,ClosePrice,Volume,Turnover
		FROM minute
		WHERE (OpenPrice = HighPrice AND
			     OpenPrice = LowPrice AND
			     OpenPrice = ClosePrice)
	    AND Volume < 50;") %>%
	as.data.table()

dtCFFEX <- dbGetQuery(mysql,"
		SELECT TradingDay,Minute,InstrumentID,OpenPrice,HighPrice,
			     LowPrice,ClosePrice,Volume,Turnover
		FROM minute
		WHERE (OpenPrice = HighPrice AND
			   OpenPrice = LowPrice AND
			   OpenPrice = ClosePrice)
	  AND Volume < 5000
    AND (InstrumentID REGEXP '^IF[0-9]{1,}|^IC[0-9]{1,}|^IH[0-9]{1,}|^T[0-9]{1,}|^TF[0-9]{1,}');") %>%
  as.data.table()

dt <- list(dt,dtCFFEX) %>% rbindlist() %>%
  .[!duplicated(.[,.(TradingDay,Minute,InstrumentID)])] %>%
  .[,":="(ProductID = gsub('[0-9]','',InstrumentID),
        Multiplier = Turnover / Volume / OpenPrice
        )
  ]
################################################################################
dt2 <- dt[,.(Multiplier = round(Multiplier,0))
	,by = c('TradingDay','InstrumentID')]

dt2[,unique(Multiplier)]

dt3 <- dt2[,.(Multiplier = unique(Multiplier))
		   ,by = c('TradingDay','InstrumentID')]
dt3[,unique(Multiplier)]
################################################################################
y <- dt3[,.(TradingDay,Multiplier,
	lag1 = .SD[,shift(Multiplier,1,type = 'lag')],
	lag2 = .SD[,shift(Multiplier,2,type = 'lag')],
	lag3 = .SD[,shift(Multiplier,3,type = 'lag')],
	lag4 = .SD[,shift(Multiplier,4,type = 'lag')],
	lag5 = .SD[,shift(Multiplier,5,type = 'lag')],
	lag6 = .SD[,shift(Multiplier,6,type = 'lag')],
	lead1 = .SD[,shift(Multiplier,1,type = 'lead')],
	lead2 = .SD[,shift(Multiplier,2,type = 'lead')],
	lead3 = .SD[,shift(Multiplier,3,type = 'lead')],
	lead4 = .SD[,shift(Multiplier,4,type = 'lead')],
	lead5 = .SD[,shift(Multiplier,5,type = 'lead')],
	lead6 = .SD[,shift(Multiplier,6,type = 'lead')])
	,by = 'InstrumentID']
setorderv(y,c('InstrumentID','TradingDay'))

allYears <- seq(2011,2017) %>% as.character()


library(parallel)
cl <- makeCluster(length(allYears),type = 'FORK')

dt <- parLapply(cl,1:length(allYears),function(i){
  theYear <- allYears[i]
  temp <- y[TradingDay %between% c(paste0(as.numeric(theYear)-1,"-12-20"),
                                   paste0(as.numeric(theYear)+1,"-01-10"))]
  tempDT <- temp[1:1][,":="(mp = lapply(.SD,function(x){
    temp <- .SD[,c(Multiplier,lag1,lag2,lag3,lag4,lag5,lag6,
                   lead1,lead2,lead3,lead4,lead5,lead6)] %>% .[!is.na(.)]
    if(all(!is.na(.SD[1, lag1:lag3])) & all(equals(.SD[1,Multiplier] * 3, .SD[1,lead1:lead3]))){
      tempRes <- .SD[1,Multiplier]
    }else{
      tempRes <- names(which.max(table(temp))) %>% as.integer()
    }

    return(tempRes)
  })
  ),by = c('TradingDay','InstrumentID')]


  ##
  tempDT <- tempDT[TradingDay %between% c(paste0(as.numeric(theYear),"-01-01"),
                                          paste0(as.numeric(theYear),"-12-31"))]
  #setwd("~/myCodes/china_futures_bar")
  #fwrite(temp,paste0('multiplier_',theYear,'.csv'))

  return(tempDT)
})
stopCluster(cl)

# length(allYears)
dt1 <- rbindlist(dt) %>%
  .[,.(TradingDay,InstrumentID,Multiplier = mp)] %>%
  .[-grep("[A-Z]",InstrumentID)]

dt2 <- rbindlist(dt) %>%
  .[,.(TradingDay,InstrumentID,Multiplier = mp)] %>%
  .[grep('^IF[0-9]{1,}|^IC[0-9]{1,}|^IH[0-9]{1,}|^T[0-9]{1,}|^TF[0-9]{1,}',InstrumentID)]

DT <- list(dt1,dt2) %>% rbindlist()

setwd("~/myCodes/china_futures_bar/output/")
fwrite(DT,paste0('instrumentID_multiplier_dce_shfe_cffex','.csv'))

################################################################################
################################################################################

setwd("~/myCodes/china_futures_bar")
list.files('./CZCE')
library(readr)

dt <- lapply(list.files('./CZCE'), function(i){
  tempDT <- read_delim(paste0('./CZCE/',i), delim = "|",
                       locale = locale(encoding = 'GB18030'),
                       skip = 1) %>%
    as.data.table()

  colnames(tempDT) <- c('TradingDay','InstrumentID','LastSettlementPrice',
                        'OpenPrice','HighPrice','LowPrice','ClosePrice',
                        'TodaySettlementPrice','Change1','Change2',
                        'Volume','ShortVolume','DiffVolume','Turnover',
                        'SettlementPrice','X16')
  tempDT[,c('LastSettlementPrice','TodaySettlementPrice','Change1','Change2',
            'ShortVolume','DiffVolume','SettlementPrice','X16') := NULL]

  cols <- colnames(tempDT)

  tempDT[,":="(InstrumentID = gsub('\\t|,','',InstrumentID),
               OpenPrice = gsub('\\t|,','',OpenPrice) %>% as.numeric(),
               HighPrice = gsub('\\t|,','',HighPrice) %>% as.numeric(),
               LowPrice = gsub('\\t|,','',LowPrice) %>% as.numeric(),
               ClosePrice = gsub('\\t|,','',ClosePrice) %>% as.numeric(),
               Volume = gsub('\\t|,','',Volume) %>% as.numeric(),
               Turnover = gsub('\\t|,','',Turnover) %>% as.numeric() * 10000
  )]

}) %>% rbindlist()

dt[,":="(ProductID = gsub('[0-9]','',InstrumentID),
         Multiplier = Turnover / Volume / ((OpenPrice + HighPrice + LowPrice +
                                              ClosePrice)/4)
)
]

################################################################################
dt2 <- dt[,.(Multiplier = round(Multiplier,0))
          ,by = c('TradingDay','InstrumentID')]

dt2[,unique(Multiplier)]

dt3 <- dt2[,.(Multiplier = unique(Multiplier))
           ,by = c('TradingDay','InstrumentID')]
dt3[,unique(Multiplier)]
################################################################################

y <- dt3[,.(TradingDay,Multiplier,
            lag1 = .SD[,shift(Multiplier,1L,type = 'lag')],
            lag2 = .SD[,shift(Multiplier,2L,type = 'lag')],
            lag3 = .SD[,shift(Multiplier,3L,type = 'lag')],
            lag4 = .SD[,shift(Multiplier,4L,type = 'lag')],
            lag5 = .SD[,shift(Multiplier,5L,type = 'lag')],
            lag6 = .SD[,shift(Multiplier,6L,type = 'lag')],
            lag7 = .SD[,shift(Multiplier,7L,type = 'lag')],
            lag8 = .SD[,shift(Multiplier,8L,type = 'lag')],
            lag9 = .SD[,shift(Multiplier,9L,type = 'lag')],
            lag10 = .SD[,shift(Multiplier,10L,type = 'lag')],
            lead1 = .SD[,shift(Multiplier,1L,type = 'lead')],
            lead2 = .SD[,shift(Multiplier,2L,type = 'lead')],
            lead3 = .SD[,shift(Multiplier,3L,type = 'lead')],
            lead4 = .SD[,shift(Multiplier,4L,type = 'lead')],
            lead5 = .SD[,shift(Multiplier,5L,type = 'lead')],
            lead6 = .SD[,shift(Multiplier,6L,type = 'lead')],
            lead7 = .SD[,shift(Multiplier,7L,type = 'lead')],
            lead8 = .SD[,shift(Multiplier,8L,type = 'lead')],
            lead9 = .SD[,shift(Multiplier,9L,type = 'lead')],
            lead10 = .SD[,shift(Multiplier,10L,type = 'lead')])
         ,by = 'InstrumentID']
setorderv(y,c('InstrumentID','TradingDay'))

cl <- makeCluster(round(detectCores()/3),type = 'FORK')
# nrow(y)
tempDT <- parLapply(cl,1:nrow(y),function(i){
  temp <- y[i]

  if(!all(is.na(temp[,.(lag1,lag2,lag3,lag4,lag5)])) & identical(temp[,.(lag1,lag2,lag3,lag4,lag5)],rep(temp[,Multiplier],5)) ){
    temp[,mp := Multiplier]
  }else{
    temp2 <- temp[,.(Multiplier,lag1,lag2,lag3,lag4,lag5,lag6,lag7,lag8,lag9,lag10,lead1,lead2,lead3,lead4,lead5,lead6,lead7,lead8,lead9,lead10)] %>% unlist() %>% as.vector() %>%
      .[!is.na(.)]
    temp[,mp := names(which.max(table(temp2[]))) %>% as.integer()]
  }

  ## temp <- temp[,.(TradingDay,InstrumentID,Multiplier,mp)]
  return(temp)

}) %>% rbindlist()
stopCluster(cl)

tempDT[, mp2 := ifelse(nchar(mp) <= 1, round(mp),
                       round( mp / (10^(nchar(mp) - 1))) * 10^(nchar(mp) - 1)
                       )]
tempDT[,unique(mp2)]
tempDT[!is.na(mp2)]
tempDT[is.na(mp2)]

tempDT2 <- tempDT[,.(TradingDay,InstrumentID,Multiplier,mp,mp2)]

tempDT3 <- tempDT2[,.(Multiplier = unique(mp2)), by =c('TradingDay','InstrumentID')][!is.na(Multiplier)]
tempDT3[,unique(Multiplier)]

fwrite(tempDT3,'InstrumentID_multiplier_czce.csv')

# system('cp InstrumentID_multiplier_czce.csv /shared/public/fl/')
















dt

y[,":="(sumLag = sum(c(lag1,lag2,lag3), na.rm = TRUE))
  ,by = c("TradingDay",'InstrumentID')]
y[1][,":="(maxNum = names(which.max(table(.SD[,Multiplier:lead6] %>% unlist()))) %>% as.integer())
  ,by = c("TradingDay",'InstrumentID')]
y
w <- y[1]
w[,unlist(Multiplier:lead6)] %>% table()

w <- y
w[,":="(maxNum = names(which.max(table(.SD[,Multiplier:lead6] %>% unlist()))) %>% as.integer())
  ,by = c("TradingDay",'InstrumentID')]
w

w[Multiplier * 3  == sumLag, multiple := Multiplier]
w[Multiplier * 3  != sumLag, multiple := maxNum]
