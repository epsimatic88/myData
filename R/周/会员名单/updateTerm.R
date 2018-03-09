rm(list = ls())

library(tidyverse)
library(readxl)
library(openxlsx)
library(data.table)

setwd("C:/Users/Administrator/Desktop/周")

dt1 <- read_excel('有效会员存档有电话.xls') %>% 
  as.data.table() %>% 
  .[, newName := gsub('-A|-B|A|B','',姓名)]
head(dt1)


dt2 <- read_excel("dt2.xlsx") %>% 
  as.data.table() %>% 
  .[, newName := gsub('-A|-B|A|B','',名称)] %>% 
  .[延期后有效期止 >= Sys.Date()] %>% 
  .[,延期后有效期止 := gsub('-','.',延期后有效期止)]
head(dt2)

for (i in 1:nrow(dt1)){
  if(dt1[i,newName] %in% dt2[,newName]){
    print(dt1[i,newName])
    if(nrow(dt2[newName == dt1[i,newName]]) >=2){
      print('有2个重复的名字')
    }
    dt1$会籍到期[i] <- dt2[newName == dt1[i,newName], 延期后有效期止]
  }
}

dt1[,newName := NULL]

write.xlsx(dt1,'newData.xlsx')
