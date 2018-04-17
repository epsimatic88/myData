################################################################################
## 用于建立 china_stocks_bar 的数据表。
## 包括：
## 1. daily
################################################################################

CREATE DATABASE `china_stocks_bar` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

################################################################################
## china_stocks_bar.daily
################################################################################
CREATE TABLE  china_stocks_bar.daily(
    TradingDay      DATE             NOT NULL,          ## 交易日期
    stockID         CHAR(6)          NOT NULL,          ## 日期属性: 
    stockName       VARCHAR(30),                        ## 股票名称: 
    #------------------------------------------------------
    open            DECIMAL(15,3),                      ## 开盘价
    high            DECIMAL(15,3),                      ## 开盘价
    low             DECIMAL(15,3),                      ## 开盘价
    close           DECIMAL(15,3),                      ## 开盘价
    #-----------------------------------------------------
    bAdj            DECIMAL(30,6),                      ## 后复权因子
    #-----------------------------------------------------
    volume          BIGINT,                             ## 交易量， 股
    turnover        DECIMAL(30,3),                      ## 交易额，元
    #-----------------------------------------------------
    -- fcap            DECIMAL(30,3),                      ## 流通市值
    -- tcap            DECIMAL(30,3),                      ## 总市值
    #-----------------------------------------------------
    status          VARCHAR(50),                        ## 交易状态
    upperLimit      DECIMAL(15,3),                      ## 涨停价
    lowerLimit      DECIMAL(15,3),                      ## 跌停价
    isLimit         CHAR(1),                            ## 涨跌停标识
                                                        ## 1. u: 涨停
                                                        ## 2, l：跌停
    ifST            CHAR(1),                            ## 是否 st:
                                                        ## 1. y: 是st
                                                        ## 2. n：不是st
    #-----------------------------------------------------
    PRIMARY KEY (TradingDay, stockID)                   ## 主键唯一，重复不可输入
    );

##----------- INDEX --------------------------------------------------------- ##
CREATE INDEX index_daily
ON china_stocks_bar.daily
(TradingDay, stockID);  
## -------------------------------------------------------------------------- ## 


################################################################################
## china_stocks_bar.price_limit
################################################################################
CREATE TABLE  china_stocks_bar.price_limit(
    TradingDay      DATE             NOT NULL,          ## 交易日期
    stockID         CHAR(6)          NOT NULL,          ## 日期属性: 
    stockName       VARCHAR(30),                        ## 股票名称: 
    #------------------------------------------------------
    isUL            CHAR(1),                            ## 涨跌停标识
                                                        ## 1. u: 涨停
                                                        ## 2, l：跌停
    #-----------------------------------------------------
    PRIMARY KEY (TradingDay, stockID)                   ## 主键唯一，重复不可输入
    );

##----------- INDEX --------------------------------------------------------- ##
CREATE INDEX index_price_limit
ON china_stocks_bar.price_limit
(TradingDay, stockID);  
## -------------------------------------------------------------------------- ## 

################################################################################
## china_stocks_bar.lhb
################################################################################
CREATE TABLE  china_stocks_bar.lhb(
    TradingDay      DATE             NOT NULL,          ## 交易日期
    stockID         CHAR(6)          NOT NULL,          ## 股票代码
    stockName       VARCHAR(30)      NOT NULL,          ## 股票名称
    #------------------------------------------------------
    lhbName         VARCHAR(100),                       ## 龙虎榜名称
    DeptName        VARCHAR(100),                       ## 营业部名称
    buyAmount       DECIMAL(30,3),                      ## 买入金额（元）
    sellAmount      DECIMAL(30,3),                      ## 卖出金额（元）
    netAmount       DECIMAL(30,3),                      ## 净额（元）
    #-----------------------------------------------------
    PRIMARY KEY (TradingDay, stockID, 
                 lhbName, DeptName, buyAmount, sellAmount) ## 主键唯一，重复不可输入
    );
##----------- INDEX --------------------------------------------------------- ##
CREATE INDEX index_lhb
ON china_stocks_bar.lhb
(TradingDay, stockID, 
 lhbName, DeptName, buyAmount, sellAmount);  
## -------------------------------------------------------------------------- ## 


################################################################################
## china_stocks_bar.rzrq
################################################################################
CREATE TABLE  china_stocks_bar.rzrq(
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
CREATE INDEX index_rzrq
ON china_stocks_bar.rzrq
(TradingDay, stockID);
## -------------------------------------------------------------------------- ##




################################################################################
## china_stocks_bar.dzjy
################################################################################
CREATE TABLE  china_stocks_bar.dzjy(
    TradingDay      DATE             NOT NULL,          ## 交易日期
    stockID         CHAR(6)          NOT NULL,          ## 股票代码
    stockName       VARCHAR(30)      NOT NULL,          ## 股票名称
    #------------------------------------------------------
    price           DECIMAL(15,3),                      ## 成交价格：元
    volume          BIGINT,                             ## 成交数量：股
    turnover        DECIMAL(30,3),                      ## 成交金额：源
    #-----------------------------------------------------
    DeptBuy         VARCHAR(100),                       ## 买入营业部
    DeptSell        VARCHAR(100),                       ## 卖出营业部
    #-----------------------------------------------------
    PRIMARY KEY (TradingDay, stockID, price, volume, turnover,
                 DeptBuy, DeptSell)                   ## 主键唯一，重复不可输入
    );

##----------- INDEX --------------------------------------------------------- ##
CREATE INDEX index_dzjy
ON china_stocks_bar.dzjy
(TradingDay, stockID, price, volume, turnover,
 DeptBuy, DeptSell);
## -------------------------------------------------------------------------- ##



################################################################################
## china_stocks_bar.minute
################################################################################
CREATE TABLE  china_stocks_bar.minute(
    TradingDay      DATE             NOT NULL,          ## 交易日期
    Minute          TIME             NOT NULL,          ## 分钟，格式为==> "HH:MM:SS"", 与 Wind 数据库类似
    stockID         CHAR(6)          NOT NULL,          ## 股票代码:
    #------------------------------------------------------
    open            DECIMAL(15,3),                      ## 开盘价
    high            DECIMAL(15,3),                      ## 开盘价
    low             DECIMAL(15,3),                      ## 开盘价
    close           DECIMAL(15,3),                      ## 开盘价
    #-----------------------------------------------------
    volume          BIGINT,                             ## 交易量， 股
    turnover        DECIMAL(30,3),                      ## 交易额，元
    #-----------------------------------------------------
    PRIMARY KEY (TradingDay, Minute, stockID)           ## 主键唯一，重复不可输入
    );

##----------- INDEX --------------------------------------------------------- ##
CREATE INDEX index_minute
ON china_stocks_bar.minute
(TradingDay, Minute, stockID);
## -------------------------------------------------------------------------- ##
##----------- PARTITIONS ---------------------------------------------------- ##
ALTER TABLE china_stocks_bar.minute
    PARTITION BY RANGE( TO_DAYS(TradingDay) )(
    #---------------------------------------------------------------------------
    PARTITION p_2007_01 VALUES LESS THAN (TO_DAYS('2007-02-01')),
    PARTITION p_2007_02 VALUES LESS THAN (TO_DAYS('2007-03-01')),
    PARTITION p_2007_03 VALUES LESS THAN (TO_DAYS('2007-04-01')),
    PARTITION p_2007_04 VALUES LESS THAN (TO_DAYS('2007-05-01')),
    PARTITION p_2007_05 VALUES LESS THAN (TO_DAYS('2007-06-01')),
    PARTITION p_2007_06 VALUES LESS THAN (TO_DAYS('2007-07-01')),
    PARTITION p_2007_07 VALUES LESS THAN (TO_DAYS('2007-08-01')),
    PARTITION p_2007_08 VALUES LESS THAN (TO_DAYS('2007-09-01')),
    PARTITION p_2007_09 VALUES LESS THAN (TO_DAYS('2007-10-01')),
    PARTITION p_2007_10 VALUES LESS THAN (TO_DAYS('2007-11-01')),
    PARTITION p_2007_11 VALUES LESS THAN (TO_DAYS('2007-12-01')),
    PARTITION p_2007_12 VALUES LESS THAN (TO_DAYS('2008-01-01')),
    #---------------------------------------------------------------------------
    #---------------------------------------------------------------------------
    PARTITION p_2008_01 VALUES LESS THAN (TO_DAYS('2008-02-01')),
    PARTITION p_2008_02 VALUES LESS THAN (TO_DAYS('2008-03-01')),
    PARTITION p_2008_03 VALUES LESS THAN (TO_DAYS('2008-04-01')),
    PARTITION p_2008_04 VALUES LESS THAN (TO_DAYS('2008-05-01')),
    PARTITION p_2008_05 VALUES LESS THAN (TO_DAYS('2008-06-01')),
    PARTITION p_2008_06 VALUES LESS THAN (TO_DAYS('2008-07-01')),
    PARTITION p_2008_07 VALUES LESS THAN (TO_DAYS('2008-08-01')),
    PARTITION p_2008_08 VALUES LESS THAN (TO_DAYS('2008-09-01')),
    PARTITION p_2008_09 VALUES LESS THAN (TO_DAYS('2008-10-01')),
    PARTITION p_2008_10 VALUES LESS THAN (TO_DAYS('2008-11-01')),
    PARTITION p_2008_11 VALUES LESS THAN (TO_DAYS('2008-12-01')),
    PARTITION p_2008_12 VALUES LESS THAN (TO_DAYS('2009-01-01')),
    #---------------------------------------------------------------------------
    #---------------------------------------------------------------------------
    PARTITION p_2009_01 VALUES LESS THAN (TO_DAYS('2009-02-01')),
    PARTITION p_2009_02 VALUES LESS THAN (TO_DAYS('2009-03-01')),
    PARTITION p_2009_03 VALUES LESS THAN (TO_DAYS('2009-04-01')),
    PARTITION p_2009_04 VALUES LESS THAN (TO_DAYS('2009-05-01')),
    PARTITION p_2009_05 VALUES LESS THAN (TO_DAYS('2009-06-01')),
    PARTITION p_2009_06 VALUES LESS THAN (TO_DAYS('2009-07-01')),
    PARTITION p_2009_07 VALUES LESS THAN (TO_DAYS('2009-08-01')),
    PARTITION p_2009_08 VALUES LESS THAN (TO_DAYS('2009-09-01')),
    PARTITION p_2009_09 VALUES LESS THAN (TO_DAYS('2009-10-01')),
    PARTITION p_2009_10 VALUES LESS THAN (TO_DAYS('2009-11-01')),
    PARTITION p_2009_11 VALUES LESS THAN (TO_DAYS('2009-12-01')),
    PARTITION p_2009_12 VALUES LESS THAN (TO_DAYS('2010-01-01')),
    #---------------------------------------------------------------------------
    #---------------------------------------------------------------------------
    PARTITION p_2010_01 VALUES LESS THAN (TO_DAYS('2010-02-01')),
    PARTITION p_2010_02 VALUES LESS THAN (TO_DAYS('2010-03-01')),
    PARTITION p_2010_03 VALUES LESS THAN (TO_DAYS('2010-04-01')),
    PARTITION p_2010_04 VALUES LESS THAN (TO_DAYS('2010-05-01')),
    PARTITION p_2010_05 VALUES LESS THAN (TO_DAYS('2010-06-01')),
    PARTITION p_2010_06 VALUES LESS THAN (TO_DAYS('2010-07-01')),
    PARTITION p_2010_07 VALUES LESS THAN (TO_DAYS('2010-08-01')),
    PARTITION p_2010_08 VALUES LESS THAN (TO_DAYS('2010-09-01')),
    PARTITION p_2010_09 VALUES LESS THAN (TO_DAYS('2010-10-01')),
    PARTITION p_2010_10 VALUES LESS THAN (TO_DAYS('2010-11-01')),
    PARTITION p_2010_11 VALUES LESS THAN (TO_DAYS('2010-12-01')),
    PARTITION p_2010_12 VALUES LESS THAN (TO_DAYS('2011-01-01')),
    #---------------------------------------------------------------------------
    #---------------------------------------------------------------------------
    PARTITION p_2011_01 VALUES LESS THAN (TO_DAYS('2011-02-01')),
    PARTITION p_2011_02 VALUES LESS THAN (TO_DAYS('2011-03-01')),
    PARTITION p_2011_03 VALUES LESS THAN (TO_DAYS('2011-04-01')),
    PARTITION p_2011_04 VALUES LESS THAN (TO_DAYS('2011-05-01')),
    PARTITION p_2011_05 VALUES LESS THAN (TO_DAYS('2011-06-01')),
    PARTITION p_2011_06 VALUES LESS THAN (TO_DAYS('2011-07-01')),
    PARTITION p_2011_07 VALUES LESS THAN (TO_DAYS('2011-08-01')),
    PARTITION p_2011_08 VALUES LESS THAN (TO_DAYS('2011-09-01')),
    PARTITION p_2011_09 VALUES LESS THAN (TO_DAYS('2011-10-01')),
    PARTITION p_2011_10 VALUES LESS THAN (TO_DAYS('2011-11-01')),
    PARTITION p_2011_11 VALUES LESS THAN (TO_DAYS('2011-12-01')),
    PARTITION p_2011_12 VALUES LESS THAN (TO_DAYS('2012-01-01')),
    #---------------------------------------------------------------------------
    #---------------------------------------------------------------------------
    PARTITION p_2012_01 VALUES LESS THAN (TO_DAYS('2012-02-01')),
    PARTITION p_2012_02 VALUES LESS THAN (TO_DAYS('2012-03-01')),
    PARTITION p_2012_03 VALUES LESS THAN (TO_DAYS('2012-04-01')),
    PARTITION p_2012_04 VALUES LESS THAN (TO_DAYS('2012-05-01')),
    PARTITION p_2012_05 VALUES LESS THAN (TO_DAYS('2012-06-01')),
    PARTITION p_2012_06 VALUES LESS THAN (TO_DAYS('2012-07-01')),
    PARTITION p_2012_07 VALUES LESS THAN (TO_DAYS('2012-08-01')),
    PARTITION p_2012_08 VALUES LESS THAN (TO_DAYS('2012-09-01')),
    PARTITION p_2012_09 VALUES LESS THAN (TO_DAYS('2012-10-01')),
    PARTITION p_2012_10 VALUES LESS THAN (TO_DAYS('2012-11-01')),
    PARTITION p_2012_11 VALUES LESS THAN (TO_DAYS('2012-12-01')),
    PARTITION p_2012_12 VALUES LESS THAN (TO_DAYS('2013-01-01')),
    #---------------------------------------------------------------------------
    #---------------------------------------------------------------------------
    PARTITION p_2013_01 VALUES LESS THAN (TO_DAYS('2013-02-01')),
    PARTITION p_2013_02 VALUES LESS THAN (TO_DAYS('2013-03-01')),
    PARTITION p_2013_03 VALUES LESS THAN (TO_DAYS('2013-04-01')),
    PARTITION p_2013_04 VALUES LESS THAN (TO_DAYS('2013-05-01')),
    PARTITION p_2013_05 VALUES LESS THAN (TO_DAYS('2013-06-01')),
    PARTITION p_2013_06 VALUES LESS THAN (TO_DAYS('2013-07-01')),
    PARTITION p_2013_07 VALUES LESS THAN (TO_DAYS('2013-08-01')),
    PARTITION p_2013_08 VALUES LESS THAN (TO_DAYS('2013-09-01')),
    PARTITION p_2013_09 VALUES LESS THAN (TO_DAYS('2013-10-01')),
    PARTITION p_2013_10 VALUES LESS THAN (TO_DAYS('2013-11-01')),
    PARTITION p_2013_11 VALUES LESS THAN (TO_DAYS('2013-12-01')),
    PARTITION p_2013_12 VALUES LESS THAN (TO_DAYS('2014-01-01')),
    #---------------------------------------------------------------------------
    #---------------------------------------------------------------------------
    PARTITION p_2014_01 VALUES LESS THAN (TO_DAYS('2014-02-01')),
    PARTITION p_2014_02 VALUES LESS THAN (TO_DAYS('2014-03-01')),
    PARTITION p_2014_03 VALUES LESS THAN (TO_DAYS('2014-04-01')),
    PARTITION p_2014_04 VALUES LESS THAN (TO_DAYS('2014-05-01')),
    PARTITION p_2014_05 VALUES LESS THAN (TO_DAYS('2014-06-01')),
    PARTITION p_2014_06 VALUES LESS THAN (TO_DAYS('2014-07-01')),
    PARTITION p_2014_07 VALUES LESS THAN (TO_DAYS('2014-08-01')),
    PARTITION p_2014_08 VALUES LESS THAN (TO_DAYS('2014-09-01')),
    PARTITION p_2014_09 VALUES LESS THAN (TO_DAYS('2014-10-01')),
    PARTITION p_2014_10 VALUES LESS THAN (TO_DAYS('2014-11-01')),
    PARTITION p_2014_11 VALUES LESS THAN (TO_DAYS('2014-12-01')),
    PARTITION p_2014_12 VALUES LESS THAN (TO_DAYS('2015-01-01')),
    #---------------------------------------------------------------------------
    #---------------------------------------------------------------------------
    PARTITION p_2015_01 VALUES LESS THAN (TO_DAYS('2015-02-01')),
    PARTITION p_2015_02 VALUES LESS THAN (TO_DAYS('2015-03-01')),
    PARTITION p_2015_03 VALUES LESS THAN (TO_DAYS('2015-04-01')),
    PARTITION p_2015_04 VALUES LESS THAN (TO_DAYS('2015-05-01')),
    PARTITION p_2015_05 VALUES LESS THAN (TO_DAYS('2015-06-01')),
    PARTITION p_2015_06 VALUES LESS THAN (TO_DAYS('2015-07-01')),
    PARTITION p_2015_07 VALUES LESS THAN (TO_DAYS('2015-08-01')),
    PARTITION p_2015_08 VALUES LESS THAN (TO_DAYS('2015-09-01')),
    PARTITION p_2015_09 VALUES LESS THAN (TO_DAYS('2015-10-01')),
    PARTITION p_2015_10 VALUES LESS THAN (TO_DAYS('2015-11-01')),
    PARTITION p_2015_11 VALUES LESS THAN (TO_DAYS('2015-12-01')),
    PARTITION p_2015_12 VALUES LESS THAN (TO_DAYS('2016-01-01')),
    #---------------------------------------------------------------------------
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
    #---------------------------------------------------------------------------
    PARTITION p_2019_01 VALUES LESS THAN (TO_DAYS('2019-02-01')),
    PARTITION p_2019_02 VALUES LESS THAN (TO_DAYS('2019-03-01')),
    PARTITION p_2019_03 VALUES LESS THAN (TO_DAYS('2019-04-01')),
    PARTITION p_2019_04 VALUES LESS THAN (TO_DAYS('2019-05-01')),
    PARTITION p_2019_05 VALUES LESS THAN (TO_DAYS('2019-06-01')),
    PARTITION p_2019_06 VALUES LESS THAN (TO_DAYS('2019-07-01')),
    PARTITION p_2019_07 VALUES LESS THAN (TO_DAYS('2019-08-01')),
    PARTITION p_2019_08 VALUES LESS THAN (TO_DAYS('2019-09-01')),
    PARTITION p_2019_09 VALUES LESS THAN (TO_DAYS('2019-10-01')),
    PARTITION p_2019_10 VALUES LESS THAN (TO_DAYS('2019-11-01')),
    PARTITION p_2019_11 VALUES LESS THAN (TO_DAYS('2019-12-01')),
    PARTITION p_2019_12 VALUES LESS THAN (TO_DAYS('2020-01-01')),
    #---------------------------------------------------------------------------    
    PARTITION p_2020_01 VALUES LESS THAN maxvalue
    );
## -------------------------------------------------------------------------- ##   




