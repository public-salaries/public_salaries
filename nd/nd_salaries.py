import requests
from requests.adapters import HTTPAdapter
from scrapy import Selector
import csv
import os
import json

#--------------------define variables-------------------
OUTPUT_FILE = 'nd_salaries.csv'
START_AGENCY = 'Williston State College'
#-------------------------------------------------------

#--------------------define global functions------------

# -----------------------------------------------------------------------------------------------------------------------
class NDScraper:
    def __init__(self,
                 base_url='http://cognospubrep.nd.gov/cognos/cgi-bin/cognos.cgi'
                 ):
        # define session object
        self.session = requests.Session()
        self.session.mount('https://', HTTPAdapter(max_retries=4))

        # set proxy
        # self.session.proxies.update({'http': 'http://127.0.0.1:40328'})

        # define urls
        self.base_url = base_url

        # set headers
        # self.SetHeaders()

    def SetHeaders(self):
        headers = {
            'Accept': '*/*',
            'Accept-Encoding': 'gzip, deflate',
            'Accept-Language': 'en-US,en;q=0.9',
            'Connection': 'keep-alive',
            'Content-Type': 'application/x-www-form-urlencoded',
            'Cookie': 'userCapabilities=3%3B0%3B3c0008%3B400f8%26AgcAAABTSEEtMjU2FAAAAAvwXxg8oMdJ%2Fbq5dn59%2FKnrnmtA49FcE2%2F2q4f9%2B2uo7VrhnmvD4%2BBMbbtY7Ea3Z2mIjW8%3D; viewer_session=uig:|e_hp:CAMID(*22*3a*3aAnonymous*22)|e_user:Anonymous|show_logon:true|pp:4041805287; cea-ssa=false; usersessionid=AggAAADOPmlaAAAAAAoAAACZrAB/3qaBBoChFAAAAAvwXxg8oMdJ/bq5dn59/KnrnmtABwAAAFNIQS0yNTYgAAAA6A+8HttJAGoTGgaW1ICNGPj1EbuUPTDTtyoRjiyzImY=; cam_passport=MTsxMTA6ODk1OGFmNzYtYjM2Ny1iYmQ0LTQxMjQtNzlhYjllY2Y4MGE2OjM3OTI2NTU5MzQ7MDszOzE7; CRN=listViewSeparator%3Dnone%26showHiddenObjects%3Dfalse%26showWelcomePage%3Dfalse%26displayMode%3Dlist%26productLocale%3Den%26showOptionSummary%3Dtrue%26format%3DHTML%26skin%3Dcorporate%26contentLocale%3Den-us%26automaticPageRefresh%3D30%26useAccessibilityFeatures%3Dfalse%26linesPerPage%3D100%26http%3A%2F%2Fdeveloper.cognos.com%2Fceba%2Fconstants%2FbiDirectionalOptionEnum%23biDirectionalFeaturesEnabled%3Dfalse%26timeZoneID%3DCST%26columnsPerPage%3D3%26; cc_session=s_cc:|s_conf:na|s_sch:td|s_hd:sa|s_serv:na|s_disp:na|s_set:|s_dep:na|s_dir:na|s_sms:dd|s_ct:sa|s_cs:sa|s_so:sa|e_hp:CAMID(*22*3a*3aAnonymous*22)|e_proot:Public*20Folders|prootid:i2CF70D8C57BE4B6CB07A709859FEE024|e_mroot:My*20Folders|mrootid:iE5A7B7BC9BC94395B67856E8EC5555A6|e_mrootpath:CAMID(*22*3a*3aAnonymous*22)*2ffolder*5b*40name*3d*27My*20Folders*27*5d|e_user:Anonymous|e_tenantID:|e_tenantDisplayName:|e_showTenantInfo:false|e_isSysAdmin:false|e_isTenantAdmin:false|e_isImpersonating:false|cl:en-us|dcid:i2CF70D8C57BE4B6CB07A709859FEE024|show_logon:true|uig:|ui:|rsuiprofile:|lch:f|lca:f|ci:f|write:false|eom:0|pp:3792655934; caf=CAFW000001f8Q0FGQTYwMDAwMDAxMGFBaFFBQUFBTDhGOFlQS0RIU2YyNnVYWipmZnlwNjU1clFBY0FBQUJUU0VFdE1qVTJJQUFBQVBsckh0QXZIekVPZXBwNFp5WFFzUDZaR0JWYUdjQ1ZmWENGWTh6clZ5SmI0MjExNzh8MTEwOjg5NThhZjc2LWIzNjctYmJkNC00MTI0LTc5YWI5ZWNmODBhNjowOTIwMjkwOTc0fDExMDo4OTU4YWY3Ni1iMzY3LWJiZDQtNDEyNC03OWFiOWVjZjgwYTY6MTE5MTA2NzI4MHwxMTA6ODk1OGFmNzYtYjM2Ny1iYmQ0LTQxMjQtNzlhYjllY2Y4MGE2OjIyMjc4MTg4Nzh8MTEwOjg5NThhZjc2LWIzNjctYmJkNC00MTI0LTc5YWI5ZWNmODBhNjo0MDQxODA1Mjg3fDExMDo4OTU4YWY3Ni1iMzY3LWJiZDQtNDEyNC03OWFiOWVjZjgwYTY6Mzc5MjY1NTkzNA__; _ga=GA1.2.320947741.1516079446; _gid=GA1.2.1912957867.1516241993',
            'Host': 'cognospubrep.nd.gov',
            'Origin': 'http://cognospubrep.nd.gov',
            # 'Proxy-Connection': 'keep-alive',
            'Referer': 'http://cognospubrep.nd.gov/cognos/cgi-bin/cognos.cgi',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36'
            # 'X-Requested-With': 'XMLHttpRequest'
        }
        self.session.headers = headers

    def GetBienniumList(self):
        return [
            '17-19',
            '15-17',
            '13-15',
            '11-13',
            '09-11',
            '07-09'
        ]

    def GetAgencyList(self):
        # set get data
        params = {}
        params['b_action'] = 'cognosViewer'
        params['ui.action'] = 'run'
        params['ui.object'] = 'storeID("iB263D43A441F4F9CB7FCE6F97A6E9727")'
        params['ui.name'] = 'Payroll - By Business Unit'
        params['run.outputFormat'] = ''
        params['run.prompt'] = 'true'
        params['cv.header'] = 'false'
        params['cv.toolbar'] = 'false'
        params['ui.backURL'] = 'http://cognospubrep.nd.gov:80/Cognos/cps4/portlets/common/close.html'
        params['m_session'] = '_CPSID_8D57CBA494F44C52273DF3E9F153EDE9'
        params['m_sessionConv'] = '_CPSID_8D57CBA494F44C52273DF3E9F153EDE9'

        # set url
        url = self.base_url

        # get request
        ret = self.session.post(url, data=params)

        if ret.status_code == 200:
            # get form data for agency
            scripts = Selector(text=ret.text).xpath('//script').extract()
            for script in scripts:
                if 'oCV.initViewer(' in script:
                    temp = str(script).split('oCV.initViewer(')[1].split(');')[0]
                    self.agency_form_data = json.loads(temp)
            # print(self.agency_form_data)

            # get agency list
            spans = Selector(text=ret.text).xpath('//table[@id="rt_NS_"]/tr/td/table/tr/td[1]/span').extract()

            agency_list = []
            for idx in range(1, len(spans) - 1):
                span = spans[idx]
                name = Selector(text=span).xpath('//span/text()').extract()[0]
                temp = Selector(text=span).xpath('//@dttargets').extract()[0]
                temp = str(temp).split(' ' + name)[0].split('displayValue=\\"')
                id = temp[len(temp)-1]
                agency = {
                    'name': name,
                    'id': id
                }

                agency_list.append(agency)
            print(agency_list)

            return agency_list
        else:
            print('fail to get agency list')

    def GetNorthDakotaData(self, agency, biennium):
        if biennium == '17-19':
            # params = {}
            # params['authoredDrill.request'] = '<authoredDrillRequest><param name="action">default</param><param name="target">/content/folder[@name=&apos;Public Reporting&apos;]/folder[@name=&apos;Web Reports&apos;]/report[@name=&apos;Payroll - By Business Unit - Position and Level 3&apos;]</param><param name="format">HTMLFragment</param><param name="locale">en-us</param><param name="prompt">false</param><param name="dynamicDrill">false</param><param name="sourceTracking">CAFS6000000174AhQAAAAL8F8YPKDHSf26uXZ*ffyp655rQAcAAABTSEEtMjU2IAAAAH*mkg6x6frFSrC4PDvWvVlCFa4oLGhi-i1WNan1oejIH4sIAAAAAAAAAHWRPW*DMBBA5-ZXVOzF4FCJIMLSSlGlMmXpSvAFG4GNfJcA-75OHEW0ol4s*d67L*fHM2a10RewWJEy*t1ogolepr7TmLnoLpBEQ8aYgAt0ZgAb1qbRBt3VM6wl9BWyo3Io27DgLk6oHuI4juG4CY1tGI*imH2XX4eb9qo0UqVrcBaqjOYBdsE-DQXF89P15Nd4dToprWg*kAXdkFzoE2ZKO-otiqKcrcHLREr8VpGs0k1QdPt5L*eRd1zybSKFaPm2a8uEl5jOPG05L3kquPQVlFjm1EbA58d63tgLHllKgzU1IP71bqPEPLmP8qCWqlshnXG9nvuioQMCr3vSu-5lZdHFD0iJtMsTAgAA</param><param name="source">/content/folder[@name=&apos;Public Reporting&apos;]/folder[@name=&apos;Web Reports&apos;]/report[@name=&apos;Payroll - By Business Unit&apos;]</param><param name="metadataModel">/content/folder[@name=&apos;Public Reporting&apos;]/package[@name=&apos;PR_Cube&apos;]/model[@name=&apos;2011-03-11T22:25:19.533Z&apos;]</param><param name="selectionContext">&lt;s:selection rModel=&quot;MP_0&quot; xmlns:s=&quot;http://developer.cognos.com/schemas/selection/1/&quot; xmlns:xml=&quot;http://www.w3.org/XML/1998/namespace&quot;&gt;&lt;s:metadataCells&gt;&lt;/s:metadataCells&gt;&lt;s:cells&gt;&lt;/s:cells&gt;&lt;s:strings&gt;&lt;s:s xml:id=&quot;MP_0&quot;&gt;/content/folder[@name=&amp;apos;Public Reporting&amp;apos;]/package[@name=&amp;apos;PR_Cube&amp;apos;]/model[@name=&amp;apos;2011-03-11T22:25:19.533Z&amp;apos;]&lt;/s:s&gt;&lt;/s:strings&gt;&lt;/s:selection&gt;</param><param name="source">/content/folder[@name=&apos;Public Reporting&apos;]/folder[@name=&apos;Web Reports&apos;]/report[@name=&apos;Payroll - By Business Unit&apos;]</param><param name="sourceContext">&lt;bus:parameters xmlns:bus=&quot;http://developer.cognos.com/schemas/bibus/3/&quot; xmlns:xsi=&quot;http://www.w3.org/2001/XMLSchema-instance&quot; xmlns:SOAP-ENC=&quot;http://schemas.xmlsoap.org/soap/encoding/&quot; xsi:type=&quot;SOAP-ENC:Array&quot; SOAP-ENC:arrayType=&quot;bus:baseParameter[3]&quot;&gt;&lt;item xsi:type=&quot;bus:parameter&quot;&gt;&lt;bus:name xsi:type=&quot;xs:string&quot;&gt;pBiennium&lt;/bus:name&gt;&lt;bus:type xsi:type=&quot;bus:parameterDataTypeEnum&quot;&gt;memberUniqueName&lt;/bus:type&gt;&lt;/item&gt;&lt;item xsi:type=&quot;bus:parameter&quot;&gt;&lt;bus:name xsi:type=&quot;xs:string&quot;&gt;pBusinessUnit&lt;/bus:name&gt;&lt;bus:type xsi:type=&quot;bus:parameterDataTypeEnum&quot;&gt;memberUniqueName&lt;/bus:type&gt;&lt;/item&gt;&lt;item xsi:type=&quot;bus:parameter&quot;&gt;&lt;bus:name xsi:type=&quot;xs:string&quot;&gt;pBusinessUnitShortName&lt;/bus:name&gt;&lt;bus:type xsi:type=&quot;bus:parameterDataTypeEnum&quot;&gt;xsdString&lt;/bus:type&gt;&lt;/item&gt;&lt;/bus:parameters&gt;</param><param name="objectPaths">&lt;bus:objectPaths xmlns:bus=&quot;http://developer.cognos.com/schemas/bibus/3/&quot; xmlns:xsi=&quot;http://www.w3.org/2001/XMLSchema-instance&quot; xmlns:SOAP-ENC=&quot;http://schemas.xmlsoap.org/soap/encoding/&quot; xsi:type=&quot;SOAP-ENC:Array&quot; SOAP-ENC:arrayType=&quot;bus:searchPathSingleObject[4]&quot;&gt;&lt;item xsi:type=&quot;bus:searchPathSingleObject&quot;&gt;storeID(&quot;i8EDD623D1E0640A3BEFADCB78405DFC7&quot;)&lt;/item&gt;&lt;item xsi:type=&quot;bus:searchPathSingleObject&quot;&gt;storeID(&quot;i7886F2E83E0F43EE9DF4D47CA62F5E2A&quot;)/model[last()]&lt;/item&gt;&lt;item xsi:type=&quot;bus:searchPathSingleObject&quot;&gt;/content/folder[@name=&apos;Public Reporting&apos;]/package[@name=&apos;PR_Cube&apos;]/model[@name=&apos;2011-03-11T22:25:19.533Z&apos;]&lt;/item&gt;&lt;item xsi:type=&quot;bus:searchPathSingleObject&quot;&gt;/content/folder[@name=&apos;Public Reporting&apos;]/package[@name=&apos;PR_Cube&apos;]/model[last()]&lt;/item&gt;&lt;/bus:objectPaths&gt;</param><drillParameters><param name="p_pBusinessUnit">&lt;selectChoices propertyToPass=&quot;businessKey&quot;&gt;&lt;selectOption useValue=&quot;[PR_Cube].[All Business Units].[All Business Units].[PR Business Unit]-&amp;gt;:[PC].[@MEMBER].[32500]&quot; displayValue=&quot;32500 Human Services&quot;/&gt;&lt;/selectChoices&gt;</param><param name="p_pBusinessUnitShortName">&lt;selectChoices&gt;&lt;selectOption useValue=&quot;[PR_Cube].[All Business Units].[All Business Units].[PR Business Unit]-&amp;gt;:[PC].[@MEMBER].[32500]&quot; mun=&quot;[PR_Cube].[All Business Units].[All Business Units].[PR Business Unit]-&amp;gt;:[PC].[@MEMBER].[32500]&quot; displayValue=&quot;Human Services&quot;/&gt;&lt;/selectChoices&gt;</param></drillParameters><param name="executionParameters">CAFS6000000164AhQAAAAL8F8YPKDHSf26uXZ*ffyp655rQAcAAABTSEEtMjU2IAAAAKJyq6ntbPjruV4uQglhTN*Z7fniPF-xoCnLDJTYkhlYH4sIAAAAAAAAAH2Ry2rDMBBF1*lXFO3jcZqdcAxpySLQF6SUQshCcQZHYD3QyLHz95VdW00IRBtJM-feOULZviZuhRMKPTp6bFWliYfigh29txzggCesjEWXFKbUhsKmgIojKkGwl0EKc2CDsSUZjU3TJM08Ma6EpzSdwc-b66a3TaUmL3SBwUWS*7PFBdt8LD*nq-cXvnROnMe8sRpDh8FJaJMRtk-vDoC6MAepy4ASo0QX9dXHXz3zW1Q1bmc7lj9M*pVJj*oC5lYdpZOsa*rQutC3xMm7MJ3l9lmi1rJWGYzCa*upi7vz8Dv0qkdZB9ZtumMQ6aHDH25-Y-9-NP8FzM7gueIBAAA_</param></authoredDrillRequest>'
            # params['ui.action'] = 'authoredDrillThrough2'
            # params['b_action'] = 'cognosViewer'
            # params['cv.id'] = '_NS_'
            # params['cv.header'] = 'false'
            # params['cv.toolbar'] = 'false'
            # params['ui.backURL'] = 'http://cognospubrep.nd.gov:80/Cognos/cps4/portlets/common/close.html'
            # params['ui.routingServerGroup'] = ''
            # params['cv.previousReports'] = '<previousReports><previousReport><param name="ui.action">currentPage</param><param name="ui.conversation">CAFS6000000ac0AhQAAAAL8F8YPKDHSf26uXZ*ffyp655rQAcAAABTSEEtMjU2IAAAABNHd*udSFKhWVoqunJZWvtnTftNOtCQBG1f7UtqkM2gH4sIAAAAAAAAANVZaXPbOBL9nP0VM56ayW65Yt6XJ0ktT0m2Duq0rFTKBZKgRJsEKRLU4V*-oCgpkuM4lpw4s-xiFdndeP3QaHS33zt5dp6kQQTSZQdOc5jh3xZRiLJz8uHDyQTj5JyiPDiDYZzA9MyNxyjOyJ*IytwJjEBGOQERpTjqZK24yIKt4nw*P5tzZ3E6pliaZqhho95dqb0LUIYBciHRyoJzvEzgh5MCC8iWyJ2soZx8-Neb4nlffEEggjvCi*w8w2mAxicf0xy9pzYiuyqxcwtdbAM8ebBKBkHqTooPXWIhhK2V4MnHDMcprBn-Pgk0VuQMnlN5nrF4S9E1ydJN0VIkVTQViZVO-lMu*WWJvYUTHMQo21m121Ltd2ZTP1fTFCw3XG3ebglbk3pGPmcxSFbMFT8oiNzYI1gJzVtToDDV2zpVLvqJkT9veHvzPsAweuA7Yau1ktTiOIQAbYUfpXlPw0R5ROiGOE9RK8dJjq8mEKkzEITACeFXm7A2OQNh-mDrnM3aOM3XeiupLXCqQP6UG2WglLhqCH-fi12F0pF13F*BAPcmKcwmcegd4ENQrModBX4MEUwDtwRDDoVZ7C70yK*n-dgJ*qeOpgsdQLnx6ojhrPiFIcINgMAYpjogMfaFhj9WXxf4uY4X70h07iJeQwmwRzCQhZLcOUPe2TienSscTVMJm3hUBtNZCDHlBVkCsDu5ufn9zz9-v7lJYRKnuJ3DdLl5dcgp3OgwPC-KvMg7EuM60HFlqPDAk12ec10eACADRnZERnBoGgIaQgYCwXVkj-c4DvKssrGTAPeOsLSHZ0Mg5ZMAgemn-xYsfXhr504YuL91Vg6QPXn7mVprbyU6N3ruwLefN5ZY0ecd15Mk2Ye0wjMMKzgSVIAPOQaKLA*gL7Ec5wORAAaCxAg*4-AcLQOHd2iF2dgBrhvnaJ81hhUFnpNkVtq88ThWUHgIgcfSvisyriC6HlRkiXMUSWEdh1VoGijQc3xPdjxHkRXgSZBTWAA4GgobO0eF*DZplImCxAtIsjwExauDU078tY1D4vUR9dIuitFx2WeLr7s6jmVSP84rK04j8Ozj9-Aeeewy2GaJT8yXq*BrP3aSSbXXqFspGEckyvedf-MyeprEoUGhexxDiyy0QUrEMEyzH0nRxtIK2yfpKZr2RHfkvpeg9UFZVXSg-wjyb18rG-15gLx4fhbrg0e24OEm-DjYc*h04vixePw*ZKq8g14Vrz7o6j*K6K7*qtD7GdQNtad2CfiiXDwK-TcKqJ9I*GqPBwGcw7RmHIX5ptl97FL5eZiLL6TscGHtsQLvHwiYhIaVh6GdRliPoyQI4XHAfRBmzwqPF9fg5rpBOaYQBxiTorS4fDZWDrndN61RaatRa5gvdubZrdEjvoRzsMxqyA1zD9p7nfWr9kfbm1RFy36ndszV2*-UD4C87cZnZ0T3ZZiPbU2TlByW-y*eyyKwHrsHVbXHNYIEPelVSECWF*Zm0S9tIMLdovd6eU-7HDJ*RjObBWMEcJ4eMovYgKBZhqfLR7NowWJkTldpXeIVy9BUTZFEyZQMS1cVU1NMUSPCUikucLzMM6zBsZzAiezaCCcJNOl-SddqaoIp6oal6ZZimhIr6IxOc7woiZol6CrPcYaoqIZgqZyl8bpOOl6WFn7NEcpgWJYjGsigZ8EVm8*uvXeP1LfungOceNZg54EDM0i6cReEZgiLG*UQ6KuJDkv-GuKBNysGol7ZL-8iwo8GH4bxXEUoxuBbpexrwK8DNM5JXnhJP15kxefPMn9OPw7Ruzz7ERXaXlJ*1uYel5WdwAjSMm*AcCcf773fJBMTFdPiQ0ath8XIejJfzuB3x-LJdpbwupP57brluIF5ekC-L-3s3Uq0ACIU5NGPnpMQPNEKSo1g-UR-PqGeYP0LxbvEZwl0Az8oy43X5b6s0Lu7AHZ9KOGRrAUNgMHTc*6-Qvz3VvSvMf67ymc1df1QwqArsTOnoRnKgOokp6OOdUGFVb9yNU8q3PW1xRicUb-WzVYnFXmWpWp3V-3Z6Slroro3q9Z6QQueUnk1P71Th9rQSRh8ymnDfDm*G6TglunoMAX21KgsBj2fb-drtln1h1eT0YXbvEgqMJINz63Eo2nugiBqn4oLIAdcNbps2AyuVitLOYzSYU0w6WBA3*kR2*kNL6n7e3*AcYCWg*HIEfSLqtGuJ5WLe3HUmgGv2s-6Vt9Pm*JUthbLW-WKxdOLqGrJer1amTg9Px-e3o*SoM5JQxZdoZhj52J1EU1YK5qKMB35iplSA*NKaSDHT3nXuPdBHUCtfjXU1dbIux*r7oSLbh22JVwmF65J0kUSWgo6nY9dCZpVsWdM5bER2HxP7lITfTKfTUdUbkVSfThCgyWO0DW6ZGzHINWbUOWkunl-7Yyq9bYmjZg07N3OxOZItesC0BYN50oRWqcTpmnbKXbrZo2t9Uipd32PL26NKru0k1rHmGoXrO132u4ll3Tbi*YluAvsnqV0G9r8VrWcVrPB3Ppsk-KKfy4s6knXTjXcak-a-fGky*P*aFa7zKIlPR3YHabZYpfd0Xiut6WObJrCMrRPjcverU0xQqaaPD2-DFELWplxL2lXvbvsTl6y-Up3yaNK5CEYSHbaUyv*uBqYMy7uTf0L9bJWuQ0FK58ous13rmNr5E27l3gxPW36c33e6Ckdvd0gUfnhQxG01F7Ulgd1*6o8COvTu9evfvwf33q7dR4eAAA_</param><param name="m_tracking">CAFS6000000178AhQAAAAL8F8YPKDHSf26uXZ*ffyp655rQAcAAABTSEEtMjU2IAAAAHOv0i-0D8eKoccFfCDMU66OTs6Hx0-sy4Y8zvPPsDTdH4sIAAAAAAAAAHWRO2*DMBCA5-ZXVOzFQKhEEGFJpKhSmbJ0JfiCjcBGvguPf18njiJaUS*WfN93L2fnK6aVVgMYLElqtdeKYKK3qWsVpja68wRRnzLGYYBW92D8StdKo706hpWArkR2lhZlG*Y9xAnlUxzH0R83vjY1i4IgZN-F1*muvUuFVKoKrIUypbmHnfdPQ17**nI72S1eXi5SSZpPZEDVJBb6hKlUlv4IgiBja-AykeS-VSQjVe3lRXvkTSMwntto27Tz-hgLjqJIkqIYkhkF347zNhKuguTLnEpz*Dys5w2d4JCl1BtdAeJf7z5KGMWPUZ7UUrUrpCuu17Nf1LdA4HRHOte9rCw6-wF81f3aEwIAAA__</param><param name="run.outputFormat">HTML</param><param name="ui.object">storeID("iB263D43A441F4F9CB7FCE6F97A6E9727")</param><param name="ui.primaryAction">run</param><param name="ui.name">Payroll - By Business Unit</param></previousReport><previousReport><param name="ui.action">currentPage</param><param name="ui.conversation">CAFS6000000b70AhQAAAAL8F8YPKDHSf26uXZ*ffyp655rQAcAAABTSEEtMjU2IAAAAMAYDclP5jx347np1Q0C1ykMC*puIH0FqvAH-hq9AlvmH4sIAAAAAAAAAO1ZW3PayBJ*3vMrWJ-azQMV644kb*I6EpIwGGzMzSapVGokjcSANBIaiYt--RkhwOA4jo0dJw*rF6iZ7tbX-fXMdI8*2Bk5iRMUgmTZgdMMkrS0CANMTujEx6NRmsYnDOPCGQyiGCbHTuTjiNCfkCHOCIaAMDaioozAHK0VFwRtFefz*fFcOI4Sn*FZlmNuWs3uSu09wiQF2IFUi6CTdBnDj0c5FkCW2BmtoRyd-ueP-PmQz2AQwh3hBTkhaYKwf3SaZPgDsxHZVYnsMXTSNkhH995CIEicUT7RpRYCeLkSPDplnAinEKeMFwUuTD7-L7f48V07swPklDowjpKUKrz7ck-gGtrrWULnktW-rTJYJlEQlN6X9GVJzwjCkJBSH6OUDrUjglIU4RLAbqmZh7kkvPtSeHOHfs*nOJcnOw51L7X2e-OieqIlCVhuaNiMbrlY83VMp0kE4hUp*R8GYidyqVeUwa0pkJvqbeNVvPQzp3zZUPLHB5TC8F5YKRGXK0k9igII8Fb4QQb3NEychZRJmGYJvszSOEuvRxBrM4ACYAfwG37XJmcgyO5lhb15d5pka72V1BY4kyN-khvdVYIVYX2uK9HKCStKQpA*Ff19Jh*iY5v3n7k7Mr71Y2d5nPVaTSsBfkgTe9-5Pw4KT7FEn0n0rlIRIBDMwZLUsRNkLmzvbUFvyvY*smIpHORPmgJnlAd5Y*WpbuRjm0VY2GrVW*ZBzvgQwwQ5BS4NL-ud*uO*7OTJY5u9A22Qb475pp2SzTbZAhj4MKlSv*FdKP5LkI8BXcjPWbUbECzPiWzx6BYrWZwiVDW2KouqZeiarsoV2ZQNq6qppq6aFZ0Ky4W4JIiKyPGGwAuSUOHXRriKYihU0uIqpsUbPCeZQqUiiZKuCbpqsGZVobKWYXFVrWqoklyxeEGQTE43NEXSD2NhNznqOD0km9Zn8jVAaW*UQDKi580zwonytwovTyF6YK*yGbr039tn0mp28eT9IB*jx9su4jUUlLoUA31RnNnH2D32o9mJKrAsE-OxyxCYzAKYMi4iMUid0devf-71159fvxYH*VUGk*Vm6DepEDZwJBHwPBQkF6rAE2jqq7ZbAbYtcIrHQ55zZFH2RLbiVFRRUgUqLHCcXfFEm3dslWU3dmLgTCgBB7q61v6eRMkAKaDZnN7hhhLLOy5ne1CsCBSqw7GqokAKTuB4INsuKwiyLLsiFGVFVCSOr6iSyEnQViVB5re4geNEGd6niMpKoiArvLwZsW3gAKhAp8LxKuA9zxZt1*YUW6qoHuBtyeUkx4a2J3EVR5EqEpAqsiOrDiurrAvBxs7LqomirKHJCWKSBSAfOrCq2LPxnMXxgHphF0f4hbXSBQUwyHUPK5cWJGiDhIqlMCGvWS9tLK2wfZYfq5n2RHfkfrTdVQdF-9CB3gPIf3zmzRF2o-lxVB08QMF9El4P9hzanSh6aHP9MWSm2NHfFG910K2*VqC71TeF3iewamg9rUvB593bQei-U*H*xICvOB4gOIdJ3TgI89eL7kO75s-DnM-QQ9yB9YfKpd8QME0NKwuCdhKm1SiMUQAPA*6BgDwpPV62zTcB9jN61r*kKW5GDnh6S-9zmmKI32fkVSPzlG7r4YOv32ke0Ckls2Oq*zLMh97TxAlN1YPa9O*l6c8P9F3uPadqOqyroehp7Uv7t*K82ry06I5pswETiy707pJQwV-DIIFBcRbpgEDXgqt*-cmF1ysz*qQe*Z4DNIYpovuIGcD8zuU50FfNMc-*msADd5bfe7tFN-CLAn4w*CCI5hrGUQq*V8f8RPh7NxNPcuGw1WsjAyXF6gDBzm3E3vhmyZg4v59*zt3M8yKx-hZQ3PrvfgiIt*3S234L2L636KiExz8J7Es-ma14cw2S34J0R1GS5v3la-eFFFy4wlWnwB8vHXJxgsI4gO1dpW8KPZTfZxM0*-E19Vbyvon8FioAy4cDo7njLM-SUi1fDGB9-q9V7lvKyHfC*7AVKv66VeNrkP8v56dSfiNeeh3mV7Z*N7oRxBhl4b9Un3LCe046jNkd1ZcwW8zfHS67Rw6JoYM8VBSzb3vqFF9IursAPrNfjpg9eLQqgfld8*OfBP4O0n*2on-76T9nIqlr64eRBr0ur9j1jlE*VxcK8m*b7Smcck3Ec-24MRQmPXVgSK3aENfKsctrjaYoqJ7cixs822pbbr1e1uVb0NHPqxfjm0vek*vukm*iYbcWziLoL9pcYN1qN-ZwMlZqfbNZxb6dXE3YDEz6Pc*u6r0LYyi7*qgnnjlW*bahLhZI60nDjsTc3EySK5L1pItUzdJZyHen6eAaDBIv4aAyVK0wrCTGlROYUwOLbaOWTlneBnMtZNVruacpXGeBdJtLp40ZAYp5e12NkziVmx2VcFJTUlsX415ZGWTts0*A9NMr202sYS-0L0OryfDn84srm7DDm3xMgNWby5HSH1V9mS83uH543hDrXhmratlMhI5y5QmInPVu5Qnf*sRDeRzwC*5TmHamygV0FDjWZIIynnCsZc9VjZXrQ*T255kx1brasN1r28ktxpWW1GonSr1r3iafBKd8KyusVvaEUD5v1z-VnPFIMpChXy9hd8jrV*c3vqcv0fJSj2QQnLlMw64IUQtPWn0JMjZU*Z6h*m1T0ufg0u8slnKfa9TA*Iy7uOorQBsKvRvPmSeXXNtRyCiYGO24BtSuaU3qpDytI0HK5N55zJv2uDl158Jk1ND8MKx1b8KkairiEs9a80AUyuRcMbuLeEKuW5Y08AMo1crDZmNClEkzjLLOMsYWH11Da1YbW4O23zQnszl7272oI1YPLg2-5TbdWn24WGhRPxxF45t*2dOwqC9NNBMnLYOm68c8mZm9bC4W8HaoWCDrVb33lf30-8yAYh39IwAA</param><param name="m_tracking">CAFS6000000178AhQAAAAL8F8YPKDHSf26uXZ*ffyp655rQAcAAABTSEEtMjU2IAAAALtNs7-mq2cjb*llV3YBZYTeWAMuzqdME2kB9uAPbn9bH4sIAAAAAAAAAHWRO2*DMBCA5-ZXVOyNgVCJIsJCJVSpTFm6ErhgR3Am3IXHv68TRxGtqBdLvu*7l*PDhaJS4wA9Faw0phoZJn6Z2gYpMtGdI5m7SIgKBmh0B-2m1DVqMlcrqJTQFiQOyqBiK5y7OJF6iOM4bsbtRve18F3XE9-51-6mvSokLrAEY5GKeO5g5-zTkJM8P11PfI0Xx6NCxfOee8Ca5UKfKFJo6DfXdWOxBi8Tqeq3StwrrJ1EynTMh4xymZ39PKc5zE7h**xTMw-VKU3DMAiGJg1tBVUtc6Ku4PNjPa9nBYsspa7XJRD99W6jeH5wH*VBLVWzQr7Qej3zRV0DDFa3pHXty8qikx-uvbWiEwIAAA__</param><param name="run.outputFormat">HTML</param><param name="ui.object">/content/folder[@name=\'Public Reporting\']/folder[@name=\'Web Reports\']/report[@name=\'Payroll - By Business Unit - Position and Level 3\']</param><param name="ui.primaryAction">run</param><param name="ui.name">Payroll - By Business Unit - Position and Level 3</param></previousReport><previousReport><param name="ui.action">currentPage</param><param name="ui.conversation">CAFS6000000ab4AhQAAAAL8F8YPKDHSf26uXZ*ffyp655rQAcAAABTSEEtMjU2IAAAACy5ozd-rbTa*JEvfs0do8tctC2SQ*gpREQtSPHYBaDrH4sIAAAAAAAAAM1ZW3PayBJ*zvkVXp-azQMV637zJqkjJDDY3EFgnEq5ZqQRCKSRLI0A*dfvgACD13EwdpyjF1Mz3T1fX6anu-0Zpsl5FHsBiLMOuktRQk4WgY*Tc7rx5XRMSHTOMA6aIT*MUHxmhyMcJvRPwCT2GAUgYaBHSRmBOV0zLhJvyzifz8-mwlkYjxieZTnmul7rrtg*eTghANuIciXeOcki9OV0iQUkGbbHayinX--zYfl9Xu5gEKAd4kVynpDYw6PTr3GKPzMbkl2WEE6QTVqAjB*dkiAQ2*PlRpdK8FFzRXj6lbFDTBAmjBv6Doq--W8p8cvHVgp9zz7poCiMCWX4*P0RwQDB9W5C9*LVry0zyOLQ908*nRSzk2KaeBglyYmFPfLxew77AeYe*Ih4IU52kHebeutTqWGc63EMso29N6tbo68dc0a3kxBEK*svfzAI26FD4VNXbUWBpaje1jD5od849fvG9h8*ewQFj*xHLd5cURbD0EcAb4mfdNUeRwmnAXUZImmMmymJUjIYI6zPgOcD6KN-OXItcgb89JH74eZsEqdrvhXVFjizRH6QGt1VJOVmfakq4UqJchgHgByK-rEnn3LHNsC-cQ-O*LceO-eg0qvXyjEYBTSC95X-cJR58rv4QkfvMuUGAv4cZEkV237qoNZernlXb*8jy6-CUfoQAuzx0sgbKYeqsVzbXMJcVr1aLx2lzAhhFHt2jkvHmdWpPq-LTpw8l9VtBMEyCy6zM0k2*bAOMBih2KB6owdT-DfxRhjQi-ySW7sBwfKcyOZfscxKZU4VDJ01FFErm0W9qCmyUlLMsqFrpaJWkouUWMnJJUFURY43BV6QBJlfC*ElgS2LZUOSygLHyYrI6YIgGCVFK0qszGq6rBqloqLwxZJeNBWZFVlOYQXdNCmbKBqvDqkqJsdE0-rxHQCP9MYxSsb0YXmBOb3lqcLrQ4i*zKtoRg799f6RtNpdHJwPlmv0edtFvIbiEYdioAdFKTzDztkonJ1rAssyER85TILimY8I43hJBIg9vr39488--7i9zV-sdoribLP03qXA5lxOFGVVlEWocDZE0FaRJgJHtUXBtkUAgAo4FcqcBFkWARYhDgHJhqojOoKARF7byImAPaWWPlKnNfeWonNrpBA9oORlV4S2oyiqi1hN5DheggrSgIsEDsm8CJCr8ILgApkCBpLCSS4HRYFVARQhq3EbOcC2wxTvW57jZUkUFJVXNiuOwEuaiBBweNa1Zc6WZNtBmqoIUFM0HkJeY1mgIQe6jgodqKkacBQkaDwAAoukjZzXFQl5tUJjDkRJ6oPl0pHFwp6Ml8T8E*y5XBziV5ZADQqgv*Q9rgpaJH4LxJSMoDh5yzJoI2mF7ZvyXCm0R7pD97MsZvTz*r*D3CeQ--wpm3vYCednodF-wgWPnfB2sOcIdsLwqZz5c8hMnqjfFa-R7xpvZejuU*-1r4NuJcgw9Z7epeCXTdlR6H9QuP5Cg6983PfQHMVV8yjMt43uU1nz12Fe7tC32UbVp6qg-0PANDTKqe*34oAYYRB5PjoOuAv85KDweF2arwE8SunL-ppetxba4PBO-df0ugh-SpM3tcwhTdTTD5-VqR3RAMWzM8r7OszHjl*imIbq*3bfr7XzQ*i9pGg6rleh6GkpTLuy-LnaHJr3vLSFQHGZ3vNullDC3*PABPn5U1QECXLKaNWFH1x37Tr0R3nnBUoc1Pk*UoDakHg0jZR8tJykvAT6quXl2d9jeODMlmNrJ28GfpPBjwbv**Fcxzgk4EdlzC*EvzdvOEiF424v9Ewvzm8H8HdmDHvrmytTwsup80smLi*zxHrCn8-yd8f70bZbet8J--bcvKHinh-071Mf7K2o6CGMvTR4606Q4glWUKoU6zf2*ynzjNUfTLxr*CRCtud6eUp-X9vn07-uLoBdHXJ49G4iExDw-LjrL5-8vSX9a0T*rohJVV9-jNTvKvwM1oum1mc6UeGmU768xwV7MJhHF8JwWOZMwawNjVKzE8sizzPV6cCaFQp8CdecWaXa85qowKSVtDDVr4vXMOJIQShep9lo2o-BhOsYKAatO-Ni0e*5YtuqtkoV93owvrm0G5fRBQpU07Evwpu71AZe0C7IC6B6QiW4KrU4UqlcZKofxP2qZLFen50aAd-pXV8V7u-dPkm9IOtfR-DGuDTNdi26uLyXb5oz4FSsxCpbbtyQ79TyIpvoA57cXQaVsmpItUmbjIlQk6TEkiqKFku9GuQhHDrm8L6tGPd9p*UkM3TXZ*6iCF3A2YxTm8Wb2azcaBl*zZzouJ5I82q9DZUOgRXb9yO75MVO7QoyTW1cEvmk3mKDiiW1KyV3PpF8xiibY9e6Z4a1Bj*Y3aN4ChvNebOfunwlnkdea8YPGngeZK3ByOTv494VvoYsyHT32pub3pAnSuZopoyQW7mTBtUO28ZRdjWewN7AuCCs221npmX0QreQjcT*rDsde8DiLnUUQHk6NMcX*lVmg5u4wiSwoKSiuBjfR91WXCTN9rjdHxupt8imdqNvDSedaCqVLZaBl1Gq6zetpKJbPWxo0nzWsOoz5TqY13sTsx4N6lBKRgaKQGHolxYB6N70slpgg8vMkW*mKlGrw4I*qDbduIMtuadb7Ualxl85ZqHkjrxF*4qXrWkfTPoqZOb6xJILyGjXaVR**bIMWmYvavOLul3KL8L69u79p*jrP8CoSiiqHgAA</param><param name="m_tracking">CAFS6000000174AhQAAAAL8F8YPKDHSf26uXZ*ffyp655rQAcAAABTSEEtMjU2IAAAAH*mkg6x6frFSrC4PDvWvVlCFa4oLGhi-i1WNan1oejIH4sIAAAAAAAAAHWRPW*DMBBA5-ZXVOzF4FCJIMLSSlGlMmXpSvAFG4GNfJcA-75OHEW0ol4s*d67L*fHM2a10RewWJEy*t1ogolepr7TmLnoLpBEQ8aYgAt0ZgAb1qbRBt3VM6wl9BWyo3Io27DgLk6oHuI4juG4CY1tGI*imH2XX4eb9qo0UqVrcBaqjOYBdsE-DQXF89P15Nd4dToprWg*kAXdkFzoE2ZKO-otiqKcrcHLREr8VpGs0k1QdPt5L*eRd1zybSKFaPm2a8uEl5jOPG05L3kquPQVlFjm1EbA58d63tgLHllKgzU1IP71bqPEPLmP8qCWqlshnXG9nvuioQMCr3vSu-5lZdHFD0iJtMsTAgAA</param><param name="run.outputFormat">HTML</param><param name="ui.object">/content/folder[@name=\'Public Reporting\']/folder[@name=\'Web Reports\']/report[@name=\'Payroll - By Business Unit\']</param><param name="ui.primaryAction">run</param><param name="ui.name">Payroll - By Business Unit</param></previousReport></previousReports>'

            # set get data
            params = {}
            params['authoredDrill.request'] = '<authoredDrillRequest>' \
                                              '<param name="action">default</param>' \
                                              '<param name="target">/content/folder[@name=&apos;Public Reporting&apos;]/folder[@name=&apos;Web Reports&apos;]/report[@name=&apos;Payroll - By Business Unit - Position and Level 3&apos;]</param>' \
                                              '<param name="format">HTMLFragment</param>' \
                                              '<param name="locale">en-us</param>' \
                                              '<param name="prompt">false</param>' \
                                              '<param name="dynamicDrill">false</param>' \
                                              '<param name="sourceTracking">%s</param>' \
                                              '<param name="source">storeID(&quot;iB263D43A441F4F9CB7FCE6F97A6E9727&quot;)</param>' \
                                              '<param name="metadataModel">/content/folder[@name=&apos;Public Reporting&apos;]/package[@name=&apos;PR_Cube&apos;]/model[@name=&apos;2011-03-11T22:25:19.533Z&apos;]</param>' \
                                              '<param name="selectionContext">&lt;s:selection rModel=&quot;MP_0&quot; xmlns:s=&quot;http://developer.cognos.com/schemas/selection/1/&quot; xmlns:xml=&quot;http://www.w3.org/XML/1998/namespace&quot;&gt;&lt;s:metadataCells&gt;&lt;/s:metadataCells&gt;&lt;s:cells&gt;&lt;/s:cells&gt;&lt;s:strings&gt;&lt;s:s xml:id=&quot;MP_0&quot;&gt;/content/folder[@name=&amp;apos;Public Reporting&amp;apos;]/package[@name=&amp;apos;PR_Cube&amp;apos;]/model[@name=&amp;apos;2011-03-11T22:25:19.533Z&amp;apos;]&lt;/s:s&gt;&lt;/s:strings&gt;&lt;/s:selection&gt;</param>' \
                                              '<param name="source">storeID(&quot;iB263D43A441F4F9CB7FCE6F97A6E9727&quot;)</param>' \
                                              '<param name="sourceContext">&lt;bus:parameters xmlns:bus=&quot;http://developer.cognos.com/schemas/bibus/3/&quot; xmlns:xsi=&quot;http://www.w3.org/2001/XMLSchema-instance&quot; xmlns:SOAP-ENC=&quot;http://schemas.xmlsoap.org/soap/encoding/&quot; xsi:type=&quot;SOAP-ENC:Array&quot; SOAP-ENC:arrayType=&quot;bus:baseParameter[3]&quot;&gt;&lt;item xsi:type=&quot;bus:parameter&quot;&gt;&lt;bus:name xsi:type=&quot;xs:string&quot;&gt;pBiennium&lt;/bus:name&gt;&lt;bus:type xsi:type=&quot;bus:parameterDataTypeEnum&quot;&gt;memberUniqueName&lt;/bus:type&gt;&lt;/item&gt;&lt;item xsi:type=&quot;bus:parameter&quot;&gt;&lt;bus:name xsi:type=&quot;xs:string&quot;&gt;pBusinessUnit&lt;/bus:name&gt;&lt;bus:type xsi:type=&quot;bus:parameterDataTypeEnum&quot;&gt;memberUniqueName&lt;/bus:type&gt;&lt;/item&gt;&lt;item xsi:type=&quot;bus:parameter&quot;&gt;&lt;bus:name xsi:type=&quot;xs:string&quot;&gt;pBusinessUnitShortName&lt;/bus:name&gt;&lt;bus:type xsi:type=&quot;bus:parameterDataTypeEnum&quot;&gt;xsdString&lt;/bus:type&gt;&lt;/item&gt;&lt;/bus:parameters&gt;</param>' \
                                              '<param name="objectPaths">&lt;bus:objectPaths xmlns:bus=&quot;http://developer.cognos.com/schemas/bibus/3/&quot; xmlns:xsi=&quot;http://www.w3.org/2001/XMLSchema-instance&quot; xmlns:SOAP-ENC=&quot;http://schemas.xmlsoap.org/soap/encoding/&quot; xsi:type=&quot;SOAP-ENC:Array&quot; SOAP-ENC:arrayType=&quot;bus:searchPathSingleObject[4]&quot;&gt;&lt;item xsi:type=&quot;bus:searchPathSingleObject&quot;&gt;storeID(&quot;i8EDD623D1E0640A3BEFADCB78405DFC7&quot;)&lt;/item&gt;&lt;item xsi:type=&quot;bus:searchPathSingleObject&quot;&gt;storeID(&quot;i7886F2E83E0F43EE9DF4D47CA62F5E2A&quot;)/model[last()]&lt;/item&gt;&lt;item xsi:type=&quot;bus:searchPathSingleObject&quot;&gt;/content/folder[@name=&apos;Public Reporting&apos;]/package[@name=&apos;PR_Cube&apos;]/model[@name=&apos;2011-03-11T22:25:19.533Z&apos;]&lt;/item&gt;&lt;item xsi:type=&quot;bus:searchPathSingleObject&quot;&gt;/content/folder[@name=&apos;Public Reporting&apos;]/package[@name=&apos;PR_Cube&apos;]/model[last()]&lt;/item&gt;&lt;/bus:objectPaths&gt;</param>' \
                                              '<drillParameters>' \
                                              '<param name="p_pBusinessUnit">&lt;selectChoices propertyToPass=&quot;businessKey&quot;&gt;&lt;selectOption useValue=&quot;[PR_Cube].[All Business Units].[All Business Units].[PR Business Unit]-&amp;gt;:[PC].[@MEMBER].[%s]&quot; displayValue=&quot;%s Adjutant General&quot;/&gt;&lt;/selectChoices&gt;</param>' \
                                              '<param name="p_pBusinessUnitShortName">&lt;selectChoices&gt;&lt;selectOption useValue=&quot;[PR_Cube].[All Business Units].[All Business Units].[PR Business Unit]-&amp;gt;:[PC].[@MEMBER].[%s]&quot; mun=&quot;[PR_Cube].[All Business Units].[All Business Units].[PR Business Unit]-&amp;gt;:[PC].[@MEMBER].[%s]&quot; displayValue=&quot;Adjutant General&quot;/&gt;&lt;/selectChoices&gt;</param>' \
                                              '</drillParameters>' \
                                              '<param name="executionParameters">%s</param>' \
                                              '</authoredDrillRequest>' % (self.agency_form_data['m_sTracking'], agency['id'], agency['id'], agency['id'], agency['id'], self.agency_form_data['m_sParameters'])
            params['ui.action'] = 'authoredDrillThrough2'
            params['b_action'] = 'cognosViewer'
            params['cv.id'] = '_NS_'
            params['cv.header'] = 'false'
            params['cv.toolbar'] = 'false'
            params['ui.backURL'] = 'http://cognospubrep.nd.gov:80/Cognos/cps4/portlets/common/close.html'
            params['ui.routingServerGroup'] = ''
            params['cv.previousReports'] = '<previousReports>' \
                                           '<previousReport>' \
                                           '<param name="ui.action">currentPage</param>' \
                                           '<param name="ui.conversation">%s</param>' \
                                           '<param name="m_tracking">%s</param>' \
                                           '<param name="run.outputFormat">HTML</param>' \
                                           '<param name="ui.object">storeID("iB263D43A441F4F9CB7FCE6F97A6E9727")</param>' \
                                           '<param name="ui.primaryAction">run</param>' \
                                           '<param name="ui.name">Payroll - By Business Unit</param>' \
                                           '</previousReport>' \
                                           '</previousReports>' % (self.agency_form_data['m_sConversation'], self.agency_form_data['m_sTracking'])
        else:
            # set get data
            params = {}
            params['_promptControl'] = 'prompt'
            params['b_action'] = 'cognosViewer'
            params['cv.catchLogOnFault'] = 'true'
            params['cv.header'] = 'false'
            params['cv.id'] = '_NS_'
            params['cv.objectPermissions'] = 'execute read traverse'
            params['cv.responseFormat'] = 'data'
            params['cv.showFaultPage'] = 'true'
            params['cv.toolbar'] = 'false'
            params['errURL'] = 'http://cognospubrep.nd.gov:80/Cognos/cps4/portlets/common/close.html'
            params['executionParameters'] = self.form_data['m_sParameters']
            params['m_tracking'] = self.form_data['m_sTracking']
            params['p_pBiennium'] = '<selectChoices><selectOption useValue="%s" displayValue="%s"/></selectChoices>' % (biennium, biennium)
            params['p_pBusinessUnitShortName'] = '<selectChoices><selectOption useValue="%s" displayValue="%s"/></selectChoices>' % (agency, agency)
            params['run.prompt'] = 'false'
            params['ui.action'] = 'forward'
            params['ui.backURL'] = 'http://cognospubrep.nd.gov:80/Cognos/cps4/portlets/common/close.html'
            #m_sCAFContext
            params['ui.cafcontextid'] = self.form_data['m_sCAFContext']
            params['ui.conversation'] = self.form_data['m_sConversation']
            params['ui.object'] = "/content/folder[@name='Public Reporting']/folder[@name='Web Reports']/report[@name='Payroll - By Business Unit - Position and Level 3']"
            params['ui.objectClass'] = 'report'
            params['ui.primaryAction'] = 'run'
            params['ui.routingServerGroup'] = ''

        # set url
        url = self.base_url

        # get request
        ret = self.session.post(url, data=params)

        if ret.status_code == 200:
            if biennium == '17-19':
                # get form data for agency
                scripts = Selector(text=ret.text).xpath('//script').extract()
                for script in scripts:
                    if 'oCV.initViewer(' in script:
                        temp = str(script).split('oCV.initViewer(')[1].split(');')[0]
                        self.form_data = json.loads(temp)
                # print(self.form_data)

            data_table = Selector(text=ret.text).xpath('//table[@id="rt_NS_"]/tr/td/table').extract()

            if len(data_table) == 0:
                temp = Selector(text=ret.text).xpath('//state/text()').extract()

                if len(temp) == 0:
                    # get form data for agency
                    scripts = Selector(text=ret.text).xpath('//script').extract()
                    for script in scripts:
                        if 'oCV_NS_.initViewer(' in script:
                            temp = str(script).split('oCV_NS_.initViewer(')[1].split(');')[0]
                            self.form_data = json.loads(temp)

                    params = {}
                    params['b_action'] = 'cognosViewer'
                    params['cv.actionState'] = self.form_data['m_sActionState']
                    params['cv.catchLogOnFault'] = 'true'
                    params['cv.cv.header'] = 'false'
                    params['cv.cv.id'] = '_NS_'
                    params['cv.objectPermissions'] = 'execute read traverse '
                    params['cv.responseFormat'] = 'page'
                    params['cv.showFaultPage'] = 'true'
                    params['cv.toolbar'] = 'false'
                    params['errURL'] = 'http://cognospubrep.nd.gov:80/Cognos/cps4/portlets/common/close.html'
                    params['executionParameters'] = self.form_data['m_sParameters']
                    params['m_tracking'] = self.form_data['m_sTracking']
                    params['ui.action'] = 'wait'
                    params['ui.backURL'] = 'http://cognospubrep.nd.gov:80/Cognos/cps4/portlets/common/close.html'
                    params['ui.cafcontextid'] = self.form_data['m_sCAFContext']
                    params['ui.conversation'] = self.form_data['m_sConversation']
                    params['ui.object'] = "/content/folder[@name='Public Reporting']/folder[@name='Web Reports']/report[@name='Payroll - By Business Unit - Position and Level 3']"
                    params['ui.objectClass'] = 'report'
                    params['ui.primaryAction'] = 'run'
                    params['ui.routingServerGroup'] = ''
                    params['cv.previousReports'] = '<previousReports>' \
                                           '<previousReport>' \
                                           '<param name="ui.action">currentPage</param>' \
                                           '<param name="ui.conversation">%s</param>' \
                                           '<param name="m_tracking">%s</param>' \
                                           '<param name="run.outputFormat">HTML</param>' \
                                           '<param name="ui.object">storeID("iB263D43A441F4F9CB7FCE6F97A6E9727")</param>' \
                                           '<param name="ui.primaryAction">run</param>' \
                                           '<param name="ui.name">Payroll - By Business Unit</param>' \
                                           '</previousReport>' \
                                           '</previousReports>' % (self.form_data['m_sConversation'], self.form_data['m_sTracking'])
                    params['CV_jsID'] = 'window.oCV_NS_'
                    params['encoding'] = 'UTF-8'
                    params['ui.outputLocale'] = 'en-us'
                    params['executionPrompt'] = 'true'
                    params['metadataInformationURI'] = '/lineageUIService'
                    params['promptOnRerun'] = 'true'
                    params['ui.name'] = 'Payroll - By Business Unit - Position and Level 3'
                    params['packageBase'] = '/content/folder[@name=\'Public Reporting\']/package[@name=\'Public Reporting Datamart\']'
                    params['modelPath'] = '/content/folder[@name=\'Public Reporting\']/package[@name=\'Public Reporting Datamart\']/model[@name=\'model\']'
                    params['ui.format'] = 'HTML'
                    params['cv.useAsynchReportOutput'] = ''
                    params['authoredDrill.request'] = '<authoredDrillRequest>' \
                                              '<param name="action">default</param>' \
                                              '<param name="target">/content/folder[@name=&apos;Public Reporting&apos;]/folder[@name=&apos;Web Reports&apos;]/report[@name=&apos;Payroll - By Business Unit - Position and Level 3&apos;]</param>' \
                                              '<param name="format">HTMLFragment</param>' \
                                              '<param name="locale">en-us</param>' \
                                              '<param name="prompt">false</param>' \
                                              '<param name="dynamicDrill">false</param>' \
                                              '<param name="sourceTracking">%s</param>' \
                                              '<param name="source">storeID(&quot;iB263D43A441F4F9CB7FCE6F97A6E9727&quot;)</param>' \
                                              '<param name="metadataModel">/content/folder[@name=&apos;Public Reporting&apos;]/package[@name=&apos;PR_Cube&apos;]/model[@name=&apos;2011-03-11T22:25:19.533Z&apos;]</param>' \
                                              '<param name="selectionContext">&lt;s:selection rModel=&quot;MP_0&quot; xmlns:s=&quot;http://developer.cognos.com/schemas/selection/1/&quot; xmlns:xml=&quot;http://www.w3.org/XML/1998/namespace&quot;&gt;&lt;s:metadataCells&gt;&lt;/s:metadataCells&gt;&lt;s:cells&gt;&lt;/s:cells&gt;&lt;s:strings&gt;&lt;s:s xml:id=&quot;MP_0&quot;&gt;/content/folder[@name=&amp;apos;Public Reporting&amp;apos;]/package[@name=&amp;apos;PR_Cube&amp;apos;]/model[@name=&amp;apos;2011-03-11T22:25:19.533Z&amp;apos;]&lt;/s:s&gt;&lt;/s:strings&gt;&lt;/s:selection&gt;</param>' \
                                              '<param name="source">storeID(&quot;iB263D43A441F4F9CB7FCE6F97A6E9727&quot;)</param>' \
                                              '<param name="sourceContext">&lt;bus:parameters xmlns:bus=&quot;http://developer.cognos.com/schemas/bibus/3/&quot; xmlns:xsi=&quot;http://www.w3.org/2001/XMLSchema-instance&quot; xmlns:SOAP-ENC=&quot;http://schemas.xmlsoap.org/soap/encoding/&quot; xsi:type=&quot;SOAP-ENC:Array&quot; SOAP-ENC:arrayType=&quot;bus:baseParameter[3]&quot;&gt;&lt;item xsi:type=&quot;bus:parameter&quot;&gt;&lt;bus:name xsi:type=&quot;xs:string&quot;&gt;pBiennium&lt;/bus:name&gt;&lt;bus:type xsi:type=&quot;bus:parameterDataTypeEnum&quot;&gt;memberUniqueName&lt;/bus:type&gt;&lt;/item&gt;&lt;item xsi:type=&quot;bus:parameter&quot;&gt;&lt;bus:name xsi:type=&quot;xs:string&quot;&gt;pBusinessUnit&lt;/bus:name&gt;&lt;bus:type xsi:type=&quot;bus:parameterDataTypeEnum&quot;&gt;memberUniqueName&lt;/bus:type&gt;&lt;/item&gt;&lt;item xsi:type=&quot;bus:parameter&quot;&gt;&lt;bus:name xsi:type=&quot;xs:string&quot;&gt;pBusinessUnitShortName&lt;/bus:name&gt;&lt;bus:type xsi:type=&quot;bus:parameterDataTypeEnum&quot;&gt;xsdString&lt;/bus:type&gt;&lt;/item&gt;&lt;/bus:parameters&gt;</param>' \
                                              '<param name="objectPaths">&lt;bus:objectPaths xmlns:bus=&quot;http://developer.cognos.com/schemas/bibus/3/&quot; xmlns:xsi=&quot;http://www.w3.org/2001/XMLSchema-instance&quot; xmlns:SOAP-ENC=&quot;http://schemas.xmlsoap.org/soap/encoding/&quot; xsi:type=&quot;SOAP-ENC:Array&quot; SOAP-ENC:arrayType=&quot;bus:searchPathSingleObject[4]&quot;&gt;&lt;item xsi:type=&quot;bus:searchPathSingleObject&quot;&gt;storeID(&quot;i8EDD623D1E0640A3BEFADCB78405DFC7&quot;)&lt;/item&gt;&lt;item xsi:type=&quot;bus:searchPathSingleObject&quot;&gt;storeID(&quot;i7886F2E83E0F43EE9DF4D47CA62F5E2A&quot;)/model[last()]&lt;/item&gt;&lt;item xsi:type=&quot;bus:searchPathSingleObject&quot;&gt;/content/folder[@name=&apos;Public Reporting&apos;]/package[@name=&apos;PR_Cube&apos;]/model[@name=&apos;2011-03-11T22:25:19.533Z&apos;]&lt;/item&gt;&lt;item xsi:type=&quot;bus:searchPathSingleObject&quot;&gt;/content/folder[@name=&apos;Public Reporting&apos;]/package[@name=&apos;PR_Cube&apos;]/model[last()]&lt;/item&gt;&lt;/bus:objectPaths&gt;</param>' \
                                              '<drillParameters>' \
                                              '<param name="p_pBusinessUnit">&lt;selectChoices propertyToPass=&quot;businessKey&quot;&gt;&lt;selectOption useValue=&quot;[PR_Cube].[All Business Units].[All Business Units].[PR Business Unit]-&amp;gt;:[PC].[@MEMBER].[%s]&quot; displayValue=&quot;%s Adjutant General&quot;/&gt;&lt;/selectChoices&gt;</param>' \
                                              '<param name="p_pBusinessUnitShortName">&lt;selectChoices&gt;&lt;selectOption useValue=&quot;[PR_Cube].[All Business Units].[All Business Units].[PR Business Unit]-&amp;gt;:[PC].[@MEMBER].[%s]&quot; mun=&quot;[PR_Cube].[All Business Units].[All Business Units].[PR Business Unit]-&amp;gt;:[PC].[@MEMBER].[%s]&quot; displayValue=&quot;Adjutant General&quot;/&gt;&lt;/selectChoices&gt;</param>' \
                                              '</drillParameters>' \
                                              '<param name="executionParameters">%s</param>' \
                                              '</authoredDrillRequest>' % (self.form_data['m_sTracking'], agency['id'], agency['id'], agency['id'], agency['id'], self.form_data['m_sParameters'])
                    params['run.outputFormat'] = 'HTML'
                    params['reportTitle'] = 'IBM Cognos Viewer - Payroll - By Business Unit - Position and Level 3'
                    params['viewerTitle'] = 'IBM Cognos Viewer'

                else:
                    ret_json = json.loads(temp[0])
                    # print(ret_json)

                    # set get data
                    params = {}
                    params['b_action'] = 'cognosViewer'
                    params['cv.actionState'] = ret_json['m_sActionState']
                    params['cv.catchLogOnFault'] = 'true'
                    params['cv.responseFormat'] = 'data'
                    params['cv.showFaultPage'] = 'true'
                    params['errURL'] = 'http://cognospubrep.nd.gov:80/Cognos/cps4/portlets/common/close.html'
                    params['cm_tracking'] = ret_json['m_sTracking']
                    params['ui.action'] = 'wait'
                    params['ui.backURL'] = 'http://cognospubrep.nd.gov:80/Cognos/cps4/portlets/common/close.html'
                    params['ui.primaryAction'] = 'run'

                # set url
                url = self.base_url

                # get request
                ret = self.session.post(url, data=params)

                if ret.status_code == 200:
                    data_table = Selector(text=ret.text).xpath('//table[@id="rt_NS_"]/tr/td/table').extract()

            if len(data_table) == 0: return

            trs = Selector(text=data_table[0]).xpath('//tr').extract()

            # set file name
            file_name = 'csvs/' + agency['name'] + '_' + biennium + '.csv'

            # make and write header
            tds = Selector(text=trs[0]).xpath('//td/span/text()').extract()
            header_info = []
            for td in tds:
                header_info += str(td).split(', ')
            self.WriteHeader(header_info, file_name)

            # make and write rows
            prev_data = []
            for idx in range(1, len(trs)-1):
                tr = trs[idx]
                tds = Selector(text=tr).xpath('//td/span[1]').extract()

                data = []
                if len(tds) <= len(prev_data):
                    for idx in range(0, len(prev_data) - len(tds)):
                        data.append(prev_data[idx])

                for td in tds:
                    td_text = ''
                    if len(Selector(text=td).xpath('//text()').extract()) > 0:
                        td_text = Selector(text=td).xpath('//text()').extract()[0]
                    data.append(str(td_text).replace(' \xa0', ''))

                prev_data = data

                self.WriteData(data, file_name)

            # print(ret.url)
        else:
            print('fail to get agency list')

    def WriteHeader(self, header_info, file_name):
        # write header into output csv file
        writer = csv.writer(open(file_name, 'w'), delimiter=',', lineterminator='\n')
        writer.writerow(header_info)

    def WriteData(self, data, file_name):
        # write data into output csv file
        writer = csv.writer(open(file_name, 'a'), delimiter=',', lineterminator='\n')
        writer.writerow(data)

    def Start(self):
        # get agency list
        print('getting agency list ...')
        agency_list = self.GetAgencyList()

        # get biennium list
        print('getting biennium list ...')
        biennium_list = self.GetBienniumList()
        print(biennium_list)

        flag = True
        if START_AGENCY != '': flag = False

        for agency in agency_list:
            if START_AGENCY == agency['name']: flag = True
            if flag == False: continue

            for biennium in biennium_list:
                # get north dakota data
                print('getting north dakota data for %s:%s ...' % (agency['name'], biennium))
                self.GetNorthDakotaData(agency, biennium)

            #     break;
            # break;


#------------------------------------------------------- main -------------------------------------------------------
def main():
    # create scraper object
    scraper = NDScraper()

    # start to scrape
    scraper.Start()

if __name__ == '__main__':
    main()
