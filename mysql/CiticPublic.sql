################################################################################
## 用于建立 CiticPublic 的数据表。
## 包括：
## 1. daily
## 2. minute
################################################################################

CREATE DATABASE `CiticPublic` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

################################################################################～～～～～～～～～～～～
## CiticPublic.daily                                                               ## CiticPublic.daily
################################################################################～～～～～～～～～～～～
CREATE TABLE  CiticPublic.daily(
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
    Turnover         DECIMAL(30,3)          NULL,          ## 成交额
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
    );

##----------- INDEX --------------------------------------------------------- ##
CREATE INDEX index_daily
ON CiticPublic.daily
(TradingDay, Sector, InstrumentID);  
## -------------------------------------------------------------------------- ## 

##----------- PARTITIONS ---------------------------------------------------- ##
ALTER TABLE CiticPublic.daily
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
## -------------------------------------------------------------------------- ##   


################################################################################～～～～～～～～～～～～～
## CiticPublic.minute                                                   ## CiticPublic.minute
################################################################################～～～～～～～～～～～～～

CREATE TABLE  CiticPublic.minute(
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
    Turnover         DECIMAL(30,3)          NULL,          ## 成交额
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
    );

##----------- INDEX --------------------------------------------------------- ##
CREATE INDEX index_minute
ON CiticPublic.minute
(TradingDay, Minute, InstrumentID);  
## -------------------------------------------------------------------------- ## 

##----------- PARTITIONS ---------------------------------------------------- ##
ALTER TABLE CiticPublic.minute
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
## -------------------------------------------------------------------------- ##   


################################################################################～～～～～～～～～～～～
## dev.CiticPublic_breakTime                                                      ## dev.CiticPublic_breakTime
################################################################################～～～～～～～～～～～～

CREATE TABLE CiticPublic.breakTime(
    TradingDay   DATE      NOT      NULL,                  ## 交易日期
    beginTime    TIME      NOT     NULL,                  ## 数据中断开始的时间
    endTime      TIME      NOT     NULL,                  ## 数据中断结束的时间
    #-----------------------------------------------------
    DataSource   CHAR(20)  NOT      NULL,                  ## 原始数据文件的来源，为主要目录
    DataFile     CHAR(20)  NOT      NULL,                  ## 原始数据的文件，为 csv 文件/路径
    #-----------------------------------------------------
    PRIMARY KEY (TradingDay, beginTime, endTime,
                 DataSource, DataFile)                     ## 主键唯一，重复不可输入
    );

################################################################################～～～～～～～～～～～～
## dev.CiticPublic_log                                                             ## dev.CiticPublic_log
################################################################################～～～～～～～～～～～～

CREATE TABLE CiticPublic.log(
    TradingDay   DATE           NOT      NULL,             ## 交易日期
    Sector       CHAR(20)       NOT      NULL,             ## 输入的数据类型：
    #                                                      ## 1. 'daily':主要处理日数据
    #                                                      ## 2. 'minute':分钟级别的数据
    #-----------------------------------------------------
    User         TINYTEXT           NULL,                  ## 哪个账户在录入数据
    MysqlDB      TINYTEXT           NULL,                  ## 数据输入到哪个数据库
    DataSource   TINYTEXT  NOT      NULL,                  ## 原始数据文件的来源，为主要目录
    DataFile     TEXT      NOT      NULL,                  ## 原始数据的文件，为 csv 文件/路径
    #-----------------------------------------------------
    RscriptMain  TEXT      NOT      NULL,                  ## 使用的主要 R 脚本文件，为最上层的文件，包括需要的包、相应的配置
    RscriptSub   TEXT      NOT      NULL,                  ## 使用的次一级 R 脚本，主要包括编写的函数即各种算法
    ProgBeginTime    DATETIME  NOT      NULL,              ## 程序开始运行的时间
    ProgEndTime      DATETIME  NOT      NULL,              ## 程序结束运行的时间
    Results      TEXT               NULL,                  ## 对数据哭修改的内容记录
    Remarks      TEXT               NULL,                  ## 备注，方便日后添加说明
    #-----------------------------------------------------
    PRIMARY KEY (TradingDay, Sector)                       ## 主键唯一，重复不可输入
    );

################################################################################～～～～～～～～～～～～
## dev.CiticPublic_log                                                             ## dev.CiticPublic_log
################################################################################～～～～～～～～～～～～

CREATE TABLE CiticPublic.info(
    TradingDay       DATE           NOT NULL,              ## 交易日期
    InstrumentID     CHAR(30)       NOT NULL,              ## 合约名称
    PriceTick        DECIMAL(10,5)  ,           
    VolumeMultiple   mediumint      ,     
    #-----------------------------------------------------
    PRIMARY KEY (TradingDay, InstrumentID)                 ## 主键唯一，重复不可输入
    );



####################################################################################################
####################################################################################################
##                   OPTIONS
##                   期权数据
####################################################################################################
####################################################################################################
################################################################################～～～～～～～～～～～～
## CiticPublic.daily                                                                  ## CiticPublic.daily     
################################################################################～～～～～～～～～～～～
CREATE TABLE  CiticPublic.daily_options(
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
    Turnover         DECIMAL(30,3)          NULL,          ## 成交额
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
CREATE INDEX index_daily_options
ON CiticPublic.daily_options
(TradingDay, Sector, InstrumentID);  
## -------------------------------------------------------------------------- ## 

##----------- PARTITIONS ---------------------------------------------------- ##
ALTER TABLE CiticPublic.daily_options
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
## -------------------------------------------------------------------------- ##   


################################################################################～～～～～～～～～～～～～
## CiticPublic.minute                                                                ## CiticPublic.minute
################################################################################～～～～～～～～～～～～～

CREATE TABLE  CiticPublic.minute_options(
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
    Turnover         DECIMAL(30,3)          NULL,          ## 成交额
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
CREATE INDEX index_minute_options
ON CiticPublic.minute_options
(TradingDay, Minute, InstrumentID);  
## -------------------------------------------------------------------------- ## 

##----------- PARTITIONS ---------------------------------------------------- ##
ALTER TABLE CiticPublic.minute_options
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
## -------------------------------------------------------------------------- ##   


################################################################################
-- truncate table daily;
-- truncate table minute;
-- truncate table breakTime;
-- truncate table info;
-- truncate table log;
