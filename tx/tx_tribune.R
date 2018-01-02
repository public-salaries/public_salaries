# Texas Files

library(tidyverse)
library(readxl)
library(stringi)

# Functions ------------------------
# Function to read in excel files
import_excel <- function(wd){
  setwd(wd)
  file_list_xls <- list.files(pattern = '*.xls*')
  df_list <- sapply(file_list_xls, read_excel, simplify = FALSE, trim_ws = TRUE)
  file_list_csv <- list.files(pattern = '*.csv')
  df_list_2 <- sapply(file_list_csv, read.csv, header = TRUE, na.strings = c("", NA),
                      stringsAsFactors = FALSE, check.names = FALSE, simplify = FALSE)
  df_list_final <- c(df_list, df_list_2)
  
  # Make column names title format
  for (i in 1:length(df_list_final)){
    colnames(df_list_final[[i]]) <- stri_trans_totitle(colnames(df_list_final[[i]]))
  }
  
  return(df_list_final)
}

# Get column names
get_cols <- function(df_list){
  col_names_list <- c()
  for (i in 1:length(df_list)){
    update_list <- colnames(df_list[[i]])
    col_names_list <- c(col_names_list, update_list)
  }
  col_names_list <- unique(col_names_list)
  return(col_names_list)
}

# Convert all salary variables to numeric 
salary_numeric <- function(df_list){
  for (i in 1:length(df_list)){
    df_list[[i]]$`Annual Salary` <- gsub(",","", df_list[[i]]$`Annual Salary`)
    df_list[[i]] <- df_list[[i]] %>%
    mutate(`Annual Salary` = as.numeric(`Annual Salary`))
  }
  return(df_list)
}

# Load data -------------------------------
# 2016
df_list_city_16 <- import_excel("~/public_salaries/data/tx/2016/city")
df_list_uni_16 <- import_excel("~/public_salaries/data/tx/2016/university")
df_list_k12_16 <- import_excel("~/public_salaries/data/tx/2016/k12")

# 2017
df_list_city_17 <- import_excel("~/public_salaries/data/tx/2017/city")
df_list_uni_17 <- import_excel("~/public_salaries/data/tx/2017/university")
df_list_k12_17 <- import_excel("~/public_salaries/data/tx/2017/k12")


# Normalize column names ----------------------------

# City 16 
df_list_city_16[[1]] <- df_list_city_16[[1]] %>%
  rename("Last Name" = "Last",
         "Annual Salary" = "Annual Rt",
         "Ethnicity" = "Ethnic Grp")

df_list_city_16[[2]] <- df_list_city_16[[2]] %>%
  rename("Annual Salary" = "Fy16 Annual Salary2",
         "Ethnicity" = "Ethnic Origin10",
          "Hire Date" = "Hire Date1") %>%
  mutate(`Hire Date` = as.character(`Hire Date`))

# K12 16
df_list_k12_16[[1]]$`Position Contract Amt` <- gsub(",","", df_list_k12_16[[1]]$`Position Contract Amt`)
df_list_k12_16[[1]] <- df_list_k12_16[[1]] %>%
  rename("Annual Salary" = "Position Contract Amt")
  mutate(`Annual Salary` = as.numeric(`Annual Salary`))

df_list_k12_16[[2]] <- df_list_k12_16[[2]] %>%
  rename("First Name" = "Fname",
         "Last Name" = "Lname",
         "Annual Salary" = "Budgeted_salary",
         "Hire Date" = "Hiredate") %>%
  mutate(`Hire Date` = as.character(`Hire Date`))

df_list_k12_16[[3]] <- df_list_k12_16[[3]] %>%
  mutate(`Hire Date` = as.character(`Hire Date`))

df_list_k12_16[[4]] <- df_list_k12_16[[4]] %>%
  rename("Full Name" = "Full Name Last-First-Middle") %>%
  mutate(`Hire Date` = as.character(`Hire Date`))

df_list_k12_16[[5]] <- df_list_k12_16[[5]] %>%
  rename("Annual Salary" = "Salary")

# Uni 16
df_list_uni_16[[1]] <- df_list_uni_16[[1]] %>%
  rename("Last Name" = "Last",
         "Ethnicity" = "Ethnic Grp",
         "Annual Salary" = "Annual Rt")

df_list_uni_16[[2]] <- df_list_uni_16[[2]] %>%
  rename("Last Name" = "Last",
         "Ethnicity" = "Ethnic Grp",
         "Annual Salary" = "Annual Rt")

df_list_uni_16[[3]] <- df_list_uni_16[[3]] %>%
  rename("Last Name" = "Last",
         "Ethnicity" = "Ethnic Grp",
         "Annual Salary" = "Annual Rt")

df_list_uni_16[[4]] <- df_list_uni_16[[4]] %>%
  rename("Last Name" = "Last",
         "Ethnicity" = "Ethnic Grp",
         "Annual Salary" = "Annual Rt")

df_list_uni_16[[5]] <- df_list_uni_16[[5]] %>%
  rename("Last Name" = "Last",
         "Ethnicity" = "Ethnic Grp",
         "Annual Salary" = "Annual Rt")

df_list_uni_16[[6]] <- df_list_uni_16[[6]] %>%
  rename("First Name" = "Fname",
         "Annual Salary" = "Gross",
         "Hire Date" = "Hiredate") %>%
  mutate(`Hire Date` = as.character(`Hire Date`))

df_list_uni_16[[7]] <- df_list_uni_16[[7]] %>%
  rename("Full Name" = "Name",
         "Annual Salary" = "Total Salary",
         "Hire Date" = "Hire_date")  %>%
  mutate(`Hire Date` = as.character(`Hire Date`))

df_list_uni_16[[8]] <- df_list_uni_16[[8]] %>%
  rename("Full Name" = "Name",
         "Annual Salary" = "Total Salary",
         "Hire Date" = "Hire_date")  %>%
  mutate(`Hire Date` = as.character(`Hire Date`))

df_list_uni_16[[9]] <- df_list_uni_16[[9]] %>%
  rename("Full Name" = "Name",
         "Annual Salary" = "Total Salary",
         "Hire Date" = "Hire_date")  %>%
  mutate(`Hire Date` = as.character(`Hire Date`))

df_list_uni_16[[10]] <- df_list_uni_16[[10]] %>%
  rename("Full Name" = "Employee Name",
         "Annual Salary" = "Salary",
         "Hire Date" = "Date of Hire")  %>%
  mutate(`Hire Date` = as.character(`Hire Date`))

df_list_uni_16[[11]] <- df_list_uni_16[[11]] %>%
  rename("Annual Salary" = "Annual Rt") %>%
  mutate(`Hire Date` = as.character(`Hire Date`))

df_list_uni_16[[12]] <- df_list_uni_16[[12]] %>%
  rename("Full Name" = "Name",
         "Annual Salary" = "Annual Rt",
         "Hire Date" = "Start Date") %>%
  mutate(`Hire Date` = as.character(`Hire Date`))

df_list_uni_16[[13]] <- df_list_uni_16[[13]] %>%
  rename("Last Name" = "Last",
         "Annual Salary" = "Annual Rt",
         "Hire Date" = "Start Date") %>%
  mutate(`Hire Date` = as.character(`Hire Date`))

for (i in 14:length(df_list_uni_16)){
  df_list_uni_16[[i]] <- df_list_uni_16[[i]] %>%
    rename("Last Name" = "Lastname",
           "First Name" = "Firstname",
           "Annual Salary" = "Budgetedsalary")
}

# City 17
df_list_city_17[[1]] <- df_list_city_17[[1]] %>%
  rename("Last Name" = "Last",
         "First Name" = "First")

df_list_city_17[[2]] <- df_list_city_17[[2]] %>%
  rename("Full Name" = "Name - Full",
         "Annual Salary" = "Rate Of Pay")

df_list_city_17[[3]] <- df_list_city_17[[3]] %>%
  rename("Last Name" = "Last",
         "Annual Salary" = "Annual Rt")

# K12 17
df_list_k12_17[[1]] <- df_list_k12_17[[1]] %>%
  rename("Annual Salary" = "Annl Sal") %>%
  mutate(`Hire Date` = as.character(`Hire Date`))

df_list_k12_17[[2]] <- df_list_k12_17[[2]] %>%
  rename("Full Name" = "Full_name",
         "Annual Salary" = "Salary") %>%
  mutate(`Hire Date` = as.character(`Hire Date`))

df_list_k12_17[[3]] <- df_list_k12_17[[3]] %>%
  rename("Full Name" = "Employee Name")

df_list_k12_17[[4]] <- df_list_k12_17[[4]] %>%
  rename("Full Name" = "Name",
         "Annual Salary" = "Contract Salary")

df_list_k12_17[[5]] <- df_list_k12_17[[5]] %>%
  rename("Annual Salary" = "Gross Annual Salary")

# Uni 17
df_list_uni_17[[1]] <- df_list_uni_17[[1]] %>%
  rename("First Name" = "Name First",
         "Middle Name" = "Name Middle",
         "Last Name" = "Name Last",
         "Annual Salary" = "Salary (Fiscal Year Allocation)") %>%
  mutate(`Hire Date` = as.character(`Hire Date`))

df_list_uni_17[[2]] <- df_list_uni_17[[2]] %>%
  rename("Last Name" = "Last",
         "Annual Salary" = "Comp Rate") %>%
  mutate(`Hire Date` = as.character(`Hire Date`))

df_list_uni_17[[3]] <- df_list_uni_17[[3]] %>%
  rename("Annual Salary" = "Annual") %>%
  mutate(`Hire Date` = as.character(`Hire Date`))

df_list_uni_17[[4]] <- df_list_uni_17[[4]] %>%
  rename("Last Name" = "Last",
         "Annual Salary" = "Comp Rate")

df_list_uni_17[[5]] <- df_list_uni_17[[5]] %>%
  rename("Full Name" = "Name")

# Bind Rows ----------------------------------------

df_list_uni_16 <- salary_numeric(df_list_uni_16)
df_list_k12_16 <- salary_numeric(df_list_k12_16)
df_list_city_16 <- salary_numeric(df_list_city_16)

df_list_uni_17 <- salary_numeric(df_list_uni_17)
df_list_k12_17 <- salary_numeric(df_list_k12_17)
df_list_city_17 <- salary_numeric(df_list_city_17)

df_list_city_16_total <- bind_rows(df_list_city_16)
df_list_k12_16_total <- bind_rows(df_list_k12_16)
df_list_uni_16_total <- bind_rows(df_list_uni_16)

df_list_city_17_total <- bind_rows(df_list_city_17)
df_list_k12_17_total <- bind_rows(df_list_k12_17)
df_list_uni_17_total <- bind_rows(df_list_uni_17)



# Not implemented ----------------------------
# Adjust salary if hourly
df_list_city_17[[2]]$`Annual Salary` <- NA
for(i in 1:nrow(df_list_city_17[[2]])){
  if(df_list_city_17[[2]]$`Rate of Pay`[[i]] < 36000){
    df_list_city_17[[2]]$`Annual Salary`[[i]] <- df_list_city_17[[2]]$`Rate of Pay`[[i]] * df_list_city_17[[2]]$`Annual Hours`[[i]]
  }
  else{
    df_list_city_17[[2]]$`Annual Salary`[[i]] <- df_list_city_17[[2]]$`Rate of Pay`[[i]]
  }
}