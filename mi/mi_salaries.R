# Michigan Salaries

setwd(githubdir)
setwd("public_salaries/")

library(rvest)

# State

results <- read_html("https://www.mackinac.org/salaries?report=state&sort=wage2016-desc&page=1")
res_tab <- html_table(results, fill = T)[[1]]
res_tab <- res_tab[-1, -6]

for (i in 2:1204) {

  results  <- read_html(paste0("https://www.mackinac.org/salaries?report=state&sort=wage2016-desc&page=", i))
  temp_tab <- html_table(results, fill = T)[[1]]
  temp_tab <- temp_tab[-1, -6]
  res_tab  <- rbind(res_tab, temp_tab)
}

# Fix the header row
names(res_tab)[5] <- "2016 Wage"

write.csv(res_tab, file = "mi/mi_state_salaries.csv", row.names = F)

# Education

results <- read_html("https://www.mackinac.org/salaries?report=education&sort=wage2016-desc&page=1")
res_tab <- html_table(results, fill = T)[[1]]
res_tab <- res_tab[-1, ]

for (i in 2:12192) {

  results  <- read_html(paste0("https://www.mackinac.org/salaries?report=education&sort=wage2016-desc&page=", i))
  temp_tab <- html_table(results, fill = T)[[1]]
  temp_tab <- temp_tab[-1, ]
  res_tab  <- rbind(res_tab, temp_tab)
}

# Fix the header row
names(res_tab)[5] <- "2016 Wage"

write.csv(res_tab, file = "mi/mi_educ_salaries.csv", row.names = F)

# Judges

results <- read_html("https://www.mackinac.org/salaries?report=judges&sort=wage2016-desc&page=1")
res_tab <- html_table(results, fill = T)[[1]]
res_tab <- res_tab[-1, ]

for (i in 2:3) {

  results  <- read_html(paste0("https://www.mackinac.org/salaries?report=judges&sort=wage2016-desc&page=", i))
  temp_tab <- html_table(results, fill = T)[[1]]
  temp_tab <- temp_tab[-1, ]
  res_tab  <- rbind(res_tab, temp_tab)
}

write.csv(res_tab, file = "mi/mi_judicial_salaries.csv", row.names = F)
