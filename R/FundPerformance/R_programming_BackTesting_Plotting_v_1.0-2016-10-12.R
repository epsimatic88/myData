################################################################################
##############        BackTesting Programming      #############################
##############        Author: William Fang         #############################
##############        Date: 2016-10-10
##############        Version: v1.1.3
##############  主要修改内容：
##############  v1.1.2: 使用 Parallel Computing 重新改写原来的函数
##############  v1.1.3：=> 集成所有命令
##############          => 增加夏普比率
##############          => 增加信息比率
##############          => 增加 max draw down duration：突破前期净值高点的时长
################################################################################

rm(list = ls())

## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
################################################################################
#########################    Setting File Paths   ##############################
#########################     设置文件路径        ##############################
################################################################################
#! File path
#`
#` @r.code.path：R命令文件路径 
#` @data.file.path：数据路径
## -----------------------------------------------------------------------------
####################### file_name_main <- "DC6220e6g1"
####################### 
####################### 
####################### 
####################### file_name_sub <- "kdj"
## -----------------------------------------------------------------------------
#! r.code.path：

r.code.path <- "D:/汉云投资/R_Coding/"

data.file.path <- "D:/汉云投资/林焕耿/"
## <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<






## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
################################################################################
#########################    Loading  Dependent   ##############################
#########################         Packages        ##############################
################################################################################
## -----------------------------------------------------------------------------
source(paste0(r.code.path, "myInit.R"), encoding = 'UTF-8', echo=TRUE)

no.cores <- detectCores()
## <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
################################################################################
#########################   Loading Self-defined  ##############################
#########################        Functions        ##############################
################################################################################
#` @ht(): 用于显示数据的 head 与 tail，
## -----------------------------------------------------------------------------
source(paste0(r.code.path, "loading_functions.R"), encoding = 'UTF-8', echo=TRUE)
## <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
################################################################################
#########################      Initializing       ##############################
#########################       Parameters        ##############################
################################################################################
#! Parameters Initializing
#! 参数初始化设置
#`
#` @initial_capital:初始资金规模
#` @fee: 单边的交易手续费
#` @
#` @no_ohlc_backward: 往前提取 OHLC 的日期长度
#` @no_ohlc_forward: 往后提取 OHLC 的日期长度
#` @
#` @kdj_days_backwark：9,3,3
#` @kdj_ma_days：
#` @kdj_j_threshold：
#` 
## -----------------------------------------------------------------------------
#! 初始资金设定为：
initial_capital <- 50000000

#! 交易手续费设定为:
fee <- 0.002

rtn_free <- 0.04

#! 采集数据的日期
#! 往前倒推 100 日
#! 往后倒推 1000 日
no_ohlc_backward <- 100
no_ohlc_forward <- 10

## <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<






## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
################################################################################
#########################        Plotting         ##############################
#########################       Formattting       ##############################
#########################          File           ##############################
################################################################################
## -----------------------------------------------------------------------------

setwd(paste0(data.file.path, file_name_main))  

#```````````````````````````````````````````````````````````````````````````````

if(exists('file_name_sub')){
  file_name <- paste(file_name_main,file_name_sub, sep="_")
}else{
  file_name <- file_name_main
}


dataInfor <- read_excel(paste0(file_name, "_回测结果.xlsx"), sheet = "回测净值") %>% as.data.table()

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
# png(paste0(file_name,"_基金产品净值曲线.png"), res = 72*3, height=1500*0.9, width=1500*1.6)
par(mar=c(2.5,4.8,2,4.8), bg = "#d5e4eb")
plot(draw.down.infor$Date, -draw.down.infor$Per_Draw_Down, type = "s",
     xaxt = "n", axes = F, ylab="", xlab = "",
     ylim = c(min(-draw.down.infor$Per_Draw_Down)*2,0),
     col = "cyan2", lwd = 1)
axis(4)
mtext("回撤比例", side =4,line=3)
par(new = TRUE)

plot(draw.down.infor$Date, draw.down.infor$NAV, type = "s",
     col = "black", lwd = 2, 
     main = "基金产品净值曲线", xlab="", ylab="单位净值")
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

lines(draw.down.infor[nav.draw.down.pos, Date],
      draw.down.infor[nav.draw.down.pos, NAV],
      col = "red", lwd = 2.5, lty = 3)

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
lines(h.date,draw.down.infor[max.dd.duration.from:max.dd.duration.to, NAV],
      col = "green", lwd = 2.5)
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



# dev.off()

## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
################################################################################
#########################        Plotting:#2       #############################
#########################      交易盈亏分布图      ##############################
################################################################################
## 
#` @
#` @
#
## -----------------------------------------------------------------------------


return.infor <- read_excel(paste0(file_name, "_回测结果.xlsx"), sheet = "收益情况") %>% as.data.table()

plot(return.infor$Date, return.infor$Return, type="h")












## 交易盈亏分布
DD_0_5 <- length(which(return.infor[,Return] >= 0 &
                         return.infor[,Return] < .05))
DD_5_10 <- length(which((return.infor[,Return] >= .05) &
                          (return.infor[,Return] < .1)))
DD_10_15 <- length(which((return.infor[,Return]  >=  .1)
                         & (return.infor[,Return] < .15)))
DD_15_20 <- length(which((return.infor[,Return] >=  .15)
                         & (return.infor[,Return] < .2)))
DD_20_25 <- length(which((return.infor[,Return]  >=  .2)
                         & (return.infor[,Return] < .25)))
DD_25_30 <- length(which((return.infor[,Return]  >=  .25)
                         & (return.infor[,Return] < .30)))
DD_30_40 <- length(which((return.infor[,Return]  >=  .30)
                         & (return.infor[,Return] < .40)))
DD_40_50 <- length(which((return.infor[,Return]  >=  .40)
                         & (return.infor[,Return] < .50)))
DD_50 <- length(which(return.infor[,Return]  >=  .50))

DD_N_5_0 <- length(which((return.infor[,Return] < 0) &
                           (return.infor[,Return] >= -.05)))
DD_N_10_5 <- length(which((return.infor[,Return] < -.05) &
                            (return.infor[,Return] >= -.1)))
DD_N_15_10 <- length(which((return.infor[,Return]  <  -.1)
                           & (return.infor[,Return] >= -.15)))
DD_N_20_15 <- length(which((return.infor[,Return] <  -.15)
                           & (return.infor[,Return] >= -.20)))
DD_N_25_20 <- length(which((return.infor[,Return]  <  -.20)
                           & (return.infor[,Return] >= -.25)))
DD_N_30_25 <- length(which((return.infor[,Return]  <  -.25)
                           & (return.infor[,Return] >= -.30)))
DD_N_40_30 <- length(which((return.infor[,Return]  < -.30)
                           & (return.infor[,Return] >= -.40)))
DD_N_50_40 <- length(which((return.infor[,Return]  <  -.40)
                           & (return.infor[,Return] >= -.50)))
DD_N_50 <- length(which(return.infor[,Return] < -.50))


DD <- data.table(交易盈亏 = c(-50, -40, -30, -25,
                   -20,  -15,  -10,  -5, 0,
                   5, 10, 15, 20, 25,
                   30, 40, 50, 51),
                交易次数 = c(DD_N_50, DD_N_50_40, DD_N_40_30, DD_N_30_25, DD_N_25_20, DD_N_20_15,
                   DD_N_15_10, DD_N_10_5, DD_N_5_0,
                   DD_0_5, DD_5_10, DD_10_15, DD_15_20, DD_20_25, DD_25_30, DD_30_40,
                   DD_40_50, DD_50))
DD$交易次数 <- as.numeric(DD$交易次数)

## 交易亏损次数统计
DD

plot(DD$交易盈亏,DD$交易次数, type = "h")
par(new=TRUE)
plot(DD$交易盈亏,DD$交易次数, type = "s")


holdingDays <- return.infor[,Holding_Days]
holdingDays_1_7 <- which(holdingDays < 7) %>% length(.)
holdingDays_7_15 <- which(holdingDays >= 7 & holdingDays < 14) %>% length(.)
holdingDays_15_30 <- which(holdingDays >= 14 & holdingDays < 30) %>% length(.)
holdingDays_30_60 <- which(holdingDays >= 30 & holdingDays < 60) %>% length(.)
holdingDays_60_90 <- which(holdingDays >= 60 & holdingDays < 90) %>% length(.)
holdingDays_90_180 <- which(holdingDays >= 90 & holdingDays < 180) %>% length(.)
holdingDays_180_365 <- which(holdingDays >= 180 & holdingDays < 365) %>% length(.)
holdingDays_365 <- which(holdingDays >= 365) %>% length(.)

holdingDays_dis <- data.frame("持股周期(天)" = c("[1,7)", "[7,15)", "[15,30)", "[30,60)",
                                            "[60,90)", "[90,180)", "[180,365)",
                                            "[365,)"),
                              "交易次数" = c(holdingDays_1_7, holdingDays_7_15, holdingDays_15_30, holdingDays_30_60,
                                         holdingDays_60_90, holdingDays_90_180, holdingDays_180_365,
                                         holdingDays_365))
holdingDays_dis
holdingDays_dis$持股周期.天. <- factor(holdingDays_dis$持股周期.天.,
                                  levels =  unique(holdingDays_dis$持股周期.天.))


plot(holdingDays_dis[,1],holdingDays_dis[,2], type = "h")
par(new=TRUE)
lines(holdingDays_dis[,1],holdingDays_dis[,2])

hist(holdingDays)

x <- c(rep("[1,7)", holdingDays_1_7), rep("[7,15)",holdingDays_7_15))
x <- rnorm(1000)
hist(as.factor(x))
## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
################################################################################
#########################        Plotting:#3       #############################
######################### 基金产品净值日内波动情况 ############################
################################################################################
## 
#` @
#` @
#
## -----------------------------------------------------------------------------

# png(paste0(file_name,"_基金产品净值日内波动情况.png"), res = 72*3, height=1350*0.9, width=1500*1.6)
par(mar=c(2.5,4.8,2,1), bg = "#d5e4eb")
nav.return.infor <- read_excel("DC6220e6g1_2016_回测结果.xlsx", sheet = "单日净值波动") %>% as.data.table()

plot(nav.return.infor$Date, nav.return.infor$Fund_rtn, type="n",
     ylab = "净值日收益率",main="基金产品净值日内波动情况")
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

# dev.off()


## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
################################################################################
#########################        Plotting:#2       #############################
#########################        收益分布图       ##############################
################################################################################
## 
#` @
#` @
#
## -----------------------------------------------------------------------------


return.infor <- read_excel(paste0(file_name, "_回测结果.xlsx"), sheet = "收益情况") %>% as.data.table()

par(mar=c(2.5,4.8,2,1), bg = "#d5e4eb")

plot(hist(return.infor$Return), type="h")











