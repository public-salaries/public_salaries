"

Iowa state salaries data from 2006--2016 from:
http://db.desmoinesregister.com/state-salaries-for-iowa/

"

# Set directory 
setwd(githubdir)
setwd("public_salaries/")

# Load libraries
library(dplyr)
library(httr)
library(rvest)

# Initialize result data.frame 
dataset <- list()

# Loop over the result pages 
for (i in 1:27283) {
	page <- GET(paste0("http://db.desmoinesregister.com/state-salaries-for-iowa/page=", i))
	data_single_page <- page %>% read_html() %>% html_table()
	dataset <- c(dataset, data_single_page)
}

# Combine 
iowa_df <- ldply(dataset, data.frame)

# Write out the data
write.csv(iowa_df, file="iowa_2016_state_salaries.csv")
