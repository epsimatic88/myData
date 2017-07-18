################################################################################
## MainContract_00_main.R
## 寻找主力合约
##
## Author:lgh
## Date: 2017-02-07
##
## Revised: William Fang
## Update: 2017-02-08
################################################################################
# Rscript /home/fl/William/Codes/MainContract/MainContract_00_main.R


#Find main contracts for each product
#Start from the daily data
#End up with the continue contract for each product

rm(list=ls())

# load Packages
library(magrittr)
library(data.table)
library(RMySQL)


# Get daily data from the database
#
conn <- dbConnect(MySQL(), dbname = "china_futures_bar", host="127.0.0.1",
                  user = "lhg", password = "abc@123")
dbSendQuery(conn, "truncate table main_contract_daily;")

startday <- "2011-01-01"
# startday <- "2017-01-01"
endday   <- Sys.Date() %>% as.character()

select_col <- "TradingDay, Sector, InstrumentID, ClosePrice, Volume, Turnover, CloseOpenInterest"
stSQL<-paste('SELECT', select_col, 'FROM daily
             WHERE sector = "allday" AND','TradingDay <= "',endday,
             '" AND TradingDay >= "',startday,
             '" ORDER BY TradingDay,InstrumentID;')
suppressWarnings(
  data_1 <- dbGetQuery(conn,stSQL) %>% as.data.table()
  )
dbDisconnect(conn);

#Indentify product and contract month
#
data_1[,":="(Product  = gsub('[0-9]','',InstrumentID),
             ConMonth = gsub('[a-zA-Z]','',InstrumentID)
             )
       ]

################################################################################
## 以下条件定义了主力合约的性质
## 1)
## 2)
## 3)
################################################################################
#
# Define main contract at the i-th day as the same with the (i-1)-th day unless
# the following conditions happen:
# 1).the max-turnover contract different from the main contract in the (i-1)-th day
# 2).the turnover of the max-turnover contract in the (i-1)-th in the (i-2)-th day
#    is greater then [half] of the max turnover in that day
# 3).the max-turnover contract month is greater than the main contract month in
#    (i-1)-th day
##----------------
# To formulize:
##----------------
# 1).Max_turnover_contract[i-1]!=Main_contract[i-1] and
# 2).lag_Max_turnover_contract[i-2]>max_turnover[i-2]*0.5
# 3).Max_turnover_contract_month[i-1]>=Main_contract_month[i-1]
#
#Here we first add all the columns we need

a <- data_1[,("Pre_Volume"):=shift(.SD,1,NA,"lag"),
            .SDcols=c("Volume"),by=InstrumentID] %>%
  .[,lag_c:=shift(.SD,1,NA,'lag'),.SDcols='ClosePrice',by=InstrumentID] %>%
  .[,ret:=(ClosePrice-lag_c)/lag_c] %>%
  .[,list(TradingDay,InstrumentID,Product,ret,Pre_Volume)];

#select the max_turnover contract and its previous max_turnover contract
b <- data_1[,ord:=order(order(-Volume,CloseOpenInterest)),
            by=.(TradingDay,Product)] %>%
  .[ord==1,list(TradingDay,InstrumentID,Volume,Product)] %>%
  .[,("Last_maxvolume"):=shift(.SD,1,NA,"lag"),
    .SDcols=c("Volume"),by=Product];

a1 <- a[b, on = c("TradingDay","InstrumentID")];

#we need to lag one period

col <- c("InstrumentID","Pre_Volume","Volume","Last_maxvolume");
ancol <- paste("lag_",col,sep = "");
a2 <- a1[,(ancol):=shift(.SD,1,NA,"lag"),.SDcols=col,by=Product] %>%
  .[,list(TradingDay,Product,CadMain=lag_InstrumentID,
          lag_Pre_Volume,lag_Volume,lag_Last_maxvolume)];

#use the rules above,note that we use cummax() to avoid use "for"
a3 <- a2[,od:=order(order(TradingDay)),by=Product] %>%
  .[,va:=od*(lag_Pre_Volume>0.5*lag_Last_maxvolume),by=Product] %>%
  .[,va2:=ifelse(od==1 | od==2,od,cummax(ifelse(is.na(va),0L,va)))
    ,by=Product];

a3_1<-unique(a3[,list(TradingDay,Product,va2)]);

a3_2 <- unique(a3[,list(Product,od,CadMain)]);

a4_1 <- a3_2[a3_1,on=c(Product="Product",od="va2"),nomatch=NA] %>%
  .[,list(TradingDay,Product,Main_contract=CadMain)];

a4 <- a[a4_1,on=c(TradingDay="TradingDay",InstrumentID="Main_contract"),nomatch=NA] %>%
  .[,list(TradingDay,Product=i.Product,Main_contract=InstrumentID,ret)] %>%
  .[,ret:=ifelse(is.na(ret),0,ret)] %>%
  .[,prod_index:=cumprod(1+ret),by=Product] %>%
  .[,list(TradingDay,Product,Main_contract,prod_index)];

################################################################################

conn <- dbConnect(MySQL(), dbname = "china_futures_bar", host="127.0.0.1",
                  user = "lhg", password = "abc@123");
dbWriteTable(conn, "main_contract_daily",a4,
             row.name=FALSE, append = T)

dbDisconnect(conn);


################################################################################

################################################################################
################################################################################
#The following is just for temporary use
#To build the VolumeMultiplier for each product
#
if (0) {
  data1 <- read.csv("/home/lhg/importdata/Instrument.csv",
                    fileEncoding = 'UTF-8',
                    header = TRUE);
  data1 <- as.data.table(data1)
  t1 <- data1[,list(Product=ProductID,VolumeMultiple)] %>% unique(.,by='Product')

  conn <- dbConnect(MySQL(), dbname = "china_futures_bar", host="127.0.0.1",
                    user = "lhg", password = "abc@123");
  dbWriteTable(conn, "Volume_Multiple",as.data.frame(t1),
               row.name=FALSE, append = T)

  dbDisconnect(conn);
}
