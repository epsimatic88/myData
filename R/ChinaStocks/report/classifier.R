## 研报目录分类

## =============================================================================
suppressMessages({
  source('/home/fl/myData/R/Rconfig/myInit.R')
})

DATA_PATH <- '/data/ChinaStocks/Report/FromJRJ'

## 列出所有的年度
allYears <- list.files(DATA_PATH, full.names = T)

for (i in 1:length(allYears)) {

    ## 列出所有的日期
    allDays <- list.files(allYears[i], full.names = T)

    for (j in 1:length(allDays)) {

        ##　列出所有的研报
        allFiles <- list.files(allDays[j], full.names = T, pattern = "pdf|doc|docx")

        if (length(allFiles) == 0) next

        for (k in 1:length(allFiles)) {
            f <- allFiles[k]

            ## 提取研报类型
            reportClass <- gsub(".*[0-9]{4}-[0-9]{2}-[0-9]{2}-", "", f) %>% 
                strsplit(., "-") %>% 
                unlist() %>% 
                .[1]

            ## 提取研报标题
            reportTitle <- gsub(".*/[0-9]{4}-[0-9]{2}-[0-9]{2}/", "", f) 

            ## 创建研报分类目录
            tempDir <- paste0(allDays[j], '/', reportClass)
            if (!dir.exists(tempDir)) dir.create(tempDir)

            ## 移动文件
            destFile <- paste0(tempDir, '/', reportTitle)
            file.rename(from = f, to = destFile)
        }

    }

}
