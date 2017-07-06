find_bt<-function(x,k=60){ ##- 间断超过 60s
  n<-length(x);
  count<-0;
  m<-0;
  begin_time<-NULL;
  end_time<-NULL;
  result<-data.frame();
  for (i in 1:n){
    if (x[i]==1) {
      if (is.null(begin_time)) begin_time<-i;
      count<-count+1;
      if (i==n && count>=k) {
        m<-m+1;
        end_time<-i;
        result<-rbind(result,c(begin_time,end_time,count));
      }
    }
    else {
      if (count>=k)
      {
        m<-m+1;
        end_time<-i-1;
        result<-rbind(result,c(begin_time,end_time,count));
      }
      begin_time<-NULL;
      end_time<-NULL;
      count<-0;
    }
  }
  if (length(result) > 0) names(result) <- c("begin_time","end_time","count");
  return (result);
}
