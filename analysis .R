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
courses <- read.csv("futurelearn_data.csv", sep = ";")

sum(courses$Enrollments =="") #how many are empty
position_of_blanks <-which(courses$Enrollments=="", arr.ind=TRUE) # Specify which are empty

courses$Enrollments <-as.numeric(gsub("\\D", "",courses$Enrollments)) #replace string by only the number of educators

sum(is.na(courses$Enrollments)) #how many are NA
position_of_NAs <-which(is.na(courses$Enrollments), arr.ind=TRUE) # Specify which are NA
#Na increases because some enrollments only say: "Educators are currently active on this course" , without specifying the number of educators

sum(courses$Review_count =="")
courses$Review_count <- as.numeric(gsub("\\D", "",courses$Review_count))
sum(is.na(courses$Review_count))

courses$Duration <- as.numeric(gsub("\\D", "",courses$Duration))
colnames(courses)[11] <- "Duration in weeks"

courses$Weekly_study <- as.numeric(gsub("\\D", "",courses$Weekly_study))
colnames(courses)[12] <- "Weekly_study in hours"

#make txt file for tableau
write.table(courses, file = "courses.txt", sep = "\t",
            row.names = FALSE, col.names = TRUE)


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

#Top 10 universities offering courses
courses %>% 
     group_by(Name_school) %>%
     summarize(count=n()) %>% arrange(desc(count))

courses %>% 
       group_by(Name_school) %>%
       summarize(count=n())

#average rating per university
uni_ratings <- data.frame(university = courses$Name_school, ratings = courses$normalized_ratings)
setDT(uni_ratings)
uni_ratings[ ,list(mean=mean(ratings)), by = university]
