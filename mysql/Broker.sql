################################################################################
## 用于建立 Broker 的数据表。
## 包括：
## 1. 兴业证券: xyzq
################################################################################

CREATE DATABASE `Broker` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

## xyzq
CREATE TABLE Broker.XYZQ (
    accountName     CHAR(50)         NOT NULL,            ## 账户id
    accountID       CHAR(50)         NOT NULL,            ## 账户id
    updateDate      DATE             NOT NULL,
    updateTime      TIME             NOT NULL,
    assetValue      DECIMAL(30,3)    NULL,
    PRIMARY KEY (accountID, updateDate, updateTime)       ## 主键唯一，重复不可输入
)DEFAULT CHARSET=utf8;
