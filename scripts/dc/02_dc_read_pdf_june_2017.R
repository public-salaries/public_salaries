
library(pdftools)
library(tibble)
library(magrittr)
library(qdapDictionaries)

## Read in Washington DC pdf data.
## Source of the pdf docs is https://dchr.dc.gov/public-employee-salary-information

# This script will read in file "public_salaries/data/dc/public_body_employee_information_06302017.pdf", 
# apply transformations to extract relevant data. Output is a tidy data frame 
# that containsvariables: "agency", "last_name", "first_name", "type_appt",
# "position_title", "compensation", and "hire_date"

# Eastablish dictionary of common terms that will be used to help ID proper 
# names.
dict <- c("dmgeo", "inspector", "ofc", "ofc.", "dc", "appeals", "ethics", 
          "mgmt", "resources", "dept", "services", "homeland", "ema", 
          "consumer", "regulatory", "security", "&", "arts", "humanities", 
          "comm", "espinoza", "ent.", "zoning", "orm", "workers", "-", 
          "department", "advisor", "agcy", "islander", "affairs", 
          "charititable", "games", "mayor's", "off.", "people's", "elections", 
          "disabil.", "advry", "neighborhood", "retirement", "planning", 
          "developm", "dv", "emerg.", "medical", "svcs", "schools", 
          "complaints", "corrections", "grants", "administration", "ps&j", 
          "dep", "sciences", "hearings", "examiner", "superintendent", "d.c.", 
          "non", "osse", "parks", "rights", "rehab", "energy", "works", 
          "vehicles", "reg", "admin", "comm.", "dept.", "behavioral", 
          "info", "serv.", "gr", "for-hire", "excepted", "securities", 
          "unified", "communications", "contracting", "procurement", 
          qdapDictionaries::DICTIONARY$word)

# Establish vector of column headers known to be used in these pdf's.
known_cols <- c(
  "agency name", 
  "last name", 
  "first name", 
  "type appt", 
  "position title", 
  "grade", 
  "compensation", 
  "hire date"
)

# Read in the pdf document.
file_name <- "./data/dc/public_body_employee_information_06302017.pdf"
txt <- pdftools::pdf_text(file_name)

# Find the column headers of the data within the pdf doc.
cols <- txt[1] %>% 
  strsplit(., "\n") %>% 
  unlist(., FALSE, FALSE) %>% 
  .[grepl(".*Last Name.*", .)] %>% 
  strsplit(., "\\s{1,}") %>% 
  unlist(., FALSE, FALSE) %>% 
  tolower %>% 
  .[!. %in% c("name", "appt", "title", "hire")] %>% 
  vapply(., function(x) {
    known_cols[which(grepl(x, known_cols))]
  }, character(1), USE.NAMES = FALSE)

# For each page of the doc, extract each relevant observation as a char vector.
observations <- lapply(txt, function(page) {
  # split text up by lines (obs), and extract relevant obs.
  page %>% 
    strsplit(., "\n") %>% 
    unlist(., FALSE, FALSE) %>% 
    magrittr::extract(4:48)
}) %>% 
  unlist(., FALSE, FALSE) %>% 
  .[!is.na(.)] %>% 
  .[!grepl("Page \\d{1,5} of \\d{1,5}", .)] %>% 
  .[!grepl("\\s{20,}[January|February|March|April|May|June|July|August|September|October|November|December]", .)]

# Initiate agency data dictionary. This will be used to help ID the government 
# agency of each observation and separate the string from the last name string.
agency_dd <- vector(mode = "character")

# For each observation within the pdf, extract relevant data and save output 
# as a single-row data frame. Each of these df's will be compiled into a list, 
# which will then be rbind together using do.call().
obs_list <- lapply(observations, function(obs) {
  # Split obs up into a vector of elements (as strings).
  obs <- obs %>% 
    strsplit(., "\\s{2,}") %>% 
    unlist(., FALSE, FALSE) %>% 
    .[!. == "$"] %>% 
    gsub(",", "", .)

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
      if (any(dict == term)) {
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
      agency_dd <<- c(agency_dd, agency)
    }
  }
  
  # Remove the agency str from obs[1], should leave us with a proper name.
  name <- obs[1] %>% 
    gsub(agency, "", ., ignore.case = TRUE) %>% 
    trimws
  
  # Unpacking the proper name. There are a few different cases to handle. 
  # In addition to the cases listed below, need to be able to handle the 
  # existence of spaces within a person's first or last name.
  # 1. Last and first name are both contained in obj "name", sep by " ".
  # 2. Only last name is contained in obj "name", in which case the first 
  #   name should be the first str in obs[2].
  # This step will also extract the variables "type of appointment" and 
  # "position title".
  if (name == "") {
    last_name <- obs[2]
    first_name <- obs[3]
    type_appt <- obs[4]
    pos_title <- obs[5]
  } else {
    space_in_name <- grepl(" ", name, fixed = TRUE)
    first_term_obs_two <- obs[2] %>% 
      strsplit(., " ") %>% 
      unlist(., FALSE, FALSE) %>% 
      magrittr::extract(1) %>% 
      tolower
    if (space_in_name == FALSE || 
        !any(dict == first_term_obs_two)) {
      last_name <- name
      first_name <- obs[2]
      type_appt <- obs[3]
      pos_title <- obs[4]
      obs <- obs[5:length(obs)]
    } else if (any(dict == first_term_obs_two)) {
      name <- unlist(strsplit(name, " "), FALSE, FALSE)
      if (length(name) == 2) {
        last_name <- name[1]
        first_name <- name[2]
      } else if (length(name) > 2) {
        last_name <- paste(name[1:(length(name) - 1)], collapse = " ")
        first_name <- name[length(name)]
      }
      type_appt <- obs[2]
      pos_title <- obs[3]
      obs <- obs[4:length(obs)]
    } else {
      msg <- paste0(obs, collapse = "\n")
      stop(paste("unable to locate first/last name, obs is currently:\n", msg), 
           call. = FALSE)
    }
  }
  
  # Extract the compensation.
  comp <- sapply(obs, function(x) suppressWarnings(as.double(x)), 
                 USE.NAMES = FALSE)
  if (any(!is.na(comp))) {
    comp <- max(comp, na.rm = TRUE)
  } else {
    comp <- NA
  }

  # Extract hire date.
  for (i in obs) {
    hire_date <- as.Date(i, format = "%m/%d/%Y")
    if (!is.na(hire_date)) {
      break
    }
  }
  
  return(
    data.frame(
      agency = agency, 
      last_name = last_name, 
      first_name = first_name, 
      type_appt = type_appt, 
      position_title = pos_title, 
      compensation = comp, 
      hire_date = hire_date, 
      stringsAsFactors = FALSE
    )
  )
})

# rbind all observations together into a single data frame.
obs_df <- tibble::as_data_frame(do.call(rbind, obs_list))

# Write obs_df to file.
write.csv(obs_df, "./data/dc/public_body_employee_information_06302017.csv", row.names = FALSE)
