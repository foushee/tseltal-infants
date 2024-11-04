library(tidyverse)
library(ggplot2)
library(forcats)
library(lme4)
library(boot)
library(car)
library(ggridges)
library(kableExtra)
library(papaja)
library(lmerTest)
library(texreg)
library(ggpubr)
library(BayesFactor)
library(here)

here::i_am("_libraries_functions_ggvars.R")

## functions
set.seed(1)

"bootstrap"<- function(x,nboot,theta,...,func=NULL) {
  call <- match.call()
  
  n <- length(x)
  bootsam<- matrix(sample(x,size=n*nboot,replace=TRUE),nrow=nboot)
  thetastar <- apply(bootsam,1,theta,...)
  func.thetastar <- NULL; jack.boot.val <- NULL; jack.boot.se <- NULL;
  if(!is.null(func)){
    match1 <- function(bootx,x){
      duplicated(c(bootx,x))[(length(x)+1) : (2*length(x))]
    } 
    matchs <- t(apply(bootsam,1,match1,x))
    func.thetastar <- func(thetastar)
    jack.boot <- function(inout,thetastar,func){
      func(thetastar[!inout])
    }
    jack.boot.val <- apply(matchs,2,jack.boot,thetastar,func)
    
    if(sum(is.na(jack.boot.val)>0)) {
      cat("At least one jackknife influence value for func(theta) is undefined", 
          fill=TRUE)
      cat(" Increase nboot and try again",fill=TRUE)
      return()
    }
    
    if( sum(is.na(jack.boot.val))==0) {
      jack.boot.se <- sqrt(
        ((n-1)/n)*sum((jack.boot.val-mean(jack.boot.val))^2 )
        )
      
    }
  }
  
  return(list(thetastar=thetastar, func.thetastar=func.thetastar,
              jack.boot.val=jack.boot.val, jack.boot.se=jack.boot.se,
              call=call))
}
################################################################################
summarySE <- function(data=NULL, measurevar, groupvars=NULL, na.rm=FALSE,
                      conf.interval=.95, .drop=TRUE) {
  
  # New version of length which can handle NA's: if na.rm==T, don't count them
  length2 <- function (x, na.rm=FALSE) {
    if (na.rm) sum(!is.na(x))
    else       length(x)
  }
  
  # This does the summary. For each group's data frame, return a vector with
  # N, mean, and sd
  datac <- ddply(data, groupvars, .drop=.drop,
                 .fun = function(xx, col) {
                   c(N    = length2(xx[[col]], na.rm=na.rm),
                     mean = mean   (xx[[col]], na.rm=na.rm),
                     sd   = sd     (xx[[col]], na.rm=na.rm)
                   )
                 },
                 measurevar
  )
  
  # Rename the "mean" column    
  datac <- rename(datac, c("mean" = measurevar))
  
  datac$se <- datac$sd / sqrt(datac$N)  # Calculate standard error of the mean
  
  # Confidence interval multiplier for standard error
  # Calculate t-statistic for confidence interval: 
  # e.g., if conf.interval is .95, use .975 (above/below), and use df=N-1
  ciMult <- qt(conf.interval/2 + .5, datac$N-1)
  datac$ci <- datac$se * ciMult
  
  return(datac)
}

################################################################################
## Bootstrapping confidence intervals 
theta <- function(x,xdata,na.rm=T) {mean(xdata[x],na.rm=na.rm)}
ci.low <- function(x,na.rm=T) {
  mean(x,na.rm=na.rm) - quantile(
    bootstrap(1:length(x),1000,theta,x,na.rm=na.rm)$thetastar,
    .025,na.rm=na.rm)}
ci.high <- function(x,na.rm=T) {
  quantile(
    bootstrap(1:length(x),1000,theta,x,na.rm=na.rm)$thetastar,
    .975,na.rm=na.rm) - mean(x,na.rm=na.rm)}
na.mean <- function(x) {mean(x,na.rm=T)}
na.sum <- function(x) {sum(x,na.rm=T)}

## return mean proportion as a percent
percent <- function(x){100*na.mean(x)}

## print full two decimal places, even if 0
op = function(x, d=2) sprintf(paste0("%1.",d,"f"), x) 

## format pval for reporting
reportP <- function(pvalue) {
  if(pvalue>=.05) {
    return(paste("p=", sprintf("%.3f", pvalue), sep=""))
  }
  if(pvalue<.001) {
    return("p<.001")
  }
  if(pvalue<.01) {
    return("p<.01")
  }
  if(pvalue<.05) {
    return("p<.05")
  }
}

options(digits = 2)

################################################################################
## ggplot variables

### for figures
cornyellow = '#E6AB02'
horsebrown = '#A6761D'
tortpurple = '#7570B3' 
fireorange = '#D95F02'
carteal = '#1B9E77'
soupgreen = '#66A61E'
sheeppink = '#E7298A'
cowgrey = '#666666'
waterblue ="#2b8cbe"
dark2brown ="#a6761d"
lightpink <- '#E7298A10'

noun_pair_fills <- c('baby-corn' = cornyellow,
                     'car-shoe' = carteal,
                     'chayote-cow' = cowgrey,
                     'chicken-tortilla' = tortpurple,
                     'dog-fire' = fireorange,
                     'horse-soda' = horsebrown,
                     'rabbit-soup' = soupgreen,
                     'sheep-water' = waterblue)

brighterblue = "#225ea8"

greeting_pair_fills <- c('old_man-young_woman' = sheeppink, 
                         'old_woman-young_man' = "#fe9929")

age_group_fills<- c("6-9 months" = "#bae4bc",
                    "10-13 months" = "#7bccc4",
                    "14-16 months" = "#2b8cbe")

# for comparison plot with bs2012
rf_color=sheeppink
rf_fill=sheeppink

## plotting themes
storybook.theme <- theme(
  panel.border = element_rect(colour="gray30", fill=NA),
  axis.title.x = element_text(size=12, colour="gray30", family='serif'),
  axis.text.x = element_text(size=12, colour="gray30", family='serif'),
  axis.ticks.x = element_blank(),
  axis.title.y = element_text(size=12, colour="gray30", family='serif'),
  axis.text.y = element_text(size=12, colour="gray30", family='serif'),
  panel.background = element_blank(),
  panel.grid.major.y = element_blank(),
  panel.grid.minor.y = element_blank(),
  panel.grid.major.x = element_blank(),
  legend.position="right",
  legend.title = element_text(size=12, colour="gray30", family='serif'),
  legend.text  = element_text(size=12, colour="gray30", family='serif'),
  plot.title = element_text(size=14, colour="gray30", family='serif'),
  strip.text.x = element_text(size=14, colour="gray30", family='serif'),
  strip.background = element_rect(colour="gray30", fill=NA),
)

sb.density.theme <- theme(
  panel.border = element_rect(colour="gray30", fill=NA),
  axis.title = element_blank(),
  axis.ticks = element_blank(),
  axis.text.y = element_text(size=9, colour="gray30", family='sans'),
  axis.text.x = element_text(size=9, colour="gray30", family='sans'),
  panel.background = element_blank(),
  panel.grid.major.y = element_blank(),
  panel.grid.minor.y = element_blank(),
  panel.grid.major.x = element_blank(),
  legend.position="right",
  legend.title = element_text(size=9, colour="gray30", family='sans'),
  legend.text  = element_text(size=9, colour="gray30", family='sans'),
  plot.title = element_text(size=9, colour="gray30", family='sans'),
  strip.text.x = element_text(size=9, colour="gray30", family='sans'),
  strip.background = element_rect(colour="gray30", fill=NA),
)

sb.density.theme <- theme(
  panel.border = element_rect(colour="gray30", fill=NA),
  axis.title = element_blank(),
  axis.ticks = element_blank(),
  axis.text.y = element_text(size=8, colour="gray30", family='sans'),
  axis.text.x = element_text(size=8, colour="gray30", family='sans'),
  panel.background = element_blank(),
  panel.grid.major.y = element_blank(),
  panel.grid.minor.y = element_blank(),
  panel.grid.major.x = element_blank(),
  legend.position="right",
  legend.title = element_text(size=8, colour="gray30", family='sans'),
  legend.text  = element_text(size=8, colour="gray30", family='sans'),
  plot.title = element_text(size=8, colour="gray30", family='sans'),
  strip.text.x = element_text(size=8, colour="gray30", family='sans'),
  strip.background = element_rect(colour="gray30", fill=NA),
)
