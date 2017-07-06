################################################################################
## myInit.R
## 初始化设置
# __1. 账号、密码__
# 2. 文件路径
# 3. 需要的软件包
# __4. 参数设置__
################################################################################
## =============================================================================
pkgs <- c("tidyverse", "data.table", "parallel",
          "RMySQL", "stringr", "bit64", "Rcpp",
          "lubridate","zoo",'beepr','plotly','rowr')
##------------------------------------------------------------------------------
if(length(pkgs[!pkgs %in% installed.packages()]) != 0){
  sapply(pkgs[!pkgs %in% installed.packages()], install.packages)
}
##------------------------------------------------------------------------------
sapply(pkgs, require, character.only = TRUE)

##------------------------------------------------------------------------------
options(digits = 8, digits.secs = 6, width　=　120,
        datatable.verbose = FALSE, scipen = 10)
##------------------------------------------------------------------------------
## =============================================================================

################################################################################
## MySQL
## 链接到 MySQL 数据库，以获取数据
################################################################################

MySQL(max.con = 300)
for( conns in dbListConnections(MySQL()) ){
  dbDisconnect(conns)
}

mysql_user <- 'fl'
mysql_pwd  <- 'abc@123'
mysql_host <- "127.0.0.1"
mysql_port <- 3306

#---------------------------------------------------
# mysqlFetch
# 函数，主要输入为
# database
#---------------------------------------------------
mysqlFetch <- function(x, host = mysql_host){
  dbConnect(MySQL(),
    dbname   = as.character(x),
    user     = mysql_user,
    password = mysql_pwd,
    host     = host,
    port     = mysql_port)
}
