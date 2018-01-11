import requests
from requests.adapters import HTTPAdapter
from scrapy import Selector
import csv
import os

#--------------------define variables-------------------
OUTPUT_FILE = 'maryland_2013_salaries.csv'

START_PAGE = 0
#-------------------------------------------------------

#--------------------define global functions------------

# -----------------------------------------------------------------------------------------------------------------------
class MarylandScraper:
    def __init__(self,
                 base_url='http://data.baltimoresun.com/salaries/state/cy2013/'
                 ):
        # define session object
        self.session = requests.Session()
        self.session.mount('https://', HTTPAdapter(max_retries=4))

        # set proxy
        # self.session.proxies.update({'http': 'http://127.0.0.1:40328'})

        # define urls
        self.base_url = base_url

    def GetPageData(self, page):
        # set get data
        params = {}
        params['showvals'] = 'true'
        params['first-name'] = ''
        params['last-name'] = ''
        params['suffix'] = ''
        params['system'] = ''
        params['msa-code'] = ''
        params['agency-number'] = ''
        params['organization-name'] = ''
        params['organization-subtitle'] = ''
        params['class-code'] = ''
        params['annual-salarymin'] = '0'
        params['annual-salarymax'] = '977955'
        params['pay-rate'] = ''
        params['regular-earningsmin'] = '0'
        params['regular-earningsmax'] = '893042'
        params['overtime-earningsmin'] = '0'
        params['overtime-earningsmax'] = '91849'
        params['other-earningsmin'] = '-14300'
        params['other-earningsmax'] = '1789497'
        params['ytd-grossmin'] = '0'
        params['ytd-grossmax'] = '2229195'
        params['page'] = page

        # set url
        url = self.base_url


        # get request
        ret = self.session.post(url, params=params)

        if ret.status_code == 200:
            trs = Selector(text=ret.text).xpath('//table[@id="dbresults"]/tbody/tr').extract()

            for tr in trs:
                tds = Selector(text=tr).xpath('//td/span/text()').extract()

                # get data
                data = [
                    tds[0],
                    tds[1],
                    tds[2],
                    tds[3],
                    tds[4],
                    tds[5],
                    tds[6]
                ]

                # write data into output csv file
                self.WriteData(data)
        else:
            print('fail to get page data')

    def WriteHeader(self):
        # set headers
        header_info = []
        header_info.append('First Name')
        header_info.append('Last name')
        header_info.append('Suffix')
        header_info.append('Organization title')
        header_info.append('Salary/pay scale*')
        header_info.append('Date of hire (EOD)')
        header_info.append('YTD gross compensation**')

        # write header into output csv file
        writer = csv.writer(open(OUTPUT_FILE, 'w'), delimiter=',', lineterminator='\n')
        writer.writerow(header_info)

    def WriteData(self, data):
        # write data into output csv file
        writer = csv.writer(open(OUTPUT_FILE, 'a'), delimiter=',', lineterminator='\n')
        writer.writerow(data)

    def Start(self):
        # write header into output csv file
        if START_PAGE == 0: self.WriteHeader()

        for page in range(START_PAGE, 8479):
            # get data and save it into csv file
            print('getting data for %s page ...' % (page))
            self.GetPageData(page)

#------------------------------------------------------- main -------------------------------------------------------
def main():
    # create scraper object
    scraper = MarylandScraper()

    # start to scrape
    scraper.Start()

if __name__ == '__main__':
    main()
