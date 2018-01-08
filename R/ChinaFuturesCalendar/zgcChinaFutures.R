### 2011
daysInYear <- as.numeric(as.Date("2011-12-31")-as.Date("2011-01-01"))
days <- as.Date(0:daysInYear, origin="2011-01-01")
days <- days[-which(weekdays(days) %in% c("Saturday", "Sunday"))]
days <- days[-c(
                  which(days>="2011-01-01"&days<="2011-01-03"),
                  which(days>="2011-02-02"&days<="2011-02-08"),
                  which(days>="2011-04-03"&days<="2011-04-05"),
                  which(days>="2011-04-30"&days<="2011-05-02"),
                  which(days>="2011-06-04"&days<="2011-06-06"),
                  which(days>="2011-09-10"&days<="2011-09-12"),
                  which(days>="2011-10-01"&days<="2011-10-07")
              )]
nights <- rep(as.Date(NA), length(days))
res2011 <- data.frame(nights,
                      days)

### 2012
daysInYear <- as.numeric(as.Date("2012-12-31")-as.Date("2012-01-01"))
days <- as.Date(0:daysInYear, origin="2012-01-01")
days <- days[-which(weekdays(days) %in% c("Saturday", "Sunday"))]
days <- days[-c(
                  which(days>="2012-01-01"&days<="2012-01-03"),
                  which(days>="2012-01-22"&days<="2012-01-28"),
                  which(days>="2012-04-02"&days<="2012-04-04"),
                  which(days>="2012-04-29"&days<="2012-05-01"),
                  which(days>="2012-06-22"&days<="2012-06-24"),
                  which(days>="2012-10-01"&days<="2012-10-07")
              )]
nights <- rep(as.Date(NA), length(days))
res2012 <- data.frame(nights,
                      days)


### 2013
daysInYear <- as.numeric(as.Date("2013-12-31")-as.Date("2013-01-01"))
days <- as.Date(0:daysInYear, origin="2013-01-01")
days <- days[-which(weekdays(days) %in% c("Saturday", "Sunday"))]
days <- days[-c(
                  which(days>="2013-01-01"&days<="2013-01-03"),
                  which(days>="2013-02-09"&days<="2013-02-15"),
                  which(days>="2013-04-04"&days<="2013-04-06"),
                  which(days>="2013-04-29"&days<="2013-05-01"),
                  which(days>="2013-06-10"&days<="2013-06-12"),
                  which(days>="2013-09-19"&days<="2013-09-21"),
                  which(days>="2013-10-01"&days<="2013-10-07")
              )]
nights <- c(as.Date(NA), days[-length(days)])
nights[which(as.character(nights)<"2013-07-05")] <- NA
nights[which(as.character(nights) %in% c(
                             "2013-09-18",
                             "2013-09-30"
                         ))] <- NA
res2013 <- data.frame(nights,
                      days)


### 2014
daysInYear <- as.numeric(as.Date("2014-12-31")-as.Date("2014-01-01"))
days <- as.Date(0:daysInYear, origin="2014-01-01")
days <- days[-which(weekdays(days) %in% c("Saturday", "Sunday"))]
days <- days[-c(
                  which(days>="2014-01-01"&days<="2014-01-01"),
                  which(days>="2014-01-31"&days<="2014-02-06"),
                  which(days>="2014-04-05"&days<="2014-04-07"),
                  which(days>="2014-05-01"&days<="2014-05-03"),
                  which(days>="2014-05-31"&days<="2014-06-02"),
                  which(days>="2014-09-06"&days<="2014-09-08"),
                  which(days>="2014-10-01"&days<="2014-10-07")
              )]
nights <- c(as.Date(NA), days[-length(days)])
nights[which(as.character(nights) %in% c(
                             "2014-01-30",
                             "2014-04-04",
                             "2014-04-30",
                             "2014-05-30",
                             "2014-09-05",
                             "2014-09-30"
                         ))] <- NA
res2014 <- data.frame(nights,
                      days)

### 2015
daysInYear <- as.numeric(as.Date("2015-12-31")-as.Date("2015-01-01"))
days <- as.Date(0:daysInYear, origin="2015-01-01")
days <- days[-which(weekdays(days) %in% c("Saturday", "Sunday"))]
days <- days[-c(
                  which(days>="2015-01-01"&days<="2015-01-03"),
                  which(days>="2015-02-18"&days<="2015-02-24"),
                  which(days>="2015-04-05"&days<="2015-04-06"),
                  which(days>="2015-05-01"&days<="2015-05-01"),
                  which(days>="2015-06-20"&days<="2015-06-22"),
                  which(days>="2015-09-03"&days<="2015-09-05"),
                  which(days>="2015-09-27"&days<="2015-09-27"),
                  which(days>="2015-10-01"&days<="2015-10-07")
              )]
nights <- c(as.Date(NA), days[-length(days)])
nights[which(as.character(nights) %in% c(
                             "2015-02-17",
                             "2015-04-03",
                             "2015-04-30",
                             "2015-06-19",
                             "2015-09-02",
                             "2015-09-25",
                             "2015-09-30"
                         ))] <- NA
res2015 <- data.frame(nights,
                      days)


### 2016
daysInYear <- as.numeric(as.Date("2016-12-31")-as.Date("2016-01-01"))
days <- as.Date(0:daysInYear, origin="2016-01-01")
days <- days[-which(weekdays(days) %in% c("Saturday", "Sunday"))]
days <- days[-c(
                  which(days>="2016-01-01"&days<="2016-01-03"),
                  which(days>="2016-02-07"&days<="2016-02-13"),
                  which(days>="2016-04-02"&days<="2016-04-04"),
                  which(days>="2016-04-30"&days<="2016-05-02"),
                  which(days>="2016-06-09"&days<="2016-06-11"),
                  which(days>="2016-09-15"&days<="2016-09-17"),
                  which(days>="2016-10-01"&days<="2016-10-07")
              )]
nights <- c(as.Date(NA), days[-length(days)])
nights[which(as.character(nights) %in% c(
                             "2016-02-05",
                             "2016-04-01",
                             "2016-04-29",
                             "2016-06-08",
                             "2016-09-14",
                             "2016-09-30",
                             "2016-12-30"
                         ))] <- NA
res2016 <- data.frame(nights,
                      days)


#### 2017
daysInYear <- as.numeric(as.Date("2017-12-31")-as.Date("2017-01-01"))
days <- as.Date(0:daysInYear, origin="2017-01-01")
days <- days[-which(weekdays(days) %in% c("Saturday", "Sunday"))]
days <- days[-c(
                  which(days>="2017-01-01"&days<="2017-01-02"),
                  which(days>="2017-01-27"&days<="2017-02-02"),
                  which(days>="2017-04-02"&days<="2017-04-04"),
                  which(days>="2017-04-29"&days<="2017-05-01"),
                  which(days>="2017-05-28"&days<="2017-05-30"),
                  which(days>="2017-10-01"&days<="2017-10-08")
              )]
nights <- c(as.Date(NA), days[-length(days)])
nights[which(as.character(nights) %in% c(
                             "2017-01-26",
                             "2017-03-31",
                             "2017-04-28",
                             "2017-05-26",
                             "2017-09-29"
                         ))] <- NA
res2017 <- data.frame(nights,
                      days)


### output
res <- rbind(res2011, res2012, res2013, res2014, res2015, res2016, res2017)
write.csv(res, file="/data/Calendar/ChinaFutures.csv", row.names=FALSE, quote=FALSE)
