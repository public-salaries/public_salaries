"
Merge City Level Data for CA

"

# Set Directory 
setwd(githubdir)
setwd("public_salaries")

# Read in all the data 

# Get list of files
files       <- list.files(path=paste0("data/ca/", 2009:2015), pattern = '.zip', full.names=T)

# Unzip and read 
tables      <- lapply(files, function(x) read.csv(unzip(x), header = TRUE))

# Merge
city_year   <- do.call(rbind , tables)

# Convert names to lower case 
names(city_year) <- tolower(names(city_year))
