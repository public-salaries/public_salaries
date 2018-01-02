
library(pdftools)
library(tibble)
library(magrittr)

cwd <- getwd()

## Read in Washington DC pdf data.
## Source of the pdf docs is https://dchr.dc.gov/public-employee-salary-information

# This script will read in file "public_salaries/data/dc/public_body_employee_information_jun16_0.pdf", 
# apply transformations to extract relevant data. Output is a tidy data frame 
# that contains variables: "agency", "last_name", "first_name", "type_appt",
# "position_title", and "compensation".

# Read in the pdf document.
file_name <- file.path(
  cwd, "dc", "public_body_employee_information_jun16_0.pdf"
)
txt <- pdftools::pdf_text(file_name)

# Establish vector of column headers
cols <- c("agency", "last_name", "first_name", "position_title", 
          "compensation", "type_appt")

# For each page of the doc, extract each relevant observation as a char vector.
observations <- vector(mode = "character", length = length(txt) * 68)
counter <- 1
for (page in txt) {
  obs <- page %>% 
    strsplit(., "\n") %>% 
    unlist(., FALSE, FALSE)
  for (i in obs) {
    observations[counter] <- i
    counter <- counter + 1
  }
}
observations <- observations[observations != ""]
observations <- observations[2:length(observations)]

# Load type_appt_dd data dictionary, this will be used to help identify 
# type appt strings.
type_appt_dd <- readRDS(
  file.path(cwd, "dc", "scripts", "dc_type_appt_data_dictionary.RDS")
)

# Load agency_dd data dictionary, this will be used to help identify agency 
# strings.
agency_dd <- c(readRDS(file.path(cwd, "dc", "scripts", 
                                 "dc_agency_names_data_dictionary.RDS")), 
               "Public Employee Relations Brd") %>% 
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
    gsub(",|\\$", "", .) %>% 
    strsplit(., "\\s{2,}") %>% 
    unlist(., FALSE, FALSE) %>% 
    .[!. == "$"] %>% 
    trimws
  
  # If obs is vector of length 6, this means the elements of obs were cleanly 
  # delimited, and can safely return the relevant elements.
  if (length(obs) == 6) {
    return(
      data.frame(
        agency = tolower(obs[1]), 
        last_name = obs[2], 
        first_name = obs[3], 
        position_title = obs[4], 
        compensation = as.double(obs[5]), 
        type_appt = obs[6], 
        stringsAsFactors = FALSE
      )
    )
  }
  
  # Extract the commpensation.
  comp_id <- vapply(obs, function(x) {
    out <- suppressWarnings(as.double(x))
    if (is.na(out)) {
      return(NA_character_)
    } else {
      return(x)
    }
  }, character(1), USE.NAMES = FALSE)
  if (any(!is.na(comp_id))) {
    comp <- max(as.double(comp_id[!is.na(comp_id)]), na.rm = TRUE)
  } else {
    comp <- NA
  }
  
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
      # Add agency to agency_dd
      agency_dd <<- c(agency_dd, agency) %>% 
        unique %>% 
        .[order(nchar(.), decreasing = TRUE)]
    }
  }
  
  # Eliminate the extracted agency string from obs.
  if (grepl("[()]", agency)) {
    obs[1] <- tolower(obs[1])
    obs[1] <- obs[1] %>% 
      gsub(agency, "", ., fixed = TRUE) %>% 
      trimws
  } else {
    obs[1] <- obs[1] %>% 
      gsub(agency, "", ., ignore.case = TRUE) %>% 
      trimws
  }
  obs <- obs[obs != ""]
  
  # Eliminate the extracted comp_id string from obs.
  if (any(!is.na(comp_id))) {
    obs <- obs %>% 
      gsub(comp_id[!is.na(comp_id)], "", ., ignore.case = TRUE) %>% 
      trimws %>% 
      .[. != ""] %>% 
      strsplit(., "\\s{2,}") %>% 
      unlist(., FALSE, FALSE)
  }
  
  # Extract last_name and first_name variables.
  position_title <- NA
  if (length(obs) == 1) {
    if (grepl(" ", obs)) {
      name <- obs %>% 
        strsplit(., " ") %>% 
        unlist(., FALSE, FALSE)
      last_name <- name[1]
      first_name <- name[2]
    } else {
      last_name <- obs
      first_name <- NA
    }
  } else if (length(obs) == 2) {
    last_name <- obs[1]
    first_name <- obs[2]
  } else if (length(obs) == 3) {
    last_name <- obs[1]
    first_name <- obs[2]
    comp <- obs[3]
  } else if (length(obs) == 4) {
    pos_title_found <- TRUE
    last_name <- obs[1]
    first_name <- obs[2]
    position_title <- obs[3]
    comp <- obs[4]
  } else {
    stop(paste("unable to locate first/last name, obs is currently:\n", j), 
         call. = FALSE)
  }
  
  out_df <- tryCatch(
    data.frame(
      agency = agency, 
      last_name = last_name, 
      first_name = first_name, 
      position_title = position_title, 
      compensation = comp, 
      type_appt = type_appt, 
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
obs_df$month <- 06
obs_df$year <- 2016

# Write obs_df to file.
write.csv(
  obs_df, 
  file.path(cwd, "dc", "public_body_employee_information_jun16_0.csv"), 
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
