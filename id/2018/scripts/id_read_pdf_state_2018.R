
library(tibble)
library(magrittr)

cwd <- getwd()

## Read in ID 2018 pdf data.
## Source of the pdf docs is https://ibis.sco.idaho.gov/pubtrans/workforce/Workforce%20by%20Name%20Summary-en-us.pdf

# Define data directory file path, and path to the PDF file..
data_dir <- file.path(cwd, "id", "2018")
pdf_file <- file.path(data_dir, "state_2018.pdf")

# Read in functions that will be used throughout this script.
source(file.path(cwd, "id", "id_functions.R"))

# Read in the pdf doc. Using a hacky function for this, as pdftools::pdf_text
# is not working for any of the ID pdf docs. This function uses base::system2
# as a way to call "pdftotext" via the cmd prompt on the input pdf doc. It 
# has been tested on a PC, it has NOT been tested on a Mac or Linux.
txt <- manual_read_pdf(pdf_file)

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
observations <- vector(mode = "character", length = length(txt) * 35)
counter <- 1
for (page in txt) {
  obs <- page %>% 
    strsplit("\r\n\r\n", fixed = TRUE) %>% 
    unlist(FALSE, FALSE) %>% 
    .[!grepl("^\\s+classified$|^\\s{10,}|name\\s+job title\\s+agency\\s+", ., 
             ignore.case = TRUE)]
  for (i in obs) {
    observations[counter] <- i
    counter <- counter + 1
  }
}
observations <- observations[observations != ""]

# For each observation within the pdf, extract relevant data and save output 
# as a single-row data frame. Each of these df's will be compiled into a list, 
# which will then be rbind together using do.call.
obs_list <- lapply(observations, function(j) {
  # Split obs up into a vector of elements (as strings).
  obs <- j %>% 
    strsplit("\\s{2,}") %>% 
    unlist(., FALSE, FALSE)
  
  # If length of obs is greater than 8, redo the strsplit step with a delim of 
  # "3 or more" spaces.
  if (length(obs) > 8) {
    obs <- j %>% 
      strsplit("\\s{3,}") %>% 
      unlist(., FALSE, FALSE) %>% 
      gsub("\\s{2,}", " ", .)
  }
  
  # Check to see if the name string was split up by mistake.
  if (grepl(".*,$", obs[1]) || grepl(".*,.*\\.$|[A-Z]\\.|\\.", obs[2])) {
    obs[1] <- paste(obs[1], obs[2])
    obs <- obs[-2]
  }
  
  # If obs is length 3 or less, return the values as they are and move on.
  if (length(obs) <= 3) {
    return(get_single_obs_df(obs, col_names = cols))
  }
  
  # If obs is vector of length 8, this means the elements of obs were cleanly 
  # delimited, and can safely return the relevant elements.
  if (length(obs) == 8 && 
      grepl("^NON-$|^CLASSIFIED$", obs[4], ignore.case = TRUE)) {
    obs <- gsub("^NON-$", "non-classified", obs, ignore.case = TRUE)
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
  
  # If length of obs is 7, this means the value for variable agency or job 
  # title is split into two values. Combine all of the values in obs[2:4] into 
  # a single str (the agency and job_title should get properly separated 
  # during the "get_agency" step, which happens later).
  if (length(obs) == 7) {
    obs[2] <- paste(obs[2:4], collapse = " ")
    obs <- obs[-c(3:4)]
  }
  
  # Return obs and other values as a data frame.
  return(get_single_obs_df(obs, type_appt, comp, job_title))
})


# rbind all observations together into a single data frame, and eliminate any 
# observations that are completely filled with NA's.
obs_df <- obs_list %>% 
  do.call(rbind, .) %>% 
  tibble::as_data_frame() %>% 
  .[apply(., 1, function(x) !all(is.na(x))), ]

# Fix instances in which a portion of a person's name was split off into a new
# row (when a string is too long for a single cell, the PDF will wrap the 
# string into a second line within the "cell", and this causes pdftotext or R 
# or both to read that as a completely new observation/row).
obs_df <- stitch_broken_name_strings(obs_df)

# Go back and extract/fill-in NA's within variable agency.
obs_df <- fill_missing_agency(obs_df)

# For agency values that have a leading single digit, the digit is actually 
# part of the job_title value. Remove the digit from the agency value and 
# append it to the end of the job_title value.
for (row in which(grepl("^\\d", obs_df$agency))) {
  obs_df[row, ] <- digit_move(obs_df[row, ])
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
  file.path(data_dir, "state_2018.csv"), 
  row.names = FALSE
)
