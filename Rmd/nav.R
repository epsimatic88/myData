## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
################################################################################
#########################        Plotting:#1       #############################
#########################      基金净值曲线      ##############################
################################################################################
## 
#` @
#` @draw.down.infor：净值回撤情况
#
## -----------------------------------------------------------------------------
png(paste0("../fig/",file_name,"_基金产品净值曲线",
           ".png"), res = 72*3, height=1500*0.9, width=1500*1.6)

draw.down.infor <- dataInfor[,.(Date,NAV,Draw_Down,Per_Draw_Down,
                                DD_Duration = rep(0))]

for(i in 2:nrow(dataInfor)){
  if(draw.down.infor[i,Draw_Down] == 0){draw.down.infor$DD_Duration[i] <- 0} 
  else{draw.down.infor$DD_Duration[i] <- draw.down.infor$DD_Duration[i-1] + 1} 
}

max.dd.duration <- max(draw.down.infor$DD_Duration)
## 最大回撤金额
max_DD_amount <- dataInfor[,max(Draw_Down)]
## 最大回撤比例
max_DD_percentage <- dataInfor[,max(Per_Draw_Down)]


draw.down.infor <- draw.down.infor[,.(Date, NAV, 
                                      NAV_Max_Value = rep(0),
                                      NAV_Draw_Down = rep(0),
                                      Draw_Down,Per_Draw_Down,DD_Duration)]
for(i in 1:nrow(draw.down.infor)){
  draw.down.infor[i,NAV_Max_Value := 
                    max(draw.down.infor[1:i,NAV])
                  ]
  
  draw.down.infor[i,NAV_Draw_Down := 
                    draw.down.infor[i,NAV_Max_Value] - draw.down.infor[i,NAV]
                  ]
}

## -----------------------------------------------------------------------------
## 
par(mar=c(2.5,2.8,2,4.8), bg = "#d5e4eb")
plot(draw.down.infor$Date, -draw.down.infor$Per_Draw_Down*100, type = "s",
     xaxt = "n", axes = F, ylab="", xlab = "",
     ylim = c(min(-draw.down.infor$Per_Draw_Down)*3*100,0),
     col = "cyan2", lwd = 1)
axis(4)
mtext("回撤比例", side =4,line=3)
par(new = TRUE)

plot(draw.down.infor$Date, draw.down.infor$NAV, type = "s",
     col = "black", lwd = 2, 
     ylim = c(min(dataInfor$NAV, dataInfor$NAV_SH_index, dataInfor$NAV_HS300_index)*1.05,
              max(dataInfor$NAV, dataInfor$NAV_SH_index, dataInfor$NAV_HS300_index)*1.05)
     ##    ,main = paste0("基金产品净值曲线: ",data_name), xlab="", ylab="单位净值"
)
axis(2)
points(x = draw.down.infor[1, Date],
       y = draw.down.infor[1, NAV], 
       cex = 1.0, col = "red", pch=19)
text(x = draw.down.infor[1, Date],
     y = draw.down.infor[1, NAV],
     "初始净值\n 1.00"
     , cex = 0.7, adj = c(0.5,-0.5), col = "red")


points(x = draw.down.infor[.N, Date],
       y = draw.down.infor[.N, NAV], 
       cex = 2.0, col = "red", pch=19)
text(x = draw.down.infor[.N, Date],
     y = draw.down.infor[.N, NAV],
     paste("期末净值\n", sprintf("%.2f", draw.down.infor[.N,NAV]))
     , cex = 0.7, adj = c(0.3,1.5), col = "red")


lines(x = dataInfor$Date,
      y = dataInfor$NAV_SH_index,
      col = "gray80")

lines(x = dataInfor$Date,
      y = dataInfor$NAV_HS300_index,
      col = "gray60")

points(x = dataInfor[.N, Date],
       y = dataInfor[.N, NAV_SH_index], 
       cex = 1.1, col = "brown", pch=19)

points(x = dataInfor[.N, Date],
       y = dataInfor[.N, NAV_HS300_index], 
       cex = 1.1, col = "brown", pch=19)


max.nav.draw.down.pos <- which.max(draw.down.infor$Per_Draw_Down)

nav.draw.down.pos <- which(draw.down.infor[1:max.nav.draw.down.pos]$NAV_Max_Value == 
                             draw.down.infor[1:max.nav.draw.down.pos]$NAV_Max_Value[max.nav.draw.down.pos])
points(x = draw.down.infor[nav.draw.down.pos[1], Date],
       y = draw.down.infor[nav.draw.down.pos[1], NAV], 
       cex = 1.1, col = "blue", pch=19)
points(x = draw.down.infor[nav.draw.down.pos[length(nav.draw.down.pos)], Date],
       y = draw.down.infor[nav.draw.down.pos[length(nav.draw.down.pos)], NAV], 
       cex = 1.1, col = "blue", pch=19)
points(x = draw.down.infor[nav.draw.down.pos[1], Date],
       y = draw.down.infor[nav.draw.down.pos[length(nav.draw.down.pos)], NAV], 
       cex = 0.5, col = "gray", pch=19)

#lines(draw.down.infor[nav.draw.down.pos, Date],
#      draw.down.infor[nav.draw.down.pos, NAV],
#      col = "red", lwd = 2.5, lty = 3)

max.nav.dd <- seq(draw.down.infor[nav.draw.down.pos[1], NAV], 
                  draw.down.infor[max.nav.draw.down.pos, NAV], 
                  by = -0.01)


max.dd.duration.from <- which.max(draw.down.infor$DD_Duration) - max(draw.down.infor$DD_Duration)
max.dd.duration.to <- which.max(draw.down.infor$DD_Duration)
points(x = draw.down.infor[max.dd.duration.from, Date],
       y = draw.down.infor[max.dd.duration.from, NAV], 
       cex = 1.1, col = "blue", pch=19)

points(x = draw.down.infor[max.dd.duration.to, Date],
       y = draw.down.infor[max.dd.duration.to, NAV], 
       cex = 1.1, col = "blue", pch=19)
h.date <- draw.down.infor[max.dd.duration.from:max.dd.duration.to, Date]
v.nav <- rep(draw.down.infor[max.dd.duration.from, NAV], length(h.date))
lines(h.date, v.nav, col = "red",lty = 3)
#lines(h.date,draw.down.infor[max.dd.duration.from:max.dd.duration.to, NAV],
#      col = "green", lwd = 2.5)
text(draw.down.infor[max.dd.duration.from + length(h.date)/2, Date],
     draw.down.infor[max.dd.duration.from, NAV] + 0.15,
     paste("最长回撤期:\n",max.dd.duration,"天"), cex = 0.7, adj = c(0.5,0.8), col = "red")



lines(rep(draw.down.infor[nav.draw.down.pos[1], Date],length(max.nav.dd)),
      max.nav.dd, col = "red", lty = 3)
lines(x = draw.down.infor[nav.draw.down.pos, Date],
      y = rep(draw.down.infor[nav.draw.down.pos[length(nav.draw.down.pos)], NAV], length(nav.draw.down.pos)),
      col = "red", lty = 3)
text(draw.down.infor[nav.draw.down.pos[length(nav.draw.down.pos)], Date],
     y = draw.down.infor[nav.draw.down.pos[length(nav.draw.down.pos)], NAV],
     paste("最大回撤比例:\n",sprintf("%.2f%%", max_DD_percentage * 100)), cex = 0.7, adj = c(0.5,1.3), col = "red")

## add legend

legend(x = (dataInfor[1,Date]-86400*150), y = dataInfor[,max(NAV,NAV_SH_index,NAV_HS300_index)*0.75],legend = c('最大回撤(%)','上证综指','沪深300','基金净值'),
       col = c("cyan2","gray80","gray60","black"),
       lty = c(1,1,1,1),bty='n', cex=0.80, horiz=F,
       lwd = 3.0)

dev.off()



png(paste0("../fig/",file_name,"_基金产品净值日内波动情况",
           ".png"), res = 72*3, height=1350*0.9, width=1500*1.6)
par(mar=c(2.5,4.8,2,1), bg = "#d5e4eb")

nav.return.infor <- read_excel(paste0("../output/",file_name, "_回测结果"
                                      ,".xlsx"), sheet = "单日净值波动") %>% 
  as.data.table()

plot(nav.return.infor$Date, nav.return.infor$Fund_rtn, type="h",
     ylab = "净值日收益率"
     #,main = paste0("基金产品净值日内波动情况: ", data_name)
)
abline(h=c(-0.05,0.05),lty=3, col="gray65")
lines(nav.return.infor$Date, nav.return.infor$Fund_rtn, 
      col = "gray50")
points(x = nav.return.infor[Fund_rtn > 0, Date], 
       y = nav.return.infor[Fund_rtn > 0,Fund_rtn], 
       col = "red", pch=21)
points(nav.return.infor[Fund_rtn < 0, Date], nav.return.infor[Fund_rtn < 0,Fund_rtn], 
       col = "green", pch=21)
points(nav.return.infor[Fund_rtn >= 0.05 | Fund_rtn <= -0.05, Date], 
       nav.return.infor[Fund_rtn >= 0.05 | Fund_rtn <= -0.05, Fund_rtn], 
       cex = 1.1, col = "blue", pch=19)
text(nav.return.infor[Fund_rtn >= 0.05 | Fund_rtn <= -0.05, Date], 
     nav.return.infor[Fund_rtn >= 0.05 | Fund_rtn <= -0.05, Fund_rtn], 
     sprintf("%.2f%%", nav.return.infor[Fund_rtn >= 0.05 | Fund_rtn <= -0.05, Fund_rtn] * 100),
     cex = 0.8, col = "blue", adj=c(-0.15,-0.1))
text(nav.return.infor[Fund_rtn >= 0.05 | Fund_rtn <= -0.05, Date], 
     nav.return.infor[Fund_rtn >= 0.05 | Fund_rtn <= -0.05, Fund_rtn], 
     paste0("(",nav.return.infor[Fund_rtn >= 0.05 | Fund_rtn <= -0.05, Date],")"),
     cex = 0.6, col = "gray20", adj=c(-0.05,1.2))

dev.off()
