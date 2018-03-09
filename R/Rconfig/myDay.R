myDay <- data.table(
  hour   = seq(0,86399,by=1) %/% 3600,
  minute = (seq(0,86399,by=1) %% 3600) %/% 60,
  second = (seq(0,86399,by=1) %% 3600) %% 60,
  id     = seq(0,86399,by=1) + 1
)

myDay <- rbind(myDay[id %between% c(20*3600+58*60+1, 24*3600)],                 ## 20:58 -- 24:00,包含集合竞价
               myDay[id %between% c(0, 2*3600+30*60)],                          ## 00:00 -- 02:30
               myDay[id %between% c(8*3600+58*60+1, 11*3600+30*60)],            ## 08:58 -- 11:30,包含集合竞价
               myDay[id %between% c(13*3600+1, 15*3600+15*60)]                  ## 13:00 -- 15:15
) %>%
  .[,':='(
    trading_period = paste(sprintf('%02d', hour),
                          sprintf('%02d', minute),
                          sprintf('%02d', second),
                          sep = ':')
  )]
#-------------------------------------------------------------------------------
# myDay2

myDayPlus <- data.table(
  hour   = seq(0,86399,by=1) %/% 3600,
  minute = (seq(0,86399,by=1) %% 3600) %/% 60,
  second = (seq(0,86399,by=1) %% 3600) %% 60,
  id     = seq(0,86399,by=1) + 1
)

myDayPlus <- rbind(myDayPlus[id %between% c(20*3600+58*60+1, 24*3600)],         ## 20:58 -- 24:00,包含集合竞价
               myDayPlus[id %between% c(0, 2*3600+45*60)],                      ## 00:00 -- 02:45
               myDayPlus[id %between% c(8*3600+58*60+1, 11*3600+30*60+1)],      ## 08:58 -- 11:30,包含集合竞价
               myDayPlus[id %between% c(13*3600+1, 15*3600+30*60)]              ## 13:00 -- 15:30
) %>%
  .[,':='(
    trading_period = paste(sprintf('%02d', hour),
                           sprintf('%02d', minute),
                           sprintf('%02d', second),
                           sep = ':')
  )]
