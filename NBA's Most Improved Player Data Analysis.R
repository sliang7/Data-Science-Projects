library(tidyverse)
library(ggplot2)
library(MASS)
library(caret)
library(RColorBrewer)
library(readxl)

MIP <- read_excel("MIP.xlsx")
View(MIP)
#0. Data Prep
MIP$Won <- factor(MIP$Won) # convert it to factor data type
MIP$Position <- factor(MIP$Position) # convert it to factor data type
levels(MIP$Position)
MIP$TeamChange <- factor(MIP$TeamChange) # convert it to factor data type

############################################################
#I. Exploratory Data Analysis
############################################################
dim(MIP)
#154 rows by 23 columns

#Summary
summary(MIP)

#Filter Data for Players Who Won MIP or were Runner-Ups
filteredData <- MIP[MIP$Won == 1, ]
View(filteredData)

#a. Position
summary(MIP$Position)
#Center: 17   Forward: 46     Forward/Center: 17     Guard: 63     Guard/Forward: 11

ggplot(MIP, aes(x = Position, fill = Won)) +
  geom_bar(position = "dodge", stat = "count") +
  labs(title = "Dataset by Position", x = "Position", y = "Count") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))
#As we can see, guards and then forwards have won the NBA MIP
#the most often.

#Let's examine the exact counts of those who won by position:
summary(filteredData$Position)
#Center: 7    Forward: 25     Forward/Center: 8     Guard: 29  Guard/Forward: 9

#b. Age
summary(MIP$Age) #Min: 19 Max: 35
ggplot(MIP, aes(x = Age)) +
  geom_histogram(binwidth = 1, color = "black", fill = "skyblue", alpha = 0.7) +
  labs(title = "Distribution of Ages", x = "Age (in Years)", y = "Frequency") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))

#Let's check the filtered dataset for the age distribution:
summary(filteredData$Age)

ggplot(filteredData, aes(x = Age)) +
  geom_histogram(binwidth = 1, color = "black", fill = "skyblue", alpha = 0.7) +
  labs(title = "Distribution of Ages Among MIP/Runner-Ups", x = "Age (in Years)", y = "Frequency") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))
#We see that no player in their 30's has ever won the award.

#c. DraftPick
summary(MIP$DraftPick) #Min: 1 Max: 73 (undrafted)

library(gridExtra)
ggplot1 <- ggplot(MIP, aes(x = DraftPick)) +
  geom_histogram(binwidth = 1, color = "black", fill = "skyblue", alpha = 0.7) +
  labs(title = "Overall Distribution of Draft Picks", x = "Draft Pick Number", y = "Frequency") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))

#Let's examine the distribution of draft picks after filtering for MIP winners
ggplot2 <- ggplot(filteredData, aes(x = DraftPick)) +
  geom_histogram(binwidth = 1, color = "black", fill = "skyblue", alpha = 0.7) +
  labs(title = "Distribution of Draft Picks for MIPs", x = "Draft Pick Number", y = "Frequency") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))

grid.arrange(ggplot1, ggplot2, ncol = 2)
#Note that the distribution is skew right, meaning most players who win or
#were runner-ups for MIP were drafted earlier in their respective drafts 
#(lower than 30)

#Draft Pick vs. Won?
ggplot(MIP, aes(x = DraftPick)) +
  geom_histogram(binwidth = 1, color = "black", fill = "skyblue", alpha = 0.7) +
  labs(title = "Draft Picks by MIP vs. MVP/ROY", x = "Draft Pick", y = "Frequency") +
  facet_wrap(~ Won) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))

#d. YearsNBA
summary(MIP$YearsNBA) #Min: 1 Max: 14
#Median: 2 Mean: 2.766
ggplot(MIP, aes(x = YearsNBA)) +
  geom_histogram(binwidth = 1, color = "black", fill = "royalblue", alpha = 0.7) +
  labs(title = "Distribution of NBA Experience", x = "Years in the NBA", y = "Frequency") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))

#Distribution of NBA experience
counts2 = table(MIP$YearsNBA)
counts2

#Let's examine MIP winners/runner-ups:
summary(filteredData$YearsNBA) #Min: 1 Max: 7
ggplot(filteredData, aes(x = YearsNBA)) +
  geom_histogram(binwidth = 1, color = "black", fill = "royalblue", alpha = 0.7) +
  labs(title = "Distribution of NBA Experience for MIPs", x = "Years in the NBA", y = "Frequency") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))
#Hence, the most common players to win or be nominated for MIP are juniors 
#(third years) followed by sophomores (second years) and seniors (fourth years).
#It is notable that the distribution is skew right, meaning most players who 
#get nominated are relatively new to the NBA.

############################################################
#II. Logistic Regression (based on Week 6 Code)
############################################################
#a. Cross-Validation: Let's create a training set and a testing set.
#According to p. 24/25 of Week 6 Notes: in practice, we split the data manually,
#which leads to training and testing sets. This strategy is called cross-validation.

#Note: I obtained the training/testing set code from ChatGPT:
# Split the data into training and testing sets (80% for training, 20% for testing)
set.seed(123)  # Setting seed for reproducibility
train_index <- createDataPartition(MIP$Won, p = 0.8, list = FALSE)
training_set <- MIP[train_index, ]  # Training set
testing_set <- MIP[-train_index, ]  # Testing set

#Check the training and testing sets
View(training_set)
View(testing_set)
dim(training_set)  # Dimensions of training set
dim(testing_set)   # Dimensions of testing set

#b. Build the Logistic Regression Model
logisticModel = glm(Won~Position+Age+DraftPick+TeamChange+YearsNBA
                    +GamesPlayed+GamesStarted+MPG+FGPerc+ThreePtPerc+FTPerc+FantasyPTS 
                    ,data=training_set,family=binomial)
summary(logisticModel)
#There are two columns that are significant: DraftPick (p-value: 0.01368)
#and FantasyPTS (p-value: 0.00517)
#Position (GuardForward) has the largest p-value: 0.98794

#c. Model Selection (Backward Stepwise Selection)
#Let's remove Position (the variable with the largest p-value)
logisticModel1=update(logisticModel,~.-Position)
summary(logisticModel1)

#Let's now remove ThreePtPerc (p-value: 0.92280) 
logisticModel2=update(logisticModel1,~.-ThreePtPerc)
summary(logisticModel2)

#Let's now remove FTPerc (p-value: 0.55985)
logisticModel3=update(logisticModel2,~.-FTPerc)
summary(logisticModel3)

#Next, let's remove TeamChange (p-value: 0.5557)
logisticModel4=update(logisticModel3,~.-TeamChange)
summary(logisticModel4)

#Next, let's remove GamesPlayed (p-value: 0.331334)
logisticModel5=update(logisticModel4,~.-GamesPlayed)
summary(logisticModel5)

#Let's remove FGPerc (p-value: 0.356218)
logisticModel6=update(logisticModel5,~.-FGPerc)
summary(logisticModel6)

#Let's remove MPG (p-value: 0.28494)
logisticModel7=update(logisticModel6,~.-MPG)
summary(logisticModel7)

#Let's remove GamesStarted (p-value: 0.1747)
logisticModel8=update(logisticModel7,~.-GamesStarted)
summary(logisticModel8)

#Let's remove Age (p-value: 0.0850)
logisticModel9=update(logisticModel8,~.-Age)
summary(logisticModel9)

#Let's remove YearsNBA (p-value: 0.261)
logisticModel10=update(logisticModel9,~.-YearsNBA)
summary(logisticModel10)

#Our model says that of the original variables, DraftPick (p-value: 0.0441) 
#and FantasyPTS (p-value: 3.34e-06) are the two statistically significant variables 
#of whether a player will win MIP. With an estimated coefficient of 0.07624, an 
#increase of one unit in DraftPick will increase the log odds that a player will 
#win MIP by an average of 0.07624. For FantasyPTS, with an estimated coefficient of 
#-0.23879, an increase of one #unit in FantasyPTS, decreases (since it's negative) 
#the log odds that a player will win MIP by an average of 0.23879.

#d. Check for Model Strength/Predictive Power 
#According to https://www.statology.org/logistic-regression-in-r/, we can
#compute McFadden's R^2 to assess our model's predictive power. Values over 0.40
#indicate that a model fits the data very well.
install.packages('pscl')
library(pscl)
pscl::pR2(logisticModel10)["McFadden"]
#We get a value of 0.6514361 which indicates that our model fits the data very
#well and has high predictive power.

#e. VarImp (Variable Importance)
varImp(logisticModel10)
#Overall
#DraftPick  2.013103
#FantasyPTS 4.648834
#This matches up with the p-values from earlier.
#FantasyPts is the more important predictor and then DraftPick.

#f. VIF
car::vif(logisticModel10)
#DraftPick: 1.000012
#FantasyPTS: 1.000012 
#Since neither column has a VIF over 5, we conclude that multicollinearity
#is not a problem in our model.

#g. Predictions
#Define NBA player (player who was not drafted high with low fantasy points in
#a season). This player is Jose Alvarado of the New Orleans Pelicans.
new <- data.frame(DraftPick = 61, FantasyPTS = 18.86)

#Predict probability of winning MIP
predict(logisticModel10, new, type="response")
#Our model predicts that Jose Alvarado has a 0.9998335 probability of winning
#the 2024 MIP award.

#h. Test Dataset
#Calculate probability of Won for each individual in test dataset
predicted <- predict(logisticModel10, testing_set, type="response")
predicted
#1           2           3           4           5           6           7 
#0.925913048 0.547482348 0.009364797 0.008414500 0.099829572 0.919417899 0.884723116 
#8           9          10          11          12          13          14 
#0.906236258 0.107792447 0.180228697 0.239001776 0.976013314 0.002664880 0.994989900 
#15          16          17          18          19          20          21 
#0.095091135 0.623199598 0.673268802 0.448242860 0.979899053 0.477156474 0.007391458 
#22          23          24          25          26          27          28 
#0.282352586 0.994753133 0.505669128 0.063020520 0.001007751 0.993891446 0.278322072 
#29          30 
#0.107433979 0.417105233
predictedBinary <- ifelse(predicted >= 0.5, 1, 0)
predictedBinary
typeof(predictedBinary)

############################################################
#III. Model Diagnostics 
############################################################
#a. Confusion Matrix
#Based on https://www.statology.org/logistic-regression-in-r/
#Any player in our test dataset with a probability of Won 
#greater than 0.5 will be predicted to be MIP/runner-up.
testing_set$Won
testing_set$Won <- factor(testing_set$Won)
predictedBinary <- factor(predictedBinary)
confusionMatrix(testing_set$Won, predictedBinary)
#
#            Reference
#Prediction  0  1
#         0 14  1
#         1  3 12

#p. 21/25 of Week 6
#Sensitivity: the conditional probability that the test is positive
#given the player won MIP.
#Sensitivity = True Positive/(True Positive + False Negative)
#Sensitivity = 12/(12+3) = 0.8

#Specificity = True Negative/(True Negative + False Positive)
#Specificity = 14/(14+1) = 0.9333

#Precision Rate = True Positive/(True Positive + False Positive) = 12/(12+1)
#Precision Rate = 0.9231

#Model Accuracy = (True Positive + True Negative)/Total = (12+14)/30
#Accuracy rate (overall fraction of correct predictions) = 0.8667

#b. ROC Curve
library(pROC)
roc_data <- roc(testing_set$Won, predicted)
roc_data
plot(roc_data, main = "ROC Curve for Logistic Regression Model")
auc(roc_data) #Area under the curve: 0.9333
#According to p. 23/25 of Week 6, AUC is a scalar that represents
#the area under the ROC curve. A value of 0.5 indicates a model that
#performs no better than a random guess whereas a value of 1 indicates
#a perfect model that correctly classifies all instances. Given our
#AUC value of 0.9333, our model does a good job of predicting whether
#a player will win MIP.

############################################################
#IV. Predictions
############################################################
library(readxl)
MIP2024 <- read_excel("MIP2024.xlsx")
View(MIP2024)
predictions <- predict(logisticModel10, newdata = MIP2024, type = "response")
predictions
typeof(predictions) #double

#with the help of ChatGPT:
topTen <- head(sort(predictions, decreasing = TRUE), 10)
print(topTen)
#According to our model, Jose Alvarado, Jae'Sean Tate, Terance Mann, Christian Braun, 
#Royce O'Neale, Moses Moody, Cam Thomas, Jalen Johnson, Daniel Gafford, Louis King 
#have the highest odds of winning MIP 2024.