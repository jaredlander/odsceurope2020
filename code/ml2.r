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

rec2 <- recipe(Career ~ Years + Review + Sector + Floor, data=comp) %>% 
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

library(xgboost)

career_xg <- xgb.DMatrix(data=career_x, label=career_y)
career_xg
class(career_xg)

tree1 <- xgb.train(
    data=career_xg,
    objective='binary:logistic',
    nrounds=1
)
tree1
xgb.plot.multi.trees(tree1)

library(modeldata)
data(credit_data)
credit_data

credit_data %>% count(Status)

rec3 <- recipe(Status ~ ., data=credit_data) %>% 
    themis::step_downsample(Status, under_ratio=1.15) %>% 
    step_integer(Status, zero_based=TRUE) %>% 
    step_nzv(all_predictors()) %>% 
    step_other(all_nominal(), other='misc') %>% 
    step_dummy(all_nominal(), one_hot=TRUE)
rec3
prep3 <- prep(rec3)
juice(prep3)

credit_x <- juice(prep3, all_predictors(), composition='dgCMatrix')
credit_y <- juice(prep3, all_outcomes(), composition='matrix')
credit_x
head(credit_y)

credit_xg <- xgb.DMatrix(data=credit_x, label=credit_y)

tree1 <- xgb.train(
    data=credit_xg,
    objective='binary:logistic',
    nrounds=1
)
xgb.plot.multi.trees(tree1)


# common problem: overfitting, unstable, high variance

# two solutions: random forest, boosted tree

tree2 <- xgb.train(
    data=credit_xg,
    objective='binary:logistic',
    nrounds=100
)
tree2
xgb.plot.multi.trees(tree2)

library(vip)
vip(tree2, num_features=15)


tree3 <- xgb.train(
    data=credit_xg,
    objective='binary:logistic',
    nrounds=100,
    eval_metric='logloss',
    watchlist=list(train=credit_xg),
    print_every_n=10
)

tree4 <- xgb.train(
    data=credit_xg,
    objective='binary:logistic',
    nrounds=200,
    eval_metric='logloss',
    watchlist=list(train=credit_xg),
    print_every_n=10
)

tree5 <- xgb.train(
    data=credit_xg,
    objective='binary:logistic',
    nrounds=500,
    eval_metric='logloss',
    watchlist=list(train=credit_xg),
    print_every_n=10
)

library(rsample)

credit_split <- initial_split(credit_data, prop=0.8, strata='Status')
credit_split
credit_train <- training(credit_split)
credit_val <- testing(credit_split)
credit_train %>% as_tibble()
credit_val %>% as_tibble()


rec3 <- recipe(Status ~ ., data=credit_train) %>% 
    themis::step_downsample(Status, under_ratio=1.15) %>% 
    step_integer(Status, zero_based=TRUE) %>% 
    step_nzv(all_predictors()) %>% 
    step_other(all_nominal(), other='misc') %>% 
    step_dummy(all_nominal(), one_hot=TRUE)
prep3 <- prep(rec3)

credit_x <- juice(prep3, all_predictors(), composition='dgCMatrix')
credit_y <- juice(prep3, all_outcomes(), composition='matrix')

credit_xg <- xgb.DMatrix(data=credit_x, label=credit_y)

credit_val_x <- bake(prep3, new_data=credit_val, all_predictors(), composition='dgCMatrix')
credit_val_y <- bake(prep3, new_data=credit_val, all_outcomes(), composition='matrix')

credit_val_xg <- xgb.DMatrix(data=credit_val_x, label=credit_val_y)

tree5 <- xgb.train(
    data=credit_xg,
    objective='binary:logistic',
    nrounds=500,
    eval_metric='logloss',
    watchlist=list(train=credit_xg),
    print_every_n=10
)

tree6 <- xgb.train(
    data=credit_xg,
    objective='binary:logistic',
    nrounds=500,
    eval_metric='logloss',
    watchlist=list(train=credit_xg, validate=credit_val_xg),
    print_every_n=10
)

library(dygraphs)

dygraph(tree6$evaluation_log)


tree7 <- xgb.train(
    data=credit_xg,
    objective='binary:logistic',
    nrounds=200,
    eval_metric='logloss',
    watchlist=list(train=credit_xg, validate=credit_val_xg),
    print_every_n=10,
    max_depth=3
)
min(tree7$evaluation_log$validate_logloss)
min(tree6$evaluation_log$validate_logloss)

tree8 <- xgb.train(
    data=credit_xg,
    objective='binary:logistic',
    nrounds=200,
    eval_metric='logloss',
    watchlist=list(train=credit_xg, validate=credit_val_xg),
    print_every_n=10,
    max_depth=10
)
min(tree8$evaluation_log$validate_logloss)

tree9 <- xgb.train(
    data=credit_xg,
    objective='binary:logistic',
    nrounds=200,
    eval_metric='logloss',
    watchlist=list(train=credit_xg, validate=credit_val_xg),
    print_every_n=10,
    max_depth=2
)
min(tree9$evaluation_log$validate_logloss)

tree10 <- xgb.train(
    data=credit_xg,
    objective='binary:logistic',
    nrounds=200,
    eval_metric='logloss',
    watchlist=list(train=credit_xg, validate=credit_val_xg),
    print_every_n=10,
    max_depth=2,
    eta=0.2
)
min(tree10$evaluation_log$validate_logloss)

tree11 <- xgb.train(
    data=credit_xg,
    objective='binary:logistic',
    nrounds=200,
    eval_metric='logloss',
    watchlist=list(train=credit_xg, validate=credit_val_xg),
    print_every_n=10,
    max_depth=2,
    eta=0.45
)
min(tree11$evaluation_log$validate_logloss)

tree12 <- xgb.train(
    data=credit_xg,
    objective='binary:logistic',
    nrounds=200,
    eval_metric='logloss',
    watchlist=list(train=credit_xg, validate=credit_val_xg),
    print_every_n=10,
    max_depth=2,
    eta=0.45,
    early_stopping_rounds=30
)
dygraph(tree12$evaluation_log)


tree13 <- xgb.train(
    data=credit_xg,
    objective='binary:logistic',
    nrounds=200,
    eval_metric='logloss',
    watchlist=list(train=credit_xg, validate=credit_val_xg),
    print_every_n=10,
    max_depth=2,
    eta=0.45,
    early_stopping_rounds=30,
    subsample=0.7
)

tree14 <- xgb.train(
    data=credit_xg,
    objective='binary:logistic',
    nrounds=200,
    eval_metric='logloss',
    watchlist=list(train=credit_xg, validate=credit_val_xg),
    print_every_n=10,
    max_depth=2,
    eta=0.45,
    early_stopping_rounds=30,
    subsample=0.7,
    colsample_bytree=0.5
)

tree15 <- xgb.train(
    data=credit_xg,
    objective='binary:logistic',
    nrounds=1,
    eval_metric='logloss',
    watchlist=list(train=credit_xg, validate=credit_val_xg),
    print_every_n=10,
    max_depth=2,
    eta=0.45,
    early_stopping_rounds=30,
    subsample=0.5,
    colsample_bytree=0.5,
    num_parallel_tree=200
)
# pseudo random forest

tree16 <- xgb.train(
    data=credit_xg,
    objective='binary:logistic',
    nrounds=100,
    eval_metric='logloss',
    watchlist=list(train=credit_xg, validate=credit_val_xg),
    print_every_n=10,
    max_depth=2,
    eta=0.45,
    early_stopping_rounds=30,
    subsample=0.5,
    colsample_bytree=0.5,
    num_parallel_tree=50
)
# boosted pseudo random forest

tree17 <- xgb.train(
    data=credit_xg,
    objective='binary:logistic',
    nrounds=100,
    eval_metric='logloss',
    watchlist=list(train=credit_xg, validate=credit_val_xg),
    print_every_n=10,
    max_depth=2,
    eta=0.45,
    early_stopping_rounds=30,
    subsample=0.5,
    colsample_bytree=0.5,
    num_parallel_tree=100
)
# boosted pseudo random forest
?xgb.train

credit_val_x

preds14 <- predict(tree14, newdata=credit_val_x)
preds14 %>% head
credit_val_y %>% head

logloss <- function(truth, predicted)
{
    mean(-(truth*log(predicted) + (1 - truth)*log(1 - predicted)))
}

logloss(credit_val_y, preds14)

rec4 <- recipe(Status ~ ., data=credit_train) %>% 
    themis::step_downsample(Status) %>% 
    step_nzv(all_predictors()) %>% 
    step_normalize(all_numeric()) %>% 
    step_integer(Status, zero_based=TRUE) %>% 
    step_other(all_nominal(), other='misc') %>% 
    step_dummy(all_nominal(), one_hot=TRUE) %>% 
    step_intercept()
prep4 <- prep(rec4)

reg_x <- juice(prep4, all_predictors(), composition='dgCMatrix')
reg_y <- juice(prep4, all_outcomes(), composition='matrix')

reg_xg <- xgb.DMatrix(data=reg_x, label=reg_y)

reg1 <- xgb.train(
    data=reg_xg,
    booster='gblinear',
    objective='reg:logistic',
    nrounds=100,
    watchlist=list(train=reg_xg),
    print_every_n=10,
    alpha=.005
)
