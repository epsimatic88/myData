################################################################################
## 用于建立 china_stocks_bar 的数据表。
## 包括：
## 1. from_sina
################################################################################

CREATE DATABASE `china_stocks_bar` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

################################################################################
## china_stocks_bar.from_sina
################################################################################
CREATE TABLE  china_stocks_bar.from_sina(
    TradingDay      DATE             NOT NULL,          ## 交易日期
    stockID         CHAR(30)         NOT NULL,          ## 日期属性: 
    #------------------------------------------------------
    open            DECIMAL(15,5),                      ## 开盘价
    high            DECIMAL(15,5),                      ## 开盘价
    low             DECIMAL(15,5),                      ## 开盘价
    close           DECIMAL(15,5),                      ## 开盘价
    #-----------------------------------------------------
    volume          BIGINT,                             ## 交易量， 股
    turnover        DECIMAL(30,3),                      ## 交易额，元
    bAdj            DECIMAL(15,5),                      ## 后复权因子
    #-----------------------------------------------------
    PRIMARY KEY (TradingDay, stockID)                   ## 主键唯一，重复不可输入
    );

##----------- INDEX --------------------------------------------------------- ##
CREATE INDEX index_from_sina
ON china_stocks_bar.from_sina
(TradingDay, stockID);  
## -------------------------------------------------------------------------- ## 
