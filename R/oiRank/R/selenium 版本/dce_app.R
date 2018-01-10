print(paste("## :==>",productID))

## ===========================================================================
## 所有的品种所对应的选择
productClickRadio <- remDr$findElements(using = 'xpath', value = "//*/input[contains(@type,'radio')]")
if (class(try(
  productClickRadio[[which(product == productID)]]$clickElement()
  )) =='try-error') {
  next
}
Sys.sleep(ifelse(tryNo <= 3, 1, sqrt(tryNo)+2))

if (class(try(
  tempCheckAll <- remDr$findElement(using = 'class', value = 'dataArea')
  )) == 'try-error'){
  next
}

## 检查当天是不是有该品种的持仓排名数据
tempCheckAllTable <- tempCheckAll$getElementAttribute('outerHTML')[[1]] %>% 
  read_html() %>% 
  html_nodes('table') %>% 
  html_table(fill = TRUE) %>% 
  .[[2]]

if (nrow(tempCheckAllTable) < 2) next

## 是不是有合约数据
tempContract <- remDr$findElements(using = 'class', value = 'keyWord_65')
if (length(tempContract) == 0) next
## ===========================================================================

## ===========================================================================
contract <- remDr$getPageSource()[[1]] %>% 
  read_html() %>% 
  html_nodes('.tradeSel .clearfix .keyWord_65') %>% 
  html_text() %>% 
  gsub('\\n|\\t| ','',.)
print('----------------------------------------------------------------------')
print(contract)
print('----------------------------------------------------------------------')
## ===========================================================================

for (contractID in contract) {
  if (gsub("[0-9]","", contractID) != productID) next

  destFile <- paste0(dataPath, exchCalendar[i,calendarYear],'/',
                     exchCalendar[i,days],'_',
                     contractID,'.xlsx')
  ## ---------------------------------------------------------------------------
  if (file.exists(destFile)) {
    tempDataFile <- readxl::read_excel(destFile)
    if (grepl('总计',tempDataFile$名次[nrow(tempDataFile)])) {
      next
    } else {
      file.remove(destFile)
    }
  }
  ## ---------------------------------------------------------------------------

  ## ===========================================================================
  ## 开始下载数据
  ## 找到合约的 ClickRadio
  tempClickRadio <- remDr$findElements(using = 'xpath', value = "//*/input[@type='radio']")
  tempClickRadioContract  <- tempClickRadio[-(1:16)]
  tempClickRadioContract[[which(contract == contractID)]]$clickElement()
  Sys.sleep(ifelse(tryNo <= 3, 1, sqrt(tryNo)+2))

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
  Sys.sleep(ifelse(tryNo <= 3, 1, sqrt(tryNo)+2))

  ##-- 如果数据表格没有更新，则跳过
  if (!any(grepl(contractID,tempCheckInfo)) | 
     !any(grepl(exchCalendar[i,days],tempCheckInfo))) {
    next
  }

  #-- 找到数据
  if (class(try(
    tempData <- remDr$findElement(using = 'class', value = 'dataArea')
    )) == 'try-error') {
    next
  }
  Sys.sleep(ifelse(tryNo <= 3, 1, sqrt(tryNo)+2))

  webData <- tempData$getElementAttribute('outerHTML')[[1]] %>% 
    read_html() %>% 
    html_nodes('table') %>% 
    html_table(fill = TRUE) %>% 
    .[[2]]

  if (nrow(webData) >= 2 & grepl('总计',webData[nrow(webData),1])) {
    print(webData)
    openxlsx::write.xlsx(webData, file = destFile,
                         colNames = TRUE, rowNames = FALSE)
  }
  ## ===========================================================================
  Sys.sleep(.5)
}
