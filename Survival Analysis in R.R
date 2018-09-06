rm(list=ls())

########## Load the Libraries ########## 
library('survival')
library('survminer')
library("ggplot2")
library("prodlim")
library("riskRegression")
library("pec")
library("ggfortify")
library("glmnet")
library('corrplot')

########## Load the Data ##########
all_data = read.csv("Final Data 5.1.csv")
colnames(all_data)[8] <- "Page.Since.Last.Failure"
all_data = subset(all_data, ProblemOccured ==1)
all_data[is.na(all_data)] = 0

########## check the correlation matrix ##########
cor(all_data[,c(6,7,8,9,11,12,13,14)])
corrplot(cor(all_data[,c(6,7,8,9,11,12,13,14)]),method='circle')

########## Scale the independent variables to make interpretation easier ##########
all_data$CumPage = (all_data$CumPage/100000)
all_data$Page.Since.Last.Failure = (all_data$Page.Since.Last.Failure/100000)
all_data$Page.30D = (all_data$Page.30D/100000)
all_data$Page.15D = (all_data$Page.15D/100000)
all_data$Page.7D = (all_data$Page.7D/100000)
all_data$Page.2D = (all_data$Page.2D/100000)

########## split data into training and test dataset ##########
set.seed(123) #set seed to get the same results each time
sample = floor(0.8 * nrow(all_data))
train_ind <- sample(seq_len(nrow(all_data)), size = sample)
train <- all_data[train_ind, ]
test <- all_data[-train_ind, ]

########################################
########## Cause-Specific Cox ##########
########################################
# Just another model we explored
CSCmodel = CSC(Hist(Survival.Day, ProblemTypeName) ~ age+factor(Label)+CumPage+Page.Since.Last.Failure+
                 Page.30D+Page.15D+Page.7D+Page.2D, 
            data = train)
summary(CSCmodel)
predict(CSCmodel, asset1, type = 'expected', cause = 'Paper Jam', times = c(7,30))
########################################
########################################

########## Cox Proportional Harzard Regression ##########
### Univariate Regression ###
summary(coxph(Surv(Survival.Day, ProblemOccured) ~ Page.30D, data = train, x=TRUE))

cox_model <- coxph(Surv(Survival.Day, ProblemOccured) ~ age+CumPage+factor(Label)+
                     Page.Since.Last.Failure+
                     Page.30D+Page.15D+Page.7D+Page.2D,
                   data = train, x=TRUE)
summary(cox_model)
cox.zph(cox_model)

########## Lasso Regression to check the independent variables ##########
fit <- glmnet(model.matrix( ~ age+CumPage+factor(Label)+
                              Page.Since.Last.Failure+
                              Page.30D+Page.15D+Page.7D+Page.2D, train), 
              Surv(train$Survival.Day, train$ProblemOccured), family="cox", alpha=1)
cv.fit = cv.glmnet(model.matrix( ~ age+CumPage+factor(Label)+
                       Page.Since.Last.Failure+
                       Page.30D+Page.15D+Page.7D+Page.2D, train), 
       Surv(train$Survival.Day, train$ProblemOccured), family="cox", alpha=1)
coef(cv.fit, s = "lambda.min")

########## Use pec fuction to get the prediction error and Use Test data to evaluate our model ##########
PredError <- pec(list("CoxModel"=cox_model), Surv(Survival.Day, ProblemOccured) ~ 1, data=test)
crps(PredError)
ibs(PredError)
print(PredError, times = seq(5,30,5)) # Check the error rate over time

########## Plot the Prediction Error Curve ##########
plot(PredError,xlim=c(0,200),ylim = c(0, 0.35))

########## Find the Maximum Prediction Error for the Reference and Our Cox Model ##########
which.max(PredError$AppErr$Reference)
max(PredError$AppErr$Reference)

which.max(PredError$AppErr$Cox)
max(PredError$AppErr$Cox)


########## Predict the failure rate on a specific time for a group of assets ##########
Predict_Failure_Rate = function(Age, TotalPage, Class, Page_Since_Last_Failure, Volume_30, Volume_15, Volume_7, Volume_2, time){
  assets = data.frame(age= Age,
                     CumPage = TotalPage,
                      Label = Class, 
                     Page.Since.Last.Failure = Page_Since_Last_Failure, 
                     Page.30D = Volume_30, 
                     Page.15D = Volume_15, 
                     Page.7D = Volume_7, 
                     Page.2D = Volume_2)
  predictCox(cox_model, assets, type = "survival", times = time)
}

test$Failure_rate_15 =round((1-Predict_Failure_Rate(test$age, 
                                                    test$CumPage,
                                                    test$Label, 
                                                    test$Page.Since.Last.Failure, 
                                  test$Page.30D, test$Page.15D, test$Page.7D, test$Page.2D, 15)$survival),3)



########## Find the failure rate for a specific Asset over a period ##########
NewAsset = data.frame(age = 25,
                      CumPage = 5,
                    Label = 2,
                    Page.Since.Last.Failure = 1,
                    Page.30D = 0.8, 
                    Page.15D = 0.4,
                    Page.7D = 0.08,
                    Page.2D = 0.02)

NewAssetFailureRate = data.frame(time = 1:300, failure_rate = NA)
for (i in (1:300)) {
  a = predictCox(cox_model, NewAsset, type = "survival", times = i)
  NewAssetFailureRate$failure_rate[i] = round((1-a$survival), 3)
}


plot(NewAssetFailureRate, type = "line")
