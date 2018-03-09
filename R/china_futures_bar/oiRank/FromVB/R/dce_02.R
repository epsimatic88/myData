##--------------------------------------------------------------------------
## 以下开始循环下载数据
##--------------------------------------------------------------------------

##-- 品种
# tempInfo <- remDr$findElements(using = 'class', value = "selBox")
# tempProduct <- remDr$findElements(using = 'css selector', value = '.keyWord_100')

remDr$open()
remDr$deleteAllCookies()
remDr$navigate(exchURL)
source('../../../R/dce_01.R', encoding = 'UTF-8', echo=TRUE)

tempPP <- data.table(id = seq(1:16),
                     conName = c('a','b','m','y','p','c','cs','jd',
                                 'fb','bb','l','v','pp','j','jm','i')
                     )
for(pp in 1:nrow(tempPP)){
  ## remDr$refresh()
  # Sys.sleep(10)
  print(paste(tempPP[pp,id],":==>",tempPP[pp,conName]))
  ##-- 开始模拟鼠标点击网页
  ## 一共有多少个 ClickRadio
  ## 应该是等于 product + contract 的数量
  ## 
  Sys.sleep(.1)
  
  #for(ppp in 1:1){
    tempClickRadio <- remDr$findElements(using = 'xpath', value = "//*/input[contains(@type,'radio')]")
    #R> length(tempClickRadio)
    
    # tempClickRadio[[pp]]$clickElement()
    # tempClickRadio[[pp]]$highlightElement()
    if(class(try(tempClickRadio[[pp]]$clickElement())) =='try-error'){
      next
    }
  #  Sys.sleep(.5)
  #}
  Sys.sleep(5)
  
  ##----------------------------------------------------------------------------
  if(class(try(tempCheckAll <- remDr$findElement(using = 'class', value = 'dataArea'))) == 'try-error'){
    #remDr$close()
    next
  }
  
  # tempCheckAll <- remDr$findElement(using = 'class', value = 'dataArea')
  ## length(tempCheckAll)
  tempCheckAllTable <- tempCheckAll$getElementAttribute('outerHTML')[[1]] %>% 
    read_html() %>% 
    html_nodes('table') %>% 
    html_table(fill = TRUE) %>% 
    .[[2]]
  
  if(nrow(tempCheckAllTable) < 2){
    #remDr$close()
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
  Sys.sleep(.1)
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
    #remDr$close()
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
#  for(tt in 1:2){
    try(
      source('../../../R/dce_03.R', encoding = 'UTF-8', echo=TRUE)
    )
#  }
  ########################################################################## 
  
  
  ########################################################################## 
  ## remDr$quit()
  ## remDr$open()
  ##########################################################################
  Sys.sleep(2)
}
remDr$close()