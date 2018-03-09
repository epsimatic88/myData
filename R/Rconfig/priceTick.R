################################################################################
## priceTick.R
## 根据 BidPrice1 和 AskPric1 来计算最小单位价格
## PriceTick
################################################################################

calPriceTick <- function(dt) {
    res <- dt[, .(TradingDay = .SD[,unique(TradingDay)],
                  PriceTick = .SD[, min(abs(diff(BidPrice1)[diff(BidPrice1) != 0]), 
                                       abs(diff(AskPrice1)[diff(AskPrice1) != 0]),
                                       abs(BidPrice1 - AskPrice1)[abs(BidPrice1 - AskPrice1) != 0])])
              , by = 'InstrumentID']
    return(res)
}

