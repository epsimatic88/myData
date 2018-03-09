################################################################################
## 用于建立 Exchange 的数据表。
## 包括：
## 1. daily
## 2. oiRank
################################################################################

CREATE DATABASE `Exchange` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

################################################################################～～～～～～～～～～～～
## Exchange.daily                                                               ## Exchange.daily
################################################################################～～～～～～～～～～～～
CREATE TABLE  Exchange.daily(
    TradingDay       DATE             NOT NULL,            ## 交易日期
    ExchangeID       CHAR(20)         NULL,                ## 交易所
    InstrumentID     CHAR(30)         NOT NULL,            ## 合约名称
    #------------------------------------------------------
    OpenPrice        DECIMAL(15,5)          NULL,          ## 开盘价
    HighPrice        DECIMAL(15,5)          NULL,          ## 最高价
    LowPrice         DECIMAL(15,5)          NULL,          ## 最低价
    ClosePrice       DECIMAL(15,5)          NULL,          ## 收盘价
    #-----------------------------------------------------
    Volume           INT UNSIGNED           NULL,          ## 成交量
    Turnover         DECIMAL(30,3)          NULL,          ## 成交额
    CloseOpenInterest INT UNSIGNED          NULL,          ## 分钟的开仓的收盘量，即 position
    SettlementPrice  DECIMAL(15,5)          NULL,          ## 当日交易所公布的结算价
    #-----------------------------------------------------
    PRIMARY KEY (TradingDay, InstrumentID)                 ## 主键唯一，重复不可输入
    );

##----------- INDEX --------------------------------------------------------- ##
CREATE INDEX index_daily
ON Exchange.daily
(TradingDay, InstrumentID);  
## -------------------------------------------------------------------------- ## 
