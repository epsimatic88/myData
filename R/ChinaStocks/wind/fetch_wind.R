## =============================================================================
## fetch_wind.R
##
## 从 Wind 数据库提取数据
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

mysql <- mysqlFetch('wind')
dbListTables(mysql)


## =============================================================================
## Daily Bar 数据
## 
## 日行情数据
## 
## DB  : ASHAREEODPRICES  
## 截止 : 2016-09-12
## ---------------------
dtBar <- mysqlQuery(db = 'wind',
                    query = "select TRADE_DT as TradingDay,                     ## 交易日期
                                    S_INFO_WINDCODE as stockID,                 ## 股票代码
                                    S_DQ_OPEN as open,                          ##（裸）开盘价
                                    S_DQ_HIGH as high,                          ##（裸）最高价
                                    S_DQ_LOW as low,                            ##（裸）最低价
                                    S_DQ_CLOSE as close,                        ##（裸）收盘价
                                    S_DQ_CHANGE as chg,                         ##（裸）增减额
                                    S_DQ_PCTCHANGE as pchg,                     ##（裸）涨跌幅
                                    S_DQ_ADJFACTOR as bAdj,                     ## 后复权因子
                                    S_DQ_ADJOPEN as openAdj,                    ##（后复权）开盘价
                                    S_DQ_ADJHIGH as highAdj,                    ##（后复权）最高价
                                    S_DQ_ADJLOW as lowAdj,                      ##（后复权）最低价
                                    S_DQ_ADJCLOSE as closeAdj,                  ##（后复权）收盘价
                                    S_DQ_VOLUME as volume,                      ##（裸） 成交量
                                    S_DQ_AMOUNT as turnover,                    ## 成交额
                                    S_DQ_TRADESTATUS as status                  ## 交易状态
                             from ASHAREEODPRICES
                             order by TRADE_DT")
dtBar[, TradingDay := ymd(TradingDay)]
## -----------------------------------------------------------------------------
## 保存数据
if (F) {
    destFile <- '/home/fl/myData/data/ChinaStocks/Wind/wind_bar.csv'
    fwrite(dtBar, destFile)
}
## -----------------------------------------------------------------------------


## =============================================================================
## XDXR
## 
## 除权除息数据、股权分置改革方案数据
## 用于计算股票复权因子
## 
## DB  : ASHAREEXRIGHTDIVIDENDRECORD
## 截止 : 2016-09-12
## ---------------------
dbListFields(mysql, 'ASHAREEXRIGHTDIVIDENDRECORD')
dtBonus <- mysqlQuery(db = 'wind',
                      query = "select S_INFO_WINDCODE as stockID                ## 股票代码
                                      ,EX_DATE as exDay                         ## 除权除息日
                                      ,EX_TYPE as exClass                       ## 除权类型
                                      ,EX_DESCRIPTION as exDescription          ## 除权说明
                                      ,BONUS_SHARE_RATIO as shareRatio          ## 送股比例
                                      ,CASH_DIVIDEND_RATIO as cashRatio         ## 分红比例
                                      ,CONVERSED_RATIO as conversedRatio        ## 转增比例
                                      ,RIGHTSISSUE_PRICE as rightIssuePrice     ## 配股价格
                                      ,RIGHTSISSUE_RATIO as rightIssueRatio     ## 配股比例
                                      ,SEO_PRICE as seoPrice                    ## 增发价格
                                      ,SEO_RATIO as seoRatio                    ## 增发比例
                                      ,CONSOLIDATE_SPLIT_RATIO as consolidateSplitRatio ## 缩减比例
                               from ASHAREEXRIGHTDIVIDENDRECORD
                               order by S_INFO_WINDCODE, EX_DATE")
dtBonus[, exDay := ymd(exDay)]
## -----------------------------------------------------------------------------
## 保存数据
if (F) {
    destFile <- '/home/fl/myData/data/ChinaStocks/Wind/wind_bonus.csv'
    fwrite(dtBonus, destFile)
}
## -----------------------------------------------------------------------------
