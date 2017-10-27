################################################################################
## VolumeMultiple.R
## 用于计算 china_futures 的合约乘数。
## 
## Author: fl@hicloud-investment.com
## CreateDate: 2017-10-23
################################################################################


################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("VolumeMultiple.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
################################################################################

## =============================================================================
mysql <- mysqlFetch('china_futures_bar', host = '192.168.1.166')
dtMain <- dbGetQuery(mysql, "
        select TradingDay, 
               Main_contract as InstrumentID
        from main_contract_daily 
    ") %>% as.data.table()

## =============================================================================
mysql <- mysqlFetch('china_futures_info', host = '192.168.1.166')
dtVM <- dbGetQuery(mysql, "
        select * from VolumeMultiple
    ") %>% as.data.table()
        


## =============================================================================
mysql <- mysqlFetch('Exchange', host = '192.168.1.166')
dt <- dbGetQuery(mysql, "
        select * from daily
        where Volume != 0
        and ClosePrice != 0") %>% as.data.table()
dt[, VolumeMultiple := NA]

## =============================================================================
cl <- makeCluster(max(round(detectCores()*3/4),4), type='FORK')
dt$VolumeMultiple <- parSapply(cl, 1:nrow(dt), function(i){
    temp <- dt[i, Turnover / Volume /
                  mean(c(OpenPrice, HighPrice, LowPrice, ClosePrice),
                       na.rm = TRUE)] %>% round(., 0)
    res <- round(temp / (10^(nchar(temp)-1)),1) * (10^(nchar(temp) - 1))
})
stopCluster(cl)
## =============================================================================


## =============================================================================
updateVM <- function(x) {
    tempRes <- x[,.SD]
    tempRes[, ":="(
            lag01  = shift(VolumeMultiple, 1L, type = 'lag'),
            lag02  = shift(VolumeMultiple, 2L, type = 'lag'),
            lag03  = shift(VolumeMultiple, 3L, type = 'lag'),
            lag04  = shift(VolumeMultiple, 4L, type = 'lag'),
            lag05  = shift(VolumeMultiple, 5L, type = 'lag'),
            lead01 = shift(VolumeMultiple, 1L, type = 'lead'),
            lead02 = shift(VolumeMultiple, 2L, type = 'lead'),
            lead03 = shift(VolumeMultiple, 3L, type = 'lead'),
            lead04 = shift(VolumeMultiple, 4L, type = 'lead'),
            lead05 = shift(VolumeMultiple, 5L, type = 'lead')
        )]
    tempRes[, ":="(lagM = 0, leadM = 0)]

    cols <- c('lag01','lag02','lag03','lag04','lag05',
              'lead01','lead02','lead03','lead04','lead05')
    tempRes[, (cols) := lapply(.SD, function(x){
        ifelse(is.na(x), 0, x)
    }), .SDcol = cols]

    for (i in 1:nrow(tempRes)) {
        tempRes$lagM[i] <- tempRes[i, median(c(lag01, lag02, lag03, lag04, lag05), na.rm = TRUE)]
        tempRes$leadM[i] <- tempRes[i, median(c(lead01, lead02, lead03, lead04, lead05), na.rm = TRUE)]
    }

    tempRes[, (cols) := NULL]

    ## =========================================================================
    res <- sapply(1:nrow(tempRes), function(i){
        # ifelse(tempRes$lagM[i] == tempRes$leadM[i], tempRes$lagM[i],
        #        ifelse(abs(tempRes$VolumeMultiple[i] - tempRes$lagM[i]) < abs(tempRes$VolumeMultiple[i] - tempRes$leadM),
        #               tempRes$lagM[i], tempRes$leadM[i])
        #        )
        temp <- c(tempRes$lagM[i], tempRes$leadM[i], tempRes$VolumeMultiple[i]) %>% 
                .[. > 0]

        y <- ifelse((tempRes$lagM[i] == tempRes$leadM[i]) & (tempRes$lagM[i] != 0), tempRes$lagM[i],
               min(temp))
        if (is.na(y)) y <- tempRes$VolumeMultiple[i]
        return(y)
    })
    if (any(is.na(res))) res[is.na(res)] <- 0
    return(res)
    ## =========================================================================
}


## =============================================================================
dt[, VolumeMultiple := updateVM(.SD), by = "InstrumentID"]
dt <- dt[TradingDay < max(TradingDay)]
dt[, unique(VolumeMultiple)]


## =============================================================================
cl <- makeCluster(max(round(detectCores()*3/4),4), type='FORK')
dt$VolumeMultiple <- parSapply(cl, 1:nrow(dt), function(i){
    temp <- dt[i, VolumeMultiple] %>% as.character()
    if (nchar(temp) == 2) {
        tempRes <- strsplit(temp,'') %>% unlist()
        if (tempRes[2] %in% c('1','2')) {
            res <- (as.numeric(tempRes[1])) * 10
        } else {
            if (tempRes[2] %in% c('8','9')) {
                res <- (as.numeric(tempRes[1]) + 1) * 10
            } else {
                res <- dt[i, VolumeMultiple]
            }
        }
    } else {
        res <- dt[i, VolumeMultiple]
    }
    return(res)
})
stopCluster(cl)
## =============================================================================
dt[, unique(VolumeMultiple)]


## =============================================================================
dt[VolumeMultiple %between% c(285, 305), VolumeMultiple := 300]
dt[VolumeMultiple %between% c(980, 1050), VolumeMultiple := 1000]
dt[VolumeMultiple %between% c(470, 510), VolumeMultiple := 500]
dt[VolumeMultiple %between% c(95,105), VolumeMultiple := 100]
## =============================================================================
dt[, unique(VolumeMultiple)]




temp <- merge(dt, dtVM , by = c('TradingDay','InstrumentID'), all.y = TRUE) %>% 
        .[TradingDay <= '2017-07-01']
temp[VolumeMultiple.x != VolumeMultiple.y]


## =============================================================================
## FromDC
mysql <- mysqlFetch('FromDC')
info <- dbGetQuery(mysql, "
        select * from info
    ") %>% as.data.table() %>% 
    merge(., dt, by = c('TradingDay','InstrumentID'), all.x = TRUE) %>% 
    .[, .(TradingDay, InstrumentID, PriceTick, 
          VolumeMultiple = VolumeMultiple.y)]

updatePriceTick<- function(x) {
    tempRes <- x[,.SD]
    tempRes[, ":="(
            lag01  = shift(PriceTick, 1L, type = 'lag'),
            lag02  = shift(PriceTick, 2L, type = 'lag'),
            lag03  = shift(PriceTick, 3L, type = 'lag'),
            lag04  = shift(PriceTick, 4L, type = 'lag'),
            lag05  = shift(PriceTick, 5L, type = 'lag'),
            lag06  = shift(PriceTick, 6L, type = 'lag'),
            lag07  = shift(PriceTick, 7L, type = 'lag'),
            lag08  = shift(PriceTick, 8L, type = 'lag'),
            lag09  = shift(PriceTick, 9L, type = 'lag'),
            lag15  = shift(PriceTick, 15L, type = 'lag'),
            lag20  = shift(PriceTick, 20L, type = 'lag'),
            lag25  = shift(PriceTick, 25L, type = 'lag'),
            lag30  = shift(PriceTick, 30L, type = 'lag'),
            lag35  = shift(PriceTick, 35L, type = 'lag'),
            lead01 = shift(PriceTick, 1L, type = 'lead'),
            lead02 = shift(PriceTick, 2L, type = 'lead'),
            lead03 = shift(PriceTick, 3L, type = 'lead'),
            lead04 = shift(PriceTick, 4L, type = 'lead'),
            lead05 = shift(PriceTick, 5L, type = 'lead'),
            lead06 = shift(PriceTick, 6L, type = 'lead'),
            lead07 = shift(PriceTick, 7L, type = 'lead'),
            lead08 = shift(PriceTick, 8L, type = 'lead'),
            lead09 = shift(PriceTick, 9L, type = 'lead'),
            lead15 = shift(PriceTick, 15L, type = 'lead'),
            lead20 = shift(PriceTick, 20L, type = 'lead'),
            lead25 = shift(PriceTick, 25L, type = 'lead'),
            lead30 = shift(PriceTick, 30L, type = 'lead'),
            lead35 = shift(PriceTick, 35L, type = 'lead'),
            lead40 = shift(PriceTick, 40L, type = 'lead'),
            lead45 = shift(PriceTick, 45L, type = 'lead')
        )]
    tempRes[, ":="(lagM = 0, leadM = 0)]

    cols <- c('lag01','lag02','lag03','lag04','lag05','lag06','lag07','lag08','lag09',
              'lag15','lag20','lag25','lag30','lag35',
              'lead01','lead02','lead03','lead04','lead05','lead06','lead07','lead08','lead09',
              'lead15','lead20','lead25','lead30','lead35','lead40','lead45')
    tempRes[, (cols) := lapply(.SD, function(x){
        ifelse(is.na(x), 0, x)
    }), .SDcol = cols]

    for (i in 1:nrow(tempRes)) {
        a <- tempRes[i, (c(lag01, lag02, lag03, lag04, lag05,
                           lag06, lag07, lag08, lag09,
                           lag15,lag20,lag25,lag30,lag35))] %>% .[. != 0]
        tempRes$lagM[i] <- a[max(table(a))]
        b <- tempRes[i, (c(lead01, lead02, lead03, lead04, lead05,
                           lead06, lead07, lead08, lead09,
                           lead15,lead20,lead25,lead30,lead35,lead40,lead45))] %>% .[. != 0]
        tempRes$leadM[i] <- b[max(table(b))]
    }

    tempRes[, (cols) := NULL]

    cols <- c('PriceTick','lagM', 'leadM')
    tempRes[, (cols) := lapply(.SD, function(x){
        ifelse(is.na(x), 0, x)
    }), .SDcol = cols]


    ## =========================================================================
    res <- sapply(1:nrow(tempRes), function(i){

        if (tempRes$lagM[i] == 0) {
            if (tempRes$leadM[i] == 0) {
                y <- tempRes$PriceTick[i]
            } else {
                y <- tempRes$leadM[i]
            }
        } else {
            if (tempRes$leadM[i] == 0) {
                y <- tempRes$lagM[i]
            } else {
                if (tempRes$lagM[i] == tempRes$leadM[i]) {
                    y <- tempRes$lagM[i]
                } else {
                    y <- tempRes$PriceTick[i]
                }
            }
        }

        return(y)
    })
    # if (any(is.na(res))) res[is.na(res)] <- 0
    return(res)
    ## =========================================================================
}

for (i in 1:3) {
    print(i)
    info[, PriceTick := updatePriceTick(.SD), by = "InstrumentID"]
}
info[,unique(PriceTick)]

dbSendQuery(mysql, "
        truncate table info
    ")
dbWriteTable(mysql, 'info',
             info, row.names = FALSE, append = TRUE)
## =============================================================================

info2 <- info[,.SD] %>% 
        .[TradingDay %between% c(dtMain[,min(TradingDay)], dtMain[,max(TradingDay)])]
temp <- merge(dtMain, info2, by = c('TradingDay','InstrumentID'), 
    all.x = TRUE)

u <- temp[!is.na(InstrumentID)][TradingDay < '2016-11-01'][is.na(PriceTick)]
y <- temp[!is.na(InstrumentID)][TradingDay < '2016-11-01'][!is.na(PriceTick)]
y[,unique(PriceTick)]
