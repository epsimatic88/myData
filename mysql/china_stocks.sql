################################################################################
## 用于建立 china_stocks 的数据表。
## 包括：
################################################################################

CREATE DATABASE `china_stocks` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;


################################################################################
## china_stocks.daily_from_sina
################################################################################
CREATE TABLE  china_stocks.daily_from_sina(
    TradingDay      DATE             NOT NULL,          ## 交易日期
    stockID         CHAR(6)          NOT NULL,          ## 股票代码: 
    #------------------------------------------------------
    open            DECIMAL(15,3),                      ## 开盘价
    high            DECIMAL(15,3),                      ## 开盘价
    low             DECIMAL(15,3),                      ## 开盘价
    close           DECIMAL(15,3),                      ## 开盘价
    #-----------------------------------------------------
    volume          BIGINT,                             ## 交易量， 股
    turnover        DECIMAL(30,3),                      ## 交易额，元
    bAdj            DECIMAL(15,3),                      ## 后复权因子
    #-----------------------------------------------------
    PRIMARY KEY (TradingDay, stockID)                   ## 主键唯一，重复不可输入
    );

##----------- INDEX --------------------------------------------------------- ##
CREATE INDEX index_daily_from_sina
ON china_stocks.daily_from_sina
(TradingDay, stockID);  
## -------------------------------------------------------------------------- ## 


################################################################################
## china_stocks.daily_from_163
################################################################################
CREATE TABLE  china_stocks.daily_from_163(
    TradingDay      DATE             NOT NULL,          ## 交易日期
    stockID         CHAR(6)          NOT NULL,          ## 股票代码: 
    stockName       VARCHAR(30)      NOT NULL,          ## 股票名称: 
    #------------------------------------------------------
    open            DECIMAL(15,3),                      ## 开盘价
    high            DECIMAL(15,3),                      ## 开盘价
    low             DECIMAL(15,3),                      ## 开盘价
    close           DECIMAL(15,3),                      ## 开盘价
    preClose        DECIMAL(15,3),                      ## 前收盘价
    chg             DECIMAL(10,3),                      ## 涨跌额
    pchg            DECIMAL(10,3),                      ## 涨跌幅
    #-----------------------------------------------------
    volume          BIGINT,                             ## 交易量， 股
    turnover        DECIMAL(30,3),                      ## 交易额，元
    mcap            DECIMAL(30,3),                      ## 流通市值，元
    tcap            DECIMAL(30,3),                      ## 总市值，元
    #-----------------------------------------------------
    PRIMARY KEY (TradingDay, stockID)                   ## 主键唯一，重复不可输入
    );

##----------- INDEX --------------------------------------------------------- ##
CREATE INDEX index_daily_from_163
ON china_stocks.daily_from_163
(TradingDay, stockID);  
## -------------------------------------------------------------------------- ## 



################################################################################
## china_stocks.limit_from_jrj
################################################################################
CREATE TABLE  china_stocks.limit_from_jrj(
    TradingDay      DATE             NOT NULL,          ## 交易日期
    stockID         CHAR(6)          NOT NULL,          ## 股票代码 
    ## -------------------------------------------------------------------------
    zdtType         VARCHAR(10)      NOT NULL,          ## 涨跌停类型
                                                        ## 1：涨停
                                                        ## 2：跌停
    zdtText         VARCHAR(50),                        ## 涨跌停类型
    ## -------------------------------------------------------------------------
    close           DECIMAL(15,3),                      ## 开盘价
    pchg            DECIMAL(10,3),                      ## 涨跌幅
    amplitude       DECIMAL(10,3),                      ## 振幅
    zdtForce        DECIMAL(10,3),                      ## 振幅
    isLhb           VARCHAR(10),                        ## 是否登录龙虎榜
    ## -------------------------------------------------------------------------
    PRIMARY KEY (TradingDay, stockID)                   ## 主键唯一，重复不可输入
    );

##----------- INDEX --------------------------------------------------------- ##
CREATE INDEX index_limit_from_jrj
ON china_stocks.limit_from_jrj
(TradingDay, stockID);  
## -------------------------------------------------------------------------- ## 



################################################################################
## china_stocks.rzrq_from_sina
################################################################################
CREATE TABLE  china_stocks.rzrq_from_sina(
    TradingDay      DATE             NOT NULL,          ## 交易日期
    stockID         CHAR(6)          NOT NULL,          ## 股票代码
    stockName       VARCHAR(30)      NOT NULL,          ## 股票名称
    #------------------------------------------------------
    rzye            DECIMAL(30,3),                      ## 融资余额(元)
    rzmre           DECIMAL(30,3),                      ## 融资买入额(元)
    rzche           DECIMAL(30,3),                      ## 融资偿还额(元)
    #------------------------------------------------------        
    rqye            DECIMAL(30,3),                      ## 融券余额(元)
    rqyl            BIGINT,                             ## 融券余量(股)
    rqmcl           BIGINT,                             ## 融券卖出量(股)
    rqchl           BIGINT,                             ## 融券偿还量(股)
    #-----------------------------------------------------
    rzrqye          DECIMAL(30,3),                      ## 融资融券余额(元)
    #-----------------------------------------------------
    PRIMARY KEY (TradingDay, stockID)                   ## 主键唯一，重复不可输入
    );

##----------- INDEX --------------------------------------------------------- ##
CREATE INDEX index_rzrq_from_sina
ON china_stocks.rzrq_from_sina
(TradingDay, stockID);  
## -------------------------------------------------------------------------- ## 




################################################################################
## china_stocks.rzrq_from_eastmoney
################################################################################
CREATE TABLE  china_stocks.rzrq_from_eastmoney(
    TradingDay      DATE             NOT NULL,          ## 交易日期
    stockID         CHAR(6)          NOT NULL,          ## 股票代码
    stockName       VARCHAR(30)      NOT NULL,          ## 股票名称
    #------------------------------------------------------
    rzye            DECIMAL(30,3),                      ## 融资余额(元)
    rzmre           DECIMAL(30,3),                      ## 融资买入额(元)
    rzche           DECIMAL(30,3),                      ## 融资偿还额(元)
    #------------------------------------------------------        
    rqye            DECIMAL(30,3),                      ## 融券余额(元)
    rqyl            BIGINT,                             ## 融券余量(股)
    rqmcl           BIGINT,                             ## 融券卖出量(股)
    rqchl           BIGINT,                             ## 融券偿还量(股)
    #-----------------------------------------------------
    rzrqye          DECIMAL(30,3),                      ## 融资融券余额(元)
    #-----------------------------------------------------
    PRIMARY KEY (TradingDay, stockID)                   ## 主键唯一，重复不可输入
    );




################################################################################
## china_stocks.dzjy_from_exch
################################################################################
CREATE TABLE  china_stocks.dzjy_from_exch(
    TradingDay      DATE             NOT NULL,          ## 交易日期
    stockID         CHAR(6)          NOT NULL,          ## 股票代码
    stockName       VARCHAR(30)      NOT NULL,          ## 股票名称
    #------------------------------------------------------
    price           DECIMAL(15,3),                      ## 成交价格：元
    volume          BIGINT,                             ## 成交数量：股
    turnover        DECIMAL(30,3),                      ## 成交金额：源
    #-----------------------------------------------------
    DeptBuy         VARCHAR(100),                       ## 买入营业部
    DeptSell        VARCHAR(100)                       ## 卖出营业部
    #-----------------------------------------------------
    );

##----------- INDEX --------------------------------------------------------- ##
-- CREATE INDEX index_dzjy_from_exch
-- ON china_stocks.dzjy_from_exch
-- (TradingDay, stockID);  
## -------------------------------------------------------------------------- ## 


################################################################################
## china_stocks.dzjy_from_exch
################################################################################
CREATE TABLE  china_stocks.dzjy_from_sina(
    TradingDay      DATE             NOT NULL,          ## 交易日期
    stockID         CHAR(6)          NOT NULL,          ## 股票代码
    stockName       VARCHAR(30)      NOT NULL,          ## 股票名称
    #------------------------------------------------------
    price           DECIMAL(15,3),                      ## 成交价格：元
    volume          BIGINT,                             ## 成交数量：股
    turnover        DECIMAL(30,3),                      ## 成交金额：源
    #-----------------------------------------------------
    DeptBuy         VARCHAR(100),                       ## 买入营业部
    DeptSell        VARCHAR(100)                        ## 卖出营业部
    #-----------------------------------------------------
    );

##----------- INDEX --------------------------------------------------------- ##
-- CREATE INDEX index_dzjy_from_sina
-- ON china_stocks.dzjy_from_sina
-- (TradingDay, stockID);  
## -------------------------------------------------------------------------- ## 





##----------- INDEX --------------------------------------------------------- ##
CREATE INDEX index_rzrq_from_eastmoney
ON china_stocks.rzrq_from_eastmoney
(TradingDay, stockID);  
## -------------------------------------------------------------------------- ## 


################################################################################
## china_stocks.report_from_jrj
################################################################################
CREATE TABLE  china_stocks.report_from_jrj(
    TradingDay      DATE             NOT NULL,          ## 交易日期
    #------------------------------------------------------
    reportClass     VARCHAR(30),                        ## 研报类型
    reportClassID   VARCHAR(10),                        ## 研报类型ID
    title           TEXT,                               ## 标题
    author          VARCHAR(100),                       ## 作者
    brokerName      VARCHAR(100),                       ## 券商
    brokerID        VARCHAR(30),                        ## 券商ID
    industryClass   VARCHAR(30),                        ## 行业类型
    industryID      VARCHAR(30),                        ## 行业类型ID
    reportID        VARCHAR(30) NOT NULL,               ## 研报ID,网页标识
    pageNo          SMALLINT,                           ## 页数
    ref             TEXT,                               ## 研报连接     
    #-----------------------------------------------------
    PRIMARY KEY (TradingDay, reportID)                  ## 主键唯一，重复不可输入
    );

##----------- INDEX --------------------------------------------------------- ##
CREATE INDEX index_report_from_jrj
ON china_stocks.report_from_jrj
(TradingDay, reportID);  
## -------------------------------------------------------------------------- ## 


