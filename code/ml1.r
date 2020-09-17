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
# inputs: predictors, features, variables, covariates, data (don't use this), independent variabels (don't use)
# intercept: bias (don't use this), consider as just another coefficient
# coefficients: weights

# how good did lm fit our data?
# RMSE
# MAE
# R^2 (don't use this)


