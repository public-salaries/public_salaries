## Kentucky Salaries

URL = https://transparency.ky.gov/search/Pages/SalarySearch.aspx#/salary

The [script](kentucky.py) iterates through the search results (a list of 78,024 people) and creates a CSV [kansas.csv (7z)](kentucky.csv.7z) that has the following columns: `name, title, branch_cabinet, department, salary`.

### Running the Script

```
pip install -r requirements.txt
python kentucky.py
```

### Metadata from the web page:

    "Salaries displayed in the search include employees of Executive and Judicial Branch agencies as well as post-secondary educational institutions.  The Personnel Cabinet has payroll authority for salary purposes for the Executive Branch.  The data contained in this report is for informational purposes only and does not constitute an official business record. 

    Executive Branch salary data is updated on the 7th and 24th of each month.

    Salary database information is accurate as of the time stamp date provided. 

    General questions with respect to the Executive Branch salary database may be directed to the Personnel Cabinet's Public Information Office at 502-564-7430. Requests for copies of official records may be made in writing to the Custodian of Records, Personnel Cabinet, 501 High Street, Third Floor, Frankfort, KY. 40601.

    For questions regarding the Judicial Branch, please contact the Kentucky Court of Justice, Human Resources office at 502-573-2350.  

    For questions regarding universities and community and technical college salary questions, please contact the individual school."
