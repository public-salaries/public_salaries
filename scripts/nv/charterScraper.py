import requests
from requests.adapters import HTTPAdapter
from scrapy import Selector

from mergeFunction import MergeCsvFiles

#--------------------define variables-------------------
FOLDER_PATH = 'charter_school/'
OUTPUT_FILE = 'charter_school.csv'
#-------------------------------------------------------

#--------------------define global functions------------
def makeCookieString(cookie_dic):
    return "; ".join([str(key) + "=" + str(cookie_dic[key]) for key in cookie_dic]) + ';'

# -----------------------------------------------------------------------------------------------------------------------
class CharterScraper:
    def __init__(self,
                 base_url='http://transparentnevada.com',
                 home_url='http://transparentnevada.com/agencies/salaries/charter-schools/'
                 ):
        # define session object
        self.session = requests.Session()
        self.session.mount('https://', HTTPAdapter(max_retries=4))

        # set proxy
        # self.session.proxies.update({'http': 'http://127.0.0.1:40328'})

        # define urls
        self.base_url = base_url
        self.home_url = home_url

    def GetCharterList(self):
        # set url
        url = self.home_url

        # get request
        ret = self.session.get(url)

        if ret.status_code == 200:
            trs = Selector(text=ret.text).xpath('//table[@class="table table-condensed table-striped agency-list"][1]/tbody/tr').extract()

            charter_list = []
            for tr in trs:
                charter = {
                    'charter_name': Selector(text=tr).xpath('//td[1]/a/text()').extract()[0],
                    'url': self.base_url + Selector(text=tr).xpath('//td[1]/a/@href').extract()[0]
                }
                charter_list.append(charter)

            print(charter_list)
            return charter_list
        else:
            print('failed to get charter list')
            return None

    def GetCsvList(self, url):

        # get request
        ret = self.session.get(url)

        if ret.status_code == 200:
            csv_list = Selector(text=ret.text).xpath('//div[@id="view-downloads"]/p/a/@href').extract()

            print(csv_list)
            return csv_list
        else:
            print('failed to get csv list')
            return None

    def DownloadCsvFile(self, download_url):
        # set filename
        filename = str(download_url).split('/')[2]
        print(filename)

        # set url
        url = self.base_url + download_url

        # get request
        ret = self.session.get(url, stream=True)

        if ret.status_code == 200:
            with open(FOLDER_PATH + filename, 'wb') as f:
                f.write(ret.content)
            print('successfully downloaded %s' % (filename))
        else:
            print('failed to get csv information')

    def Start(self):
        # get charter list
        print('getting charter list ...')
        charter_list = self.GetCharterList()

        for charter in charter_list:
            charter_name = charter['charter_name']
            charter_url = charter['url']

            # get csv file list
            print('getting csv file list for %s ...' % (charter_name))
            csv_list = self.GetCsvList(charter_url)

            for one in csv_list:
                # download and save pdf file
                print('downloading %s ...' % (one))
                self.DownloadCsvFile(one)

            #     break
            # break

#------------------------------------------------------- main -------------------------------------------------------
def main():
    # create scraper object
    scraper = CharterScraper()

    # start to scrape
    scraper.Start()

    # merge csv files
    MergeCsvFiles(output_file=OUTPUT_FILE, folder_path=FOLDER_PATH)

if __name__ == '__main__':
    main()
