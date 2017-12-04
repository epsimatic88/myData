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
        where Volume != 0") %>% as.data.table()
dt[, VolumeMultiple := NA]

## =============================================================================
cl <- makeCluster(max(round(detectCores()*3/4),8), type='FORK')
dt$VolumeMultiple <- parSapply(cl, 1:nrow(dt), function(i){
    temp <- dt[i, Turnover / Volume /
                  mean(c(OpenPrice, HighPrice, LowPrice, ClosePrice),
                       na.rm = TRUE)] %>% round(., 0)
    res <- round(temp / (10^(nchar(temp)-1)),1) * (10^(nchar(temp) - 1))
})
stopCluster(cl)
## =============================================================================


## =============================================================================
updateVolumeMultiple<- function(x) {
  tempRes <- x[,.SD]
  tempRes[, ":="(
    lag01  = shift(VolumeMultiple, 1L, type = 'lag'),
    lag02  = shift(VolumeMultiple, 2L, type = 'lag'),
    lag03  = shift(VolumeMultiple, 3L, type = 'lag'),
    lag04  = shift(VolumeMultiple, 4L, type = 'lag'),
    lag05  = shift(VolumeMultiple, 5L, type = 'lag'),
    lag06  = shift(VolumeMultiple, 6L, type = 'lag'),
    lag07  = shift(VolumeMultiple, 7L, type = 'lag'),
    lag08  = shift(VolumeMultiple, 8L, type = 'lag'),
    lag09  = shift(VolumeMultiple, 9L, type = 'lag'),
    lag15  = shift(VolumeMultiple, 15L, type = 'lag'),
    lag20  = shift(VolumeMultiple, 20L, type = 'lag'),
    lag25  = shift(VolumeMultiple, 25L, type = 'lag'),
    lag30  = shift(VolumeMultiple, 30L, type = 'lag'),
    lag35  = shift(VolumeMultiple, 35L, type = 'lag'),
    lag40  = shift(VolumeMultiple, 40L, type = 'lag'),
    lag45  = shift(VolumeMultiple, 45L, type = 'lag'),
    lead01 = shift(VolumeMultiple, 1L, type = 'lead'),
    lead02 = shift(VolumeMultiple, 2L, type = 'lead'),
    lead03 = shift(VolumeMultiple, 3L, type = 'lead'),
    lead04 = shift(VolumeMultiple, 4L, type = 'lead'),
    lead05 = shift(VolumeMultiple, 5L, type = 'lead'),
    lead06 = shift(VolumeMultiple, 6L, type = 'lead'),
    lead07 = shift(VolumeMultiple, 7L, type = 'lead'),
    lead08 = shift(VolumeMultiple, 8L, type = 'lead'),
    lead09 = shift(VolumeMultiple, 9L, type = 'lead'),
    lead15 = shift(VolumeMultiple, 15L, type = 'lead'),
    lead20 = shift(VolumeMultiple, 20L, type = 'lead'),
    lead25 = shift(VolumeMultiple, 25L, type = 'lead'),
    lead30 = shift(VolumeMultiple, 30L, type = 'lead'),
    lead35 = shift(VolumeMultiple, 35L, type = 'lead'),
    lead40 = shift(VolumeMultiple, 40L, type = 'lead'),
    lead45 = shift(VolumeMultiple, 45L, type = 'lead'),
    lead50 = shift(VolumeMultiple, 50L, type = 'lead'),
    lead55 = shift(VolumeMultiple, 55L, type = 'lead')
  )]
  tempRes[, ":="(lagM = 0, leadM = 0)]

  cols <- c('lag01','lag02','lag03','lag04','lag05','lag06','lag07','lag08','lag09',
            'lag15','lag20','lag25','lag30','lag35','lag40','lag45',
            'lead01','lead02','lead03','lead04','lead05','lead06','lead07','lead08','lead09',
            'lead15','lead20','lead25','lead30','lead35','lead40','lead45','lead50','lead55')
  tempRes[, (cols) := lapply(.SD, function(x){
    ifelse(is.na(x), 0, x)
  }), .SDcol = cols]

  for (i in 1:nrow(tempRes)) {
    a <- tempRes[i, (c(lag01, lag02, lag03, lag04, lag05,
                       lag06, lag07, lag08, lag09,
                       lag15,lag20,lag25,lag30,lag35,lag40,lag45))] %>% .[. != 0]
    if (length(a) < 1) {
      tempRes$lagM[i] <- 0
    } else {
      tempRes$lagM[i] <- as.data.table(table(a))[which.max(N),a] %>% as.numeric()
    }

    b <- tempRes[i, (c(lead01, lead02, lead03, lead04, lead05,
                       lead06, lead07, lead08, lead09,
                       lead15,lead20,lead25,lead30,lead35,
                       lead40,lead45,lead50,lead55))] %>% .[. != 0]
    if (length(b) < 1) {
      tempRes$leadM[i] <- 0
    } else {
      tempRes$leadM[i] <- as.data.table(table(b))[which.max(N),b] %>% as.numeric()
    }
  }

  tempRes[, (cols) := NULL]

  cols <- c('VolumeMultiple','lagM', 'leadM')
  tempRes[, (cols) := lapply(.SD, function(x){
    ifelse(is.na(x), 0, x)
  }), .SDcol = cols]


  ## =========================================================================
  res <- sapply(1:nrow(tempRes), function(i){

    if (tempRes$lagM[i] == 0) {
      if (tempRes$leadM[i] == 0) {
        temp <- tempRes$VolumeMultiple[i]
      } else {
        temp <- tempRes$leadM[i]
      }
    } else {
      if (tempRes$leadM[i] == 0) {
        temp <- tempRes$lagM[i]
      } else {
        if (tempRes$lagM[i] == tempRes$leadM[i]) {
          temp <- tempRes$lagM[i]
        } else {
          temp <- tempRes$VolumeMultiple[i]
        }
      }
    }

    if (nchar(temp) == 2) {
        tempY <- strsplit(as.character(temp),'') %>% unlist()
        if (tempY[2] %in% c('1','2')) {
            y <- (as.numeric(tempY[1])) * 10
        } else {
            if (tempY[2] %in% c('8','9')) {
                y <- (as.numeric(tempY[1]) + 1) * 10
            } else {
                y <- temp
            }
        }
    } else {
        y <- temp
    }

    return(y)
  })
  # if (any(is.na(res))) res[is.na(res)] <- 0
  return(res)
  ## =========================================================================
}

tempDt = dt[InstrumentID == 'PM707']
tempDt[,unique(VolumeMultiple)]
tempDt[, VolumeMultiple := updateVolumeMultiple(.SD), by = "InstrumentID"]
tempDt[,unique(VolumeMultiple)]
# View(tempDt)


## =============================================================================
setkey(dt, 'InstrumentID')
cl <- makeCluster(max(round(detectCores()*3/4),20), type='FORK')
dtRes <- parLapply(cl, dt[,unique(InstrumentID)], function(id){
  tempDt <- dt[id]
  for (tt in 1:5) {
    tempDt[, VolumeMultiple := updateVolumeMultiple(.SD), by = "InstrumentID"]
  }
  return(tempDt)
}) %>% rbindlist()
stopCluster(cl)
## =============================================================================
dtRes[, unique(VolumeMultiple)]

# dtRes <- list()
# for (i in 1:length(dt[,unique(InstrumentID)])) {
#   print(paste(i,": --"))
#   tempDt <- dt[unique(InstrumentID)[i]]
#   for (tt in 1:3) {
#     tempDt[, VolumeMultiple := updateVolumeMultiple(.SD), by = "InstrumentID"]
#   }
#   print(tempDt[,unique(VolumeMultiple)])
#   dtRes[[i]] <- tempDt
# }


## =============================================================================
dtRes[VolumeMultiple %between% c(285, 305), VolumeMultiple := 300]
dtRes[VolumeMultiple %between% c(980, 1050), VolumeMultiple := 1000]
dtRes[VolumeMultiple %between% c(470, 510), VolumeMultiple := 500]
dtRes[VolumeMultiple %between% c(95,105), VolumeMultiple := 100]
## =============================================================================
dtRes[, unique(VolumeMultiple)]



## =============================================================================
temp <- merge(dtRes, dtVM , by = c('TradingDay','InstrumentID'), all.y = TRUE) %>%
        .[TradingDay <= '2017-11-01']
temp[VolumeMultiple.x != VolumeMultiple.y]
## =============================================================================

## =============================================================================
## FromDC
mysql <- mysqlFetch('FromDC', host = '192.168.1.166')
info <- dbGetQuery(mysql, "
        select * from info
    ") %>% as.data.table() %>%
    merge(., dtRes, by = c('TradingDay','InstrumentID'), all = TRUE) %>%
    .[, .(TradingDay, InstrumentID, PriceTick,
          VolumeMultiple = VolumeMultiple.y)]
info
info[is.na(VolumeMultiple)]


## =============================================================================
setkey(info, 'InstrumentID')
cl <- makeCluster(max(round(detectCores()*3/4),20), type='FORK')
infoRes <- parLapply(cl, info[,unique(InstrumentID)], function(id){
  tempDt <- info[id]
  for (tt in 1:10) {
    tempDt[, VolumeMultiple := updateVolumeMultiple(.SD), by = "InstrumentID"]
  }
  return(tempDt)
}) %>% rbindlist()
stopCluster(cl)
## =============================================================================
infoRes[,unique(VolumeMultiple)]
## =============================================================================

temp <- infoRes[VolumeMultiple != 0,.SD]
temp[, ProductID := gsub('[0-9]','',InstrumentID)]


for (id in temp[,unique(ProductID)]) {
  print(id)
  print(
    temp[ProductID == id][,unique(VolumeMultiple)]
    )
}

temp[ProductID == 'pb'][,unique(VolumeMultiple)]
temp[ProductID == 'fu'][,unique(VolumeMultiple)]
temp[ProductID == 'ru'][,unique(VolumeMultiple)]

## =============================================================================
## 变化的新闻链接：
## 燃料油期货新合约及实施细则公布
## http://www.360doc.com/content/11/0115/21/3588466_86775920.shtml
## 
## 上期所修改天然橡胶标准合约及相关实施细则
## http://www.qinrex.cn/news/show-10932.html
## 
## TC --> ZC
## 关于修改动力煤期货合约的通知
## https://www.citicsf.com/html/554314.html
## =============================================================================


## =============================================================================
dbSendQuery(mysql, "truncate table info")
dbWriteTable(mysql, 'info',
             infoRes[VolumeMultiple != 0], row.names = FALSE, append = TRUE)
## =============================================================================





## =============================================================================
mysql <- mysqlFetch('FromDC', host = '192.168.1.166')
info <- dbGetQuery(mysql, "
        select * from info
    ") %>% as.data.table()

updatePriceTick <- function(x) {
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
            lag40  = shift(PriceTick, 40L, type = 'lag'),
            lag45  = shift(PriceTick, 45L, type = 'lag'),
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
            lead45 = shift(PriceTick, 45L, type = 'lead'),
            lead50 = shift(PriceTick, 50L, type = 'lead'),
            lead55 = shift(PriceTick, 55L, type = 'lead')
        )]
    tempRes[, ":="(lagM = 0, leadM = 0)]

    cols <- c('lag01','lag02','lag03','lag04','lag05','lag06','lag07','lag08','lag09',
              'lag15','lag20','lag25','lag30','lag35','lag40','lag45',
              'lead01','lead02','lead03','lead04','lead05','lead06','lead07','lead08','lead09',
              'lead15','lead20','lead25','lead30','lead35','lead40','lead45','lead50','lead55')
    tempRes[, (cols) := lapply(.SD, function(x){
        ifelse(is.na(x), 0, x)
    }), .SDcol = cols]

    for (i in 1:nrow(tempRes)) {
        a <- tempRes[i, (c(lag01, lag02, lag03, lag04, lag05,
                           lag06, lag07, lag08, lag09,
                           lag15,lag20,lag25,lag30,lag35,lag40,lag45))] %>% .[. != 0]
        if (length(a) < 1) {
          tempRes$lagM[i] <- 0
        } else {
          tempRes$lagM[i] <- as.data.table(table(a))[which.max(N),a] %>% as.numeric()
        }

        b <- tempRes[i, (c(lead01, lead02, lead03, lead04, lead05,
                           lead06, lead07, lead08, lead09,
                           lead15,lead20,lead25,lead30,lead35,
                           lead40,lead45,lead50,lead55))] %>% .[. != 0]
        if (length(b) < 1) {
          tempRes$leadM[i] <- 0
        } else {
          tempRes$leadM[i] <- as.data.table(table(b))[which.max(N),b] %>% as.numeric()
        }
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

        if (nchar(as.character(y)) > 2 & y > 100) y <- 0
        return(y)
    })
    
    if (sum(res) != 0) {
      temp <- as.data.table(table(res[res != 0])) %>% 
              .[nchar(as.character(V1)) <= 2 | V1 <= 100]

      if (length(res[res == min(res[res != 0])]) >= length(res)/3 |
          length(res[res == min(res[res != 0])]) >= 20 |
          length(res[res != min(res[res != 0])]) < length(res)/3) {
        res <- rep(min(res[res != 0]), length(res))
      } else {
        res <- rep(as.numeric(temp[which.max(N), V1]),length(res))
      }
    }

    return(res)
    ## =========================================================================
}


tempDt = info[InstrumentID == 'SM508']
tempDt = info[InstrumentID == 'fb1603']
tempDt = info[InstrumentID == 'j1207']
tempDt = info[InstrumentID == 'ZC605']
tempDt = info[InstrumentID == 'SM511']
tempDt = info[InstrumentID == 'SF710']
tempDt[,unique(PriceTick)]
tempDt[, PriceTick := updatePriceTick(.SD), by = "InstrumentID"]
tempDt[,unique(PriceTick)]
# View(tempDt)

info[is.na(PriceTick)]
info[,unique(PriceTick)]

## =============================================================================
setkey(info, 'InstrumentID')
cl <- makeCluster(max(round(detectCores()*3/4),20), type='FORK')
infoRes <- parLapply(cl, info[,unique(InstrumentID)], function(id){
  tempDt <- info[id]
  for (tt in 1:2) {
    tempDt[, PriceTick := updatePriceTick(.SD), by = "InstrumentID"]
  }
  return(tempDt)
}) %>% rbindlist()
stopCluster(cl)
## =============================================================================
infoRes[,unique(PriceTick)]
## =============================================================================

# setkey(info, 'InstrumentID')
# infoRes <- list()
# for (i in 1:length(info[,unique(InstrumentID)])) {
#   print(paste(i,":--",info[unique(InstrumentID)[i],unique(InstrumentID)]))
#   tempDt <- info[unique(InstrumentID)[i]]
#   for (tt in 1:3) {
#     tempDt[, PriceTick := updatePriceTick(.SD), by = "InstrumentID"]
#   }
#   print(tempDt[,unique(PriceTick)])
#   infoRes[[i]] <- tempDt
# }

## =============================================================================
infoRes[, ProductID := gsub('[0-9]','',InstrumentID)]
for (id in infoRes[,unique(ProductID)]) {
  print(id)
  print(
    infoRes[ProductID == id][,unique(PriceTick)]
    )
  tempPriceTick <- infoRes[ProductID == id][PriceTick != 0][,unique(PriceTick)]
  if (length(tempPriceTick) == 1) {
    infoRes[ProductID == id, PriceTick := tempPriceTick]
  }
}

# infoRes[ProductID == 'fb'][PriceTick != 4.1][,unique(PriceTick)]
## =============================================================================
infoRes[,unique(PriceTick)]
infoRes[, ProductID := NULL]

dbSendQuery(mysql, "truncate table info")
dbWriteTable(mysql, 'info',
             infoRes[PriceTick != 0], row.names = FALSE, append = TRUE)
## =============================================================================


## =============================================================================
mysql <- mysqlFetch('china_futures_info', host = '192.168.1.166')
infoNew <- dbGetQuery(mysql, "
  select TradingDay, InstrumentID, PriceTick, VolumeMultiple
  from Instrument_info
  ") %>% as.data.table() %>% 
  .[nchar(InstrumentID) < 8]
## =============================================================================
dt <- merge(infoRes, infoNew, by = c('TradingDay','InstrumentID'), all = TRUE)
dt[VolumeMultiple.x != VolumeMultiple.y]
dt[PriceTick.x != PriceTick.y]

dt[is.na(PriceTick.x), PriceTick.x := PriceTick.y]
dt[is.na(VolumeMultiple.x), VolumeMultiple.x := VolumeMultiple.y]

dtRes <- dt[, .(TradingDay, InstrumentID,
                PriceTick = PriceTick.x,
                VolumeMultiple = VolumeMultiple.x)]
mysql <- mysqlFetch('FromDC', host = '192.168.1.166')
dbSendQuery(mysql, "truncate table info")
dbWriteTable(mysql, 'info',
             dtRes, row.names = FALSE, append = TRUE)
