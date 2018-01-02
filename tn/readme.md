## Tennessee Salaries

URL = https://apps.tn.gov/salary/

The [script](tennessee.py) iterates through the search results (list of 41,352 people) and creates a CSV [tennessee.csv (7z)](../../data/tennessee.csv.7z) that has the following columns: `agency_name, last_name, first_name, job_title, compensation_rate, compensation_rate_period, full_part`.

### Running the Script

```
pip install -r requirements.txt
python tennessee.py
```

### Metadata from the web page:

    "The salary information provided is as of 8/1/2017 and is updated semi-annually."
