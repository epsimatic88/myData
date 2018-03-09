## =============================================================================
## 用于下载 
## =============================================================================
library(magrittr)useR! International R User 2017 Conference
library(rvest)
library(downloader)


url <- "https://channel9.msdn.com/Events/useR-international-R-User-conferences/useR-International-R-User-2017-Conference?sort=status&direction=desc&page=2"

url %>% 
    read_html() %>% 
    html_nodes("h3 a") %>% 
    html_attr('href')

x = "https://channel9.msdn.com/Events/useR-international-R-User-conferences/useR-International-R-User-2017-Conference/Interactive-and-Reproducible-Research-for-RNA-Sequencing-Analysis" %>% 
    read_html() %>% 
    html_nodes(".download a") %>% 
    html_attr('href') %>% 
    grep('high',., value = TRUE)



download.file(x, '/home/william/Desktop/InteractiveAndReproducible_high.mp4')
