## Functions that are sourced at the top of "id_read_pdf_states.R"

## Isolate compensation value.
get_comp <- function(obs) {
  # Try to extract given the compensation value was cleanly delimited.
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
    obs <- obs[is.na(comp_id)]
  } else {
    # If that fails, use regex to try to extract the compensation.
    comp_id <- grepl("\\d+\\.\\d+", obs)
    if (any(comp_id)) {
      comp <- obs[comp_id] %>% 
        gregexpr("\\d+\\.\\d+", .) %>% 
        regmatches(obs[comp_id], .) %>% 
        unlist(FALSE, FALSE)
      obs <- obs %>% 
        gsub(comp, "", .) %>% 
        trimws %>% 
        .[. != ""]
      comp <- as.double(comp)
    } else {
      # If both methods fail, make comp NA.
      comp <- NA
    }
  }
  return(list(comp = comp, obs = obs))
}

## Extract type appt variable.
get_type_appt <- function(obs) {
  # Try to extract given the value was cleanly delimited.
  type_appt_id <- obs == "CLASSIFIED" | obs == "NON-"
  if (any(type_appt_id)) {
    type_appt <- obs[type_appt_id]
    obs <- obs[!type_appt_id]
    if (type_appt == "NON-") {
      type_appt <- "non-classified"
    } else {
      type_appt <- "classified"
    }
  } else {
    # If that fails, use regex to try to extact the type appt value.
    type_appt_id <- grepl("^classified|classified$|^non-|non-$", obs, 
                          ignore.case = TRUE)
    if (any(type_appt_id)) {
      type_appt <- obs[type_appt_id] %>% 
        gregexpr("^classified|classified$|^non-|non-$", ., 
                 ignore.case = TRUE) %>% 
        regmatches(obs[type_appt_id], .) %>% 
        unlist(FALSE, FALSE) %>% 
        tolower
      regex <- paste0("^", type_appt, "|", type_appt, "$")
      obs <- obs %>% 
        gsub(regex, "", .) %>% 
        trimws %>% 
        .[. != ""]
      if (type_appt == "non-") {
        type_appt <- "non-classified"
      } else {
        type_appt <- "classified"
      }
    } else {
      # If both methods fail, make type_appt NA.
      type_appt <- NA
    }
  }
  return(list(type_appt = type_appt, obs = obs))
}

## Try to extract the job_title variable from obs.
get_job_title <- function(obs) {
  job_title <- NA
  if (!grepl("(\\w|\\s)(\\w|\\s)\\.$", obs[1]) && 
      grepl(".", obs[1], fixed = TRUE)) {
    job_title <- obs[1] %>% 
      strsplit("(\\w|\\s)(\\w|\\s)\\.\\s") %>% 
      unlist(FALSE, FALSE) %>% 
      tail(n = 1)
    obs[1] <- obs[1] %>% 
      gsub(job_title, "", ., fixed = TRUE) %>% 
      trimws
  }
  return(list(job_title = job_title, obs = obs))
}

## Extract the agency variable using the agency data dict.
get_agency <- function(obs, agency_dd) {
  #obs_lower <- tolower(obs)
  match_found <- FALSE
  for (i in agency_dd) {
    if (any(grepl(i, obs, fixed = TRUE))) {
      obs$agency <- i
      match_found <- TRUE
      break
    }
  }
  if (match_found) {
    # Eliminate the extracted agency string from obs.
    obs$job_title <- obs$job_title %>% 
      gsub(obs$agency, "", ., fixed = TRUE) %>% 
      trimws
  }
  return(obs)
}

## Split a full name string into first name, last name, and middle initial.
name_split <- function(name) {
  name <- unlist(strsplit(name, ", ", fixed = TRUE), FALSE, FALSE)
  # ID the last name.
  ln <- name[1]
  # ID the middle initial and first name.
  if (grepl("\\s\\w\\.$", name[2])) {
    fn <- unlist(strsplit(name[2], " ", fixed = TRUE), FALSE, FALSE)
    mi <- gsub(".", "", fn[2], fixed = TRUE)
    fn <- fn[1]
  } else {
    mi <- NA_character_
    fn <- gsub("\\s|\\.$", "", name[2])
  }
  return(list(fn, mi, ln))
}

# Takes a series of char vectors, returns a single obs data frame.
get_single_obs_df <- function(obs, type_appt = NULL, comp = NULL, 
                              job_title = NULL) {
  # Input validations.
  stopifnot(is.character(obs))
  stopifnot(is.character(cols))
  n_obs <- length(obs)
  if (8 < n_obs & 4 > n_obs) {
    stop(paste("\nobs is:\n", j, collapse = " "))
  }
  
  # If length of obs is eight.
  if (length(obs) == 8) {
    return(
      data.frame(
        name = obs[1], 
        job_title = obs[2], 
        agency = obs[3], 
        appt_type = obs[4], 
        ft_pt = obs[5], 
        pay_basis = obs[6], 
        salary = as.double(obs[7]), 
        county = obs[8], 
        stringsAsFactors = FALSE
      )
    )
  }
  
  # IF length of obs is six.
  if (length(obs) == 6) {
    return(
      data.frame(
        name = obs[1], 
        job_title = obs[2], 
        agency = obs[3], 
        appt_type = type_appt, 
        ft_pt = obs[4], 
        pay_basis = obs[5], 
        salary = comp, 
        county = obs[6], 
        stringsAsFactors = FALSE
      )
    )
  }
  
  # If length of obs is five.
  if (length(obs) == 5) {
    if (is.null(job_title) || is.na(job_title)) {
      return(
        data.frame(
          name = obs[1], 
          job_title = obs[2], 
          agency = NA_character_, 
          appt_type = type_appt, 
          ft_pt = obs[3], 
          pay_basis = obs[4], 
          salary = comp, 
          county = obs[5], 
          stringsAsFactors = FALSE
        )
      )
    } else {
      return(
        data.frame(
          name = obs[1], 
          job_title = job_title, 
          agency = obs[2], 
          appt_type = type_appt, 
          ft_pt = obs[3], 
          pay_basis = obs[4], 
          salary = comp, 
          county = obs[5], 
          stringsAsFactors = FALSE
        )
      )
    }
  }
  
  # IF length of obs is four.
  if (length(obs) == 4) {
    if (is.null(job_title) || is.na(job_title)) {
      return(
        data.frame(
          name = obs[1], 
          job_title = NA_character_, 
          agency = NA_character_, 
          appt_type = type_appt, 
          ft_pt = obs[2], 
          pay_basis = obs[3], 
          salary = comp, 
          county = obs[4], 
          stringsAsFactors = FALSE
        )
      )
    } else {
      return(
        data.frame(
          name = obs[1], 
          job_title = job_title, 
          agency = NA_character_, 
          appt_type = type_appt, 
          ft_pt = obs[2], 
          pay_basis = obs[3], 
          salary = comp, 
          county = obs[4], 
          stringsAsFactors = FALSE
        )
      )
    }
  }
}
