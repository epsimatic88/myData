########################################################################## 
for(cc in 1:length(tempContract)){
  
  if(gsub("[0-9]","", tempContractID[cc]) != tempPP[pp,conName]) next
  
  destFile <- paste0('./',tempTradingDays[k,year],'/',
                     tempTradingDays[k,TradingDay],'_',
                     tempContractID[cc],'.xlsx')
  
  if(file.exists(destFile)){
    tempDataFile <- readxl::read_excel(destFile)
    if(grepl('总计',tempDataFile$名次[nrow(tempDataFile)])){
      next
    }else{
      file.remove(destFile)
    }
  }
  
  ## 找到合约的 ClickRadio
  tempClickRadio <- remDr$findElements(using = 'xpath', value = "//*/input[@type='radio']")
  tempClickRadioContract  <- tempClickRadio[-(1:16)]
  tempClickRadioContract[[cc]]$clickElement()
  Sys.sleep(.1)
  
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
  if (!any(grepl(tempContractID[cc],tempCheckInfo)) | 
     !any(grepl(tempTradingDays[k,TradingDay],tempCheckInfo))) {
    next
  }
  
  #-- 找到数据
  if(class(try(tempData <- remDr$findElement(using = 'class', value = 'dataArea'))) == 'try-error'){
    next
  }


  webData <- tempData$getElementAttribute('outerHTML')[[1]] %>% 
    read_html() %>% 
    html_nodes('table') %>% 
    html_table(fill = TRUE) %>% 
    .[[2]]
  
  print(webData)
  
  ##======================================================================
  if(!file.exists(destFile) & nrow(webData) != 0){
      openxlsx::write.xlsx(webData, file = destFile,
                           colNames = TRUE, rowNames = FALSE)
  }
  ##======================================================================
}
##########################################################################
