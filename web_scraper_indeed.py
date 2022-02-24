# -*- coding: utf-8 -*-
"""
Created on Mon Feb 21 10:59:45 2022

@author: janva
"""
# import urllib library
from urllib.request import urlopen
  
# import json
import json
# store the URL in url as 
# parameter for urlopen
url = "https://opendata.cbs.nl/ODataApi/OData/84734NED/Woonplaatsen"


  
# store the response of URL
response = urlopen(url)
  
# storing the JSON response 
# from url in data
data_json = json.loads(response.read())
  
# print the json response
for title in data_json:
    print(title)


####
import requests
from bs4 import BeautifulSoup
import time
from datetime import datetime
import csv

# "https://nl.indeed.com/vacatures?q=marketing&l=amsterdam&start=0"

#PARAMETERS
jobs=["marketing", "leraar", "administrateur"]
job_locations = ["rotterdam", "amsterdam", "tilburg"]
max_pages = 3

#Scraper
start_time = datetime.now()
data = []
num_pages_scraped = 0
for job in jobs:
    for job_location in job_locations:
        for page in range(0, max_pages):
            pagination = page*10
            url = "https://nl.indeed.com/vacatures?q=" + str(job) + "&l=" + str(job_location) + "&start=" + str(pagination)
            time.sleep(1)
            r = requests.get(url)
            soup = BeautifulSoup(r.text, "html.parser")
            listings = soup.find_all(class_="slider_container")
            num_pages_scraped += 1
            for listing in listings:
                #Jobtitle
                try:
                    title = listing.find(class_="jobTitle").find_all("span")[1].text
                    new = listing.find(class_="jobTitle").find_all("span")[0].text
                except:
                    try: 
                        title = listing.find(class_="jobTitle").find_all("span")[0].text
                    except:
                        title = ""
                    finally:
                        new = ""
                #Description
                bullets =[]
                try:
                
                    for li in listing.find(class_ = "job-snippet").find_all("li"):
                        bullets.append(li.text)
                    description = '/'.join(bullets)
                except:
                    description = ""
                del bullets    
                #Location
                try:
                    location = listing.find(class_= "companyLocation").text
                except:
                    location = ""
                #Salary
                try:
                    salary = listing.find(class_ = "salary-snippet").find("span").text
                except:
                    salary = ""
                #Star rating
                try:
                    starrating = listing.find(class_="resultContent").find(class_="ratingNumber").text
                except:
                    starrating = ""
                
                
                data.append({"Title" : title,
                             "New" : new,
                             "Description" : description,
                            "location" : location,
                            "Salary" : salary,
                            "Stars" : starrating,
                            "Search_term_location" : job_location,
                            "Search_term_job" : job,
                            "Search_term_page" : page})
                #Checks whether there's a next button. Break if there's not or no button at all
            try:
                next_label = soup.find_all("nav")[2].find_all("a")[-1]["aria-label"]
                if next_label == "Volgende":
                    pass
                else:
                    break
            except:
                break

#CSV writer
with open("listings_indeed.csv", "w", encoding = "UTF-8") as csv_file:
    writer = csv.writer(csv_file, delimiter = ";")
    writer.writerow(["Title", "New", "Description", "location", "Salary", "Stars", "ST_location", "St_job", "ST_page", "Scrape_date"])
    now = datetime.now()
    for listing in data:
        writer.writerow([listing["Title"], listing["New"], listing["Description"], listing["location"], listing["Salary"], listing["Stars"], listing["Search_term_location"], listing["Search_term_job"], listing["Search_term_page"], now])

end_time = datetime.now()
print("Time it took to scrape: " + str(end_time - start_time))
print("Number of pages scraped: " + str(num_pages_scraped))