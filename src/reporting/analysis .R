library(effectsize)
library(readxl)
library(haven)
library(readr)
library(writexl)
library(dplyr)
library(ggplot2)
library(tidyverse)
library(scales)
library(data.table)
library(ggpubr)

courses <- read.csv("../../gen/output/futurelearn_data.csv", sep = ";")

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
colnames(courses)[11] <- "Duration_in_weeks"

#replace string by only the number of study hours per week
courses$Weekly_study <- as.numeric(gsub("\\D", "",courses$Weekly_study))
#add `in hours` to the header
colnames(courses)[12] <- "Weekly_study_in_hours"

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
  geom_histogram(stat = 'count') + ggtitle("most offered category") +
  theme(axis.text.x = element_text(angle = 45, hjust=1))

#enrollments per category
#show star rating and number of enrollments
ggplot(courses, aes(x = Category, y = Enrollments)) +
  geom_col() + ggtitle("enrollments per category") +
  theme(axis.text.x = element_text(angle = 45, hjust=1))

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
        xlab="Is the course free?", ylab = "Number of courses", col=c("darkblue","red"),
        legend =  c("no", "yes"), args.legend=list(title="online?"), beside=TRUE)

#average rating per university
uni_ratings <- data.frame(university = courses$Name_school, ratings = courses$normalized_ratings)
setDT(uni_ratings)
uni_ratings[ ,list(mean=mean(ratings)), by = university]

#Comparing the means of enrollments of courses that can be accessed with an unlimited subscription
courses %>% ggboxplot(x = "Unlimited", y = "Enrollments",
                      ggtheme = theme_minimal()) +
  yscale(.scale = "log10") +
  stat_compare_means(method = "t.test")

#Comparing the menas of enrollments of courses that have accreditation
courses %>% ggboxplot(x = "Accreditation", y = "Enrollments",
                      ggtheme = theme_minimal()) +
  yscale(.scale = "log10") +
  stat_compare_means(method = "t.test")

#Comparing the means of enrollments of courses that have accreditation
courses %>% ggboxplot(x = "Endorsed", y = "Enrollments",
                      ggtheme = theme_minimal()) +
  yscale(.scale = "log10") +
  stat_compare_means(method = "t.test")

#Comparing the duration in weeks of courses which belong en do not belong to expert tracks
courses %>% ggboxplot(x = "Part_of_Expert", y = "Duration_in_weeks",
                      ggtheme = theme_minimal()) +
  stat_compare_means(method = "t.test")

#Comparing the weekly study time of courses which belong en do not belong to expert tracks
courses %>% ggboxplot(x = "Part_of_Expert", y = "Weekly_study_in_hours",
                      ggtheme = theme_minimal()) +
  stat_compare_means(method = "t.test")

write.csv(courses, "../../gen/output/futurelearn_data_clean.csv")
