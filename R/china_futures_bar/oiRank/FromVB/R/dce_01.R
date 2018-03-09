##--------------------------------------------------------------------------
## 以下用于选择交易日期
##--------------------------------------------------------------------------
##-- 选择年份
##-- 选择年份
if(tempTradingDays[k,year] ==  format(Sys.Date(),"%Y")){
  for(yy in 1:2){
    tempYear <- remDr$findElement(using = 'xpath', 
                                  value = paste0("//*/option[@value='",
                                                 tempTradingDays[k,year],"']")
    )
    tempYear$clickElement()
  }
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
## tempDay <- remDr$findElements(using = 'tag name', value = "td")
tempDay <- remDr$findElements(using = 'xpath', value = "//*/tbody/tr/td")
#R> length(tempDay)
#R> tempDay[[17]]$highlightElement()
#R> tempDay[[18]]$clickElement()

## 
tempTable <- remDr$findElements(using = 'id', value = "calender")
#R> length(tempTable)
#R> tempTable[[1]]$highlightElement()
tempCalendar <- tempTable[[1]]$getElementAttribute('outerHTML')[[1]] %>% 
  read_html() %>% 
  html_nodes('table') %>% 
  html_table(fill = TRUE) %>% 
  .[[1]]

tempDayID <- unlist(t(tempCalendar))
tempDayClick <- which(tempDayID == tempTradingDays[k,day])


## 最后确定选择的 Day
tempDay[[tempDayClick]]$clickElement()
Sys.sleep(1)

# tempAll <- remDr$findElements(using = 'xpath', value = "//*/input[contains(@onclick,'all')]")
## length(tempAll)
#tempAll[[1]]$highlightElement()
##-- 看看是否需要选择全部
# tempAll[[1]]$clickElement()

##--------------------------------------------------------------------------

##--------------------------------------------------------------------------
## 以下用于选择品种
##--------------------------------------------------------------------------
##-- 品种
## tempInfo <- remDr$findElements(using = 'class', value = "selBox")
## tempProduct <- remDr$findElements(using = 'css selector', value = '.keyWord_100')
#R> length(tempProduct)
#R> tempProduct[[2]]$highlightElement()

## all:选择全部的合约，
## 也就是一个品种的汇总数据
# tempInfo <- remDr$findElements(using = 'class', value = "selBox")
## tempAll <- remDr$findElements(using = 'xpath', value = "//*/input[@type='checkbox']")
# tempAll <- remDr$findElements(using = 'xpath', value = "//*/input[contains(@onclick,'all')]")
#R> length(tempAll)
#R> tempAll[[1]]$highlightElement()
##-- 看看是否需要选择全部
# tempAll[[1]]$clickElement()
