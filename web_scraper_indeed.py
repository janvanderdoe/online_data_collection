# -*- coding: utf-8 -*-
"""
Created on Mon Feb 21 10:59:45 2022

@author: janva
"""

import requests
from bs4 import BeautifulSoup
import time
from datetime import datetime
import csv

# "https://nl.indeed.com/vacatures?q=marketing&l=amsterdam&start=0"


jobs=["marketing"]
job_locations = ["amsterdam", "rotterdam"]
num_pages = 3

def web_scraper(num_pages, jobs=jobs, job_locations=job_locations):
    data = []
    for job in jobs:
        for job_location in job_locations:
            url = "https://nl.indeed.com/vacatures?q=" + str(job) + "&l=" + str(job_location) + "&start=0" 
            time.sleep(1)
            r = requests.get(url)
            soup = BeautifulSoup(r.text, "html.parser")
            listings = soup.find_all(class_="slider_container")           
            for listing in listings:
                #headers
                #header = listing.find(class_="jobTitle").find_all("span")[0]
                #headers.append(header)
                
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
                
                data.append({"location" : location,
                            "Salary" : salary,
                            "Stars" : starrating,
                            "Search_term_location" : job_location,
                            "Search_term_job" : job})
    return data
with open("listings_indeed.csv", "w") as csv_file:
    writer = csv.writer(csv_file, delimiter = ";")
    writer.writerow(["location", "Salary", "Stars", "ST_location", "St_job", "Scrape_date"])
    now = datetime.now()
    for listing in web_scraper(1):
        writer.writerow([listing["location"], listing["Salary"], listing["Stars"], listing["Search_term_location"], listing["Search_term_job"], now])