# 巨潮信息网(http://www.cninfo.com.cn)

巨潮信息网是由中国证监会指定的沪深两个交易所上市公司公开信息发布平台，并同时提供香港交易所上市公式的信息发布公告。作为一家官方唯一指定的正规渠道，巨潮信息网在保证公告发布的及时性、信息更新的高效性、数据传输的稳定性的方面均有良好的表现。

该网站提供的上市公司信息囊括了多维度的数据，含企业基本信息列表、财务数据、分红派息、历史行情数据、股本结构的。

本项目旨在建立一个通用的数据传输接口 API。

## 雪球文章

很偶然的一次机会，在雪球上面看到有人分享了[1.2 简单介绍数据获取方式（Excel VBA）- 分红派息](https://xueqiu.com/4240116588/34327055)。文章给出了一种获取上市公司实时更新数据的方式：巨潮网。

这篇文章介绍了如何获取股票分红派股的数据。

```bash
URL = "http://www.cninfo.com.cn/information/dividend/" & StockCode & ".html"

StockCode 是纯数字没后缀
If Left(StockCode, 1) = "6" Then

    StockCode = "shmb" & StockCode

ElseIf Left(StockCode, 3) = "002" Then

    StockCode = "szsme" & StockCode

ElseIf Left(StockCode, 1) = "3" Then

    StockCode = "szcn" & StockCode

Else

    StockCode = "szmb" & StockCode

End If
```
