# scripts for generating current and future Species Distribution Models

#### Start Current SDM ######
# 0. Load packages

source("src/packages.R")

# 1. Get occurrence Data 

# start with our data

# get our occurrence data, just lat/lon
occurrenceCoords<-read_csv("data/cleanedData.csv") %>%
  dplyr::select( decimalLongitude, decimalLatitude)


occurrenceSpatialPts <- SpatialPoints(occurrenceCoords, 
                                      proj4string = CRS("+proj=longlat"))


# now get the climate data
# make sure RAM is bumped up

# this downloads 19 raster files, one for each climate variable
worldclim_global(var="bio", res=2.5, path="data/", version="2.1") 

# update .gitignore to prevent huge files getting pushed to github

#Here are the meanings of the bioclimatic variables (bio1 to bio19) provided by WorldClim:
#bio1: Mean annual temperature
#bio2: Mean diurnal range (mean of monthly (max temp - min temp))
#bio3: Isothermality (bio2/bio7) (* 100)
#bio4: Temperature seasonality (standard deviation *100)
#bio5: Max temperature of warmest month
#bio6: Min temperature of coldest month
#bio7: Temperature annual range (bio5-bio6)
#bio8: Mean temperature of wettest quarter
#bio9: Mean temperature of driest quarter
#bio10: Mean temperature of warmest quarter
#bio11: Mean temperature of coldest quarter
#bio12: Annual precipitation
#bio13: Precipitation of wettest month
#bio14: Precipitation of driest month
#bio15: Precipitation seasonality (coefficient of variation)
#bio16: Precipitation of wettest quarter
#bio17: Precipitation of driest quarter
#bio18: Precipitation of warmest quarter
#bio19: Precipitation of coldest quarter






# let's create a faster stack (stack of layers/variables)
# list of files
climList <- list.files(path = "data/wc2.1_2.5m/", 
                       pattern = ".tif$", 
                       full.names = T)



# create the raster stack from the files list
currentClimRasterStack <- raster::stack(climList)

# plot annual temperature
plot(currentClimRasterStack[[1]]) 

# plot the points
plot(occurrenceSpatialPts, add = TRUE) 




#2. Create pseudo-absence points

# mask is the raster object that determines the area we're interested in
mask <- raster(climList[[1]]) 


# drill down on where our data lives
geographicExtent <- extent(x = occurrenceSpatialPts)


# standardize random points for reproduce-ability
set.seed(45) 


# create psuedo-absence points
backgroundPoints <- randomPoints(mask = mask, 
                                 n = nrow(occurrenceCoords), #same n 
                                 ext = geographicExtent, 
                                 extf = 1.25, # draw a slightly larger area 
                                 warn = 0) 


# change column names
colnames(backgroundPoints) <- c("longitude", "latitude")


# 3. Convert occurrence and environmental data into format for model

# Data for observation sites (presence and background), with climate data


# create a grid of climate measurements, per occurrence point
occEnv <- na.omit(raster::extract(x = currentClimRasterStack, y = occurrenceCoords))

# create a grid of measurements for the pseudo-absence points
absenceEnv<- na.omit(raster::extract(x = currentClimRasterStack, y = backgroundPoints))

# create a vector of presence/absence
presenceAbsenceV <- c(rep(1, nrow(occEnv)), rep(0, nrow(absenceEnv))) 

# create a single frame of presence/absence data by climate variable
presenceAbsenceEnvDf <- as.data.frame(rbind(occEnv, absenceEnv))


# 4. Create Current SDM with maxent


# If you get a Java error, restart R, and reload the packages
arborimusCurrentSDM <- dismo::maxent(x = presenceAbsenceEnvDf, ## env conditions
                                       p = presenceAbsenceV,   ## 1:presence or 0:absence
                                       path=paste("maxent_outputs"), #maxent output dir 
)                              


# 5. Plot the current SDM with ggplot


# bump up our bounding box
predictExtent <- 6 * geographicExtent 

# crops the geographic area
geographicArea <- crop(currentClimRasterStack, predictExtent, snap = "in")

# make a raster layer for the map, combining everything
arborimusPredictPlot <- raster::predict(arborimusCurrentSDM, geographicArea) 

# create spacial pixels data frame
raster.spdf <- as(arborimusPredictPlot, "SpatialPixelsDataFrame")

arborimusPredictDf <- as.data.frame(raster.spdf)

# get world boundaries
wrld <- ggplot2::map_data("world")


# create bounding box
xmax <- -115
xmin <- -126
ymax <- 50
ymin <- 30

# create map
ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = arborimusPredictDf, aes(x = x, y = y, fill = layer)) + 
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) +#expand=F fixes margin
  scale_size_area() +
  borders("state") +
  borders("world", colour = "black", fill = NA) + 
  labs(title = "SDM of Arborimus longicaudus Under Current Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Environmental Suitability")+ 
  theme(plot.title = element_text(hjust=0.2))+
  labs(caption = "Figure 2: Maxent Species Distribution Model of the Red Tree Vole (Arborius longicaudus). 
       This species is mostly detected in western Oregon and very northwestern California, however suitable habitat
       extends into southwestern Washington. Occurrence data was downloaded from GBIF on 03/19/2024
       (doi:https://www.gbif.org/species/2437931) and available on GitHub
       (https://github.com/BiodiversityDataScienceCorp/2024_Group1/tree/main/maxent_outputs).")+ 
  theme(plot.caption = element_text(hjust=0.2))+
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 

# save to file
ggsave("output/arborimusCurrentSdm.jpg",  width = 8, height = 6)

#### End Current SDM #########


#### Start Future SDM ########


# 6. Get Future Climate Projections

# CMIP6 is the most current and accurate modeling data
# More info: https://pcmdi.llnl.gov/CMIP6/

# downloading future climate data
futureClimateRaster <- cmip6_world("CNRM-CM6-1", "585", "2061-2080", var = "bioc", res=2.5, path="data/cmip6")

# 7. Prep for the model

# rename data sets to match
names(futureClimateRaster)=names(currentClimRasterStack)


# bump up our bounding box
predictExtent <- 2.5 * geographicExtent

# crop geographic area
geographicAreaFutureC6 <- crop(futureClimateRaster, predictExtent)


# 8. Run the future SDM

arborimusFutureSDM <- raster::predict(arborimusCurrentSDM, geographicAreaFutureC6)


# 9. Plot the future SDM

# get world boundaries
wrld <- ggplot2::map_data("world")

arborimusFutureSDMDf <- as.data.frame(arborimusFutureSDM, xy=TRUE)

# create bounding box
xmax <- max(arborimusFutureSDMDf$x)
xmin <- min(arborimusFutureSDMDf$x)
ymax <- max(arborimusFutureSDMDf$y)
ymin <- min(arborimusFutureSDMDf$y)

# create map
ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = arborimusFutureSDMDf, aes(x = x, y = y, fill = maxent)) + 
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) +
  scale_size_area() +
  borders("state") +
  borders("world", colour = "black", fill = NA) + 
  labs(title = "Future SDM of Arborimus longicaudus
       Under CMIP6 Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Env Suitability") +
  theme(plot.title = element_text(hjust=0.2))+
  labs(caption = "Figure 2: Future Maxent Species Distribution Model of the Red Tree Vole (Arborius longicaudus). 
       A distribution map of this species' suitable habitat calculated 50 years into the future. 
       Occurrence data was downloaded from GBIF on 03/19/2024
       (doi:https://www.gbif.org/species/2437931) and available on GitHub
       (https://github.com/BiodiversityDataScienceCorp/2024_Group1/tree/main/maxent_outputs).")+ 
  theme(plot.caption = element_text(hjust=0.2))+
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 

# save to file
ggsave("output/arborimusFutureSdm.jpg",  width = 8, height = 6)



##### END FUTURE SDM ######
