## Public Sector Salaries

### Aim 

To build a comprehensive (geographic coverage, over time) database of salaries of public employees, along with relevant contextual information, for instance, average income of people living in the same area, people working in similar professions, or jobs etc.  

### Why?

A couple working as custodians for the city of Richmond, California in 2015 would have had a higher family income (before any benefits) than the median family income of the wealthiest county in California. This kind of a fact takes additional gravity given the dire financial straits Richmond, the second poorest among the hundred plus cities in the Bay Area, found itself in 2015---Moody downgraded Richmond's bond rating, costing the city millions of dollars.  

About 75%--80% of Richmond's budget goes toward personnel costs. This figure itself is not unusual across cities. And highlights the importance of investigating public employee salaries if we want to understand problems with fiscal governance at the local level.  Aside from the first order concerns, the fact that public employee unions fund council members' campaign to the tune of millions suggests other reasons to scrutinize public employee salaries. 

In all, our aim is to investigate the extent to which compensation for different public employees is fair and rational.

### Data

Data is organized by state, year, and level (area) of government. For getting a sense of what kind of data is available across states, check this [excel file](sources_for_salaries.xlsx).

* [Alabama](al/)
* [Alaska](ak/) 
* [Arizona](az/)
* [Arkansas](ar/) 
* [California](ca/)
* [Connecticut](ct/)
* [Delaware](de/)
* [District of Columbia](dc/)
* [Florida](fl/)
* [Georgia](ga/)
* [Hawaii](hi/)
* [Idaho](id/)
* [Illinois](il/)
* [Iowa](ia/)
* [Louisiana](la/)
* [Kansas](ks/)
* [Kentucky](ky/)
* [Maine](me/)
* [Massachusetts](ma/)
* [Minnesota](mn/)
* [Montana](mt/)
* [New Hampshire](nh/)
* [Nevada](nv/)
* [North Carolina](nc/)
* [New Jersey](nj/)
* [New Mexico](nm/)
* [Oregon](or/)
* [Rhode Island](ri/)
* [South Carolina](sc/)
* [Texas](tx/)
* [Tennessee](tn/)
* [Utah](ut/)
* [West Virginia](wv/)

* [Data on Highered institutions from Collegiate Times](collegiate_times/)
* Census Income Data
    - [Household Income Data by City](census/hh_income_city.csv)

### Analyses For California

* [Merge California City Level Data](scripts/01_ca_city_merge.R)
* [Merge Agg. California City Level Data with Census Income data](scripts/02_agg_ca_city_census.R)

### Authors 

Chris Muir and Gaurav Sood

#### Contribute to the project

If you see an inconsistency in the data, or have a suggestion, or some data that you would like to contribute to the project, please create a pull request or open an issue. 

### License

Analyses Released under [CC BY 2.0](https://creativecommons.org/licenses/by/2.0/). Data is released under the MIT License.
