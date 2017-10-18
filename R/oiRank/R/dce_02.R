##--------------------------------------------------------------------------
## 以下开始循环下载数据
##--------------------------------------------------------------------------

##-- 品种
remDr$open(silent = T)
remDr$deleteAllCookies()
remDr$navigate(exchURL)
# Sys.sleep(1)
source('../../R/dce_01.R', encoding = 'UTF-8', echo=TRUE)
Sys.sleep(1)
for(pp in 1:nrow(tempPP)){
  # Sys.sleep(1)
  ## remDr$refresh()
  # Sys.sleep(10)
  print(paste(tempPP[pp,id],":==>",tempPP[pp,conName]))
  

  tempClickRadio <- remDr$findElements(using = 'xpath', value = "//*/input[contains(@type,'radio')]")
  if(class(try(tempClickRadio[[pp]]$clickElement())) =='try-error'){
    Sys.sleep(0.5)
    next
  }

  Sys.sleep(.5)
  
  ##----------------------------------------------------------------------------
  if(class(try(tempCheckAll <- remDr$findElement(using = 'class', value = 'dataArea'))) == 'try-error'){
    next
  }
  
  tempCheckAllTable <- tempCheckAll$getElementAttribute('outerHTML')[[1]] %>% 
    read_html() %>% 
    html_nodes('table') %>% 
    html_table(fill = TRUE) %>% 
    .[[2]]
  
  if(nrow(tempCheckAllTable) < 2){
    next
  }
  ##----------------------------------------------------------------------------
  ##
  ## 合约
  # tempInfo <- remDr$findElements(using = 'class', value = "selBox")
  tempContract <- remDr$findElements(using = 'class', value = 'keyWord_65')
  #R> length(tempContract)
  #R> tempContract[[1]]$highlightElement()
  ## 合约的名称
  #Sys.sleep(.1)
  print('##################################################################################')
  # tempContractID <- sapply(tempContract, function(x){
  #   x$getElementAttribute('outerHTML')[[1]] %>% 
  #     read_html() %>% 
  #     html_node('.keyWord_65') %>% 
  #     html_text() %>% 
  #     gsub('\\n|\\t| ','',.)
  # })
  # 
  
  if(length(tempContract) == 0){
    next
  }
  
  tempContractID <- remDr$getPageSource()[[1]] %>% 
    read_html() %>% 
    html_nodes('.tradeSel .clearfix .keyWord_65') %>% 
    html_text() %>% 
    gsub('\\n|\\t| ','',.)
  #
  print(tempContractID)
  # Sys.sleep(1)
  print('##################################################################################')
  
  ########################################################################## 
  try(
    source('../../R/dce_03.R', encoding = 'UTF-8', echo=TRUE)
  )
  ########################################################################## 
  
}
  
remDr$close()
Sys.sleep(.1)
