## Functions that are sourced at the top of "id_read_pdf_states.R"

library(magrittr)
library(readr)

## Convert a pdf file to a txt document, then read in the text doc.
manual_read_pdf <- function(pdf_path) {
  # Input validation.
  stopifnot(is.character(pdf_path))
  if (!grepl(".pdf", pdf_path, ignore.case = TRUE)) {
    stop("arg 'pdf_path' must be a file path that points to a '.pdf' file", 
         call. = FALSE)
  }
  
  # Create txt_path string.
  txt_path <- gsub(".pdf", ".txt", pdf_path, ignore.case = TRUE)
  
  # Check for existence of a txt doc with the same name as the input pdf file. 
  # If it already exists, read it in, split by page sep delimiters, then delete
  # the text file.
  if (file.exists(txt_path)) {
    txt <- read_txt(txt_path)
    file.remove(txt_path)
    return(txt)
  }
  
  # Call "pdftotext" on the file via system2, this will create a text doc 
  # containing all of the text from the pdf doc, in the same dir.
  system2("pdftotext", args = c("-table", pdf_path))
  
  # Check to see if txt file was successfully created. If not, throw an error. 
  # Otherwise, read it in, split by page sep delimiters, then delete the text 
  # file.
  if (file.exists(txt_path)) {
    txt <- read_txt(txt_path)
    file.remove(txt_path)
  } else {
    stop("'manual_read_pdf' unable to create txt doc from the input pdf doc", 
         call. = FALSE)
  }
  
  return(txt)
}

## Read in a txt doc, split the str by the page separation delimiter.
read_txt <- function(txt_path) {
  # Input validation.
  stopifnot(is.character(txt_path))
  if (!grepl(".txt", txt_path, ignore.case = TRUE)) {
    stop("arg 'txt_path' must be a file path that points to a '.txt' file", 
         call. = FALSE)
  }
  
  # Read in txt doc and split str by page sep delimiter.
  if (file.exists(txt_path)) {
    txt <- txt_path %>% 
      readr::read_file() %>% 
      strsplit("\f", fixed = TRUE) %>% 
      unlist(FALSE, FALSE)
  } else {
    stop(
      sprintf(
        "'%s' does not exist in current working directory ('%s')", 
        txt_path, getwd()
      ), call. = FALSE
    )
  }
  return(txt)
}

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
    type_appt <- obs[type_appt_id & !is.na(type_appt_id)]
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
        gsub(regex, "", ., ignore.case = TRUE) %>% 
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

## Go back and extract/fill-in NA's within variable agency.
fill_missing_agency <- function(obs_df) {
  # If there are no NA's within variable agency, return obs_df.
  if (sum(is.na(obs_df$agency)) == 0) {
    return(obs_df)
  }
  
  # Establish an agency data dictionary.
  agency_dd <- obs_df$agency %>% 
    unique %>% 
    gsub("classified$|non-$", "", ., ignore.case = TRUE) %>% 
    trimws %>% 
    unique %>% 
    .[!is.na(.)] %>% 
    .[!nchar(.) < 3] %>% 
    .[order(nchar(.), decreasing = TRUE)]
  
  # Fill in NA's in col agency using the newly created data dict.
  for (row in which(is.na(obs_df$agency))) {
    obs_df[row, ] <- get_agency(obs_df[row, ], agency_dd)
  }
  
  return(obs_df)
}

## Helper function that takes a single row ("obs") as input, searches through 
## the agency data dict looking for a substring match in all of the values of 
## obs. If one is found, take the matched substring as the agency for that obs,
## and remove the subsring from the other values of obs.
get_agency <- function(obs, agency_dd) {
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

## Move leading digits within the agency value to the job_title value.
digit_move <- function(obs) {
  # Isolate the leading digits.
  digit <- obs$agency %>% 
    strsplit(" ", fixed = TRUE) %>% 
    unlist(FALSE, FALSE) %>% 
    .[1]
  if (!grepl("^\\d+$", digit)) {
    return(obs)
  }
  # append the digit value to variable job_title.
  obs$job_title <- paste(obs$job_title, digit)
  # Remove the digit value from variable agency.
  obs$agency <- trimws(sub(digit, "", obs$agency))
  
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

## Fix instances in which a portion of a person's name was split off into a new
## row (when a string is too long for a single cell, the PDF will wrap the 
## string into a second line within the "cell", and this causes pdftotext or R 
## or both to read that as a completely new observation/row).
stitch_broken_name_strings <- function(obs_df) {
  # Get number of NA values in each observation of obs_df.
  num_nas <- vapply(obs_list, function(x) sum(is.na(x)), numeric(1))
  if (!any(num_nas > 5)) {
    return(obs_df)
  }
  
  # Iterate over the names col. If the row one ahead of the current iteration 
  # has more than 5 NA's, append the name string of that row to the name string
  # of the current iteration.
  df_names <- obs_df$name
  new_names <- vapply(seq_len(length(num_nas) - 1), function(idx) {
    idx_2 <- idx + 1
    if (num_nas[idx_2] <= 5) {
      return(df_names[idx])
    }
    return(paste(df_names[idx], df_names[idx_2]))
  }, character(1), USE.NAMES = FALSE)
  
  # Replace the name variable with the newly created vector of names.
  obs_df$name <- c(new_names, tail(df_names, 1))
  
  # Eliminate rows in obs_df that contain more than 5 NA values.
  obs_df <- obs_df[-which(num_nas > 5), ]
}



# Takes a series of char vectors, returns a single obs data frame.
get_single_obs_df <- function(obs, type_appt = NULL, comp = NULL, 
                              job_title = NULL, col_names = NULL) {
  # Input validations.
  stopifnot(is.character(obs))
  n_obs <- length(obs)
  if (8 < n_obs) {
    stop(paste0("\nlength of 'obs' is either greater than 8.", 
               "\nValue of obs is:\n"), paste(obs, collapse = " "))
  }
  
  # If length of obs is less than or equal to 3 and arg "col_names" is not NULL
  if (n_obs <= 3 && !is.null(col_names)) {
    out <- data.frame(matrix(nrow = 1, ncol = 8), stringsAsFactors = FALSE)
    out[1, ] <- as.list(c(obs, rep(NA, 8 - n_obs)))
    colnames(out) <- col_names
    return(out)
  }
  
  # If length of obs is eight.
  if (n_obs == 8) {
    return(
      data.frame(
        name = obs[1], 
        job_title = obs[2], 
        agency = obs[3], 
        appt_type = obs[4], 
        ft_pt = obs[5], 
        pay_basis = obs[6], 
        salary = suppressWarnings(as.double(obs[7])), 
        county = obs[8], 
        stringsAsFactors = FALSE
      )
    )
  }
  
  # If length of obs is six.
  if (n_obs == 6) {
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
  if (n_obs == 5) {
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
  if (n_obs == 4) {
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
  
  # If length of obs is three and arg "col_names" is NULL.
  if (n_obs == 3) {
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
          county = NA_character_, 
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
          county = NA_character_, 
          stringsAsFactors = FALSE
        )
      )
    }
  }
}
