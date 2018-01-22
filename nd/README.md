## North Dakota Public Employee Salaries

* State Employee Salaries from 2018--2018 from [http://data.share.nd.gov/pr/Pages/home.aspx](http://data.share.nd.gov/pr/Pages/home.aspx)

The python script [nd_salaries.py](nd_salaries.py) iterates through agency names, and downloads the corresponding CSVs. It also tidies up the CSV. When the title is the same, the rows right below it are empty. Same for the employee identifier. The script fills both appropriately.

```
    Job Title, Position, Employee Identifier            Fiscal Year 2018    Total Biennium
    ACCOUNT TECHNICIAN II           CL0212      1BE85BD943  17230   17230
            9B52F2E4F5  18325   18325
            F8F57DBE0F  19430   19430
    ACCOUNT/BUDGET SPEC III         CL0223      E9DF99C3F3  22500   22500
    ACCOUNTING MANAGER I            CL0224      4F0A8AC156  38720   38720
    ACCOUNTING MANAGER II           CL0225      550C68340C  46495   46495
    ADMIN ASSISTANT I               CL0041      32F074FA0A  14775   14775

```

### Running the scripts

The script downloads the CSVs in a folder called `csvs` in the local directory.
To run the script:

```
pip install -r requirements.txt
python nd_salaries.py
```

[nd.R](nd.R) merges the CSVs, and appends the agency name.

## Notes About Data

1. It doesn't provide employee names but does provide unique IDs that allow you to merge across years.

2. The script downloads more data than is made available publicly via the website!

