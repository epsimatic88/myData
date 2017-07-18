################################################################################
## MySQL:
## 用于建立 MySQL 数据库命令
## 
## 包括:
## 1. /Data/ChinaFuturesTickData/Colo1: ctpmdprod1, ctp1, guavaMD
## 2. /Data/ChinaFuturesTickData/Colo5: ctpmdprod1, ctpmdprod2, DceL2
## 
## 注意:
## breakTime 已经是包括两个 Colo 的断点时间了。不需要再额外替换。
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-01-16
## UpdateDate: 2017-01-16
################################################################################
##
##
################################################################################～～～～～～～～～～～～～～～
## china_futures_HFT.colo1_ctpmdprod1                                         ## china_futures_HFT.colo1_ctpmdprod1
################################################################################～～～～～～～～～～～～～～～

# china_futures_HFT.colo1_ctpmdprod1 

## Table

CREATE TABLE china_futures_HFT.colo1_ctpmdprod1(
    #----------------------------------------------------
    #--- DateTime Information ---------------------------
    #----------------------------------------------------
    Timestamp      CHAR(28)       NOT NULL,
    TradingDay     DATE           NOT NULL,
    UpdateTime     TIME           NOT NULL, 
    UpdateMillisec SMALLINT UNSIGNED  NULL,
    #----------------------------------------------------
    #--- 
    #----------------------------------------------------
    InstrumentID   CHAR(20)        NOT NULL,
    #----------------------------------------------------
    #--- PRICE INFORMATION ------------------------------
    #----------------------------------------------------
    LastPrice      DECIMAL(15,5)  NULL,
                                                        #    OpenPrice      DECIMAL(15,5)  NULL,
                                                        #    HighestPrice   DECIMAL(15,5)  NULL,
                                                        #    LowestPrice    DECIMAL(15,5)  NULL,
    Volume         INT  UNSIGNED  NULL,
    Turnover       DECIMAL(30,5)  NULL,
    OpenInterest   INT UNSIGNED   NULL,
                                                        #    ClosePrice     DECIMAL(15,5)  NULL,
                                                        #    SettlementPrice  DECIMAL(15,5)  NULL,
    UpperLimitPrice  DECIMAL(15,5)  NULL,
    LowerLimitPrice  DECIMAL(15,5)  NULL,
    #----------------------------------------------------
    #--- BID INFORMATION --------------------------------
    #----------------------------------------------------
    BidPrice1      DECIMAL(15,5)  NULL,
    BidVolume1     INT UNSIGNED   NULL,
    BidPrice2      DECIMAL(15,5)  NULL,
    BidVolume2     INT UNSIGNED   NULL,
    BidPrice3      DECIMAL(15,5)  NULL,
    BidVolume3     INT UNSIGNED   NULL,
    BidPrice4      DECIMAL(15,5)  NULL,
    BidVolume4     INT UNSIGNED   NULL,
    BidPrice5      DECIMAL(15,5)  NULL,
    BidVolume5     INT UNSIGNED   NULL,
    #----------------------------------------------------
    #--- ASK INFORMATION --------------------------------
    #----------------------------------------------------
    AskPrice1      DECIMAL(15,5)  NULL,
    AskVolume1     INT UNSIGNED   NULL,
    AskPrice2      DECIMAL(15,5)  NULL,
    AskVolume2     INT UNSIGNED   NULL,
    AskPrice3      DECIMAL(15,5)  NULL,
    AskVolume3     INT UNSIGNED   NULL,
    AskPrice4      DECIMAL(15,5)  NULL,
    AskVolume4     INT UNSIGNED   NULL,
    AskPrice5      DECIMAL(15,5)  NULL,
    AskVolume5     INT UNSIGNED   NULL,
    #----------------------------------------------------
    #--- Numeric Transformation -------------------------
    #----------------------------------------------------
    NumericRecvTime    DECIMAL(15,6)  NOT NULL,
    NumericExchTime    DECIMAL(15,5)  NOT NULL,
    DeltaVolume        INT UNSIGNED,
    DeltaTurnover      DECIMAL(30,5),
    DeltaOpenInterest  INT UNSIGNED   NULL,    
    #----------------------------------------------------
    #--- KEY SETTING ------------------------------------
    #----------------------------------------------------
    PRIMARY KEY (TradingDay,NumericRecvTime,NumericExchTime,InstrumentID)
    )DEFAULT CHARSET=utf8;


## Partition

ALTER TABLE china_futures_HFT.colo1_ctpmdprod1
    PARTITION BY RANGE( TO_DAYS(TradingDay) )(
    #---------------------------------------------------------------------------
    PARTITION p_2016_01 VALUES LESS THAN (TO_DAYS('2016-02-01')),
    PARTITION p_2016_02 VALUES LESS THAN (TO_DAYS('2016-03-01')),
    PARTITION p_2016_03 VALUES LESS THAN (TO_DAYS('2016-04-01')),
    PARTITION p_2016_04 VALUES LESS THAN (TO_DAYS('2016-05-01')),
    PARTITION p_2016_05 VALUES LESS THAN (TO_DAYS('2016-06-01')),
    PARTITION p_2016_06 VALUES LESS THAN (TO_DAYS('2016-07-01')),
    PARTITION p_2016_07 VALUES LESS THAN (TO_DAYS('2016-08-01')),
    PARTITION p_2016_08 VALUES LESS THAN (TO_DAYS('2016-09-01')),
    PARTITION p_2016_09 VALUES LESS THAN (TO_DAYS('2016-10-01')),
    PARTITION p_2016_10 VALUES LESS THAN (TO_DAYS('2016-11-01')),
    PARTITION p_2016_11 VALUES LESS THAN (TO_DAYS('2016-12-01')),
    PARTITION p_2016_12 VALUES LESS THAN (TO_DAYS('2017-01-01')),
    #---------------------------------------------------------------------------
    #---------------------------------------------------------------------------
    PARTITION p_2017_01 VALUES LESS THAN (TO_DAYS('2017-02-01')),
    PARTITION p_2017_02 VALUES LESS THAN (TO_DAYS('2017-03-01')),
    PARTITION p_2017_03 VALUES LESS THAN (TO_DAYS('2017-04-01')),
    PARTITION p_2017_04 VALUES LESS THAN (TO_DAYS('2017-05-01')),
    PARTITION p_2017_05 VALUES LESS THAN (TO_DAYS('2017-06-01')),
    PARTITION p_2017_06 VALUES LESS THAN (TO_DAYS('2017-07-01')),
    PARTITION p_2017_07 VALUES LESS THAN (TO_DAYS('2017-08-01')),
    PARTITION p_2017_08 VALUES LESS THAN (TO_DAYS('2017-09-01')),
    PARTITION p_2017_09 VALUES LESS THAN (TO_DAYS('2017-10-01')),
    PARTITION p_2017_10 VALUES LESS THAN (TO_DAYS('2017-11-01')),
    PARTITION p_2017_11 VALUES LESS THAN (TO_DAYS('2017-12-01')),
    PARTITION p_2017_12 VALUES LESS THAN (TO_DAYS('2018-01-01')),
    #---------------------------------------------------------------------------
    PARTITION p_2018_01 VALUES LESS THAN maxvalue
    );


## index

CREATE INDEX index_colo1_ctpmdprod1
    ON china_futures_HFT.colo1_ctpmdprod1 
    (TradingDay, InstrumentID, NumericExchTime);      


################################################################################～～～～～～～～～～～～～～～
## china_futures_HFT.CTPMD1                                                   ## china_futures_HFT.CTPMD1
################################################################################～～～～～～～～～～～～～～～

# china_futures_HFT.CTPMD1 

## Table

CREATE TABLE china_futures_HFT.CTPMD1(
    #----------------------------------------------------
    #--- DateTime Information ---------------------------
    #----------------------------------------------------
    Timestamp      CHAR(28)       NOT NULL,
    TradingDay     DATE           NOT NULL,
    UpdateTime     TIME           NOT NULL, 
    UpdateMillisec SMALLINT UNSIGNED  NULL,
    #----------------------------------------------------
    #--- 
    #----------------------------------------------------
    InstrumentID   CHAR(20)        NOT NULL,
    #----------------------------------------------------
    #--- PRICE INFORMATION ------------------------------
    #----------------------------------------------------
    LastPrice      DECIMAL(15,5)  NULL,
                                                        #    OpenPrice      DECIMAL(15,5)  NULL,
                                                        #    HighestPrice   DECIMAL(15,5)  NULL,
                                                        #    LowestPrice    DECIMAL(15,5)  NULL,
    Volume         INT  UNSIGNED  NULL,
    Turnover       DECIMAL(30,5)  NULL,
    OpenInterest   INT UNSIGNED   NULL,
                                                        #    ClosePrice     DECIMAL(15,5)  NULL,
                                                        #    SettlementPrice  DECIMAL(15,5)  NULL,
    UpperLimitPrice  DECIMAL(15,5)  NULL,
    LowerLimitPrice  DECIMAL(15,5)  NULL,
    #----------------------------------------------------
    #--- BID INFORMATION --------------------------------
    #----------------------------------------------------
    BidPrice1      DECIMAL(15,5)  NULL,
    BidVolume1     INT UNSIGNED   NULL,
    BidPrice2      DECIMAL(15,5)  NULL,
    BidVolume2     INT UNSIGNED   NULL,
    BidPrice3      DECIMAL(15,5)  NULL,
    BidVolume3     INT UNSIGNED   NULL,
    BidPrice4      DECIMAL(15,5)  NULL,
    BidVolume4     INT UNSIGNED   NULL,
    BidPrice5      DECIMAL(15,5)  NULL,
    BidVolume5     INT UNSIGNED   NULL,
    #----------------------------------------------------
    #--- ASK INFORMATION --------------------------------
    #----------------------------------------------------
    AskPrice1      DECIMAL(15,5)  NULL,
    AskVolume1     INT UNSIGNED   NULL,
    AskPrice2      DECIMAL(15,5)  NULL,
    AskVolume2     INT UNSIGNED   NULL,
    AskPrice3      DECIMAL(15,5)  NULL,
    AskVolume3     INT UNSIGNED   NULL,
    AskPrice4      DECIMAL(15,5)  NULL,
    AskVolume4     INT UNSIGNED   NULL,
    AskPrice5      DECIMAL(15,5)  NULL,
    AskVolume5     INT UNSIGNED   NULL,
    #----------------------------------------------------
    #--- Numeric Transformation -------------------------
    #----------------------------------------------------
    NumericRecvTime    DECIMAL(15,6)  NOT NULL,
    NumericExchTime    DECIMAL(15,5)  NOT NULL,
    DeltaVolume        INT UNSIGNED,
    DeltaTurnover      DECIMAL(30,5),
    DeltaOpenInterest  INT UNSIGNED   NULL,    
    #----------------------------------------------------
    #--- KEY SETTING ------------------------------------
    #----------------------------------------------------
    PRIMARY KEY (TradingDay,NumericRecvTime,NumericExchTime,InstrumentID)
    )DEFAULT CHARSET=utf8;


## Partition

ALTER TABLE china_futures_HFT.CTPMD1
    PARTITION BY RANGE( TO_DAYS(TradingDay) )(
    #---------------------------------------------------------------------------
    PARTITION p_2016_01 VALUES LESS THAN (TO_DAYS('2016-02-01')),
    PARTITION p_2016_02 VALUES LESS THAN (TO_DAYS('2016-03-01')),
    PARTITION p_2016_03 VALUES LESS THAN (TO_DAYS('2016-04-01')),
    PARTITION p_2016_04 VALUES LESS THAN (TO_DAYS('2016-05-01')),
    PARTITION p_2016_05 VALUES LESS THAN (TO_DAYS('2016-06-01')),
    PARTITION p_2016_06 VALUES LESS THAN (TO_DAYS('2016-07-01')),
    PARTITION p_2016_07 VALUES LESS THAN (TO_DAYS('2016-08-01')),
    PARTITION p_2016_08 VALUES LESS THAN (TO_DAYS('2016-09-01')),
    PARTITION p_2016_09 VALUES LESS THAN (TO_DAYS('2016-10-01')),
    PARTITION p_2016_10 VALUES LESS THAN (TO_DAYS('2016-11-01')),
    PARTITION p_2016_11 VALUES LESS THAN (TO_DAYS('2016-12-01')),
    PARTITION p_2016_12 VALUES LESS THAN (TO_DAYS('2017-01-01')),
    #---------------------------------------------------------------------------
    #---------------------------------------------------------------------------
    PARTITION p_2017_01 VALUES LESS THAN (TO_DAYS('2017-02-01')),
    PARTITION p_2017_02 VALUES LESS THAN (TO_DAYS('2017-03-01')),
    PARTITION p_2017_03 VALUES LESS THAN (TO_DAYS('2017-04-01')),
    PARTITION p_2017_04 VALUES LESS THAN (TO_DAYS('2017-05-01')),
    PARTITION p_2017_05 VALUES LESS THAN (TO_DAYS('2017-06-01')),
    PARTITION p_2017_06 VALUES LESS THAN (TO_DAYS('2017-07-01')),
    PARTITION p_2017_07 VALUES LESS THAN (TO_DAYS('2017-08-01')),
    PARTITION p_2017_08 VALUES LESS THAN (TO_DAYS('2017-09-01')),
    PARTITION p_2017_09 VALUES LESS THAN (TO_DAYS('2017-10-01')),
    PARTITION p_2017_10 VALUES LESS THAN (TO_DAYS('2017-11-01')),
    PARTITION p_2017_11 VALUES LESS THAN (TO_DAYS('2017-12-01')),
    PARTITION p_2017_12 VALUES LESS THAN (TO_DAYS('2018-01-01')),
    #---------------------------------------------------------------------------
    PARTITION p_2018_01 VALUES LESS THAN maxvalue
    );


## index

CREATE INDEX index_CTPMD1
    ON china_futures_HFT.CTPMD1 
    (TradingDay, InstrumentID, NumericExchTime);      




################################################################################～～～～～～～～～～～～～～～
## china_futures_HFT.breakTime                                                ## china_futures_HFT.breakTime
################################################################################～～～～～～～～～～～～～～～

## breakTime

CREATE TABLE china_futures_HFT.breakTime(
    TradingDay   DATE      NOT      NULL,                  ## 交易日期
    BreakBeginTime   TIME  NOT      NULL,                  ## 数据中断开始的时间
    BreakEndTime     TIME  NOT      NULL,                  ## 数据中断结束的时间
    #-----------------------------------------------------
    DataSource   varchar(100)  NOT      NULL,              ## 原始数据文件的来源，为主要目录
    DataFile     varchar(100)  NOT      NULL,              ## 原始数据的文件，为 csv 文件/路径
    #-----------------------------------------------------
    PRIMARY KEY (TradingDay, BreakBeginTime, BreakEndTime,
                 DataSource, DataFile)                     ## 主键唯一，重复不可输入
    );

################################################################################～～～～～～～～～～～～～～～
## dev.HFT_log                                                                ## dev.HFT_log
################################################################################～～～～～～～～～～～～～～～

## log

CREATE TABLE dev.HFT_log(
    TradingDay   DATE      NOT      NULL,                  ## 交易日期
    #-----------------------------------------------------
    User         TINYTEXT           NULL,                  ## 哪个账户在录入数据
    MysqlDB      TINYTEXT           NULL,                  ## 数据输入到哪个数据库
    DataSource   TINYTEXT  NOT      NULL,                  ## 原始数据文件的来源，为主要目录
    Sector       TEXT               NULL,                  ## 用于差检查是否已经录入数据库  
    DataFile     TEXT               NULL,                  ## 原始数据的文件，为 csv 文件/路径
    #-----------------------------------------------------
    #-----------------------------------------------------
    RscriptMain  TEXT      NOT      NULL,                  ## 使用的主要 R 脚本文件，为最上层的文件，包括需要的包、相应的配置
    RscriptSub   TEXT      NOT      NULL,                  ## 使用的次一级 R 脚本，主要包括编写的函数即各种算法
    ProgBeginTime    DATETIME  NOT      NULL,                  ## 程序开始运行的时间
    ProgEndTime      DATETIME  NOT      NULL,                  ## 程序结束运行的时间
    Results      TEXT               NULL,                  ## 对数据哭修改的内容记录
    Remarks      TEXT               NULL                   ## 备注，方便日后添加说明
    #-----------------------------------------------------
    )DEFAULT CHARSET=utf8;

