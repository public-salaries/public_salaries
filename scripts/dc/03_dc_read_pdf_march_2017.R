
library(pdftools)
library(tibble)
library(magrittr)

## Read in Washington DC pdf data.
## Source of the pdf docs is https://dchr.dc.gov/public-employee-salary-information

# This script will read in file "public_salaries/data/dc/public_body_employee_information_03312017.pdf", 
# apply transformations to extract relevant data. Output is a tidy data frame 
# that containsvariables: "agency", "last_name", "first_name", "type_appt",
# "position_title", "compensation", and "hire_date"


# Establish vector of column headers known to be used in these pdf's.
known_cols <- c(
  "agency name", 
  "last name", 
  "first name", 
  "type appt", 
  "position title", 
  "grade", 
  "compensation", 
  "start date"
)

# Read in the pdf document.
file_name <- "./data/dc/public_body_employee_information_03312017.pdf"
txt <- pdftools::pdf_text(file_name)

# Find the column headers of the data within the pdf doc.
cols <- txt[1] %>% 
  strsplit(., "\n") %>% 
  unlist(., FALSE, FALSE) %>% 
  .[grepl(".*Last Name.*", .)] %>% 
  strsplit(., "\\s{1,}") %>% 
  unlist(., FALSE, FALSE) %>% 
  tolower %>% 
  .[!. %in% c("name", "appt", "title", "start")] %>% 
  vapply(., function(x) {
    known_cols[which(grepl(x, known_cols))]
  }, character(1), USE.NAMES = FALSE)



# For each page of the doc, extract each relevant observation as a char vector.
observations <- lapply(txt, function(page) {
  # split text up by lines (obs), and extract relevant obs.
  page %>% 
    strsplit(., "\n") %>% 
    unlist(., FALSE, FALSE) %>% 
    magrittr::extract(4:50)
}) %>% 
  unlist(., FALSE, FALSE) %>% 
  .[!is.na(.)] %>% 
  .[!grepl("Page \\d{1,5} of \\d{1,5}", .)]

# Load the "06302017" dataset, use col "type_appt" as a data dictionary.
type_appt_dd <- readr::read_csv("./data/dc/public_body_employee_information_06302017.csv") %>% 
  magrittr::extract2("type_appt") %>% 
  tolower %>% 
  gsub("\\s{1,}\\d\\w$", "", .) %>% 
  unique %>% 
  .[grepl("\\s", .)] %>% 
  .[order(nchar(.), decreasing = TRUE)]

# Load "agency" data dict (compiled during script "02").
agency_dd <- readRDS("./scripts/dc/dc_agency_names_data_dictionary.RDS")

# For each observation within the pdf, extract relevant data and save output 
# as a single-row data frame. Each of these df's will be compiled into a list, 
# which will then be rbind together using do.call().
obs_list <- lapply(observations, function(j) {
  # Split obs up into a vector of elements (as strings).
  obs <- j %>% 
    strsplit(., "\\s{2,}") %>% 
    unlist(., FALSE, FALSE) %>% 
    .[!. == "$"] %>% 
    gsub(",", "", .)

  # If obs is vector of length 8, this means the elements of obs were cleanly 
  # delimited, and can safely return the relevant elements.
  if (length(obs) == 8) {
    return(
      data.frame(
        agency = tolower(obs[1]), 
        last_name = obs[2], 
        first_name = obs[3], 
        type_appt = obs[4], 
        position_title = obs[5], 
        compensation = as.double(obs[7]), 
        hire_date = as.Date(obs[8], format = "%m/%d/%Y"), 
        stringsAsFactors = FALSE
      )
    )
  }
  
  # Eliminate "grade" element of obs.
  obs <- obs[!grepl("^\\d\\w$", obs, ignore.case = TRUE)]
  
  # Extract the hire date.
  date_id <- as.Date(obs, format = "%m/%d/%Y")
  if (any(!is.na(date_id))) {
    hire_date <- date_id[!is.na(date_id)]
  } else {
    date_id <- grepl("\\d{1,2}/\\d{1,2}/\\d\\d\\d\\d", obs)
    if (any(date_id)) {
      date_start <- regexpr("\\d{1,2}/\\d{1,2}/\\d\\d\\d\\d", obs[date_id])
      date_end <- date_start + (attributes(date_start)$match.length - 1)
      hire_date <- obs[date_id] %>% 
        substr(., date_start, date_end) %>% 
        as.Date(format = "%m/%d/%Y")
      obs[date_id] <- trimws(substr(obs[date_id], 1, (date_start - 1)))
      date_id[date_id == FALSE] <- NA
    } else {
      hire_date <- NA
    }
  }
  
  # Extract the commpensation.
  comp <- sapply(obs, function(x) suppressWarnings(as.double(x)), 
                 USE.NAMES = FALSE)
  if (any(!is.na(comp))) {
    comp <- max(comp, na.rm = TRUE)
  } else {
    comp <- NA
  }
  
  # Eliminate elements of obs that were successfully cast as double and that 
  # were identified as the hire date. If obs is empty or all NA's, return all 
  # NA's.
  obs <- obs[is.na(comp) & is.na(date_id)]
  if (length(obs) == 0 || all(is.na(obs))) {
    return(
      data.frame(
        agency = NA, 
        last_name = NA, 
        first_name = NA, 
        type_appt = NA, 
        position_title = NA, 
        compensation = NA, 
        hire_date = NA, 
        stringsAsFactors = FALSE
      )
    )
  }
  
  # If length obs == 5, check to see if values "pos_title" and "grade" are 
  # concatted. If they are, extract "pos_title", then return values.
  if (length(obs) == 5) {
    len_obs_five <- nchar(obs[5])
    if (grepl("\\s\\d\\d", substr(obs[5], (len_obs_five - 2), len_obs_five))) {
      obs[5] <- substr(obs[5], 1, (len_obs_five - 3))
    }
    return(
      data.frame(
        agency = obs[1], 
        last_name = obs[2], 
        first_name = obs[3], 
        type_appt = obs[4], 
        position_title = obs[5], 
        compensation = comp, 
        hire_date = hire_date, 
        stringsAsFactors = FALSE
      )
    )
  }
  
  # If length obs == 6, return relevant values.
  if (length(obs) == 6) {
    return(
      data.frame(
        agency = obs[1], 
        last_name = obs[2], 
        first_name = obs[3], 
        type_appt = obs[4], 
        position_title = obs[5], 
        compensation = comp, 
        hire_date = hire_date, 
        stringsAsFactors = FALSE
      )
    )
  }
  
  # Attempt to extract variable "type_appt".
  obs_lower <- tolower(obs)
  # Get logical vector indicating which elements of type_appt_dd appear in 
  # any of the elements in obs.
  idx <- vapply(tolower(type_appt_dd), function(x) {
    if (any(grepl(x, obs_lower, fixed = TRUE))) {
      return(TRUE)
    } else {
      return(FALSE)
    }
  }, logical(1), USE.NAMES = FALSE)
  # If a single match was found, take it as the type_appt. If multiple matches 
  # were found, take the first match that matches regex ".*-.*app".
  if (any(idx)) {
    found_match <- TRUE
    if (sum(idx) == 1) {
      type_appt <- type_appt_dd[idx]
    } else { 
      type_appt <- grep(".*-.*app", type_appt_dd[idx], value = TRUE)[1]
    }
    # Eliminate the extracted type_appt string from obs.
    obs <- obs %>% 
      gsub(type_appt, "", ., ignore.case = TRUE) %>% 
      trimws %>% 
      .[. != ""]
  }
  # If a type_appt str was found and length obs == 4, return relevant values.
  if (found_match && length(obs) == 4) {
    return(
      data.frame(
        agency = obs[1], 
        last_name = obs[2], 
        first_name = obs[3], 
        type_appt = type_appt, 
        position_title = obs[4], 
        compensation = comp, 
        hire_date = hire_date, 
        stringsAsFactors = FALSE
      )
    )
  }
  
  # Look for a known agency str in the 1st element of obs.
  found_match <- FALSE
  obs_one <- tolower(obs[1])
  for (i in agency_dd) {
    if (grepl(i, obs_one, fixed = TRUE)) {
      agency <- i
      found_match <- TRUE
      break
    }
  }
  
  # If found match, and any part of the person's name is concatted with the 
  # agency string, eliminate the agency string from obs and extract the name 
  # string from position one of obs.
  if (found_match) {
    if (nchar(obs_one) > nchar(agency)) {
      name <- tolower(obs[1]) %>% 
        gsub(tolower(agency), "", ., fixed = TRUE) %>% 
        trimws
      # If obj "name" contains both the first and last name, split them up 
      # into separate variables.
      if (length(obs) == 2 && grepl(" ", name, fixed = TRUE)) {
        name <- unlist(strsplit(name, " ", fixed = TRUE))
        last_name <- name[1]
        first_name <- name[2]
      }
    } else {
      found_match <- FALSE
    }
  }
  # If any part of the person's name was extracted in the last step and the 
  # length of obs is four or less, return relevant values.
  if (found_match && length(obs) <= 4) {
    return(
      data.frame(
        agency = agency, 
        last_name = ifelse(exists("last_name", inherits = FALSE), 
                           last_name, 
                           name), 
        first_name = ifelse(exists("first_name", inherits = FALSE), 
                            first_name, 
                            obs[2]), 
        type_appt = ifelse(exists("type_appt", inherits = FALSE), 
                           type_appt, 
                           obs[3]), 
        position_title = obs[length(obs)], 
        compensation = comp, 
        hire_date = hire_date, 
        stringsAsFactors = FALSE
      )
    )
  }
  
  # Sometimes the last_name and first_name are concatted together. If no 
  # matches were found in the above steps, and a space exists in the 2nd 
  # element of obs, split obs[2] to create last and first name.
  if (grepl(" ", obs[2], fixed = TRUE)) {
    name <- unlist(strsplit(obs[2], " "), FALSE, FALSE)
    
    return(
      data.frame(
        agency = obs[1], 
        last_name = paste(name[1:(length(name) - 1)], collapse = " "), 
        first_name = name[length(name)], 
        type_appt = ifelse(exists("type_appt", inherits = FALSE), 
                           type_appt, 
                           obs[3]), 
        position_title = obs[length(obs)], 
        compensation = comp, 
        hire_date = hire_date, 
        stringsAsFactors = FALSE
      )
    )
  }
  
  # If none of the return calls above are hit, halt loop and print the 
  # intial values of the current observation (to facilitate troubleshooting).
  msg <- paste0(j, collapse = "\n")
  stop(paste("error, could not return output, obs is:", msg), 
       call. = FALSE)
})

# rbind all observations together into a single data frame, and eliminate any 
# observations that are completely filled with NA's.
obs_df <- obs_list %>% 
  do.call(rbind, .) %>% 
  tibble::as_data_frame() %>% 
  .[apply(., 1, function(x) !all(is.na(x))), ]


# Write agency_dd to file.
saveRDS(agency_dd, "./scripts/dc/dc_agency_names_data_dictionary.RDS")

# Write obs_df to file.
write.csv(obs_df, "./data/dc/public_body_employee_information_03312017.csv", 
          row.names = FALSE)
