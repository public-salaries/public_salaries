
library(pdftools)
library(tibble)
library(magrittr)

cwd <- getwd()

## Read in Washington DC pdf data.
## Source of the pdf docs is https://dchr.dc.gov/public-employee-salary-information

# This script will read in file "public_salaries/data/dc/public_body_employee_information_03312017.pdf", 
# apply transformations to extract relevant data. Output is a tidy data frame 
# that contains variables: "agency", "last_name", "first_name", "type_appt",
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
file_name <- file.path(
  cwd, "dc", "public_body_employee_information_03312017.pdf"
)
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

# Load type_appt_dd data dictionary, this will be used to help identify 
# type appt strings.
type_appt_dd <- readRDS(
  file.path(cwd, "dc", "scripts", "dc_type_appt_data_dictionary.RDS")
)

# Load agency_dd data dictionary, this will be used to help identify agency 
# strings.
agency_dd <- c(readRDS(file.path(cwd, "dc", "scripts", 
                                 "dc_agency_names_data_dictionary.RDS")), 
               "university of the district of columbia", 
               "Planning and Economic Development Office of the Deputy Mayor for", 
               "Housing and Community Development Department of", 
               "department of small and local business development", 
               "Youth Rehabilitation Services Department of", 
               "Office of the Deputy Mayor for Greater Economic Opportunity", 
               "Motion Picture and Television Development Office of", 
               "Judicial Disabilities and Tenure Commission on", 
               "Homeland Security & Emerg. Mgmt. Agency", 
               "District of Columbia State Board of Education", 
               "Criminal Justice Coordinating Council", 
               "insurance securities and banking department of", 
               "health and human services ofc of the deputy mayor", 
               "consumer and regulatory affairs department of", 
               "contracting and procurement office of", 
               "disability services department on") %>% 
  tolower %>% 
  .[order(nchar(.), decreasing = TRUE)]

# Load pn_dd data dictionary, this will be used to help differentiate between 
# proper names and dictionary words.
pn_dd <- readRDS(
  file.path(cwd, "dc", "scripts", "dc_proper_names_data_dictionary.RDS")
)

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
  obs <- obs[!grepl("^\\d\\w$|^\\w\\d$|^\\d\\d[A-z]$", obs)]
  
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
      date_id[date_id == FALSE] <- NA
    }
  }
  
  # Extract the commpensation.
  comp_id <- sapply(obs, function(x) suppressWarnings(as.double(x)), 
                    USE.NAMES = FALSE)
  if (any(!is.na(comp_id))) {
    comp <- max(comp_id, na.rm = TRUE)
  } else {
    comp <- NA
  }
  
  # Eliminate elements of obs that were successfully cast as double and that 
  # were identified as the hire date. If obs is empty or all NA's, return all 
  # NA's.
  obs <- obs[is.na(comp_id) & is.na(date_id)]
  
  # Extract type appt variable.
  type_appt_id <- grepl(".*-.* app", obs, ignore.case = TRUE)
  if (!any(type_appt_id)) {
    stop(paste("unable to find type_appt str, obs is currently:\n", j), 
         call. = FALSE)
  }
  no_match <- TRUE
  obs_appt <- tolower(obs[type_appt_id])
  for (i in type_appt_dd) {
    if (grepl(i, obs_appt, fixed = TRUE)) {
      type_appt <- i
      no_match <- FALSE
      break
    }
  }
  # If no elements of type_appt_dd were found in obs:
  if (no_match) {
    obs_appt <- obs_appt %>% 
      strsplit(., " ") %>% 
      unlist(., FALSE, FALSE)
    # Find first word of type_appt.
    for (i in obs_appt) {
      if (any(pn_dd == i)) {
        appt_start <- which(obs_appt == i)[1]
        break
      }
    }
    # Create type_appt string.
    appt_end <- grep("^appt$|^app$", obs_appt)
    type_appt <- paste(obs_appt[appt_start:appt_end], collapse = " ")
    # Eliminate the extracted type_appt string from obs.
    obs <- obs %>% 
      gsub(type_appt, "", ., ignore.case = TRUE) %>% 
      trimws %>% 
      .[. != ""] %>% 
      strsplit(., "\\s{2,}") %>% 
      unlist(., FALSE, FALSE)
    # Add type_appt to type_appt_dd.
    type_appt_dd <<- c(type_appt_dd, type_appt) %>% 
      .[order(nchar(.), decreasing = TRUE)]
  } else {
    # Else if there was a match from the type_appt_dd:
    # Eliminate the extracted type_appt string from obs.
    obs <- obs %>% 
      gsub(type_appt, "", ., ignore.case = TRUE) %>% 
      trimws %>% 
      .[. != ""] %>% 
      strsplit(., "\\s{2,}") %>% 
      unlist(., FALSE, FALSE)
  }
  
  # Look for known agency names in the first element of obs.
  no_match <- TRUE
  obs_one <- tolower(obs[1])
  for (i in agency_dd) {
    if (grepl(i, obs_one, fixed = TRUE)) {
      agency <- i
      no_match <- FALSE
      break
    }
  }
  
  # If no agency match was found, extract agency from obs[1].
  if (no_match) {
    # Isolate the first element of obs, split up by single blank space.
    first_elem <- obs[1] %>% 
      tolower %>% 
      strsplit(., " ") %>% 
      unlist(., FALSE, FALSE)
    # Attempt to separate the agency name from the person's proper name.
    agency <- vapply(first_elem, function(term) {
      if (any(pn_dd == term)) {
        return(term)
      } else {
        return(NA_character_)
      }
    }, character(1), USE.NAMES = FALSE) %>% 
      .[!is.na(.)] %>% 
      paste(collapse = " ")
    if (agency == "") {
      msg <- paste0(obs, collapse = "\n")
      stop(paste("unable to determine 'agency', obs is currently:\n", msg), 
           call. = FALSE)
    } else {
      # Add agency to .agency_dd
      agency_dd <<- c(agency_dd, agency) %>% 
        unique %>% 
        .[order(nchar(.), decreasing = TRUE)]
    }
  }
  
  # Eliminate the extracted agency string from obs.
  obs <- obs %>% 
    gsub(agency, "", ., ignore.case = TRUE) %>% 
    trimws %>% 
    .[. != ""]
  
  # Extract last_name and first_name variables.
  if (length(obs) == 2) {
    if (grepl(" ", obs[1])) {
      name <- obs[1] %>% 
        strsplit(., " ") %>% 
        unlist(., FALSE, FALSE)
      last_name <- name[1]
      first_name <- name[2]
    } else {
      stop(paste("unable to locate first/last name, obs is currently:\n", j), 
           call. = FALSE)
    }
  } else if (length(obs) == 3) {
    last_name <- obs[1]
    first_name <- obs[2]
  } else if (length(obs) == 4) {
    obs_one <- obs[1] %>% 
      strsplit(., " ") %>% 
      unlist(., FALSE, FALSE)
    if (all(obs_one %in% pn_dd)) {
      agency <- paste(agency, paste(obs_one, collapse = " "), collapse = " ")
      last_name <- obs[2]
      first_name <- obs[3]
    }
  } else {
    stop(paste("unable to locate first/last name, obs is currently:\n", j), 
         call. = FALSE)
  }
  
  # Extract the postition_title variable.
  pos_title <- obs[length(obs)]
  if (grepl("\\s\\d\\w$|\\s\\w\\d$|\\s\\d\\d[A-z]$", pos_title)) {
    pos_title <- pos_title %>% 
      gsub("\\s\\d\\w$|\\s\\w\\d$|\\s\\d\\d[A-z]$", "", .) %>% 
      trimws
  }
  
  out_df <- tryCatch(
    data.frame(
      agency = agency, 
      last_name = last_name, 
      first_name = first_name, 
      type_appt = type_appt, 
      position_title = pos_title, 
      compensation = comp, 
      hire_date = hire_date, 
      stringsAsFactors = FALSE
    ), 
    error = function(e) e)
  
  if (is.data.frame(out_df)) {
    return(out_df)
  } else {
    stop(paste(out_df$message, "\nobs is:\n", j, collapse = " "))
  }
})

# rbind all observations together into a single data frame, and eliminate any 
# observations that are completely filled with NA's.
obs_df <- obs_list %>% 
  do.call(rbind, .) %>% 
  tibble::as_data_frame() %>% 
  .[apply(., 1, function(x) !all(is.na(x))), ]

# Add month and year of the target pdf file.
obs_df$month <- 3
obs_df$year <- 2017

# Write obs_df to file.
write.csv(
  obs_df, 
  file.path(cwd, "dc", "public_body_employee_information_03312017.csv"), 
  row.names = FALSE
)

# Write agency_dd to file, this will be used to help extract agency strings in 
# other DC scripts.
saveRDS(
  agency_dd, 
  file.path(cwd, "dc", "scripts", "dc_agency_names_data_dictionary.RDS")
)

# Write type_appt_dd to file, this will be used to help extract type_appt 
# strings in other DC scripts.
saveRDS(
  type_appt_dd, 
  file.path(cwd, "dc", "scripts", "dc_type_appt_data_dictionary.RDS")
)
