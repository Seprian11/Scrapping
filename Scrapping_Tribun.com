!pip install selenium
!pip install pandas
!pip install chromedriver-autoinstaller
!pip install BeautifulSoup4


import requests #manggil librari buat ke web
import pandas as pd #buat ngolah data
from selenium import webdriver #buat hubungin ke chrome

import time
import re

from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.keys import Keys
from bs4 import BeautifulSoup  # Make sure to import BeautifulSoup

# Set up the Selenium web driver (provide the path to your ChromeDriver)
driver_path = r'C:\Users\Seprian Najib Hilmi\Downloads\chromedriver-win64\chromedriver-win64\chromedriver.exe'
service = Service(driver_path)
driver = webdriver.Chrome(service=service)

Data = []
i = 1

for page in range(1):
    # URL of the news website you want to scrape
    url = "https://www.tribunnews.com/search?q=Pencemaran+Kalimantan+Timur+&cx=partner-pub-7486139053367666%3A4965051114&cof=FORID%3A10&ie=UTF-8&siteurl=www.tribunnews.com#gsc.tab=0&gsc.q=Pencemaran%20Kalimantan%20Timur%20&gsc.page=" + str(page)

    # Send an HTTP GET request to the website using Selenium
    driver.get(url)

    # Wait for a few seconds to let the page load (you can increase this if needed)
    time.sleep(5)

    # Now you can access the fully loaded HTML content
    page_source = driver.page_source

    # Parse the web page content using BeautifulSoup
    soup = BeautifulSoup(page_source, "html.parser")

    # Find and extract news headlines and their URLs
    beritas = soup.find_all('div', class_='gsc-webResult gsc-result')

    for berita in beritas :
        judulBeritaElement = berita.find('div', class_='gs-title')
        if judulBeritaElement:
            judulBerita = judulBeritaElement.text.strip()
            #print(judulBerita)
                
        dataBeritaElement = berita.find('div', class_='gsc-table-cell-snippet-close')
        if dataBeritaElement:
            dataBerita = dataBeritaElement.text.strip()
            #Define a regular expression pattern to match the date
            date_pattern = r'(\w+ \d{1,2}, \d{4})'

            #Use re.search to find the date in the 'Data' field
            date_match = re.search(date_pattern, dataBerita)

            if date_match:
                date = date_match.group(0)
            
        link = berita.find('a')['href']
        
        if '...' in judulBerita:
            try:
                driver.get(link)
                time.sleep(3)
                page_source = driver.page_source
                soup = BeautifulSoup(page_source, "html.parser")
                judul = soup.find('h1', class_='f50 black2 f400 crimson')
                
                judulBerita = judul.text.strip()
            except Exception as e:
                print("Gagal mendapatkan judul:", e)
               
            for isi in isiBeritas :
                    konten = soup.find('div', class_='side-article txt-article multi-fontsize editcontent')
                    kontenBerita = konten.text.strip()
                
        
        Data.append({'Nomor': i, 'Judul': judulBerita, 'Tanggal': dataBerita, 'Link': link})
            #'Link': link
#         , 'tanggal dan sumber': tanggalBerita, 'Isi Singkat': kontenBerita
        i+=1
        print(Data[-1])

    




df = pd.DataFrame(Data)
df.to_csv('PencemaranKalimantanTimur.csv', index=False)

