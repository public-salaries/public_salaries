
library(pdftools)
library(magrittr)

cwd <- getwd()

## Read in and merge PA pdf data.
## Source of the pdf docs is http://pennwatch.pa.gov/employees/Pages/Employee-Salaries.aspx

# This script will read in all PDF files in directory "~/data/pa/2017", and  
# apply transformations to extract relevant data. Output is a tidy data frame 
# that contains variables: "last_name", "first_name", "position", 
# "annual_salary", "wage", "department", "month", and "year".

# Define month and year that the PDF files were created.
curr_month <- 11
curr_year <- 2017

# Define data directory file path, and get list of all PDF files.
data_dir <- file.path(cwd, "pa", "2017")
all_files <- list.files(path = data_dir, pattern = "*.pdf$", full.names = TRUE)

# Iterate over the list of PDF files. For each one, read it in, extract the 
# data, make some basic transformations, and return it as a tidy data frame. 
# Output of the loop below is a list of data frames (one per PDF file).
all_dfs <- lapply(all_files, function(curr_file) {
  # Read in the pdf document.
  txt <- pdftools::pdf_text(curr_file)
  
  # Get column headers.
  cols <- txt[1] %>% 
    strsplit("\r\n") %>% 
    unlist %>% 
    .[grepl("Last Name", .)] %>% 
    .[1] %>% 
    strsplit(" {2,}") %>% 
    unlist %>%
    c(., "department")
  
  # Record number of col headers.
  cols_len <- length(cols)
  
  # Iterate over the pages of the PDF, extract data from each one.
  pages <- lapply(txt, function(page) {
    # Split text into individual observations.
    page <- page %>% 
      strsplit("\r\n") %>% 
      unlist %>% 
      .[!grepl("Employee Salary Report|11/15/2016|Last Name|\\s+\\d+/\\d+", .)]
    
    # Stitch together position strings that have been pulled apart.
    idx <- grep("^\\s{10,}.+", page)
    if (length(idx) > 1) {
      taken <- vector()
      rows_need_pos <- vector()
      stitched_pos <- vector()
      for (i in seq_len(length(idx))) {
        idx_curr <- idx[i]
        if (idx_curr %in% taken || idx_curr == idx[length(idx)]) {
          next
        }
        idx_curr_2 <- idx[i + 1]
        if (idx_curr == (idx_curr_2 - 2)) {
          stitched_pos <- c(stitched_pos, 
                            paste(gsub("^\\s{2,}", "", page[idx_curr]), 
                                  gsub("^\\s{2,}", "", page[idx_curr_2])))
          taken <- c(taken, idx_curr, idx_curr_2)
          rows_need_pos <- c(rows_need_pos, idx_curr + 1)
        }
      }
      # Fill in the stitched positions into the observations that are missing 
      # positions.
      for (i in seq_len(length(rows_need_pos))) {
        row_curr <- rows_need_pos[i]
        k <- page[row_curr] %>% 
          strsplit("\\s+") %>% 
          unlist(FALSE, FALSE)
        page[row_curr] <- paste(k[1], k[2], stitched_pos[i], k[3], sep = "   ")
      }
      # Eliminate the rows from obj "taken".
      page <- page[-taken]
    }
    
    # Initialize output df.
    df <- data.frame(stringsAsFactors = FALSE)
    for (i in cols) {
      df[[i]] <- vector()
    }
    
    # Iterate over the obs within page. Each iteration adds a single row to 
    # the output data frame.
    curr_dept <- NA
    for (obs in page) {
      # If there are no consecutive spaces in the current obs, assign it as 
      # the current department value and move to the next iteration.
      if (!grepl(" {2,}", obs)) {
        curr_dept <- obs
        next
      }
      # If the first col header appears in the current obs, move to the next 
      # iteration.
      if (grepl(cols[1], obs, fixed = TRUE)) {
        next
      }
      
      # Split the current obs into it's individual values.
      obs <- unlist(strsplit(obs, " {2,}"), FALSE, FALSE)
      
      # Attempt to extract the salary value, and convert to numeric.
      pay <- suppressWarnings(
        as.numeric(gsub("\\$|\\$0|,| |/|[A-z]", "", obs[4]))
      )
      
      # If length of obs is three, this means one of the fields is 
      # missing. Run through a series of steps to try and figure out which 
      # field is actually missing.
      if (length(obs) == 3) {
        pay <- suppressWarnings(
          as.numeric(gsub("\\$|\\$0|,| |/|[A-z]", "", obs[3]))
        )
        if (!is.na(pay)) {
          obs_new <- c(rep(NA, 3), pay)
          spaces_1 <- grepl(" ", obs[1], fixed = TRUE)
          spaces_2 <- grepl(" ", obs[2], fixed = TRUE)
          if (spaces_1) {
            # Indication that the first and last name are combind into obs[1] 
            # AND that position variable is in obs[2].
            obs_new[3] <- obs[2]
            name <- unlist(strsplit(obs[1], " ", fixed = TRUE), FALSE, FALSE)
            obs_new[2] <- name[length(name)]
            obs_new[1] <- paste(name, collapse = " ")
          } else if (!spaces_1 && spaces_2) {
            # Indication that the position variable is in obs[2], obs[1] is the
            # last name, and first name is missing.
            obs_new[1] <- obs[1]
            obs_new[3] <- obs[2]
          } else if (!spaces_1 && !spaces_2) {
            # Indication that position is missing, last name is in obs[1] and 
            # first name is in obs[2].
            obs_new[1] <- obs[1]
            obs_new[2] <- obs[2]
          }
          obs <- obs_new
        }
      }
      
      # If obj "pay" is NA, try to extract the salary from each element of obs.
      if (is.na(pay)) {
        pay <- vapply(obs, function(x) {
          out <- suppressWarnings(
            as.numeric(gsub("\\$|\\$0|,| |/|[A-z]", "", x))
          )
          if (is.na(out)) {
            out <- NA_real_
          }
          return(out)
        }, numeric(1), USE.NAMES = FALSE)
        
        if (any(!is.na(pay))) {
          pay <- pay[!is.na(pay)][1]
        } else {
          pay <- NA_real_
        }
      }
      
      # If length of obs is shorter than the number of cols in the output df, 
      # append NA's to obs.
      if (length(obs) < cols_len) {
        obs <- c(obs, rep(NA, cols_len - length(obs)))
      }
      
      # Edit the last element of obs, and obs[4].
      obs[length(obs)] <- curr_dept
      obs[4] <- pay
      
      # Append obs to df.
      df[(nrow(df) + 1), ] <- obs
    }
    
    return(df)
  })
  
  # rbind all observations together into a single data frame, and eliminates 
  # any observations that are completely filled with NA's.
  df <- do.call(rbind, pages)
  
  # Add month and year of the target pdf file.
  df$month <- curr_month
  df$year <- curr_year
  
  return(df)
})


# rbind all observations together into a single data frame.
df <- all_dfs %>% 
  do.call(rbind, .) %>% 
  `colnames<-`(c("last_name", "first_name", "position", "annual_salary", 
                 "wage", "department", "month", "year"))

# Convert variable annual_salary to numeric.
df$annual_salary <- as.numeric(df$annual_salary)

# Write df to file.
write.csv(df, file.path(data_dir, "pa_public_salaries_2017_11_15.csv"), 
          row.names = FALSE)
