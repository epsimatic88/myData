################################################################################
## MySQL:
## 用于建立 MySQL 数据库命令
## 
## 包括:
## MarketIndex
## 
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2018-01-03
################################################################################

CREATE DATABASE `MarketIndex` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;


## =============================================================================
## 南华商品指数
CREATE TABLE MarketIndex.stocks_index(
    TradingDay      DATE            NOT NULL,
    indexID         CHAR(30)        NOT NULL,           ## 股票代码
    indexName       CHAR(30)        NOT NULL,           ## 股票名称
    ## -------------------------------------------------------------------------
    open            DECIMAL(10,3),
    high            DECIMAL(10,3),
    low             DECIMAL(10,3),
    close           DECIMAL(10,3),
    volume          BIGINT,
    turnover        DECIMAL(30,3),
    ## -------------------------------------------------------------------------
    PRIMARY KEY (TradingDay, indexID)
) DEFAULT CHARSET=utf8;
## =============================================================================


## =============================================================================
## 南华商品指数
CREATE TABLE MarketIndex.stocks_index_from163(
    TradingDay      DATE            NOT NULL,
    indexID         CHAR(30)        NOT NULL,           ## 股票代码
    indexName       CHAR(30)        NOT NULL,           ## 股票名称
    ## -------------------------------------------------------------------------
    open            DECIMAL(10,3),
    high            DECIMAL(10,3),
    low             DECIMAL(10,3),
    close           DECIMAL(10,3),
    volume          BIGINT,
    turnover        DECIMAL(30,3),
    ## -------------------------------------------------------------------------
    PRIMARY KEY (TradingDay, indexID)
) DEFAULT CHARSET=utf8;
## =============================================================================



## =============================================================================
## 南华商品指数
CREATE TABLE MarketIndex.Nanhua (
    TradingDay     DATE           NOT NULL,
    close          DECIMAL(10,3)  NULL,
    PRIMARY KEY (TradingDay)
) DEFAULT CHARSET=utf8;
## =============================================================================

