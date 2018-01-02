
## Washington DC public employee salaries data, 2011 - 2017.
## Source: https://dchr.dc.gov/public-employee-salary-information

# There are 23 PDF documents housed in the source url. This script will 
# download all 23 PDF docs, and save them to dir public_salaries/data/dc

# Load libraries.
library(magrittr)
library(rvest)

cwd <- getwd()

# Get links for all 23 PDF docs on the main page.
pdfs <- "https://dchr.dc.gov/public-employee-salary-information" %>%
  xml2::read_html() %>% 
  rvest::html_nodes("div:nth-child(1) span a") %>% 
  rvest::html_attr("href") %>% 
  .[grepl(".pdf", .)]

# Loop to download all PDF files.
for (i in pdfs) {
  # Get pdf file name from the url str.
  file_name <- i %>% 
    strsplit(split = "/") %>% 
    unlist %>% 
    .[grepl(".pdf", .)] %>% 
    gsub("%20", "_", .)
  
  # Download PDF file.
  download.file(i, file.path(cwd, "dc", file_name), mode = "wb")
}
