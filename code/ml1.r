# Data ####
dir('data', pattern='^Comp_')

europe <- readr::read_csv('data/Comp_Europe.csv')
europe

# EDA ####
library(ggplot2)
ggplot(europe, aes(x=Years, y=SalaryCY)) + geom_point() + geom_smooth()
ggplot(europe, aes(x=Years, y=SalaryCY)) + geom_point(aes(color=Title)) + geom_smooth()
ggplot(europe, aes(x=Years, y=SalaryCY)) + geom_jitter(aes(color=Title)) + geom_smooth()
ggplot(europe, aes(x=Title)) + geom_bar()
ggplot(europe, aes(x=Years)) + geom_histogram()

# More Data
dim(europe)

the_files <- dir('data', pattern='^Comp_', full.names=TRUE)
the_files

comp <- purrr::map_df(the_files, readr::read_csv)
comp
dim(comp)
ggplot(comp, aes(x=Region)) + geom_bar()

ggplot(comp, aes(x=Years, y=SalaryCY)) + geom_jitter(aes(color=Title), alpha=1/4) + geom_smooth()

# First Model ####

mod1 <- lm(SalaryCY ~ Region + Title + Years + Reports + Review + Sector + Level + Career + Office + Floor + Retirement, data=comp)
mod1
coef(mod1)
summary(mod1)

library(coefplot)
coefplot(mod1, sort='magnitude', lwdInner=2, lwdOuter=1)
# development version can make an interactive plot
coefplot(mod1, sort='magnitude', interactive=TRUE)

library(magrittr)

coef(mod1) %>% names() %>% sort()

# blue, green, red, yellow
colors <- c('blue', 'green', 'green', 'green', 'blue', 'red', 'blue', 'yellow')
colors
model.matrix( ~ colors)

# if you have q unique values of a categorical variable, you get q - 1 dummy variables

# terminology ####

# outcome: response, target, label, y, dependent variable (don't use this term)
# inputs: predictors, features, variables, covariates, data (don't use this), independent variables (don't use)
# intercept: bias (don't use this), consider as just another coefficient
# coefficients: weights

# how good did lm fit our data?
# RMSE
# MAE
# R^2 (don't use this)

# glmnet ####

library(glmnet)
library(recipes)

# glmnet (pronounced glim-net, not g-l-m-net) is THE package for fitting elastic nets
# elastic net is a combination of L2-ridge regression and L1-lasso regression

# lm: formula, data.frame
# glmnet: x and y matrices

# can't glmnet(SalaryCY ~ Reports + Title, data=comp)

# we need to build a matrix of inputs and a matrix for the output
# do that we'll use {recipes}
# biggest thing we need to do is create dummy variables for the categroical inputs

rec1 <- recipe(SalaryCY ~ Region + Title + Years + Reports + Review + Sector + Level + Career + Office + Floor + Retirement, data=comp) %>% 
    step_dummy(all_nominal(), one_hot=TRUE)
rec1
prep1 <- prep(rec1)
prep1

juice(prep1)

dense_x <- juice(prep1, all_predictors(), composition='matrix')
head(dense_x)
lobstr::obj_size(dense_x)

comp_x <- juice(prep1, all_predictors(), composition='dgCMatrix')
comp_x
lobstr::obj_size(comp_x)

# sparse matrices take up less memory and can be computed on faster

comp_y <- juice(prep1, all_outcomes(), composition='matrix')
head(comp_y)
