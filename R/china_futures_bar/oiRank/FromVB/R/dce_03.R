########################################################################## 
for(cc in 1:length(tempContract)){
  
  if(gsub("[0-9]","", tempContractID[cc]) != tempPP[pp,conName]){
    next
  }
  
  destFile <- paste0('./',tempTradingDays[k,year],'/',
                     tempTradingDays[k,TradingDay],'_',
                     tempContractID[cc],'.xlsx')
  
  if(file.exists(destFile)){
    ##--- 返回上一层目录
    ## setwd("../..")
    next
  }
  
  ## 找到合约的 ClickRadio
  tempClickRadio <- remDr$findElements(using = 'xpath', value = "//*/input[@type='radio']")
  tempClickRadioContract  <- tempClickRadio[-(1:16)]
  tempClickRadioContract[[cc]]$clickElement()
  Sys.sleep(1)
  
  ## 查看是否网页有更新
  ## 
  tempCheck <- remDr$findElements(using = "xpath",
                                  value = "//*/span")
  tempCheckInfo <- sapply(1:length(tempCheck), function(ii){
    y <- tempCheck[[ii]]$getElementAttribute('outerHTML')[[1]] %>% 
      read_html() %>% 
      html_nodes('span') %>% 
      html_text() %>% 
      gsub("\\n|\\t","",.) %>% 
      strsplit(.," |：") %>% 
      unlist()
  }) %>% unlist() %>% .[nchar(.) >1]
  
  ##-- 如果数据表格没有更新，则跳过
  if(!any(grepl(tempContractID[cc],tempCheckInfo)) | !any(grepl(tempTradingDays[k,TradingDay],tempCheckInfo))){
    next
  }
  
  #-- 找到数据
  tempData <- remDr$findElement(using = 'class', value = 'dataArea')
  Sys.sleep(.5)
  
  webData <- tempData$getElementAttribute('outerHTML')[[1]] %>% 
    read_html() %>% 
    html_nodes('table') %>% 
    html_table(fill = TRUE) %>% 
    .[[2]]
  
  print(head(webData,20))
  
  ##======================================================================
  if(!file.exists(destFile) & nrow(webData) != 0){
    openxlsx::write.xlsx(webData, file = destFile,
                         colNames = TRUE, rowNames = FALSE)
  }
  ##======================================================================
  if(nrow(webData) < 10){
    Sys.sleep(0.2)
  }else{
    Sys.sleep(2)
  }
  
}
##########################################################################