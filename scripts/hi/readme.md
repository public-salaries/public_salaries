### Hawaii 2016 Salaries

URL = http://www.civilbeat.org/2016/01/civil-beat-database-of-public-employee-salaries/

The [script](hawaiiScraper.py) iterates through the department list and then iterates through the results and produces a [CSV](../../data/hi/) with the following fields: `Dept, District, Location, Name, Name.1, Title, Salary.Range, Salary.Range.1, Year, Hrly` 

### Running the script

```
pip install -r requirements.txt
python hawaiiScraper.py
```
