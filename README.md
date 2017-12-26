## Public Sector Salaries

### Aim 

To build a comprehensive (geographic coverage, over time) database of salaries of public employees, along with relevant contextual information, for instance, average income of people living in the same area, people working in similar professions, or jobs etc.  

### Why?

A couple working as custodians for the city of Richmond, California in 2015 would have had a higher family income (before any benefits) than the median family income of the wealthiest county in California. This kind of a fact takes additional gravity given the dire financial straits Richmond, the second poorest among the hundred plus cities in the Bay Area, found itself in 2015---Moody downgraded Richmond's bond rating, costing the city millions of dollars.  

About 75%--80% of Richmond's budget goes toward personnel costs. This figure itself is not unusual across cities. And highlights the importance of investigating public employee salaries if we want to understand problems with fiscal governance at the local level.  Aside from the first order concerns, the fact that public employee unions fund council members' campaign to the tune of millions suggests other reasons to scrutinize public employee salaries. 

In all, our aim is to investigate the extent to which compensation for different public employees is fair and rational.

### Data

Data is organized by state, year, and level (area) of government. For getting a sense of what kind of data is available across states, check this [excel file](sources_for_salaries.xlsx).

* [Alabama](data/al/)
* [Alaska](data/ak/) 
* [Arizona](data/az/)
* [Arkansas](data/ar/) 
* [California](data/ca/)
* [Delaware](data/de/)
* [District of Columbia](data/dc/)
* [Florida](data/fl/)
* [Georgia](data/ga/)
* [Hawaii](data/hi/)
* [Idaho](data/id/)
* [Illinois](data/il/)
* [Iowa](data/ia/)
* [Louisiana](data/la/)
* [Kansas](data/ks/)
* [Kentucky](data/ky/)
* [Maine](data/me/)
* [Massachusetts](data/ma/)
* [Minnesota](data/mn/)
* [Montana](data/mt/)
* [New Hampshire](data/nh/)
* [Nevada](data/nv/)
* [North Carolina](data/nc/)
* [New Jersey](data/nj/)
* [New Mexico](data/nm/)
* [Oregon](data/or/)
* [Rhode Island](data/ri/)
* [South Carolina](data/sc/)
* [Texas](data/tx/)
* [West Virginia](data/wv/)

* [Data on Highered institutions from Collegiate Times](data/collegiate_times/)
* Census Income Data
    - [Household Income Data by City](data/census/hh_income_city.csv)

### Analyses For California

* [Merge California City Level Data](scripts/01_ca_city_merge.R)
* [Merge Agg. California City Level Data with Census Income data](scripts/02_agg_ca_city_census.R)

### Authors 

Chris Muir and Gaurav Sood

#### Contribute to the project

If you see an inconsistency in the data, or have a suggestion, or some data that you would like to contribute to the project, please create a pull request or open an issue. 

### License

Analyses Released under [CC BY 2.0](https://creativecommons.org/licenses/by/2.0/). Data is released under the MIT License.
