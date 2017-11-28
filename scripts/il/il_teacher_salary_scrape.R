
## Script to scrape data from the Illinois teacher Salary website 
## http://www.familytaxpayers.org/ftf/ftf_salaries.php

library(RSelenium)
library(rvest)
library(magrittr)
library(tibble)

cwd <- getwd()

## Use Selenium to iterate over the years and grab all of the district links.

# Create variables that will be used during the Selenium scraping.
drop_down <- paste0("/html/body/table/tbody/tr/td/table/tbody/tr/td/table/", 
                    "tbody/tr/td[1]/form[3]/table/tbody/tr[2]/td[2]/select/", 
                    "option[")
search_btn <- paste0("/html/body/table/tbody/tr/td/table/tbody/tr/td/table/", 
                     "tbody/tr/td[1]/form[3]/table/tbody/tr[3]/td[2]/input")
years <- 1999:2012
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
  links <- full_page[[1]] %>% 
    strsplit("href=", fixed = TRUE) %>% 
    unlist(., FALSE, FALSE) %>% 
    .[grepl("did=\\d{1,6}", .)] %>% 
    strsplit(">", fixed = TRUE) %>% 
    vapply(., "[", character(1), 1) %>% 
    gsub('"|amp;', "", .) %>% 
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
# Example of a single district link: 
# http://www.familytaxpayers.org/ftf/ftf_district.php?did=13924&year=2012
teacher_links <- list()
for (year in years) {
  year <- as.character(year)
  dist_links_year <- dist_links[[paste0("year_", year)]]
  teacher_links[[year]] <- lapply(dist_links_year, function(x) {
    Sys.sleep(2)
    x <- x %>% 
      xml2::read_html() %>% 
      rvest::html_nodes("a") %>% 
      rvest::html_attr("href") %>% 
      .[grepl("tid=\\d{1,6}", .)] %>% 
      paste0(url_base, .)
  }) %>% 
    unlist(., FALSE, FALSE) %>% 
    .[. != "http://www.familytaxpayers.org/ftf/"]
}

# Filter each vector of links to only keep unique values.
teacher_links <- lapply(teacher_links, unique)

# Save teacher_links as an rds object.
saveRDS(
  teacher_links, 
  file.path(cwd, "data", "il", "teacher_links_all_years.rds")
)

# Helper function to create a single obs df.
vect_2_df <- function(values, col_names) {
  # Return a single row data frame, in which "col_names" are the column names, 
  # and "values" is the single observation.
  matrix(values, ncol = length(col_names)) %>% 
    data.frame(stringsAsFactors = FALSE) %>% 
    `colnames<-`(col_names)
}

# Start loop to iterate over every teacher link. For each one, get text from 
# the individual listing table, save the text as a data frame and the text 
# labels as col headers.
# Example of a single teacher link:
# http://www.familytaxpayers.org/ftf/ftf_teacher.php?tid=139153&year=2012

## NOTE: This loop is going to take a LONG time to complete. It's designed to 
## iterate over 2mil+ urls, pull a small bit of data from each one, 
## and includes a 2 second Sys.sleep between each url.

for (year in years) {
  year <- as.character(year)
  cache_table <- list()
  
  # Create directory for the current year (if it doesn't already exist).
  if (!dir.exists(file.path(cwd, "data", "il", year))) {
    dir.create(file.path(cwd, "data", "il", year))
  }
  
  # Loop over all teacher links.
  obs_list <- lapply(teacher_links[[year]], function(x) {
    # Scrape data from url, or fetch the scraped data from cache_table.
    if (any(names(cache_table) == x)) {
      obs <- cache_table[[x]]
    } else {
      # Pull the url content. If there's a connection error, return the error 
      # message, do NOT record the result to obj cache_table. 
      obs <- tryCatch(xml2::read_html(x), error = function(e) e)
      if (methods::is(obs, "error")) {
        return(obs$message)
      }
      obs <- obs %>% 
        rvest::html_nodes("div.copy") %>% 
        rvest::html_text()
      # system sleep to keep from melting a server.
      Sys.sleep(2)
      # Write scraped data to the cache_table.
      cache_table[[x]] <<- obs
    }
    # Unpack col names and values.
    obs <- obs %>% 
      strsplit("\r\n", fixed = TRUE) %>% 
      unlist(., FALSE, FALSE) %>% 
      .[. != ""] %>% 
      strsplit(., ":", fixed = TRUE) %>% 
      lapply(., trimws)
    col_names <- vapply(obs, "[", character(1), 1)
    vals <- vapply(obs, "[", character(1), 2)
    # Assert that lengths are the same. If they are not, print a warning to 
    # console indicating the url, and return an error message.
    if (length(col_names) != length(vals)) {
      warning(
        paste("length of col_names does not match length of vals. link:", x), 
        call. = FALSE)
      return("error: length of col_names does not match length of vals")
    }
    # return data frame.
    return(
      vect_2_df(vals, col_names)
    )
  })
  
  # Eliminate elements of obs_list that are not data frames.
  obs_list <- obs_list[vapply(obs_list, is.data.frame, logical(1))]
  
  # rbind all observations together into a single data frame, and eliminate 
  # any observations that are completely filled with NA's.
  obs_df <- obs_list %>% 
    do.call(rbind, .) %>% 
    tibble::as_data_frame() %>% 
    .[apply(., 1, function(x) !all(is.na(x))), ]
  
  # Write obs_df to file.
  write.csv(
    obs_df, 
    file.path(
      cwd, "data", "il", year, paste0("il_teacher_salaries_", year, ".csv")
    ), 
    row.names = FALSE
  )
}
