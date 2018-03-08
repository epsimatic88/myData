## =============================================================================
## jrj.R
##
## 下载 金融界 研究报告
##
## Author : fl@hicloud-investment.com
## Date   : 2018-03-07
## =============================================================================

## =============================================================================
setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
library(httr)
library(rjson)
library(downloader)
## =============================================================================

## -----------------------------------------------------------------------------
SAVE_PATH <- "/data/ChinaStocks/Report/FromJRJ"
if (!dir.exists(SAVE_PATH)) dir.create(SAVE_PATH)
## -----------------------------------------------------------------------------

url <- "http://stock.jrj.com.cn/action/yanbao/getAllYanBaoList.jspa"
tempHeaders <- c(
    'Accept'           = 'text/javascript, application/javascript, application/ecmascript, application/x-ecmascript, */*; q=0.01',
    'Accept-Encoding'  = 'gzip, deflate',
    'Accept-Language'  = 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6',
    'Connection'       = 'keep-alive',
    'DNT'              = '1',
    'Host'             = 'stock.jrj.com.cn',
    'Referer'          = 'http://stock.jrj.com.cn/yanbao/yanbaolist_all.shtml?pn=1&ps=20&orgCode=-1&dateInterval=3650',
    'User-Agent'       = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3298.3 Safari/537.36',
    'X-Requested-With' = 'XMLHttpRequest'
    )

## -----------------------------------------------------------------------------
## 获取总共的页面数量
## 这里假设每次只查询 20 个文章
## -----------------------
payload <- list(
    vname        = "yanbaolist",
    pn           = "2",
    ps           = "20",
    orgCode      = "-1",
    dateInterval = "3650"
    )
r <- GET(url, query = payload, add_headers(tempHeaders))
p <- content(r, as = 'text')
infoData <- gsub("var yanbaolist=|;", "", p) %>% fromJSON()

totalPapers <- infoData$summary$total
totalPages <- round(totalPapers/20) + 1
## -----------------------------------------------------------------------------


## =============================================================================
dt <- lapply(1:2000, function(i){  ## totalPages
  # print(i)
    payload <- list(
        vname        = "yanbaolist",
        pn           = as.character(i),
        ps           = "20",
        orgCode      = "-1",
        dateInterval = "3650"
        )
    if (class(try(
      r <- GET(url, query = payload, add_headers(tempHeaders))
        )) == 'try-error') {
      return(data.table())
      }

    p <- content(r, as = 'text')

    if (class(try(
      infoData <- gsub("var yanbaolist=|;", "", p) %>% fromJSON()
    )) == 'try-error') {
      return(data.table())
    }


    ## -------------------------------------------------------------------------
    if (length(infoData$data) != 0) {
        webData <- infoData$data
        res <- lapply(1:length(webData), function(j){
            temp <- webData[[j]]
            data.table(TradingDay = temp[1],
                       reportClass = temp[2],
                       reportClassID = temp[3],
                       title = temp[4],
                       author = temp[5],
                       reportID = temp[6],
                       brokerName = temp[8],
                       brokerID = temp[7],
                       industryClass = temp[10],
                       industryID = temp[9])
        }) %>% rbindlist()
    } else {
        res <- data.table()
    }
    print(res)
    Sys.sleep(1)
    ## -------------------------------------------------------------------------
    return(res)
}) %>% rbindlist()
## =============================================================================


## =============================================================================
## 下载研报内容
## 主要是读取网页信息
## 然后获取研报的链接
## ---------------
fetch_report_from_jrt <- function(reportID) {
    url <- paste0('http://istock.jrj.com.cn/article,yanbao,', reportID, '.html')
    r <- GET(url)
    p <- content(r, 'text')
    link <- p %>%
        read_html() %>%
        html_nodes('#replayContent a') %>%
        html_attr('href') %>%
        .[!is.na(.)] %>%
        .[!grepl('javascript',.)] %>%
        grep('\\.pdf|\\.docx|\\.doc', ., value = T)
    if (length(link) == 0) return(NA)
    return(link)
}
## =============================================================================


for (i in 1:nrow(dt)) {
    print(i)

    ## --------------------------------------------
    ## 返回文章链接
    if (class(try(
      l <- fetch_report_from_jrt(dt[i, reportID])
             )) == 'try-error') {
      next
    }
    ## --------------------------------------------

    if (is.na(l)) next

    ## --------------------------------------------
    ## 识别研报文件类型
    ## -------------
    if (grepl("\\.pdf", l)) {
      tempFileType <- '.pdf'
    } else if (grepl("\\.docx", l)) {
      tempFileType <- '.docx'
    } else {
      tempFileType <- '.doc'
    }
    ## --------------------------------------------

    ## --------------------------------------------
    ## 设置下载的文件路径
    ## --------------
    tempDir <-  paste0(SAVE_PATH, '/',
                       dt[i, TradingDay])
    if (!dir.exists(tempDir)) dir.create(tempDir)

    tempFile <- paste0(dt[i, paste(TradingDay, reportClass, brokerName,
                                   title, sep = '-')]
                       ,tempFileType) %>% 
                gsub("/", "", .)

    destFile <- paste0(tempDir, '/', tempFile)
    ## --------------------------------------------

    ## --------------------------------------------
    if (!file.exists(destFile)) {
      if (class(try(
          download(l, destfile = destFile, mode = 'wb')
        )) == 'try-error') next
        Sys.sleep(1)
    } else {
        print("研报已经下载.")
    }
    ## --------------------------------------------

    ## ------------------------------------------
    ## 设置文件相对路径,方便以后查找
    ## 识别文件页数,这里我只处理了 pdf 文件
    ## ------------------------------
    dt[i, ref := paste0('/', TradingDay, '/', tempFile)]
    if (tempFileType == '.pdf') {
      pdfInfo <- pdftools::pdf_info(destFile)
      dt[i, pageNo := pdfInfo$page]
    }
    ## ------------------------------------------
}

## =============================================================================
## 把研报的信息录入到数据库
res <- dt[!is.na(ref)]
if (nrow(res) != 0) {
  setcolorder(res, c(colnames(res)[1:(ncol(res)-2)], 'pageNo', 'ref'))
  mysqlWrite(db = 'china_stocks', tbl = 'report_from_jrj',
             data = res)
}
## =============================================================================
