
## Script to scrape data from the Illinois teacher Salary website 
## http://www.familytaxpayers.org/ftf/ftf_salaries.php

library(RSelenium)
library(rvest)
library(magrittr)

## Use Selenium to iterate over the years and grab all of the district links.

# Create variables that will be used during the Selenium scraping.
drop_down <- paste0("/html/body/table/tbody/tr/td/table/tbody/tr/td/table/", 
                    "tbody/tr/td[1]/form[3]/table/tbody/tr[2]/td[2]/select/", 
                    "option[")
search_btn <- paste0("/html/body/table/tbody/tr/td/table/tbody/tr/td/table/", 
                     "tbody/tr/td[1]/form[3]/table/tbody/tr[3]/td[2]/input")
years <- 2012:1999
url_base <- "http://www.familytaxpayers.org/ftf/"

# Initialize selenium server, using chromedriver.
rD <- rsDriver(browser = "chrome", geckover = NULL, iedrver = NULL, 
               phantomver = NULL)
driver <- rD[["client"]]

# Navigate to the target website.
driver$navigate("http://www.familytaxpayers.org/ftf/ftf_salaries.php")

# Initialize list obj that will house all district lnks for each year.
dist_links <- list()

# Start loop that will iterate over each year, select that year from the 
# district drop down menu, and extract the url links for each district for 
# that year.
for (year in years) {
  # Change year within the drop down menu.
  driver$findElement(using = "xpath", 
                     paste0(drop_down, 
                            which(years == year), "]"))$clickElement()
  Sys.sleep(1)
  
  # Click the search button.
  driver$findElement(using = "xpath", search_btn)$clickElement()
  Sys.sleep(3)
  
  # Pull page source
  full_page <- driver$getPageSource()
  
  # Get link for each district from the page.
  links <- full_page %>% 
    unlist(., FALSE, FALSE) %>% 
    strsplit(split = "href=") %>% 
    unlist(., FALSE, FALSE) %>% 
    .[grepl("did=\\d{1,6}", .)] %>% 
    vapply(., function(x) strsplit(x, ">"), list(1)) %>% 
    vapply(., function(x) x[[1]], character(1), USE.NAMES = FALSE) %>% 
    gsub('"', "", .) %>% 
    gsub("amp;", "", .) %>% 
    paste0(url_base, .)
  
  # Add links to list obj dist_links.
  dist_links[[paste0("year_", year)]] <- links
}

# Close webdriver.
driver$close()

# Stop selenium server.
rD[["server"]]$stop()


# For each district link within each year of obj "dist_links", get all 
# individual teacher links.
teacher_links <- list()
for (year in years) {
  year <- as.character(year)
  dist_links_year <- dist_links[[paste0("year_", year)]]
  teacher_links[[year]] <- sapply(dist_links_year, function(x) {
    x <- x %>% 
      xml2::read_html() %>% 
      rvest::html_nodes("a") %>% 
      rvest::html_attr("href") %>% 
      .[grepl("tid=\\d{1,6}", .)] %>% 
      paste0(url_base, .)
    Sys.sleep(2)
    return(x)
  }, USE.NAMES = FALSE) %>% 
    unlist(., FALSE, FALSE) %>% 
    .[. != "http://www.familytaxpayers.org/ftf/"]
}


# Create cache_table to house all of the scraped text data. Doing this to make 
# sure we never scrape the same url twice unnecessarily.
cache_table <- list()

# Helper function to create a single obs df.
vect_2_df <- function(values, col_names) {
  # Return a single row data frame, in which "col_names" are the column names, 
  # and "values" is the single observation.
  stopifnot(length(values) == length(col_names))
  df  <- matrix(values, ncol = length(col_names)) %>% 
    data.frame(stringsAsFactors = FALSE) %>% 
    `colnames<-`(col_names)
  return(df)
}

# Start loop to iterate over every teacher link. For each one, get text from 
# the individual listing table, save the text as a data frame and the text 
# labels as col headers.
obs_list <- lapply(teacher_links, function(x) {
  # Scrape data from url, or fetch the scraped data from cache_table.
  if (x %in% names(cache_table)) {
    obs <- cache_table[[x]]
  } else {
    obs <- x %>% 
      xml2::read_html() %>% 
      rvest::html_nodes("div.copy") %>% 
      rvest::html_text()
    # system sleep to keep from melting a server.
    Sys.sleep(2)
    # Write scraped data to the cache_table.
    cache_table[[x]] <<- obs
  }
  # Unpack col names and values.
  obs <- obs %>% 
    strsplit("\r\n") %>% 
    unlist(., FALSE, FALSE) %>% 
    .[. != ""] %>% 
    #trimws %>% 
    vapply(., function(x) strsplit(x, ":"), list(1), USE.NAMES = FALSE) %>% 
    lapply(., trimws)
  
  col_names <- vapply(obs, function(x) magrittr::extract(x, 1), character(1), 
                      USE.NAMES = FALSE)
  vals <- vapply(obs, function(x) magrittr::extract(x, 2), character(1), 
                 USE.NAMES = FALSE)
  # Assert that lengths are the same.
  if (length(col_names) != length(vals)) {
    stop(paste("err1. link is:", x))
  }
  # return data frame.
  return(
    vect_2_df(vals, col_names)
  )
})

# rbind all observations together into a single data frame, and eliminate any 
# observations that are completely filled with NA's.
obs_df <- obs_list %>% 
  do.call(rbind, .) %>% 
  tibble::as_data_frame() %>% 
  .[apply(., 1, function(x) !all(is.na(x))), ]

# Write obs_df to file.
write.csv(obs_df, "./data/il/il_teacher_salaries.csv", 
          row.names = FALSE)
