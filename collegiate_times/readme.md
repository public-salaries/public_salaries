### Collegiate Times Salaries

URL = http://www.collegiatetimes.com/test/salaries-database/html_d0a84430-cd43-11e6-b213-d72b8da397ba.html

The [Python Script](collegiateScraper.py) iterates through the first two dropdowns to get all the years for all the schools, and then iterates through all the results to get all the available salary data. It creates a CSV a series of CSVs that take the form of school_year.csv. For instance, virginia_tech_2016.csv, virginia_tech_2015.csv, etc. The CSV has 4 columns `Name, Position, Department, Salary`

### Running the Script

```
pip install -r requirements.txt
python collegiateScraper.py
```

The final set of [7zipped CSVs](../../data/collegiate_times/collegiate_times.7z) includes data from following university--years:

1. ASU 2008
2. Christopher Newport University 2009--2011
3. George Mason University 2007--2011
4. Iowa State University 2008--2009
5. James Madison University 2008
6. Longwood University 2008--2011
7. Miami University 2008
8. Michigan State University 2009
8. Ohio State 2008--2010
9. Old Dominion 2008--2011
10. Purdue 2008
11. Radford 2008--2010
12. Rutgers 2008--2010
13. SUNY Buffalo 2008--2010
14. SUNY Stony Brook 2008--2009
15. Texas A & M 2008--2010
16. Texas Southern 2008--2010
17. Texas Tech. 2010
18. UC, Berkeley 2008
19. UC Davis 2008
19. UC Irvine 2008
19. UCLA 2008
20. UC Merced 2008
20. UC Riverside 2008
20. UCSD 2008
21. UCSF 2008
22. UCSB 2008
23. USSC 2008
24. University of Florida 2009
25. University of Illinois 2008--2009
26. University of Mary Washington 2009
27. University of Michigan, Ann Arbor 2002-2009
28. University of Michigan, Dearborn 2002--2009
29. University of Missouri, Columbia 2008--2009
29. UNC Chapel Hill 2008, 2010
29. University of Texas, Austin 2008--2010
29. University of Virginia 2008--2010
30. University of Wisconsin, Madison 2008--2009
29. Virginia Military Institute 2009
29. Virginia State University 2009--2010
30. Virginia Tech. 2007--2016
31. William and Mary 2009--2011


