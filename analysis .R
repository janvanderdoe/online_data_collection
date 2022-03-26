packages <- c("reshape2", "rmarkdown",
              "data.table", "Hmisc", "dplr",
              "stargazer", "knitr",
              "xtable","tidyverse",
              "RSQLite", "dbplyr", "haven","readxl","effectsize", "writexl", "scales")
install.packages(packages)
R --version
library(effectsize)
library(readxl)
library(haven)
library(readr)
library(writexl)
library(dplyr)
library(ggplot2)
library(tidyverse)
library(scales)
setwd("/Users/saadanwar/Documents/uvt/online data collection and mgmt/futurelearn_web_scraper")
courses <- read.csv("futurelearn_data.csv", sep = ";")

#check if the same url is scraped more than once
sum(duplicated(courses$Url))

#how many Enrollments have no value
sum(courses$Enrollments =="") 
# Specify which are empty
position_of_blanks <-which(courses$Enrollments=="", arr.ind=TRUE) 

#replace string by only the number of educators
courses$Enrollments <-as.numeric(gsub("\\D", "",courses$Enrollments)) 

#how many Enrollments have become NA 
sum(is.na(courses$Enrollments))
# Specify which are NA
position_of_NAs <-which(is.na(courses$Enrollments), arr.ind=TRUE) 
#Na increases because some enrollments only say: "Educators are currently active on this course" , without specifying the number of educators

#check how many courses have no reviews
sum(courses$Review_count =="")
#replace string by only the number of reviews
courses$Review_count <- as.numeric(gsub("\\D", "",courses$Review_count))
#check how courses became NA
sum(is.na(courses$Review_count))

#replace string by only the duration
courses$Duration <- as.numeric(gsub("\\D", "",courses$Duration))
#add `in weeks` to the header
colnames(courses)[11] <- "Duration in weeks"

#replace string by only the number of study hours per week
courses$Weekly_study <- as.numeric(gsub("\\D", "",courses$Weekly_study))
#add `in hours` to the header
colnames(courses)[12] <- "Weekly_study in hours"

#change the variable time from string type to timestamp
courses$Time =as.POSIXct(courses$Time)

summary(courses)


#number of categories
courses %>% group_by(Category) %>% summarize(count=n())

#number of different universiteis
length(unique(courses$Name_school))

#number of courses per university
courses %>% group_by(Name_school, ) %>% summarize(count=n())


#Top 10 universities offering courses
courses %>% 
  group_by(Name_school) %>%
  summarize(count=n()) %>% arrange(desc(count))



#most offered category
ggplot(courses, aes(x = Category)) +
  geom_histogram(stat = 'count') + ggtitle("most offered category")

#enrollments per category
#show star rating and number of enrollments
ggplot(courses, aes(x = Category, y = Enrollments)) +
  geom_col() + ggtitle("enrollments per category")

#relative enrollments per category
counting <- courses %>% 
  group_by(Category) %>%
  summarize(count=n())

counting$enrollments <- courses %>% 
  group_by(Category) %>%
  summarize(sum(na.omit(Enrollments)))

counting$average = counting$enrollments$`sum(na.omit(Enrollments))`/counting$count
ggplot(counting, aes(x = Category, y = average)) +
  geom_col() + ggtitle("enrollments per category")

#reviews
#show star rating and number of enrollments
ggplot(courses, aes(x = Star_rating, y = Enrollments)) +
  geom_col() + ggtitle("Rating vs. number of enrollments")

#normalize ratings with bayesian estimator
R= median(na.omit(courses$Star_rating))
W = courses$Review_count / 10
courses$normalized_ratings = as.numeric(format(round((R * W + courses$Review_count*courses$Star_rating) / (W+courses$Review_count),2),nsmall=2))

#normalized rating vs enrollments
ggplot(courses, aes(x = normalized_ratings, y = Enrollments)) +
  geom_col() + ggtitle("normalized Rating vs. number of enrollments")


#free courses and 100% online
counts <- table(courses$X100_online, courses$Free)
barplot(counts, main="Interest in free online courses",
        xlab="Is the course free?", col=c("darkblue","red"),
        legend =  c("no", "yes"), args.legend=list(title="online?"), beside=TRUE)

#average rating per university
uni_ratings <- data.frame(university = courses$Name_school, ratings = courses$normalized_ratings)
setDT(uni_ratings)
uni_ratings[ ,list(mean=mean(ratings)), by = university]