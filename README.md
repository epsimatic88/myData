# myData

> Data Manipulation
>
> 处理各种数据、管理数据库的程序脚本


```bash
.
├── data
│   └── ChinaFuturesCalendar
│       ├── ChinaFuturesCalendar_2011_2016.csv
│       └── ChinaFuturesCalendar_2011_2017.csv
├── LICENSE
├── log
│   ├── dailyDataLog_20170711.txt
│   └── dailyDataLog_20170712.txt
├── mysql
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
│   ├── ChinaFuturesCalendar
│   │   └── ChinaFuturesCalendar_2017.R
│   ├── china_futures_info
│   │   ├── ChinaFuturesInfo2mysql_00_main.R
│   │   ├── ChinaFuturesInfo2mysql_01_read_data.R
│   │   ├── ChinaFuturesInfo2mysql_02_process_Instrument_info.R
│   │   └── ChinaFuturesInfo2mysql_03_process_CommissionRate_info.R
│   ├── DataCompare
│   │   ├── jydb
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
│   └── Rconfig
│       ├── dt2DailyBar.R
│       ├── dt2MinuteBar.R
│       ├── myBreakTime.R
│       ├── myDay.R
│       ├── myFread.R
│       └── myInit.R
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
