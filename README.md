# myData

> Data Manipulation
> 用于处理数据库的所有脚本程序


```bash
.
├── data
│   ├── ChinaFuturesCalendar
│   │   ├── ChinaFuturesCalendar_2011_2016.csv
│   │   └── ChinaFuturesCalendar_2011_2017.csv
│   ├── FromMySQL
│   │   ├── china_futures_bar
│   │   │   ├── daily.fst
│   │   │   ├── main_contract_daily.fst
│   │   │   ├── minute.fst
│   │   │   └── oiRank.fst
│   │   ├── china_futures_HFT
│   │   │   ├── CiticPublic_201701.fst
│   │   │   ├── CiticPublic_201702.fst
│   │   │   ├── CiticPublic_201703.fst
│   │   │   ├── CiticPublic_201704.fst
│   │   │   ├── CiticPublic_201705.fst
│   │   │   ├── CiticPublic_201706.fst
│   │   │   └── CiticPublic_201707.fst
│   │   ├── china_futures_info
│   │   │   ├── CommissionRate_info.fst
│   │   │   ├── Instrument_info.fst
│   │   │   └── VolumeMultiple.fst
│   │   ├── dev
│   │   │   ├── basic.fst
│   │   │   ├── Basic.fst
│   │   │   ├── ChinaFuturesCalendar.fst
│   │   │   ├── CiticPublic_break_time.fst
│   │   │   ├── CiticPublic_log.fst
│   │   │   ├── daily.fst
│   │   │   ├── DC_daily_log.fst
│   │   │   ├── DC_data_break_time.fst
│   │   │   ├── DC_minute_log.fst
│   │   │   ├── HFT_log.fst
│   │   │   ├── info_log.fst
│   │   │   ├── oiRank.fst
│   │   │   ├── positionInfo.fst
│   │   │   ├── tempFL.fst
│   │   │   ├── VolumeMultiple.fst
│   │   │   └── wind_daily.fst
│   │   ├── HiCloud
│   │   │   ├── positionInfo.fst
│   │   │   ├── report_account.fst
│   │   │   ├── report_account_history.fst
│   │   │   ├── report_position.fst
│   │   │   ├── report_position_history.fst
│   │   │   └── tradingInfo.fst
│   │   ├── jydb
│   │   │   ├── DATABASECHANGELOG.fst
│   │   │   ├── DATABASECHANGELOGLOCK.fst
│   │   │   ├── Fut_MemberRankByContract.fst
│   │   │   ├── Fut_TradeStatByContract.fst
│   │   │   ├── Fut_TradeStat.fst
│   │   │   ├── Fut_WRStatByOption.fst
│   │   │   └── JYDB_DeleteRec.fst
│   │   ├── vnpy
│   │   │   ├── daily.fst
│   │   │   ├── log.fst
│   │   │   ├── minute.fst
│   │   │   └── tick.fst
│   │   └── YY_SimNow
│   │       ├── positionInfo.fst
│   │       ├── report_account.fst
│   │       ├── report_account_history.fst
│   │       ├── report_position.fst
│   │       ├── report_position_history.fst
│   │       └── tradingInfo.fst
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
│   ├── dailyDataLog_20170718.txt
│   ├── dailyDataLog_20170719.txt
│   ├── dailyDataLog_20170720.txt
│   ├── dailyDataLog_20170721.txt
│   ├── dailyDataLog_20170724.txt
│   ├── dailyDataLog_20170726.txt
│   ├── dailyDataLog_20170727.txt
│   ├── dailyDataLog_20170728.txt
│   ├── dailyDataLog_20170731.txt
│   ├── dailyDataLog_20170801.txt
│   ├── dailyDataLog_20170802.txt
│   ├── dailyDataLog_20170803.txt
│   ├── dailyDataLog_20170804.txt
│   ├── dailyDataLog_20170807.txt
│   ├── dailyDataLog_20170808.txt
│   ├── dailyDataLog_20170809.txt
│   └── dailyDataLog_20170810.txt
├── mysql
│   ├── china_futures_bar.sql
│   ├── china_futures_HFT.sql
│   ├── china_futures_info.sql
│   └── vnpy.sql
├── python
│   ├── auto it
│   │   ├── debang.py
│   │   ├── dongbei.py
│   │   ├── expt.py
│   │   ├── haitong.py
│   │   ├── init.py
│   │   ├── interface.py
│   │   ├── logging.py
│   │   ├── model.py
│   │   ├── monitor.py
│   │   ├── tdx.py
│   │   ├── tools.py
│   │   ├── wrapper.py
│   │   ├── yinhe.py
│   │   └── zhaoshang.py
│   ├── auto it.zip
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
│   │   │   │   ├── 20170726
│   │   │   │   │   ├── 20170726_dt_allday.fst
│   │   │   │   │   ├── 20170726_dt_day.fst
│   │   │   │   │   ├── 20170726_dtMinute.fst
│   │   │   │   │   ├── 20170726_dt_night.fst
│   │   │   │   │   └── 20170726_dtTick.fst
│   │   │   │   ├── 20170731
│   │   │   │   │   ├── 20170731_daily.fst
│   │   │   │   │   ├── 20170731_minute.fst
│   │   │   │   │   └── 20170731_tick.fst
│   │   │   │   ├── 20170801
│   │   │   │   │   ├── 20170801_daily.fst
│   │   │   │   │   ├── 20170801_minute.fst
│   │   │   │   │   └── 20170801_tick.fst
│   │   │   │   ├── 20170802
│   │   │   │   │   ├── 20170802_daily.fst
│   │   │   │   │   └── 20170802_minute.fst
│   │   │   │   ├── ctpmdprod1.20170504023201.csv
│   │   │   │   ├── ctpmdprod1.20170511023201.csv
│   │   │   │   └── ctpmdprod1.20170511151701.csv
│   │   │   └── readme.md
│   │   ├── colo
│   │   │   ├── ChinaFuturesTickData2mysql_00_main_history.R
│   │   │   ├── ChinaFuturesTickData2mysql_01_main_crontab.R
│   │   │   ├── ChinaFuturesTickData2mysql_10_read_data.R
│   │   │   ├── ChinaFuturesTickData2mysql_20_manipulate_data.R
│   │   │   ├── ChinaFuturesTickData2mysql_30_insert_data.R
│   │   │   ├── ChinaFuturesTickData2mysql_40_NA_data.R
│   │   │   └── ChinaFuturesTickData2mysql_50_mysql_data.R
│   │   ├── CTPMD
│   │   │   ├── ctpMD2mysql_00_main.R
│   │   │   ├── ctpMD2mysql_01_read_data.R
│   │   │   ├── ctpMD2mysql_02_manipulate_data.R
│   │   │   ├── ctpMD2mysql_03_mysql_data.R
│   │   │   ├── ctpMD2mysql_04_NA_data.R
│   │   │   └── readme.md
│   │   ├── FromDC
│   │   │   ├── FromDC2mysql_00_main.R
│   │   │   ├── FromDC2mysql_10_read_data.R
│   │   │   ├── FromDC2mysql_20_manipulate_data.R
│   │   │   ├── FromDC2mysql_30_transform_bar.R
│   │   │   ├── FromDC2mysql_40_NA_bar.R
│   │   │   └── FromDC2mysql_50_mysql_data.R
│   │   └── oiRank
│   │       ├── oiRank2mysql_00_main.R
│   │       ├── oiRank2mysql_02_CFFEX.R
│   │       └── oiRank2mysql_04_data_mysql.R
│   ├── ChinaFuturesCalendar
│   │   ├── ChinaFuturesCalendar_2017.R
│   │   └── ChinaFutures.R
│   ├── china_futures_info
│   │   ├── DongZheng_ZGC
│   │   │   ├── ChinaFuturesInfo2mysql_00_main.R
│   │   │   ├── ChinaFuturesInfo2mysql_01_read_data.R
│   │   │   ├── ChinaFuturesInfo2mysql_02_process_Instrument_info.R
│   │   │   └── ChinaFuturesInfo2mysql_03_process_CommissionRate_info.R
│   │   └── MEY_XXF
│   │       ├── ChinaFuturesInfo2mysql_00_main.R
│   │       ├── ChinaFuturesInfo2mysql_01_read_data.R
│   │       ├── ChinaFuturesInfo2mysql_02_process_Instrument_info.R
│   │       └── ChinaFuturesInfo2mysql_03_process_CommissionRate_info.R
│   ├── DataCompare
│   │   ├── colo_speed
│   │   │   └── compare_colo_receive_speed.R
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
│   │   ├── fromMySQL.R
│   │   ├── mysql2mysql.R
│   │   ├── updateDailyCloseCZCE.R
│   │   ├── userR2017_Brussels_video_downloader.R
│   │   ├── 补全数据_20170726.R
│   │   └── 补全数据.R
│   ├── Rconfig
│   │   ├── dt2DailyBar.R
│   │   ├── dt2MinuteBar.R
│   │   ├── MainContract_00_main.R
│   │   ├── myBreakTime.R
│   │   ├── myDay.R
│   │   ├── myFread.R
│   │   └── myInit.R
│   └── vnpyData
│       ├── readme.md
│       ├── vnpyData2mysql_00_main.R
│       ├── vnpyData2mysql_01_read_data.R
│       ├── vnpyData2mysql_02_manipulate_data.R
│       ├── vnpyData2mysql_03_mysql_data.R
│       └── vnpyData2mysql_04_NA_data.R
└── README.md

46 directories, 214 files
```


- china_futures_bar
    
    - [X] CiticPublic
    - [X] CTPMD
    - [ ] FromDC
    - [ ] colo
    - [ ] oiRank

- china_futures_info

    - [X] CommissionRate_info
    - [X] Instrument_info
    - [X] VolumeMultiple

- ChinaFuturesCalendar

    - [X] ChinaFuturesCalendar_2017.R

- vnpyData

- DataCompare

    - [X] jyd
    - [X] wind

- Misc

    - [X] updateDailyCloseCZCE.R
    
- [X] DataMonitor.R
