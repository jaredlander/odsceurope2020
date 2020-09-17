dir('data', pattern='^Comp_')

europe <- readr::read_csv('data/Comp_Europe.csv')
europe

library(ggplot2)
ggplot(europe, aes(x=Years, y=SalaryCY)) + geom_point() + geom_smooth()
ggplot(europe, aes(x=Years, y=SalaryCY)) + geom_point(aes(color=Title)) + geom_smooth()
ggplot(europe, aes(x=Years, y=SalaryCY)) + geom_jitter(aes(color=Title)) + geom_smooth()
ggplot(europe, aes(x=Title)) + geom_bar()
ggplot(europe, aes(x=Years)) + geom_histogram()
