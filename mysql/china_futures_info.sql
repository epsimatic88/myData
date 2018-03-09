################################################################################
## 用于建立 china_futures_info 的数据表。
## 包括：
## 1. Instrument_info：合约属性
## 2. CommissionRate_info 保证金率
## 3. VolumeMultiple: 合约乘数
################################################################################

################################################################################
## china_futures_info.Instrument_info
################################################################################
CREATE TABLE china_futures_info.Instrument_info(
  TradingDay     DATE           NOT NULL,                  ## 交易日期
  InstrumentID   CHAR(30)   NOT NULL,                      ## 合约名称
  ExchangeID     CHAR(20)   NOT NULL,                      ## 交易所代码
  ProductID      CHAR(30)   NOT NULL,                      ## 合约品种
  VolumeMultiple mediumint      NULL,                      ## 合约乘数
  PriceTick          DECIMAL(15,5)         NULL,           ## 最小变动单位价格
  LongMarginRatio    DECIMAL(15,5)         NULL,           ## 多头保证金率
  ShortMarginRatio   DECIMAL(15,5)         NULL,           ## 空头保证金率
  #-----------------------------------------------------------------------------
  PRIMARY KEY (TradingDay, InstrumentID, VolumeMultiple, PriceTick)
);


################################################################################
## china_futures_info.CommissionRate_info
################################################################################
CREATE TABLE china_futures_info.CommissionRate_info(
  TradingDay     DATE            NOT NULL,                  ## 交易日期
  Account        varchar(100)    NOT NULL,                  ## ZGC 在券商的账户: DongZheng_ZGC, GTJA_ZGC
  InstrumentID   VARCHAR(100)    NOT NULL,                  ## 合约名称
  OpenRatioByMoney        DECIMAL(15,10)        NULL,       ## 开仓手续费率 
  OpenRatioByVolume       DECIMAL(15,5)         NULL,       ## 开仓手续费
  CloseRatioByMoney       DECIMAL(15,10)        NULL,       ## 平仓手续费率
  CloseRatioByVolume      DECIMAL(15,5)         NULL,       ## 平仓手续费
  CloseTodayRatioByMoney  DECIMAL(15,10)        NULL,       ## 平今手续费率
  CloseTodayRatioByVolume DECIMAL(15,5)         NULL,       ## 平今手续费
  #-----------------------------------------------------------------------------
  PRIMARY KEY (TradingDay, Account, InstrumentID)
);


################################################################################
## china_futures_info.VolumeMultiple
################################################################################
CREATE TABLE china_futures_info.VolumeMultiple(
  TradingDay     DATE           NOT NULL,                   ## 交易日期
  InstrumentID   VARCHAR(100)   NOT NULL,                   ## 合约名称
  VolumeMultiple mediumint      NULL,                       ## 合约乘数
  #-----------------------------------------------------------------------------
  PRIMARY KEY (TradingDay, InstrumentID, VolumeMultiple)
);


################################################################################
## dev.info_log
################################################################################
CREATE TABLE dev.info_log(
  TradingDay     DATE           NOT NULL,                   ## 交易日期
  Account        varchar(100)   NOT NULL,                   ## ZGC 在券商的账户: DongZheng_ZGC, GTJA_ZGC
  Sector         varchar(100)   NOT NULL,                   ## 属性: Instrument, CommissionRate
  Results        TEXT           NULL,                       ## 处理的结果说明
  Remarks        TEXT           NULL, 
  #-----------------------------------------------------------------------------
  PRIMARY KEY (TradingDay, Account, Sector)
);

