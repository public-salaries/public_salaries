## Public Sector Salaries

### Aim 

To build a comprehensive (geographic coverage, over time) database of salaries of public employees, along with relevant contextual information, for instance, average income of people living in the same area, people working in similar professions, or jobs etc.  

### Data

Data is organized by state, year, and level (area) of government. For getting a sense of what kind of data is available across states, check this [excel file](sources_for_salaries.xlsx).

* California
    - [City Employee Data](data/ca/readme.md)
        + [2009 (zip)](data/ca/2009/city.zip)
        + [2010 (zip)](data/ca/2010/city.zip)
        + [2011 (zip)](data/ca/2011/city.zip)
        + [2012 (zip)](data/ca/2012/city.zip)
        + [2013 (zip)](data/ca/2013/city.zip)
        + [2014 (zip)](data/ca/2014/city.zip)
        + [2015 (zip)](data/ca/2015/city.zip)

* Census Income Data
    - [Household Income Data by City](data/census/hh_income_city.csv)

### Analyses

* [Merge California City Level Data](scripts/01_ca_city_merge.R)
* [Merge Agg. California City Level Data with Census Income data](scripts/02_agg_ca_city_census.R)

### Authors 

Vinay Pimple, Gaurav Sood, and Daniel Trielli

### License

Analyses Released under [CC BY 2.0](https://creativecommons.org/licenses/by/2.0/). 
