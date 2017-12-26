import requests
from requests.adapters import HTTPAdapter
from scrapy import Selector
import csv

#--------------------define variables-------------------
OUTPUT_FILE = 'hi_2016_salaries.csv'
#-------------------------------------------------------

#--------------------define global functions------------
def makeCookieString(cookie_dic):
    return "; ".join([str(key) + "=" + str(cookie_dic[key]) for key in cookie_dic]) + ';'

# -----------------------------------------------------------------------------------------------------------------------
class HawaiiScraper:
    def __init__(self,
                 base_url='https://b4.caspio.com/dp/99302000234e9b3687404ab696c4'
                 ):
        # define session object
        self.session = requests.Session()
        self.session.mount('https://', HTTPAdapter(max_retries=4))

        # set proxy
        # self.session.proxies.update({'http': 'http://127.0.0.1:40328'})

        # define urls
        self.base_url = base_url

    def GetDepartmentlist(self):
        # set url
        url = self.base_url

        # get request
        ret = self.session.get(url)

        if ret.status_code == 200:
            options = Selector(text=ret.text).xpath('//select[@name="Value1_1"]/option').extract()

            departments = []
            for idx in range(1, len(options)):
                if options[idx] != '0':
                    department = {
                        'value': Selector(text=options[idx]).xpath('//@value').extract()[0],
                        'name': Selector(text=options[idx]).xpath('//text()').extract()[0]
                    }
                    departments.append(department)

            print(departments)
            return departments
        else:
            print('failed to get department list')
            return None

    def GetAppsessionAndPagecount(self, department_name):
        # set data
        data = {
            # 'Value1_1': 'Accounting+&+General+Services',
            'Value1_1': department_name,
            # 'Value2_1': None,
            # 'Value3_1': None,
            # 'Value4_1': None,
            # 'Value5_1': None,
            # 'Value6_1': None,
            # 'Value7_1': None,
            # 'Value8_1': None,
            'Value9_1': '2016',
            'searchID': 'Search',
            'cbUniqueFormId': '_445810a22dfbe2',
            'FieldName1': 'Department',
            'Operator1': 'OR',
            'NumCriteriaDetails1': '1',
            'ComparisonType1_1': '=',
            'MatchNull1_1': 'N',
            'FieldName2': 'District',
            'Operator2': 'OR',
            'NumCriteriaDetails2': '1',
            'ComparisonType2_1': '=',
            'MatchNull2_1': 'N',
            'FieldName3': 'Location',
            'Operator3': 'OR',
            'NumCriteriaDetails3': '1',
            'ComparisonType3_1': '=',
            'MatchNull3_1': 'N',
            'FieldName4': 'First_Name',
            'Operator4': 'OR',
            'NumCriteriaDetails4': '1',
            'ComparisonType4_1': 'LIKE',
            'MatchNull4_1': 'N',
            'FieldName5': 'Last_Name',
            'Operator5': 'OR',
            'NumCriteriaDetails5': '1',
            'ComparisonType5_1': 'LIKE',
            'MatchNull5_1': 'N',
            'FieldName6': 'Title',
            'Operator6': 'OR',
            'NumCriteriaDetails6': '1',
            'ComparisonType6_1': '=',
            'MatchNull6_1': 'N',
            'FieldName7': 'Salary_Range_Start',
            'Operator7': 'OR',
            'NumCriteriaDetails7': '1',
            'ComparisonType7_1': '>=',
            'MatchNull7_1': 'N',
            'FieldName8': 'Salary_Range_End',
            'Operator8': 'OR',
            'NumCriteriaDetails8': '1',
            'ComparisonType8_1': '<=',
            'MatchNull8_1': 'N',
            'FieldName9': 'Fiscal_Year',
            'Operator9': 'OR',
            'NumCriteriaDetails9': '1',
            'ComparisonType9_1': '=',
            'MatchNull9_1': 'N',
            'AppKey': '99302000234e9b3687404ab696c4',
            'PrevPageID': '1',
            'cbPageType': 'Search',
            'PageID': '2',
            'GlobalOperator': 'AND',
            'NumCriteria': '9',
            'Search': '1'
        }

        # set url
        url = self.base_url

        # get request
        ret = self.session.post(url, data=data)

        if ret.status_code == 200:
            href = Selector(text=ret.text).xpath('//a[@data-cb-name="SearchAgainButton"]/@href').extract()[0]
            app_session = str(href).split('?')[1].split('&')[0].split('=')[1]

            if len(Selector(text=ret.text).xpath('//span[@class="cbResultSetNavigationCell cbResultSetNavigationMessages"]/text()').extract()) > 1:
                page_count_str = Selector(text=ret.text).xpath('//span[@class="cbResultSetNavigationCell cbResultSetNavigationMessages"]/text()').extract()[1]
                page_count = int(page_count_str.encode('ascii', 'ignore').decode('ascii').split('of')[1])
            else:
                page_count = 1

            ret_val = {
                'app_session': app_session,
                'page_count': page_count
            }

            print(ret_val)
            return ret_val
        else:
            print('failed to get appsession and page count')
            return None

    def GetDataFordepartment(self, app_session, page_num):
        # set data
        data = {
            'ClientQueryString': '',
            # 'appSession': '32QE7BQW68733EVL29SZ2WHVN37331N6S0WOW7S8I4B9FM4O4BO8K96V8U7W7104X30Z89PPM29ETBI909VTJ9PR8O59J0N8W2ZK0XC84W0H95V9NIJ61G6M6RD422M0',
            'appSession': app_session,
            'cbUniqueFormId': '_445810a22dfbe2',
            'cbStyle': '',
            'siblingDataPageAppSessions': {},
            'AjaxAction': 'GetData',
            'GridMode': False,
            'cbCurrentPageSize': 100,
            'CPIPage': page_num,
            'CPIOrderBy': 'Title',
            'CPISortType': 'asc',
            'PageID': 2,
            'PrevPageID': 2
        }

        # set url
        url = self.base_url

        # get request
        ret = self.session.post(url, data=data)

        if ret.status_code == 200:
            # print(ret.json()['responseText'])
            trs = Selector(text=ret.json()['responseText']).xpath('//table[@class="cbResultSetTable cbTableDefaultCellspacing"]/tr').extract()

            for idx in range(1, len(trs)):
                tr = trs[idx]

                # get data
                data = [
                    Selector(text=tr).xpath('//td[1]/text()').extract()[0].encode('ascii', 'ignore').decode('ascii'),
                    Selector(text=tr).xpath('//td[2]/text()').extract()[0].encode('ascii', 'ignore').decode('ascii'),
                    Selector(text=tr).xpath('//td[3]/text()').extract()[0].encode('ascii', 'ignore').decode('ascii'),
                    Selector(text=tr).xpath('//td[4]/text()').extract()[0].encode('ascii', 'ignore').decode('ascii'),
                    Selector(text=tr).xpath('//td[5]/text()').extract()[0].encode('ascii', 'ignore').decode('ascii'),
                    Selector(text=tr).xpath('//td[6]/text()').extract()[0].encode('ascii', 'ignore').decode('ascii'),
                    Selector(text=tr).xpath('//td[7]/text()').extract()[0].encode('ascii', 'ignore').decode('ascii'),
                    Selector(text=tr).xpath('//td[8]/text()').extract()[0].encode('ascii', 'ignore').decode('ascii'),
                    Selector(text=tr).xpath('//td[9]/text()').extract()[0].encode('ascii', 'ignore').decode('ascii'),
                    Selector(text=tr).xpath('//td[10]/text()').extract()[0].encode('ascii', 'ignore').decode('ascii')
                ]

                # write data into output csv file
                self.WriteData(data)
        else:
            print('failed to get data for a department')
            return None

    def WriteHeader(self):
        # set headers
        header_info = []
        header_info.append('Dept')
        header_info.append('District')
        header_info.append('Location')
        header_info.append('Name')
        header_info.append('Name')
        header_info.append('Title')
        header_info.append('Salary Range')
        header_info.append('Salary Range')
        header_info.append('Year')
        header_info.append('Hrly')

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

        # get department list
        print('getting departments ...')
        departments = self.GetDepartmentlist()

        for department in departments:
            department_name = department['name']

            # get appSession and page count
            print('getting appsession and page count for %s ...' % (department_name))
            ret_val = self.GetAppsessionAndPagecount(department_name)
            page_count = ret_val['page_count']
            app_session = ret_val['app_session']

            for page_num in range(1, page_count+1):
                # get data about a department
                print('getting data for %s:%s page ...' % (department_name, page_num))
                self.GetDataFordepartment(app_session, page_num)
            #
            #     break
            #
            # break

#------------------------------------------------------- main -------------------------------------------------------
def main():
    # create scraper object
    scraper = HawaiiScraper()

    # start to scrape
    scraper.Start()

if __name__ == '__main__':
    main()
