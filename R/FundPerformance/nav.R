#! /usr/bin/Rscript
## =============================================================================
## nav.R
## 数据监控与管理
##
## =============================================================================

rm(list = ls())
setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})

## =============================================================================
## ChinaFuturesCalendar
## =============================================================================
mysql <- mysqlFetch('dev')
ChinaFuturesCalendar <- dbGetQuery(mysql, "
            SELECT * FROM ChinaFuturesCalendar"
            ) %>% as.data.table()



## =============================================================================
## nav
## =============================================================================
dbName <- 'YunYang1'
mysql <- mysqlFetch(dbName)
dtNav <- dbGetQuery(mysql, "
    select TradingDay, NAV as nav
    from nav
    ") %>% as.data.table() %>% 
    .[, TradingDay := as.Date(TradingDay)] %>% 
    .[, ":="(
        maxNav = cummax(nav),
        DD  = nav - cummax(nav),
        maxDD = min(nav - cummax(nav))
    )]


## =============================================================================
## plotting
## =============================================================================
##
# figPath <- paste0('./R/FundPerformance/fig/', dbName)

# ## 保存图片
# png(paste0(filePath,
#            "/_基金产品净值曲线.png"), 
#            res    = 72*3, 
#            height = 1500*0.9, 
#            width  = 1500*1.6)

par(mar=c(2.5,4.8,2,4.8), bg = "#d5e4eb")
plot(dtNav$TradingDay, dtNav$DD, type = "s",
     xaxt = "n", axes = F, ylab="", xlab = "",
     ylim = c(dtNav[,min(maxDD)*2.5],0),
     col = "gray", lwd = 1)

points(x = dtNav[which.min(DD)][1,TradingDay],
       y = dtNav[which.min(DD)][1,DD], 
       cex = 0.5, col = "green", pch=19)
text(x = dtNav[which.min(DD)][1,TradingDay],
     y = dtNav[which.min(DD)][1,DD],
     paste0("最大回撤\n", sprintf("%.2f", dtNav[which.min(DD)][1,DD]), '%')
     , cex = 0.7, adj = c(0.3,1.5), col = "gray")
axis(4)
mtext("回撤比例(%)", side = 4, line = 3)
par(new = TRUE)

plot(dtNav$TradingDay, dtNav$nav, type = "s",
     col = "black", lwd = 2, 
     ylim = c(dtNav[,min(nav)], dtNav[, max(nav)*1.05]),
     main = paste(dbName," 基金产品净值曲线"), 
     xlab="", ylab="单位净值")
axis(2)

points(x = dtNav[1, TradingDay],
       y = dtNav[1, nav], 
       cex = 1.0, col = "red", pch=19)
text(x = dtNav[1, TradingDay],
     y = dtNav[1, nav],
     "初始净值\n 1.00"
     , cex = 0.7, adj = c(0.5,-0.5), col = "red")


points(x = dtNav[.N, TradingDay],
       y = dtNav[.N, nav], 
       cex = 2.0, col = "red", pch=19)
text(x = dtNav[.N, TradingDay],
     y = dtNav[.N, nav],
     paste("期末净值\n", sprintf("%.2f", dtNav[.N, nav]))
     , cex = 0.7, adj = c(0.5,-1.5), col = "red")

legend(x = (dtNav[1,TradingDay]), y = dtNav[,max(nav)],
       legend = c('基金净值(R)','回撤比(L)'),
       col = c("black", "gray"),
       lty = c(1,1,1,1),bty='n', cex=0.80, horiz=F,
       lwd = 3.0)
