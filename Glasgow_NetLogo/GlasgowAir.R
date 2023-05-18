library(openair)
library(openairmaps)
library(tidyverse)

meta <- importMeta(source = "saqn", all = T) %>%
  filter(str_detect(code, 'GL'),
         end_date == "ongoing")

glasgow <- importSAQN(site = "GLA5", year = 2000)
