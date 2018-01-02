### Nevada Salaries

URL = http://transparentnevada.com/agencies/salaries/

The site provides salaries for city, county, state, school district, special district, charter school, and higher ed employees. For convenience and clarity, there is a separate scraper for each: 

* [cityScraper.py](cityScraper.py)
* [countyScraper.py](countyScraper.py)
* [schoolScraper.py](schoolScraper.py)
* [specialScraper.py](specialScraper.py)
* [statewideScraper.py](statewideScraper.py)
* [charterScraper.py](charterScraper.py)
* [higheredScraper.py](higheredScraper.py)

The scraper merely iterates and downloads the CSVs available on the site for each section to a particular folder. And [mergeFunction.py](mergeFunction.py) merges the CSVs. 

### Running the scripts

```
pip install -r requirements.txt
python cityScraper.py
```

### Data
The final dataset with the 7 CSVs 7zipped is posted [here](../../data/nv/).
