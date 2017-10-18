library(data.table)
library(magrittr)
library(RSelenium)

psPath <- paste0("/home/william/Documents/oiRank/src/phantomjs-2.1.1-linux-x86_64/bin","phantomjs")

remDr <- remoteDriver(browserName = 'phantomjs'
                      ,extraCapabilities = list(phantomjs.binary.path = '/usr/bin/phantomjs'))
remDr$getStatus()
remDr$open()
remDr$navigate('https://www.baidu.com/')
remDr$close

remDr$open()
remDr$navigate("http://www.whatsmyuseragent.com/")
remDr$findElement("id", "userAgent")$getElementText()[[1]]

remDr$findElement("class", "h1")$getElementText()[[1]]



remDr <- remoteDriver(browserName = "phantomjs")
remDr$open()
remDr$navigate("http://www.whatsmyuseragent.com/")
remDr$findElement("id", "userAgent")$getElementText()[[1]]
