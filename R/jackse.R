

#-------------------------------------------------------------------------------------------------
#' @title Jackknife standard errors
#'
#' @description This function calcualte jackknife standard errors
#' @param x A vector or matrix to be summarized.
#' @param theta The summary statistic to be used. For example, theta=mean calcualted the jackknife standard errors for the mean.
#' @param bycol Logical indicating if the data are in rows or columns when x is a matrix. The default is TRUE.
#' @param ... Other parameters to be passed to the function theta().
#' @return Jackknife standard errors.
#' @author Ander Wilson
#' @export


jackse <- function(x,theta,bycol=TRUE,...){
    x <- as.matrix(x)
    if(!bycol) x <- t(x)
    n <- nrow(x)
    u <- rep(0,n)
    for(i in 1:n) u[i] <- theta(x[-i,],...)
    jack.se <- sqrt(((n-1)/n)*sum((u-mean(u))^2))
    return(jack.se)
}