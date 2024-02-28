# install packages

install.packages("leaflet")
library(leaflet)

install.packages("mapview")
library(mapview)

install.packages("tidyverse")
library(tidyverse)

install.packages("magrittr")
library(magrittr)

# read the data

data <- read.csv("data/cleanedData.csv")


# create map
map <- leaflet() |>
  addProviderTiles("Esri.WorldTopoMap") |>
  addCircleMarkers(data = data,
                   lat = ~decimalLatitude,
                   lng = ~decimalLongitude,
                   radius = 3,
                   color = "maroon",
                   fill = 0.3) |>
  addLegend(position = "topright",
            title = "Species Occurences",
            labels = "Red Tree Vole",
            colors = "maroon",
            opacity = 0.3)


#made the map
map <- map |>
  addProviderTiles("Esri.WorldTopoMap") |>
  addCircleMarkers(data = data,
                   lat = ~decimalLatitude,
                   lng = ~decimalLongitude,
                   radius = 3,
                   color = "pink",
                   fill = 0.3) |>
  addLegend(position = "topright",
            title = "Species Occurences",
            labels = "Red Tree Vole",
            colors = "pink",
            opacity = 0.3)

map


#save the map
install.packages("webshot2")
library(webshot2)


mapshot2(map, file = "output/leafletTest.png")






