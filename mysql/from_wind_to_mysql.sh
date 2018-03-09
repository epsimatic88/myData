#!/bin/sh

## --------------------------------
## 从 windSQL 把 .sql 文件加载到数据库
## --------------------------------

for i in `ls -a /data/ChinaStocks/windSQL | grep .sql`
do
    echo "$i"
    mysql -u fl -pabc@123 wind < /data/ChinaStocks/windSQL/$i
done
