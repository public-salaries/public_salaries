# North Dakota

setwd(githubdir)
setwd("public_salaries")

# Load lib.
library(readr)
library(plyr)

files <- list.files("nd/csvs", full.names = T)

yr07_09  <- files[grepl("07-09", files)]
sly07_09 <- do.call(rbind, lapply(yr07_09, function(x) cbind(read.csv(x), agency = gsub(".{10}$|^.{8}", "", x))))
write.csv(sly07_09, file = "nd/salaries_2008_2009.csv", row.names = F)

yr09_11  <- files[grepl("09-11", files)]
sly09_11 <- do.call(rbind, lapply(yr09_11, function(x) cbind(read.csv(x), agency = gsub(".{10}$|^.{8}", "", x))))
write.csv(sly09_11, file = "nd/salaries_2010_2011.csv", row.names = F)

yr11_13  <- files[grepl("11-13", files)]
sly11_13 <- rbind.fill(lapply(yr11_13, function(x) cbind(read.csv(x), agency = gsub(".{10}$|^.{8}", "", x))))
write.csv(sly11_13, file = "nd/salaries_2012_2013.csv", row.names = F)

yr13_15  <- files[grepl("13-15", files)]
sly13_15 <- rbind.fill(lapply(yr13_15, function(x) cbind(read.csv(x), agency = gsub(".{10}$|^.{8}", "", x))))
write.csv(sly13_15, file = "nd/salaries_2014_2015.csv", row.names = F)

yr15_17  <- files[grepl("15-17", files)]
sly15_17 <- do.call(rbind, lapply(yr15_17, function(x) cbind(read.csv(x), agency = gsub(".{10}$|^.{8}", "", x))))
write.csv(sly15_17, file = "nd/salaries_2016_2017.csv", row.names = F)

yr17_19  <- files[grepl("17-19", files)]
sly17_19 <- do.call(rbind, lapply(yr17_19, function(x) cbind(read.csv(x), agency = gsub(".{10}$|^.{8}", "", x))))
write.csv(sly17_19, file = "nd/salaries_2018.csv", row.names = F)
