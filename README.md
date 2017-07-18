# myData

> Data Manipulation
>
> 处理各种数据、管理数据库的程序脚本


```bash
.
├── data
│   ├── ChinaFuturesCalendar
│   │   ├── ChinaFuturesCalendar_2011_2016.csv
│   │   └── ChinaFuturesCalendar_2011_2017.csv
│   └── oiRank
│       ├── history
│       │   ├── positionRank_CFFEX_2011.csv
│       │   ├── positionRank_CFFEX_2012.csv
│       │   ├── positionRank_CFFEX_2013.csv
│       │   ├── positionRank_CFFEX_2014.csv
│       │   ├── positionRank_CFFEX_2015.csv
│       │   ├── positionRank_CFFEX_2016.csv
│       │   ├── positionRank_CFFEX_2017.csv
│       │   ├── positionRank_CZCE_2011.csv
│       │   ├── positionRank_CZCE_2012.csv
│       │   ├── positionRank_CZCE_2013.csv
│       │   ├── positionRank_CZCE_2014.csv
│       │   ├── positionRank_CZCE_2015.csv
│       │   ├── positionRank_CZCE_2016.csv
│       │   ├── positionRank_CZCE_2017.csv
│       │   ├── positionRank_DCE_2011.csv
│       │   ├── positionRank_DCE_2012.csv
│       │   ├── positionRank_DCE_2013.csv
│       │   ├── positionRank_DCE_2014.csv
│       │   ├── positionRank_DCE_2015.csv
│       │   ├── positionRank_DCE_2016.csv
│       │   ├── positionRank_DCE_2017.csv
│       │   ├── positionRank_SHFE_2011.csv
│       │   ├── positionRank_SHFE_2012.csv
│       │   ├── positionRank_SHFE_2013.csv
│       │   ├── positionRank_SHFE_2014.csv
│       │   ├── positionRank_SHFE_2015.csv
│       │   ├── positionRank_SHFE_2016.csv
│       │   └── positionRank_SHFE_2017.csv
│       └── updating
│           ├── CFFEX
│           ├── CZCE
│           ├── DCE
│           └── SHFE
├── LICENSE
├── log
│   └── dailyDataLog_20170713.txt
├── missingData.csv
├── mysql
│   ├── china_futures_bar.sql
│   └── china_futures_info.sql
├── python
│   └── sendEmail.py
├── R
│   ├── china_futures_bar
│   │   ├── CiticPublic
│   │   │   ├── CiticPublic2mysql_00_main.R
│   │   │   ├── CiticPublic2mysql_01_read_data.R
│   │   │   ├── CiticPublic2mysql_02_manipulate_data.R
│   │   │   ├── CiticPublic2mysql_03_mysql_data.R
│   │   │   ├── CiticPublic2mysql_04_NA_data.R
│   │   │   ├── CiticPublic2mysql_05_night_minute.R
│   │   │   ├── data
│   │   │   │   ├── ctpmdprod1.20170504023201.csv
│   │   │   │   ├── ctpmdprod1.20170511023201.csv
│   │   │   │   └── ctpmdprod1.20170511151701.csv
│   │   │   └── readme.md
│   │   ├── FromDC
│   │   └── oiRank
│   │       ├── oiRank2mysql_00_main.R
│   │       ├── oiRank2mysql_02_CFFEX.R
│   │       └── oiRank2mysql_04_data_mysql.R
│   ├── ChinaFuturesCalendar
│   │   └── ChinaFuturesCalendar_2017.R
│   ├── china_futures_info
│   │   ├── ChinaFuturesInfo2mysql_00_main.R
│   │   ├── ChinaFuturesInfo2mysql_01_read_data.R
│   │   ├── ChinaFuturesInfo2mysql_02_process_Instrument_info.R
│   │   └── ChinaFuturesInfo2mysql_03_process_CommissionRate_info.R
│   ├── DataCompare
│   │   ├── jydb
│   │   │   ├── 2017-01-03-2.png
│   │   │   ├── 2017-01-03.png
│   │   │   ├── 2017-03-31.png
│   │   │   ├── jydb_oiRank.R
│   │   │   ├── missingData.csv
│   │   │   ├── skeleton.bib
│   │   │   ├── 聚源数据对比.html
│   │   │   ├── 聚源数据对比.Rmd
│   │   │   └── 聚源数据库
│   │   │       ├── 期货交易统计.png
│   │   │       └── 聚源新版数据库_介绍.png
│   │   └── wind
│   │       ├── ContractInfo_20170711.csv
│   │       ├── dtAllDay.csv
│   │       ├── wind_futures_ohlc.R
│   │       ├── wind_verifying.html
│   │       ├── wind_verifying.Rmd
│   │       └── wind_verifying - 副本.html
│   ├── DataMonitor.R
│   ├── Misc
│   │   └── updateDailyCloseCZCE.R
│   ├── Rconfig
│   │   ├── dt2DailyBar.R
│   │   ├── dt2MinuteBar.R
│   │   ├── myBreakTime.R
│   │   ├── myDay.R
│   │   ├── myFread.R
│   │   └── myInit.R
│   └── vnpyData
│       └── vnpyData2mysql_00_main.R
└── README.md
```


- china_futures_bar
    
    - [X] CiticPublic
    - [ ] FromDC
    - [ ] oiRank

- china_futures_info

    - [X] CommissionRate_info
    - [X] Instrument_info
    - [X] VolumeMultiple

- ChinaFuturesCalendar

    - [X] ChinaFuturesCalendar_2017.R

- DataCompare

    - [X] jyd
    - [X] wind

- Misc

    - [X] updateDailyCloseCZCE.R
    
- [X] DataMonitor.R

福州服务器测试

�������Ĳ��Բ���
