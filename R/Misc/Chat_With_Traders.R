################################################################################
## Chat_With_Traders.R
## 
## 用于下载 Chat With Traders 的音频
## 
## Author: fl@hicloud-investment.com
## CreateDate: 2017-10-20
################################################################################

################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})

# dataPath <- '/home/fl/myListening/ChatWithTraders'
dataPath <- '/home/william/Downloads/ChatWithTraders'
if (!dir.exists(dataPath)) dir.create(dataPath, recursive = TRUE)

################################################################################
## STEP 1: 网页解析
################################################################################
URL <- 'https://chatwithtraders.com/podcast-episodes/'
articleLink <- URL %>% 
        read_html() %>% 
        html_nodes('.wpb_row h5 a') %>% 
        html_attr('href') %>% 
        .[grep('.*[0-9]{3}.*',.)]
articleTitle <- URL %>% 
        read_html() %>% 
        html_nodes('.wpb_row h5 a') %>% 
        html_text() %>% 
        .[grep('.*[0-9]{3}:.*',.)]

## =============================================================================
fetchData <- function(url) {
    # url <- allURL[1]
    tempLink <- url %>% 
            read_html() %>% 
            html_nodes('a') %>% 
            html_attr('href')

    tempLink <- url %>% 
            read_html() %>% 
            html_nodes('.player a') %>% 
            html_attr('href')

    ## -------------------------------------------------------------------------
    sapply(1:length(tempLink), function(k){
        tempPath <- paste0(dataPath, '/', tempTitle[k])
        if (!dir.exists(tempPath)) dir.create(tempPath, recursive = TRUE)
        destFile <- paste0(tempPath, '/', tempTitle[k], '.mp3')

        tryNo <- 1
        while (!file.exists(destFile) & tryNo < 10) {
            try(
                download.file(tempLink[k], destFile, mode = 'wb')
            )
            tryNo <- tryNo + 1
        }
    })
    ## -------------------------------------------------------------------------
}
## =============================================================================


## =============================================================================
cl <- makeCluster(max(round(detectCores()*3/4),4), type='FORK')
parSapply(cl, allURL, fetchData)
stopCluster(cl)
## =============================================================================
