library(tidyverse)
library(data.table)
library(mapboxapi)
library(leaflet)
library(lubridate)

cctv_raw <- fread("20230630-ubdc-cctv-glasgow-records.csv")

cctv_raw %>% 
  as_tibble() %>% 
  mutate(timestamp = lubridate::as_datetime(timestamp),
         dt_hour = lubridate::floor_date(timestamp, unit = "hour"),
         dt_day = lubridate::floor_date(timestamp, unit = "day"),
         dt_year = year(timestamp)) -> cctv


cctv %>% 
  filter(dt_day >= "2022-06-01" & dt_day <= "2022-06-30") %>% 
  select(camera_id, dt_year, dt_day, cars, buses, trucks, persons, bicycles) %>% 
  filter(camera_id == 58) %>% 
  pivot_longer(!c("camera_id", "dt_year", "dt_day"), names_to = "transport", values_to = "counts") %>% 
  group_by(dt_year, dt_day, transport) %>% 
  summarise(counts = sum(counts)) %>% 
  mutate(newday = format(dt_day, "%m-%d"),
         Year = as.factor(dt_year))  -> cctv22

cctv %>% 
  filter(dt_day >= "2023-06-01" & dt_day <= "2023-06-30") %>% 
  select(camera_id, dt_year, dt_day, cars, buses, trucks, persons, bicycles) %>% 
  filter(camera_id == 58) %>% 
  pivot_longer(!c("camera_id", "dt_year", "dt_day"), names_to = "transport", values_to = "counts") %>% 
  group_by(dt_year, dt_day, transport) %>% 
  summarise(counts = sum(counts)) %>% 
  mutate(newday = format(dt_day, "%m-%d"),
         Year = as.factor(dt_year)) -> cctv23


bind_rows(cctv22, cctv23) %>%
  ggplot(aes(newday, counts)) +
  geom_line(aes(group = Year, colour = Year)) +
  labs(x = "", y = "Daily counts", title = "Transport counts from CCTV No.58") +
  facet_wrap(~transport, scales = "free") +
  theme_bw() +
  theme(legend.position = "bottom") +
  scale_x_discrete(
    breaks = c("06-01", "06-15", "06-29"),
    labels = c("Jun 1st", "Jun 15th", "Jun 30th")
  )
  

ggsave("glasgow_transport_cam58.jpg", height = 5, width = 7)




cctv %>% 
  filter(dt_day >= "2022-06-01" & dt_day <= "2022-06-30") %>% 
  select(camera_id, dt_year, dt_day, cars, buses, trucks, persons, bicycles) %>% 
  filter(camera_id == 68) %>% 
  pivot_longer(!c("camera_id", "dt_year", "dt_day"), names_to = "transport", values_to = "counts") %>% 
  group_by(dt_year, dt_day, transport) %>% 
  summarise(counts = sum(counts)) %>% 
  mutate(newday = format(dt_day, "%m-%d"),
         Year = as.factor(dt_year))  -> cctv22

cctv %>% 
  filter(dt_day >= "2023-06-01" & dt_day <= "2023-06-30") %>% 
  select(camera_id, dt_year, dt_day, cars, buses, trucks, persons, bicycles) %>% 
  filter(camera_id == 68) %>% 
  pivot_longer(!c("camera_id", "dt_year", "dt_day"), names_to = "transport", values_to = "counts") %>% 
  group_by(dt_year, dt_day, transport) %>% 
  summarise(counts = sum(counts)) %>% 
  mutate(newday = format(dt_day, "%m-%d"),
         Year = as.factor(dt_year)) -> cctv23


bind_rows(cctv22, cctv23) %>%
  ggplot(aes(newday, counts)) +
  geom_line(aes(group = Year, colour = Year)) +
  labs(x = "", y = "Daily counts", title = "Transport counts from CCTV No.68") +
  facet_wrap(~transport, scales = "free") +
  theme_bw() +
  theme(legend.position = "bottom") +
  scale_x_discrete(
    breaks = c("06-01", "06-15", "06-29"),
    labels = c("Jun 1st", "Jun 15th", "Jun 30th")
  )


ggsave("glasgow_transport_cam68.jpg", height = 5, width = 7)


#######

cctv %>% 
  filter(dt_day >= "2022-06-01" & dt_day <= "2022-06-30") %>% 
  select(camera_id, dt_year, dt_day, cars, buses, trucks, persons, bicycles) %>% 
  filter(camera_id == 27) %>% 
  pivot_longer(!c("camera_id", "dt_year", "dt_day"), names_to = "transport", values_to = "counts") %>% 
  group_by(dt_year, dt_day, transport) %>% 
  summarise(counts = sum(counts)) %>% 
  mutate(newday = format(dt_day, "%m-%d"),
         Year = as.factor(dt_year))  -> cctv22

cctv %>% 
  filter(dt_day >= "2023-06-01" & dt_day <= "2023-06-30") %>% 
  select(camera_id, dt_year, dt_day, cars, buses, trucks, persons, bicycles) %>% 
  filter(camera_id == 27) %>% 
  pivot_longer(!c("camera_id", "dt_year", "dt_day"), names_to = "transport", values_to = "counts") %>% 
  group_by(dt_year, dt_day, transport) %>% 
  summarise(counts = sum(counts)) %>% 
  mutate(newday = format(dt_day, "%m-%d"),
         Year = as.factor(dt_year)) -> cctv23


bind_rows(cctv22, cctv23) %>%
  ggplot(aes(newday, counts)) +
  geom_line(aes(group = Year, colour = Year)) +
  labs(x = "", y = "Daily counts", title = "Transport counts from CCTV No.27") +
  facet_wrap(~transport, scales = "free") +
  theme_bw() +
  theme(legend.position = "bottom") +
  scale_x_discrete(
    breaks = c("06-01", "06-15", "06-29"),
    labels = c("Jun 1st", "Jun 15th", "Jun 30th")
  )


ggsave("glasgow_transport_cam27.jpg", height = 5, width = 7)

####

cctv %>% 
  filter(dt_day >= "2022-06-01" & dt_day <= "2022-06-30") %>% 
  select(camera_id, dt_year, dt_day, cars, buses, trucks, persons, bicycles) %>% 
  filter(camera_id == 423) %>% 
  pivot_longer(!c("camera_id", "dt_year", "dt_day"), names_to = "transport", values_to = "counts") %>% 
  group_by(dt_year, dt_day, transport) %>% 
  summarise(counts = sum(counts)) %>% 
  mutate(newday = format(dt_day, "%m-%d"),
         Year = as.factor(dt_year))  -> cctv22

cctv %>% 
  filter(dt_day >= "2023-06-01" & dt_day <= "2023-06-30") %>% 
  select(camera_id, dt_year, dt_day, cars, buses, trucks, persons, bicycles) %>% 
  filter(camera_id == 423) %>% 
  pivot_longer(!c("camera_id", "dt_year", "dt_day"), names_to = "transport", values_to = "counts") %>% 
  group_by(dt_year, dt_day, transport) %>% 
  summarise(counts = sum(counts)) %>% 
  mutate(newday = format(dt_day, "%m-%d"),
         Year = as.factor(dt_year)) -> cctv23


bind_rows(cctv22, cctv23) %>%
  ggplot(aes(newday, counts)) +
  geom_line(aes(group = Year, colour = Year)) +
  labs(x = "", y = "Daily counts", title = "Transport counts from CCTV No.423") +
  facet_wrap(~transport, scales = "free") +
  theme_bw() +
  theme(legend.position = "bottom") +
  scale_x_discrete(
    breaks = c("06-01", "06-15", "06-29"),
    labels = c("Jun 1st", "Jun 15th", "Jun 30th")
  )


ggsave("glasgow_transport_cam423.jpg", height = 5, width = 7)

###
cctv %>% 
  filter(dt_day >= "2022-06-01" & dt_day <= "2022-06-30") %>% 
  select(camera_id, dt_year, dt_day, cars, buses, trucks, persons, bicycles) %>% 
  filter(camera_id == 18) %>% 
  pivot_longer(!c("camera_id", "dt_year", "dt_day"), names_to = "transport", values_to = "counts") %>% 
  group_by(dt_year, dt_day, transport) %>% 
  summarise(counts = sum(counts)) %>% 
  mutate(newday = format(dt_day, "%m-%d"),
         Year = as.factor(dt_year))  -> cctv22

cctv %>% 
  filter(dt_day >= "2023-06-01" & dt_day <= "2023-06-30") %>% 
  select(camera_id, dt_year, dt_day, cars, buses, trucks, persons, bicycles) %>% 
  filter(camera_id == 18) %>% 
  pivot_longer(!c("camera_id", "dt_year", "dt_day"), names_to = "transport", values_to = "counts") %>% 
  group_by(dt_year, dt_day, transport) %>% 
  summarise(counts = sum(counts)) %>% 
  mutate(newday = format(dt_day, "%m-%d"),
         Year = as.factor(dt_year)) -> cctv23


bind_rows(cctv22, cctv23) %>%
  ggplot(aes(newday, counts)) +
  geom_line(aes(group = Year, colour = Year)) +
  labs(x = "", y = "Daily counts", title = "Transport counts from CCTV No.18") +
  facet_wrap(~transport, scales = "free") +
  theme_bw() +
  theme(legend.position = "bottom") +
  scale_x_discrete(
    breaks = c("06-01", "06-15", "06-29"),
    labels = c("Jun 1st", "Jun 15th", "Jun 30th")
  )


ggsave("glasgow_transport_cam18.jpg", height = 5, width = 7)


############

cctv %>% 
  group_by(camera_id) %>% 
  slice(1) %>% 
  select(camera_id, longitude, latitude) %>% 
  ungroup %>% 
  mutate(camera_id = factor(camera_id)) -> camera_locations

#write_csv(camera_locations, "camera.csv")

leaflet() %>% 
  addMapboxTiles(style_id = "streets-v8",
                 #style_id = "light-v9",
                 username = "mapbox") %>% 
  addCircleMarkers(data = camera_locations,
                   label = camera_locations$camera_id,
                   radius = 5,
                   labelOptions = labelOptions(noHide = T)) 



cctv %>% 
  #group_by(dt_day) %>% 
  filter(dt_year != 2019) %>% #removing 2019
  group_by(camera_id) %>% 
  select(6:11) %>% 
  summarise(cars = sum(cars)) %>% 
  arrange(desc(cars)) %>% 
  print(n = Inf) 


cctv %>% 
  select(dt_year, cars, persons, bicycles, buses, motorcycles, trucks) %>% 
  pivot_longer(!dt_year, names_to = "mode", values_to = "value") %>% 
  group_by(year, mode) %>% 
  summarise(value = sum(value)) %>% 
  filter(year != 2019) %>% 
  mutate(mode = factor(mode, levels = c("bicycles", "cars", "persons", "buses", "trucks", "motorcycles"))) -> transport_df 

transport_df %>% 
  filter(year == 2020) %>% 
  mutate(prop = value / sum(value) * 100) %>% 
  arrange(desc(value)) 

transport_df %>% 
  filter(year == 2021) %>% 
  mutate(prop = value / sum(value) * 100) %>% 
  arrange(desc(value)) 


transport_df %>% 
  filter(year == 2022) %>% 
  mutate(prop = value / sum(value) * 100) %>% 
  arrange(desc(value)) 

transport_df %>% 
  filter(year == 2023) %>% 
  mutate(prop = value / sum(value) * 100) %>% 
  arrange(desc(value)) 


sort(unique(cctv$camera_id))
length(unique(cctv$camera_id))

cctv %>% 
  group_by(dt_day) %>% 
  summarise(cars = sum(cars)) %>% 
  ggplot(aes(dt_day, cars)) +
  geom_line()
#######################

cctv %>% 
  filter(dt_year == 2021) %>% 
  mutate(dt_hour = hour(dt_hour)) %>% 
  select(dt_hour, cars, persons, bicycles, buses, motorcycles, trucks) %>% 
  pivot_longer(!dt_hour, names_to = "mode", values_to = "value") %>% 
  group_by(dt_hour, mode) %>% 
  summarise(value = round(sum(value)/365, 0))  -> transport_df_hour


transport_df_hour %>% 
  ggplot(aes(dt_hour, value)) +
  geom_line(aes(colour = mode), size = 2) +
  labs(x = "Hour", y = "Counts") +
  theme_minimal() +
  theme(legend.position = "bottom",
        text = element_text(size = 20)) +
  scale_colour_manual(
    name = NULL,
    values = c("#1f83b4",  "#18a188", "#ffb022", "#6f63bb", "#de3e3e","#29a03c") 
  ) 

ggsave("hour.jpg", width = 6, height = 5)

#########
cctv %>% 
  group_by(dt_day, camera_id) %>% 
  summarise(cars = sum(cars)) %>% 
  ggplot(aes(dt_day, cars)) +
  geom_line() +
  facet_wrap(~camera_id)


########################
cctv %>% 
  group_by(camera_id) %>% 
  summarise(cycle = sum(bicycles)) %>% 
  arrange(desc(cycle)) %>% 
  print(n = Inf) 


cctv %>% 
  group_by(dt_day, camera_id) %>% 
  summarise(bicycles = sum(bicycles)) %>% 
  ggplot(aes(dt_day, bicycles)) +
  geom_line() +
  facet_wrap(~camera_id)



########################
cctv %>% 
  group_by(camera_id) %>% 
  summarise(people = sum(persons)) %>% 
  arrange(desc(people)) %>% 
  print(n = Inf) 


##########################

library(magrittr)
library(hrbrthemes)
library(waffle)

three_states <- sample(state.name, 3)

data.frame(
  parts = factor(rep(month.abb[1:3], 3), levels=month.abb[1:3]),
  vals = c(10, 20, 30, 6, 14, 40, 30, 20, 10),
  col = rep(c("blue", "black", "red"), 3),
  fct = c(rep("Thing 1", 3),
          rep("Thing 2", 3),
          rep("Thing 3", 3))
) -> xdf

xdf


xdf %>%
  count(parts, wt = vals) %>%
  ggplot(aes(fill = parts, values = n)) +
  geom_waffle(n_rows = 20, size = 0.33, colour = "white", flip = TRUE, na.rm = NA, show.legend = NA) +
  scale_fill_manual(
    name = NULL,
    values = c("#a40000", "#c68958", "#ae6056"),
    labels = c("Fruit", "Sammich", "Pizza")
  ) +
  coord_equal() +
  theme_void() +
  theme_enhance_waffle()



storms %>% 
  filter(year >= 2019) %>% 
  count(year, status) -> storms_df

ggplot(storms_df, aes(fill = status, values = n)) +
  geom_waffle(color = "white", size = .25, n_rows = 10, flip = TRUE) +
  facet_wrap(~year, nrow = 1, strip.position = "bottom") +
  scale_x_discrete() + 
  scale_y_continuous(labels = function(x) x * 10, # make this multiplyer the same as n_rows
                     expand = c(0,0)) +
  ggthemes::scale_fill_tableau(name=NULL) +
  coord_equal() +
  labs(
    title = "Faceted Waffle Bar Chart",
    subtitle = "{dplyr} storms data",
    x = "Year",
    y = "Count"
  ) +
  theme_minimal() +
  theme(panel.grid = element_blank(), axis.ticks.y = element_line()) +
  guides(fill = guide_legend(reverse = TRUE))

#######
transport_df

ggplot(transport_df, aes(fill = mode, values = value/10000)) +
  geom_waffle(color = "white", size = .25, n_rows = 10, flip = TRUE) +
  facet_wrap(~dt_year, nrow = 1, strip.position = "bottom") +
  scale_x_discrete() + 
  scale_y_continuous(#labels = function(x) x * 10, # make this multiplyer the same as n_rows
                    expand = c(0,0)) +
  ggthemes::scale_fill_tableau(name=NULL) +
  coord_equal() +
  labs(
    title = "Glasgow CCTV data by Transport Mode",
    subtitle = "Jan.2020 - Mar.2023",
    x = "Year",
    y = "Count * 10^4"
  ) +
  theme_minimal() +
  theme(panel.grid = element_blank(), axis.ticks.y = element_line()) +
  guides(fill = guide_legend(reverse = TRUE))

ggsave("waffle.png", width = 8, height = 6)


# https://github.com/hrbrmstr/waffle
# https://geospock.com/en/resources/blog/using-data-visualisation-to-beat-gridlock/
# https://www.kaggle.com/code/ricardoxp1/seoul-cctv-cameras-spatial-analysis

######################
#install.packages("stats19")
library(stats19)
library(sf)
# crashes2020 = get_stats19(year = 2020, type = "accident")
# crashes2021 = get_stats19(year = 2021, type = "accident")
# crashes2022 = get_stats19(year = 2022, type = "accident")
crashes = get_stats19(year = 2020, type = "accident")

crashes_glasgow <- crashes %>% 
  # filter(longitude >= min(camera_locations$longitude) & longitude <= max(camera_locations$longitude),
  #        latitude >= min(camera_locations$latitude) & latitude <= max(camera_locations$latitude)
  #        )
  filter(longitude >= -4.4 & longitude <= -4.1,
         latitude >= 55.75 & latitude <= 55.95
  )

dim(crashes_glasgow)
crashes_sf = format_sf(crashes_glasgow)

crashes_sf %>% 
  st_transform(4326) %>% 
  select(longitude, latitude, accident_severity, day_of_week, light_conditions, weather_conditions) -> glasgow_accident


leaflet() %>% 
  addMapboxTiles(style_id = "streets-v8",
                 #style_id = "light-v9",
                 username = "mapbox") %>% 
  addCircleMarkers(data = glagsow_accident,
                   label = glagsow_accident$accident_severity,
                   color = ~ ifelse(glagsow_accident$accident_severity == "Slight", "green", 
                                    ifelse(glagsow_accident$accident_severity == "Serious", "orange", 
                                    "darkred")),
                   radius = 1) 

##
glasgow_accident %>% 
  group_by(light_conditions) %>% 
  summarise(n= n())

glasgow_accident %>% 
  group_by(day_of_week) %>% 
  summarise(n= n()) %>% 
  arrange(desc(n))

glasgow_accident %>% 
  group_by(weather_conditions) %>% 
  summarise(n= n()) %>% 
  arrange(desc(n))


####
casualties = get_stats19(year = 2020, type = "casualty", ask = FALSE)
nrow(casualties)
ncol(casualties)
sel = casualties$accident_index %in% crashes_sf$accident_index
casualties_glasgow = casualties[sel, ]

cas_types = casualties_glasgow %>%
  select(accident_index, casualty_type) %>%
  mutate(n = 1) %>%
  group_by(accident_index, casualty_type) %>%
  summarise(n = sum(n)) %>%
  tidyr::spread(casualty_type, n, fill = 0)

cas_types$Total = rowSums(cas_types[-1])

cj = left_join(crashes_glasgow, cas_types, by = "accident_index")

crashes_sf %>%
  select(accident_index, accident_severity) %>% 
  st_drop_geometry()


library(stringr)

crash_times = cj %>% 
  group_by(hour = as.numeric(str_sub(time, 1, 2))) %>% 
  summarise(
    walking = sum(Pedestrian),
    cycling = sum(Cyclist),
    passenger = sum(`Car occupant`)
  ) %>% 
  tidyr::gather(mode, casualties, -hour)



ggplot(crash_times, aes(hour, casualties)) +
  geom_line(aes(colour = mode), size = 2) +
  labs(x = "Hour", y = "Counts") +
  theme_minimal() +
  theme(legend.position = "bottom",
        text = element_text(size = 20)) +
  scale_colour_manual(
    name = NULL,
    values = c("#1f83b4", "#de3e3e", "#ffb022") 
  ) 

ggsave("casualty_hour.jpg", width = 6, height = 5)

