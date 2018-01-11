
library(pdftools)
library(tibble)
library(magrittr)

cwd <- getwd()

## Read in ID pdf data.
## Source of the pdf docs is https://pibuzz.com/wp-content/uploads/post%20documents/Idaho%202013.pdf

# Define data directory file path, and path to the PDF file..
data_dir <- file.path(cwd, "id", "2013")
pdf_file <- file.path(data_dir, "state.pdf")

# Read in functions that will be used throughout this script.
source(file.path(data_dir, "scripts", "id_functions.R"))

# Read in the pdf doc.
txt <- pdftools::pdf_text(pdf_file)

# Establish col headers.
cols <- c(
  "name", 
  "job_title", 
  "agency", 
  "appt_type", 
  "ft_pt", 
  "pay_basis", 
  "salary", 
  "county"
)

# For each page of the doc, extract each relevant observation as a char vector.
observations <- vector(mode = "character", length = length(txt) * 30)
counter <- 1
for (page in txt) {
  obs <- page %>% 
    strsplit("\n", fixed = TRUE) %>% 
    unlist(FALSE, FALSE) %>% 
    .[!grepl("^\\s{8,}", .)]
  for (i in obs) {
    observations[counter] <- i
    counter <- counter + 1
  }
}
observations <- observations[observations != ""]

# For each observation within the pdf, extract relevant data and save output 
# as a single-row data frame. Each of these df's will be compiled into a list, 
# which will then be rbind together using do.call().
obs_list <- lapply(observations, function(j) {
  # Split obs up into a vector of elements (as strings).
  obs <- j %>% 
    strsplit("\\s{2,}") %>% 
    unlist(., FALSE, FALSE)
  
  # If obs is length 2 or less, skip it and move on to the next iteration.
  if (length(obs) <= 2) {
    return(data.frame())
  }
  
  # If obs is vector of length 8, this means the elements of obs were cleanly 
  # delimited, and can safely return the relevant elements.
  if (length(obs) == 8) {
    return(get_single_obs_df(obs))
  }
  
  ## Extract the commpensation variable.
  comp <- get_comp(obs)
  obs <- comp$obs
  comp <- comp$comp
  
  ## Extract the type_appt variable.
  type_appt <- get_type_appt(obs)
  obs <- type_appt$obs
  type_appt <- type_appt$type_appt
  
  ## Check to make sure the proper name was delimited from the job title.
  job_title <- get_job_title(obs)
  obs <- job_title$obs
  job_title <- job_title$job_title
  
  # Return obs and other values as a data frame.
  return(get_single_obs_df(obs, type_appt, comp, job_title))
})


# rbind all observations together into a single data frame, and eliminate any 
# observations that are completely filled with NA's.
obs_df <- obs_list %>% 
  do.call(rbind, .) %>% 
  tibble::as_data_frame() %>% 
  .[apply(., 1, function(x) !all(is.na(x))), ]

# Establish an agency data dictionary.
agency_dd <- obs_df$agency %>% 
  unique %>% 
  gsub("classified$|non-$", "", ., ignore.case = TRUE) %>% 
  trimws %>% 
  unique %>% 
  .[!is.na(.)] %>% 
  .[order(nchar(.), decreasing = TRUE)]

## Try to fill in NA's in col agency using the newly created data dict.
for (row in which(is.na(obs_df$agency))) {
  #obs <- obs_df[row, ]
  # Try to extract the job title value from the other values in vect.
  obs_df[row, ] <- get_agency(obs_df[row, ], agency_dd)
}

## Split up the values in the name variable, and create three new variables:
## first_name, last_name, middle_initial.
full_names <- lapply(obs_df$name, name_split)
obs_df$last_name <- vapply(full_names, function(x) x[[3]], character(1))
obs_df$first_name <- vapply(full_names, function(x) x[[1]], character(1))
obs_df$middle_initial <- vapply(full_names, function(x) x[[2]], character(1))

# Write obs_df to file.
write.csv(
  obs_df, 
  file.path(data_dir, "state.csv"), 
  row.names = FALSE
)
