## Maryland Public Employee Salaries

### Sources

* Data on Baltimore Public Employee Salaries from 2011 to 2017 from [https://data.baltimorecity.gov/browse?q=salaries&sortBy=relevance](https://data.baltimorecity.gov/browse?q=salaries&sortBy=relevance) 

* Data on state employee salaries from 2012 to 2016 except 2013 from [http://www.baltimoresun.com/news/data/bal-public-salaries-archive-20150415-htmlstory.html](http://www.baltimoresun.com/news/data/bal-public-salaries-archive-20150415-htmlstory.html)

* Data on 2013 Salaries from: http://data.baltimoresun.com/salaries/state/cy2013/?first-name=&last-name=&suffix=&system=&msa-code=&agency-number=&organization-name=&organization-subtitle=&class-code=&annual-salarymin=0&annual-salarymax=977955&pay-rate=&regular-earningsmin=0&regular-earningsmax=893042&overtime-earningsmin=0&overtime-earningsmax=91849&other-earningsmin=-14300&other-earningsmax=1789497&ytd-grossmin=0&ytd-grossmax=2229195

The Python script [maryland_2013_salaries.py](maryland_2013_salaries.py) that iterates through 8,478 pages and downloads the data on 127,166 records and creates [maryland_2013_salaries.csv](maryland_2013_salaries.csv). 

### Running the script

```
pip install -r requirements.txt
python maryland_2013_salaries.py
```
