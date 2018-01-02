import requests
from requests.adapters import HTTPAdapter
from scrapy import Selector
import csv

#--------------------define variables-------------------

#-------------------------------------------------------

#--------------------define global functions------------
def makeCookieString(cookie_dic):
    return "; ".join([str(key) + "=" + str(cookie_dic[key]) for key in cookie_dic]) + ';'

# -----------------------------------------------------------------------------------------------------------------------
class CollegiateScraper:
    def __init__(self,
                 base_url='http://www.database.collegemedia.com/databases/salaries/salary2.html'
                 ):
        # define session object
        self.session = requests.Session()
        self.session.mount('https://', HTTPAdapter(max_retries=4))

        # set proxy
        # self.session.proxies.update({'http': 'http://127.0.0.1:40328'})

        # define urls
        self.base_url = base_url

    def GetSchoolList(self):
        # set url
        url = self.base_url

        # get request
        ret = self.session.get(url)

        if ret.status_code == 200:
            options = Selector(text=ret.text).xpath('//select[@id="schools"]/option').extract()

            schools = []
            for idx in range(1, len(options)):
                if options[idx] != '0':
                    school = {
                        'value': Selector(text=options[idx]).xpath('//@value').extract()[0],
                        'name': Selector(text=options[idx]).xpath('//text()').extract()[0]
                    }
                    schools.append(school)

            print(schools)
            return schools
        else:
            print('failed to get school list')
            return None

    def GetSchoolData(self, school_id, school_name, year):
        # set post data
        params = {}
        params['schools'] = school_id
        params['yr'] = year
        params['fname'] = ''
        params['depart'] = ''
        params['submit_form'] = 'Submit'

        # set url
        url = self.base_url

        # get request
        ret = self.session.get(url, params=params)

        if ret.status_code == 200:
            trs = Selector(text=ret.text).xpath('//table[@id="myTable"]/tbody/tr').extract()

            if len(trs) > 0:
                # make file name
                file_name = str(school_name).lower().replace(' ', '_').replace(',', ' and').replace('&', 'and') + '_' + year + '.csv'

                # write header into output csv file
                self.WriteHeader(file_name)

                for tr in trs:
                    name = ''
                    if len(Selector(text=tr).xpath('//td[1]/text()').extract()) > 0:
                        name = Selector(text=tr).xpath('//td[1]/text()').extract()[0]

                    position = ''
                    if len(Selector(text=tr).xpath('//td[2]/text()').extract()) > 0:
                        position = Selector(text=tr).xpath('//td[2]/text()').extract()[0]

                    department = ''
                    if len(Selector(text=tr).xpath('//td[3]/text()').extract()) > 0:
                        department = Selector(text=tr).xpath('//td[3]/text()').extract()[0]

                    salary = ''
                    if len(Selector(text=tr).xpath('//td[4]/text()').extract()) > 0:
                        salary = Selector(text=tr).xpath('//td[4]/text()').extract()[0]

                    # get data
                    data = [
                        name,
                        position,
                        department,
                        salary
                    ]

                    # write data into output csv file
                    self.WriteData(data, file_name)

                return True
            else:
                print('data does not exist for ' + school_name + ':' + year)
                return None
        else:
            print('failed to get school data')
            return None

    def WriteHeader(self, file_name):
        # set headers
        header_info = []
        header_info.append('Name')
        header_info.append('Position')
        header_info.append('Department')
        header_info.append('Salary')

        # write header into output csv file
        writer = csv.writer(open(file_name, 'w'), delimiter=',', lineterminator='\n')
        writer.writerow(header_info)

    def WriteData(self, data, file_name):
        # write data into output csv file
        writer = csv.writer(open(file_name, 'a'), delimiter=',', lineterminator='\n')
        writer.writerow(data)

    def Start(self):
        # get school list
        print('getting school list ...')
        schools = self.GetSchoolList()

        for school in schools:
            school_id = school['value']
            school_name = school['name']

            year = 2016
            while True:
                year_str = str(year)
                # get school data and save it to csv file
                print('getting school data for ' + school_name + ':' + year_str)
                ret = self.GetSchoolData(school_id, school_name, year_str)

                if ret != True and year < 2005:
                    break
                year -= 1

            #     break
            # break

#------------------------------------------------------- main -------------------------------------------------------
def main():
    # create scraper object
    scraper = CollegiateScraper()

    # start to scrape
    scraper.Start()

if __name__ == '__main__':
    main()
