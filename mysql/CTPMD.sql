################################################################################
## MySQL:
## 用于建立 MySQL 数据库命令
## 
## 包括:
## CTPMD
## 
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-07-18
################################################################################

CREATE DATABASE `CTPMD` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

################################################################################～～～～～～～～～～～～～～～
## CTPMD.tick                                                                  ## CTPMD.tick
################################################################################～～～～～～～～～～～～～～～
## table
CREATE TABLE CTPMD.tick(
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
    InstrumentID   CHAR(30)        NOT NULL,
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

## =================================================================================================
## Partition
## =================================================================================================
ALTER TABLE CTPMD.tick
    PARTITION BY RANGE( TO_DAYS(TradingDay) )(
    #---------------------------------------------------------------------------
    PARTITION p_2016_12 VALUES LESS THAN (TO_DAYS('2017-01-01')),
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

## =================================================================================================
## index_tick
## =================================================================================================
CREATE INDEX index_tick
    ON CTPMD.tick
    (TradingDay, InstrumentID, NumericRecvTime, NumericExchTime);      


## =================================================================================================
## breakTime
## =================================================================================================
CREATE TABLE CTPMD.breakTime(
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

## =================================================================================================
## log
## =================================================================================================
CREATE TABLE CTPMD.log(
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


################################################################################～～～～～～～～～～～～
## CTPMD.daily                                                                  ## CTPMD.daily     
################################################################################～～～～～～～～～～～～
CREATE TABLE  CTPMD.daily(
    TradingDay       DATE             NOT NULL,            ## 交易日期
    Sector           CHAR(20)         NOT NULL,            ## 日期属性: 
    #                                                      ## 1. 只含日盘: Sector = 'day'
    #                                                      ## 2. 只含夜盘: Sector = 'nights'
    #                                                      ## 3. 全天，包含日盘、夜盘: Sector = 'allday'
    InstrumentID     CHAR(30)         NOT NULL,            ## 合约名称
    #------------------------------------------------------
    OpenPrice        DECIMAL(15,5)          NULL,          ## 开盘价
    HighPrice        DECIMAL(15,5)          NULL,          ## 最高价
    LowPrice         DECIMAL(15,5)          NULL,          ## 最低价
    ClosePrice       DECIMAL(15,5)          NULL,          ## 收盘价
    #-----------------------------------------------------
    Volume           INT UNSIGNED           NULL,          ## 成交量
    Turnover         DECIMAL(30,5)          NULL,          ## 成交额
    #-----------------------------------------------------
    OpenOpenInterest  INT UNSIGNED          NULL,          ## 当日的开仓的开盘量
    HighOpenInterest  INT UNSIGNED          NULL,          ## 当日的开仓的最高量
    LowOpenInterest   INT UNSIGNED          NULL,          ## 当日的开仓的最低量
    CloseOpenInterest INT UNSIGNED          NULL,          ## 当日的开仓的收盘量，即 position
    #-----------------------------------------------------
    UpperLimitPrice  DECIMAL(15,5)          NULL,          ## 当日的有效最高报价
    LowerLimitPrice  DECIMAL(15,5)          NULL,          ## 当日的有效最低报价
    SettlementPrice  DECIMAL(15,5)          NULL,          ## 当日交易所公布的结算价
    #-----------------------------------------------------
    PRIMARY KEY (TradingDay, Sector, InstrumentID)         ## 主键唯一，重复不可输入
    )DEFAULT CHARSET=utf8;

##----------- INDEX --------------------------------------------------------- ##
CREATE INDEX index_daily
ON CTPMD.daily
(TradingDay, Sector, InstrumentID);  
## -------------------------------------------------------------------------- ## 

##----------- PARTITIONS ---------------------------------------------------- ##
ALTER TABLE CTPMD.daily
    PARTITION BY RANGE( TO_DAYS(TradingDay) )(
    #---------------------------------------------------------------------------
    PARTITION p_2016_12 VALUES LESS THAN (TO_DAYS('2017-01-01')),
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
    #---------------------------------------------------------------------------
    PARTITION p_2018_01 VALUES LESS THAN (TO_DAYS('2018-02-01')),
    PARTITION p_2018_02 VALUES LESS THAN (TO_DAYS('2018-03-01')),
    PARTITION p_2018_03 VALUES LESS THAN (TO_DAYS('2018-04-01')),
    PARTITION p_2018_04 VALUES LESS THAN (TO_DAYS('2018-05-01')),
    PARTITION p_2018_05 VALUES LESS THAN (TO_DAYS('2018-06-01')),
    PARTITION p_2018_06 VALUES LESS THAN (TO_DAYS('2018-07-01')),
    PARTITION p_2018_07 VALUES LESS THAN (TO_DAYS('2018-08-01')),
    PARTITION p_2018_08 VALUES LESS THAN (TO_DAYS('2018-09-01')),
    PARTITION p_2018_09 VALUES LESS THAN (TO_DAYS('2018-10-01')),
    PARTITION p_2018_10 VALUES LESS THAN (TO_DAYS('2018-11-01')),
    PARTITION p_2018_11 VALUES LESS THAN (TO_DAYS('2018-12-01')),
    PARTITION p_2018_12 VALUES LESS THAN (TO_DAYS('2019-01-01')),
    #---------------------------------------------------------------------------
    PARTITION p_2019_01 VALUES LESS THAN maxvalue
    );
## -------------------------------------------------------------------------- ##   


################################################################################～～～～～～～～～～～～～
## CTPMD.minute                                                                ## CTPMD.minute
################################################################################～～～～～～～～～～～～～

CREATE TABLE  CTPMD.minute(
    TradingDay       DATE           NOT NULL,              ## 交易日期
    Minute           TIME           NOT NULL,              ## 分钟，格式为==> "HH:MM:SS"", 与 Wind 数据库类似
    NumericExchTime  DECIMAL(15,5)  NOT NULL,              ## 分钟的数值格式，以 18:00::00 为正负界限，
    #                                                      ## 注意：取的是有 tick 的第一个，不一定是这个分钟开始的值
    #                                                      ## 为了方便 order：
    #                                                      ## 1. 负值表示夜盘的分钟
    #                                                      ## 2. 正值表示日盘的分钟
    InstrumentID     CHAR(30)   NOT NULL,                  ## 合约名称
    #------------------------------------------------------
    OpenPrice        DECIMAL(15,5)          NULL,          ## 开盘价
    HighPrice        DECIMAL(15,5)          NULL,          ## 最高价
    LowPrice         DECIMAL(15,5)          NULL,          ## 最低价
    ClosePrice       DECIMAL(15,5)          NULL,          ## 收盘价
    #-----------------------------------------------------
    Volume           INT UNSIGNED           NULL,          ## 成交量
    Turnover         DECIMAL(30,5)          NULL,          ## 成交额
    #-----------------------------------------------------
    OpenOpenInterest  INT UNSIGNED          NULL,          ## 分钟的开仓的开盘量
    HighOpenInterest  INT UNSIGNED          NULL,          ## 分钟的开仓的最高量
    LowOpenInterest   INT UNSIGNED          NULL,          ## 分钟的开仓的最低量
    CloseOpenInterest INT UNSIGNED          NULL,          ## 分钟的开仓的收盘量，即 position
    #-----------------------------------------------------
    UpperLimitPrice  DECIMAL(15,5)          NULL,          ## 当日的有效最高报价
    LowerLimitPrice  DECIMAL(15,5)          NULL,          ## 当日的有效最低报价
    SettlementPrice  DECIMAL(15,5)          NULL,          ## 当日交易所公布的结算价
    #-----------------------------------------------------
    PRIMARY KEY (TradingDay, Minute, InstrumentID)         ## 主键唯一，重复不可输入
    )DEFAULT CHARSET=utf8;

##----------- INDEX --------------------------------------------------------- ##
CREATE INDEX index_minute
ON CTPMD.minute
(TradingDay, Minute, InstrumentID);  
## -------------------------------------------------------------------------- ## 

##----------- PARTITIONS ---------------------------------------------------- ##
ALTER TABLE CTPMD.minute
    PARTITION BY RANGE( TO_DAYS(TradingDay) )(
    #---------------------------------------------------------------------------
    PARTITION p_2016_12 VALUES LESS THAN (TO_DAYS('2017-01-01')),
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
    #---------------------------------------------------------------------------
    PARTITION p_2018_01 VALUES LESS THAN (TO_DAYS('2018-02-01')),
    PARTITION p_2018_02 VALUES LESS THAN (TO_DAYS('2018-03-01')),
    PARTITION p_2018_03 VALUES LESS THAN (TO_DAYS('2018-04-01')),
    PARTITION p_2018_04 VALUES LESS THAN (TO_DAYS('2018-05-01')),
    PARTITION p_2018_05 VALUES LESS THAN (TO_DAYS('2018-06-01')),
    PARTITION p_2018_06 VALUES LESS THAN (TO_DAYS('2018-07-01')),
    PARTITION p_2018_07 VALUES LESS THAN (TO_DAYS('2018-08-01')),
    PARTITION p_2018_08 VALUES LESS THAN (TO_DAYS('2018-09-01')),
    PARTITION p_2018_09 VALUES LESS THAN (TO_DAYS('2018-10-01')),
    PARTITION p_2018_10 VALUES LESS THAN (TO_DAYS('2018-11-01')),
    PARTITION p_2018_11 VALUES LESS THAN (TO_DAYS('2018-12-01')),
    PARTITION p_2018_12 VALUES LESS THAN (TO_DAYS('2019-01-01')),
    #---------------------------------------------------------------------------
    PARTITION p_2019_01 VALUES LESS THAN maxvalue
    );
## -------------------------------------------------------------------------- ##   


################################################################################～～～～～～～～～～～～
## CTPMD.info                                                                  ## CTPMD.info     
################################################################################～～～～～～～～～～～～
CREATE TABLE  CTPMD.info(
    TradingDay       DATE             NOT NULL,            ## 交易日期
    InstrumentID     CHAR(30)         NOT NULL,            ## 合约名称
    InstrumentName   CHAR(50)         NULL,                ## 合约名称
    ProductClass     ChAR(20)         NULL,                ## 合约类型
    ExchangeID       CHAR(20)         NULL,                ## 交易所
    #-----------------------------------------------------
    PriceTick        DECIMAL(10,5)    NOT NULL,           
    VolumeMultiple   mediumint        NOT NULL,
    ShortMarginRatio DECIMAL(5,4)     NULL,
    LongMarginRatio  DECIMAL(5,4)     NULL,
    # ---------------------------------------------------- 
    OptionType       CHAR(20)         NULL,
    Underlying       CHAR(20)         NULL,
    StrikePrice      DECIMAL(15,5)    NULL,   
    #-----------------------------------------------------
    PRIMARY KEY (TradingDay, InstrumentID)         ## 主键唯一，重复不可输入
    )DEFAULT CHARSET=utf8;
##----------- INDEX --------------------------------------------------------- ##
CREATE INDEX index_info
ON CTPMD.info
(TradingDay, InstrumentID);  
## -------------------------------------------------------------------------- ## 
