comp <- dir(path='data', pattern='^Comp_', full.names=TRUE) %>% 
    purrr::map_df(readr::read_csv)

comp

library(ggplot2)

ggplot(comp, aes(x=Title)) + geom_bar()
ggplot(comp, aes(x=Level)) + geom_bar()
ggplot(comp, aes(x=Career)) + geom_bar()

# outcome: Career
# inputs: SalaryCY, BonusCY, Years, Reports, Review, Sector, Floor

# {rpart}
# recursive partitioning
# cart: classification and regression tree

library(xgboost)

# rpart(Career ~ SalaryCY + BonusCY + Years + ...., data=comp)

# X and Y matrices (in a special object)

library(recipes)
library(dplyr)

rec2 <- recipe(Career ~ SalaryCY + BonusCY + Years + Reports + Review + Sector + Floor, data=comp) %>% 
    themis::step_downsample(Career, under_ratio=1.15) %>% 
    # step_knnimpute(all_predictors())
    step_integer(Career, zero_based=TRUE) %>% 
    step_zv(all_predictors()) %>% 
    step_other(all_nominal()) %>% 
    step_dummy(all_nominal(), one_hot=TRUE)

prep2 <- prep(rec2)

rec2
prep2

juice(prep2)

# blue, blue, yellow, blue, blue, yellow, yellow, green, blue, yellow, red, blue, yellow
# blue, blue, yellow, blue, blue, yellow, yellow, other, blue, yellow, other, blue, yellow

career_x <- juice(prep2, all_predictors(), composition='dgCMatrix')
career_x
career_y <- juice(prep2, all_outcomes(), composition='matrix')
head(career_y)
tail(career_y)
table(career_y)

