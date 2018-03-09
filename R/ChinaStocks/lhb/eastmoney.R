## =============================================================================
## eastmoney.R
## 从东方财富下载 龙虎榜 数据
## 
## DATE     : 2018-03-05
## AUTHOR   : fl@hicloud-investment.com
## =============================================================================

source("/home/fl/myData/R/Rconfig/myInit.R")
library(httr)
library(rjson)
ChinaStocksCalendar <- ChinaStocksCalendar[days >= '2000-01-01']
options(width = 180)

## =============================================================================
## 获取表格数据内容
getAmount <- function(x, className) {
    # className <- classInfo[k]
    # x <- data1
    colnames(x) <- paste0("X", 1:ncol(x))
    x <- x[!grepl("序号|合计", X1)]
    x[, X2 := gsub("\\\r|\\\t|\\\n| ", "", X2)]
    x[, X2 := gsub("[0-9]{1,}次.*(%|-)", "", X2)]

    res <- lapply(1:nrow(x), function(ii){
        x[ii, .(X2, X3, X5, X7)]
    }) %>% rbindlist()
    colnames(res) <- c("DeptName", "buyAmount", "sellAmount", "netAmount")
    res[, className := className]
    setcolorder(res, c("className", colnames(res)[1:(ncol(res) - 1)]))
    return(res)
}
## =============================================================================

fetch_lhb_data <- function(tradingDay) {
    # tradingDay <- "2018-02-27"

    URL <- paste0("http://data.eastmoney.com/DataCenter_V3/stock2016/TradeDetail/pagesize=200,page=1,sortRule=-1,sortType=,startDate=",
                  tradingDay, ",endDate=",
                  tradingDay, ",gpfw=0,js=var%20data_tab_1.html")
    r <- GET(URL)
    # Sys.sleep(1)
    p <- content(r, 'parsed', encoding = "GB18030")
    info <- gsub('.*\"data\":(.*),\"url\".*', "\\1", p) %>% fromJSON(.)
    if (length(info) == 0) {
        print("找不到数据")
        return(data.table())
    }

    webData <- lapply(info, as.data.table) %>% rbindlist() %>%
        .[, .(SCode, SName,
              Bmoney, Smoney, JmMoney,
              Ctypedes)] %>%
        .[!duplicated(SCode)]
    cols <- c("Bmoney", "Smoney", "JmMoney")
    webData[, (cols) := lapply(.SD, as.numeric), .SDcols = cols]

    # if (F) {
    #     { "n": "序号", "w": 30 },
    #     { "n": '代码', "s": "SCode", "w": 50 },
    #     { "n": "名称", "w": 55 },
    #     { "n": "相关", "w": 60 },
    #     { "n": '解读<img class="handle-tips" title="成功率=买方营业部在近三个月内买入的个股上榜3天后的平均上涨概率；代表买方营业部过去三个月的综合情况。" src="/Stock2016/images/tip.png"/>', "w": 180 },
    #     { "n": "收盘价", "s": "ClosePrice", "w": 50 },
    #     { "n": "涨跌幅", "s": "Chgradio", "w": 50 },
    #     { "n": '龙虎榜<img class="handle-tips" title="龙虎榜净买额=龙虎榜买入额-龙虎榜卖出额；代表龙虎榜资金的净流入情况。" src="/Stock2016/images/tip.png"/></br>净买额(万)', "s": "JmMoney", "w": 65 },//, "s": "6"
    #     { "n": '龙虎榜</br>买入额(万)', "s": "Bmoney", "w": 60 },//, "s": "2"
    #     { "n": "龙虎榜</br>卖出额(万)", "s": "Smoney", "w": 60 },
    #     { "n": "龙虎榜</br>成交额(万)", "s": "ZeMoney", "w": 80 },
    #     { "n": "市场总</br>成交额(万)", "s": "Turnover", "w": 80 },
    #     { "n": '净买额占</br>总成交比', "s": "JmRate", "w": 60 },//, "s": "3"
    #     { "n": '成交额占</br>总成交比', "s": "ZeRate", "w": 60 },

    #     { "n": '换手率', "s": "Dchratio", "w": 55 },
    #     { "n": '流通</br>市值(亿)', "s": "Ltsz", "w": 55 },
    #     { "n": '上榜原因', "w": 150 }
    # }

    pb <- txtProgressBar(min = 0, max = nrow(webData), style = 3)
    dt <- lapply(1:nrow(webData), function(j){
        # print(j)
        setTxtProgressBar(pb, j)
        url <- paste0("http://data.eastmoney.com/stock/lhb,",
                      tradingDay, ",", webData[j,SCode], ".html")
        #Sys.sleep(.1)
        htmlInfo <- read_html(url, encoding = 'GB18030')
        classInfo <- html_nodes(htmlInfo, ".con-br") %>%
            html_text() %>%
            gsub(".*类型：(.*)", "\\1", .)
        if (length(classInfo) == 0) {
            classInfo <- webData[j,Ctypedes] %>%
                gsub('有价格.*日(.*)的前.*只.*', '\\1的证券', .)
        }
        tbls <- htmlInfo %>%
            html_nodes('.content-sepe table') %>%
            html_table(fill = T) %>%
            lapply(., as.data.table)
        if (length(tbls) == 0) return(data.table())

        dt <- lapply(1:length(classInfo), function(k){
            id1 <- k*2 - 1
            id2 <- k*2
            data1 <- tbls[[id1]] %>% as.data.table() %>%
                getAmount(., classInfo[k])
            data2 <- tbls[[id2]] %>% as.data.table() %>%
                getAmount(., classInfo[k])
            res <- list(data1, data2) %>% rbindlist()
        }) %>% rbindlist()

        dt[, ":="(
            SCode = webData[j, SCode],
            SName = webData[j, SName]
            )]
        cols <- c('buyAmount','sellAmount','netAmount')
        dt[, (cols) := lapply(.SD, function(x){
            as.numeric(x) * 10000
        }), .SDcols = cols]
        setcolorder(dt, c('SCode','SName','className',
                          'DeptName', 'buyAmount','sellAmount', 'netAmount'))
        return(dt[!is.na(DeptName)])
    }) %>% rbindlist()
    colnames(dt) <- c("股票代码", "股票名称", "上榜原因", "营业部名称",
                      "买入金额(元)", "卖出金额(元)", "净额(元)")
    return(dt)
}


## 2004 年之后才有 龙虎榜 数据
ChinaStocksCalendar <- ChinaStocksCalendar[days >= '2004-01-01'][days < Sys.Date()]
## =============================================================================
while(T) {
for (i in 1:nrow(ChinaStocksCalendar)) {
    tradingDay <- ChinaStocksCalendar[i, days]
    print(tradingDay)

    tempYear <- substr(tradingDay, 1, 4)
    tempPath <- paste0("/home/fl/myData/data/ChinaStocks/LHB/FromEastmoney/", tempYear)
    if (!dir.exists(tempPath)) dir.create(tempPath, recursive = T)

    tempFile <- paste0(tempPath, "/", tradingDay, ".csv")
    if (file.exists(tempFile)) {
        print("数据已下载")
        next
    }

    ## -------------------------------------------------------------------------
    if (any(class(try(
              dt <- fetch_lhb_data(tradingDay)
              ))  == 'try-error')) {
        Sys.sleep(30)
    } else if (nrow(dt) != 0) {
        cat("\n")
        print(dt)
        cat("\n")
        fwrite(dt, tempFile)
        Sys.sleep(3)
    }
    ## -------------------------------------------------------------------------

}
}
## =============================================================================






