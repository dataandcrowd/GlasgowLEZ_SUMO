library(data.table)
library(tidyverse)
library(leaflet)


local <- fread("local_authority_traffic.csv")
counts_aadf <- fread("dft_traffic_counts_aadf.csv")


counts_aadf %>% 
  filter(Year == 2021,
         str_detect(Local_authority_name, "Glasgow")) -> counts_aadf_glasgow




leaflet(counts_aadf_glasgow) %>% 
  addTiles() %>%
  addCircleMarkers(lng = ~Longitude, lat = ~Latitude,
                   label = ~All_motor_vehicles)
