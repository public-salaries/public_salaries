## Scraping 3 Sites

Deliverables for each sub project = 

1. A Python script in 'clean' style. 
2. requirements.txt
3. readme.md with instructions on how to run the script
4. CSV

### Utah Salaries

URL = https://www.utah.gov/transparency/

The [script](utah.py) iterates through the search results (a list of 78,024 people) and creates a CSV [kansas.csv (7z)](../../data/kansas.csv.7z) that has the following columns: `name, title, branch_cabinet, department, salary`.

The script [utah.py](utah.py) that iterates through all the combinations of dropdowns and creates three different CSVs based on the `type` field in dropdown: `expense.csv, revenue.csv, salaries.csv (employee compensation)`

It is easier than you think it is as the site provides big CSV files for each combination of dropdown. Say you pick the level as `cites and towns` and say you pick city `Alpine` and say you pick year `2011` and `employee compensation`. If you click on `Alpine city corporation` on the form on the left, a window on the right opens up and at the bottom is a button that says 'Download' with the Excel sign. If you click on that, all the data for Apline city for 2011 for employee compensation is there.

#### Running the script

```
pip install -r requirements.txt
python utah.py
```
