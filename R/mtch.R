
#-------------------------------------------------------------------------------------------------
#' @title Match
#'
#' @description This function finds matches for the events without a strata and withing a time window. The Mahalanobis-metric can be used to match on other variables as well. It is a wrapper for the matchit function from the MatchIt package.
#' @param date A vector of dates. 
#' @param casecontrol A vector where 1 indentifies events, 0 identifies potential controls, and NA represent non-event days that are not eligible to be matched (e.g. missing data, or excluded for some other reason).
#' @param matchvars A matrix where the columns represent variables that will be matched on using the Mahalanobis distrance and nearest neighbor. 
#' @param mahdoy A logical indicating if the day of year should be included in the Mahalanobis-metric matching within the caliper. The default is FALSE. If TRUE then the distance to the treatment day based on day of year will be included with the other matching variables.
#' @param caldays The number of days that matched value will be selected from. This ignors year but only looks at date and month. For example, if caldays=7 then the pairs will be from within 7 days of the control (inclusive).
#' @param by A vector of ids or a matrix with columns as the id variables. The events will be found separately within each unique combination of id variables. This is optional.
#' @param ratio The number of control units to be matched to each case. The default is 1.  See documentation for matchit for more details. 
#' @param seed A seed for a random number generator.
#' @return data A data.table of matched cases and controls.
#' @return nn A summary of the number if cases and controls that were matched. See documentation for matchit for more details.
#' @return sum.matched A summary of the quality of each match. See documentation for matchit for more details.
#' @author Ander Wilson
#' @seealso MatchIt
#' @import data.table MatchIt
#' @export
mtch <- function(date,casecontrol,matchvars=NULL,mahdoy=FALSE,caldays=Inf,by,ratio=1,seed,...){
  if(!missing(seed)) set.seed(seed)
  if(missing(by)){
    by <- NA
  }else{
    by <- data.table(by)
    setkeyv(by, names(by))
    bydt <- unique(by)
    setkeyv(bydt, names(bydt))
    bydt[,byid:=1:nrow(bydt)]
    bydt <- bydt[by]
  }
  
  if(!is.null(matchvars)){
    dat<- data.table(matchvars)
  }else{
    dat <- data.table(casecontrol)
  }
  dat[,casecontrol:=casecontrol]
  dat[,byid:=bydt[,(byid)]]
  dat[,date:=date]
  dat <- unique(dat)
  dat[,caldoy:=as.POSIXlt(dat$date)$yday-365/2]
  
  
  matched.sample <- sum.matched <- nn <- data.table()
  for(i in unique(dat[,(byid)])){
    #make matching data for county
    dati <- dat[byid==i]
    dati <- as.data.frame(dati[complete.cases(dati),])
    
    if(nrow(subset(dati,casecontrol==1))>0){
      row.names(dati) <- as.character(1:nrow(dati))
      #match the sample
        if(is.null(matchvars)){
          matchit.fit <- matchit(casecontrol~caldoy, data=dati, method="nearest", caliper=caldays/sd(dati$caldoy), ratio=ratio,...)
        }else{
          matchit.fit <- matchit(casecontrol~caldoy, data=dati, method="nearest", caliper=caldays/sd(dati$caldoy), mahvars=colnames(dati)[-which(colnames(dati)%in%(c("casecontrol","byid","date","caldoy")))], ratio=ratio,...)
        }
      
      #save match
      matchedout <- data.table(match.data(matchit.fit))
      matches <- cbind(as.numeric(cbind(matchit.fit$match.matrix,row.names(matchit.fit$match.matrix))),rep(1:nrow(matchit.fit$match.matrix),ncol(matchit.fit$match.matrix)+1))
      matches <- data.table(dati[matches[,1],])[,pairing:=matches[,2]]
      matches <-  matches[,list(date,pairing)]
      setkeyv(matches,"date")
      setkeyv(matchedout,"date")
      matched.sample <- rbind(matched.sample,matches[matchedout])

      
      #save statistics on number matched
      temp.nn <- data.table(matchit.fit$nn)
      temp.nn[,type:=row.names(matchit.fit$nn)]
      temp.nn[,byid:=i]
      nn <- rbind(nn,temp.nn)
      
      #add this
      temp.sum.matched <- data.table(summary(matchit.fit)$sum.matched)
      temp.sum.matched[,type:=row.names(summary(matchit.fit)$sum.matched)]
      temp.sum.matched[,byid:=i]
      sum.matched <- rbind(sum.matched,temp.sum.matched)
    }
  }
  
  
  
  
  
  setkeyv(bydt,"byid") 
  setkeyv(matched.sample,c("byid","date")) 
  setkeyv(nn,"byid") 
  setkeyv(sum.matched,"byid") 
  sum.matched <- unique(bydt)[sum.matched]
  nn <- unique(bydt)[nn]
  data <- unique(bydt)[matched.sample]
  sum.matched[,byid:=NULL]
  nn[,byid:=NULL]
  data[,byid:=NULL]
  
  
  return(list(data=data,nn=nn,sum.matched=sum.matched))
}


