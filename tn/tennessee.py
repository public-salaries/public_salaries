import requests
from requests.adapters import HTTPAdapter
from scrapy import Selector
import csv

#--------------------define variables-------------------
OUTPUT_FILE = 'tennessee.csv'
#-------------------------------------------------------

#--------------------define global functions------------
def makeCookieString(cookie_dic):
    return "; ".join([str(key) + "=" + str(cookie_dic[key]) for key in cookie_dic]) + ';'

# -----------------------------------------------------------------------------------------------------------------------
class TennesseeScraper:
    def __init__(self,
                 base_url='https://apps.tn.gov/salary-app/search',
                 page_url='https://apps.tn.gov/salary-app/results'
                 ):
        # define session object
        self.session = requests.Session()
        self.session.mount('https://', HTTPAdapter(max_retries=4))

        # set proxy
        # self.session.proxies.update({'http': 'http://127.0.0.1:40328'})

        # define urls
        self.base_url = base_url
        self.page_url = page_url

    def SearchData(self):
        # set url
        url = self.base_url

        # get request
        ret = self.session.post(url)

        if ret.status_code == 200:
            print('success to search data')
        else:
            print('fail to search data')
            return None

    def GetPageData(self, page_num):
        # set post data
        params = {}
        params['d-16544-p'] = page_num

        # set url
        url = self.page_url

        # get request
        ret = self.session.get(url, params=params)

        if ret.status_code == 200:
            trs = Selector(text=ret.text).xpath('//table[@id="row"]/tbody/tr').extract()

            for idx in range(0, len(trs)):
                tr = trs[idx]

                # get data
                data = [
                    Selector(text=tr).xpath('//td[1]/text()').extract()[0],
                    Selector(text=tr).xpath('//td[2]/text()').extract()[0],
                    Selector(text=tr).xpath('//td[3]/text()').extract()[0],
                    Selector(text=tr).xpath('//td[4]/text()').extract()[0],
                    Selector(text=tr).xpath('//td[5]/text()').extract()[0],
                    Selector(text=tr).xpath('//td[6]/text()').extract()[0],
                    Selector(text=tr).xpath('//td[7]/text()').extract()[0]
                ]

                # write data into output csv file
                self.WriteData(data)

            return len(trs);
        else:
            print('fail to get page data')
            return None

    def WriteHeader(self):
        # set headers
        header_info = []
        header_info.append('agency_name')
        header_info.append('last_name')
        header_info.append('first_name')
        header_info.append('job_title')
        header_info.append('compensation_rate')
        header_info.append('compensation_rate_period')
        header_info.append('full_part')

        # write header into output csv file
        writer = csv.writer(open(OUTPUT_FILE, 'w'), delimiter=',', lineterminator='\n')
        writer.writerow(header_info)

    def WriteData(self, data):
        # write data into output csv file
        writer = csv.writer(open(OUTPUT_FILE, 'a'), delimiter=',', lineterminator='\n')
        writer.writerow(data)

    def Start(self):
        # write header into output csv file
        self.WriteHeader()

        # search data
        print('search data ...')
        salaries = self.SearchData()

        page_num = 1
        while(True and page_num <= 2068):
            # get page data
            print('get page data for %s page ...' % (page_num))
            data_count = self.GetPageData(page_num)
            page_num += 1

            if data_count == 0: break


#------------------------------------------------------- main -------------------------------------------------------
def main():
    # create scraper object
    scraper = TennesseeScraper()

    # start to scrape
    scraper.Start()

if __name__ == '__main__':
    main()
