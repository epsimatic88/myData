##--------------------------------------------------------------------------
## 以下用于选择交易日期
##--------------------------------------------------------------------------
##-- 选择年份
##-- 选择年份
if(tempTradingDays[k,year] ==  format(Sys.Date(),"%Y")){
  NULL
}else{
  tempYear <- remDr$findElement(using = 'xpath', 
                                value = paste0("//*/option[@value='",
                                               tempTradingDays[k,year],"']")
  )
  tempYear$clickElement()
}

if(tempTradingDays[k,as.numeric(month)] == as.numeric(format(Sys.Date(),"%m"))){## 当前月份
  for(mm in 1:2){
    ##-- 选择月份
    ## 如果时当月，需要点击两次
    tempMonth <- remDr$findElement(using = 'xpath', 
                                   value = paste0("//*/option[@value='",
                                                  tempTradingDays[k,as.numeric(month)-1],"']"))
    tempMonth$clickElement()  
  }
}else{
  ##-- 选择月份
  tempMonth <- remDr$findElement(using = 'xpath', 
                                 value = paste0("//*/option[@value='",
                                                tempTradingDays[k,as.numeric(month)-1],"']"))
  tempMonth$clickElement()  
}


##-- 选择天，需要跑循环
tempDay <- remDr$findElements(using = 'xpath', value = "//*/tbody/tr/td")

## 
tempTable <- remDr$findElements(using = 'id', value = "calender")

tempCalendar <- tempTable[[1]]$getElementAttribute('outerHTML')[[1]] %>% 
  read_html() %>% 
  html_nodes('table') %>% 
  html_table(fill = TRUE) %>% 
  .[[1]]

tempDayID <- unlist(t(tempCalendar))
tempDayClick <- which(tempDayID == tempTradingDays[k,day])

## 最后确定选择的 Day
tempDay[[tempDayClick]]$clickElement()
Sys.sleep(0.1)
