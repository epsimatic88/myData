################################################################################
## MySQL:
## 用于建立 MySQL 数据库命令
## 
## 包括:
## china_indexs_info
## 
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2018-01-03
################################################################################

CREATE DATABASE `china_stocks_info` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

################################################################################
## china_stocks_info.stocks_list
################################################################################
CREATE TABLE china_stocks_info.stocks_list(
  stockID       CHAR(30)   NOT NULL,       ## 股票代码
  stockName     CHAR(30)   NOT NULL,       ## 股票名称
  ## ---------------------------------------------------------------------------
  stockID_B     CHAR(30)   NOT NULL,       ## 股票代码B
  stockName_B   CHAR(30)   NOT NULL,       ## 股票名称B
  ## ---------------------------------------------------------------------------
  listingDate   DATE       NOT NULL,       ## 上市时间
  exchID        CHAR(30)   NOT NULL,       ## 交易所代码, sh, sz
  #-----------------------------------------------------------------------------
  PRIMARY KEY (stockID, exchID)
);


################################################################################
## china_stocks_info.index_list
################################################################################
CREATE TABLE china_stocks_info.index_list(
  indexID       CHAR(30)   NOT NULL,       ## 股票代码
  indexName     CHAR(30)   NOT NULL,       ## 股票名称
  ## ---------------------------------------------------------------------------
  exchID        CHAR(30)   NOT NULL,       ## 交易所代码, sh, sz
  #-----------------------------------------------------------------------------
  PRIMARY KEY (indexID, exchID)
);
