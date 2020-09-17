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
# biggest thing we need to do is create dummy variables for the categorical inputs

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

mod2 <- glmnet(x=comp_x, y=comp_y, family='gaussian')
mod2
plot(mod2, xvar='lambda')
View(as.matrix(coef(mod2)))
plot(mod2, xvar='lambda', label=TRUE)
coefpath(mod2)

mod2$lambda
coefplot(mod2, sort='magnitude', lambda=500000)
coefplot(mod2, sort='magnitude', lambda=50000)
coefplot(mod2, sort='magnitude', lambda=5000)
coefplot(mod2, sort='magnitude', lambda=500)
coefplot(mod2, sort='magnitude', lambda=50)
coefplot(mod2, sort='magnitude', lambda=5)

library(patchwork)
coefplot(mod2, sort='magnitude', lambda=50000, intercept=FALSE) / 
    coefplot(mod2, sort='magnitude', lambda=5000, intercept=FALSE) / 
    coefplot(mod2, sort='magnitude', lambda=500, intercept=FALSE)

mod2 <- glmnet(x=comp_x, y=comp_y, family='gaussian', alpha=1)

mod3 <- cv.glmnet(x=comp_x, y=comp_y, family='gaussian', alpha=1, nfolds=10)
plot(mod3)
mod3$lambda.min
coefplot(mod3, sort='magnitude', lambda=mod3$lambda.min)
coefplot(mod3, sort='magnitude', lambda='lambda.min')
mod3$lambda.1se
coefplot(mod3, sort='magnitude', lambda='lambda.1se')
coefpath(mod3)

# ridge ####

mod4 <- cv.glmnet(x=comp_x, y=comp_y, family='gaussian', nfolds=10, alpha=0)
coefpath(mod4)
mod4$lambda
coefplot(mod4, sort='magnitude', intercept=FALSE, lambda=50000000)
coefplot(mod4, sort='magnitude', intercept=FALSE, lambda=5000000)
coefplot(mod4, sort='magnitude', intercept=FALSE, lambda=500000)
coefplot(mod4, sort='magnitude', intercept=FALSE, lambda=50000)
coefplot(mod4, sort='magnitude', intercept=FALSE, lambda=5000)
plot(mod4)

# lasso is better for variable selection
# ridge is better for many correlated inputs

mod5 <- cv.glmnet(x=comp_x, y=comp_y, family='gaussian', nfolds=10, alpha=0.5)
coefpath(mod5)
plot(mod5)
mod6 <- cv.glmnet(x=comp_x, y=comp_y, family='gaussian', nfolds=10, alpha=0.8)
mod7 <- cv.glmnet(x=comp_x, y=comp_y, family='gaussian', nfolds=10, alpha=0.2)

find_error <- function(model)
{
    model$cvm[model$lambda == model$lambda.1se]
}

tibble::tibble(Mod=3:7, Error=c(find_error(mod3)
, find_error(mod4)
, find_error(mod5)
, find_error(mod6)
, find_error(mod7))
) %>% ggplot(aes(x=Mod, y=Error)) + geom_col()

# cv.glmnet cross-validates lambda, not alpha
# to cross-validate alpha, either build your own (page 336 of R For Everyone Second Edition) or use {rsample}/{tune} (learn ODSC West)

