## =============================================================================
## reform_from_sina.R
##
## 获取 新浪财经 股权分置改革方案的数据
##
## Author : fl@hicloud-investment.com
## Date   : 2018-03-20
##
## =============================================================================

## =============================================================================
suppressMessages({
  source('/home/fl/myData/R/Rconfig/myInit.R')
})
## =============================================================================


## =============================================================================
dt <- lapply(1:50, function(i){
    url <- paste0("http://biz.finance.sina.com.cn/stock/company/stk_distrall.php?page=", i)
    r <- GET(url)
    p <- content(r, as = 'text', encoding = 'GB18030')
    info <- p %>% 
        read_html() %>% 
        html_nodes('table') %>% 
        html_table(fill = T) %>% 
        .[[11]] %>% 
        as.data.table()
    if (nrow(info) < 2) return(data.table())
    colnames(info) <- unlist(info[1])
    res <- info[!grep('证券代码',证券代码)]
    return(res)
}) %>% rbindlist()
## =============================================================================

destFile <- '/home/fl/myData/data/ChinaStocks/Reform/FromSina.csv'
fwrite(dt, destFile)
