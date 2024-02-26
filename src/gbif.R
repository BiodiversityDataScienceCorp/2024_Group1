# list of packages

packages<-c("tidyverse", "rgbif", "usethis", "CoordinateCleaner", "leaflet", "mapview")

# install packages

installed_packages<-packages %in% rownames(installed.packages())
if(any(installed_packages==FALSE)){
  install.packages(packages[!installed_packages])
}

# loading packages through library function

invisible(lapply(packages, library, character.only=TRUE))

usethis::edit_r_environ()

# setting up data from GBIF

voleBackbone<-name_backbone(name="Arborimus longicaudus")
speciesKey<-voleBackbone$usageKey

# download data in csv format

occ_download(pred("taxonKey", speciesKey), format="SIMPLE_CSV")

# Citation Info:

#<<gbif download>>
#  Your download is being processed by GBIF:
#  https://www.gbif.org/occurrence/download/0017170-240216155721649
#Most downloads finish within 15 min.
#Check status with
#occ_download_wait('0017170-240216155721649')
#After it finishes, use
#d <- occ_download_get('0017170-240216155721649') %>%
#  occ_download_import()
#to retrieve your download.
#Download Info:
#  Username: k_dolton
#E-mail: lc20-0445@lclark.edu
#Format: SIMPLE_CSV
#Download key: 0017170-240216155721649
#Created: 2024-02-25T17:40:10.258+00:00
#Citation Info:  
#  Please always cite the download DOI when using this data.
#https://www.gbif.org/citation-guidelines
#DOI: 10.15468/dl.ga9kke
#Citation:
#  GBIF Occurrence Download https://doi.org/10.15468/dl.ga9kke Accessed from R via rgbif (https://github.com/ropensci/rgbif) on 2024-02-25

# download raw data

d <- occ_download_get('0017170-240216155721649', path="data/") %>%
  occ_download_import()
write_csv(d, "data/rawData.csv")

#cleaning data
fData<-d %>%
  filter(!is.na(decimalLatitude),!is.na(decimalLongitude))

fData<-fData %>%
  filter(countryCode %in% c("US", "CA", "MX"))

fData<-fData %>%
  filter(!basisOfRecord %in% c("FOSSIL_SPECIMEN", "LIVING_SPECIMEN"))

fData<-fData %>%
  cc_sea(lon="decimalLongitude", lat="decimalLatitude")

#remove duplicates
fData<-fData %>%
  distinct(decimalLongitude, decimalLatitude, speciesKey, datasetKey, .keep_all = TRUE)

#one fell swoop
#  filter(!is.na(decimalLatitude),!is.na(decimalLongitude))
#  filter(countryCode %in% c("US", "CA", "MX"))
#  filter(!basisOfRecord %in% c("FOSSIL_SPECIMEN", "LIVING_SPECIMEN"))
#  cc_sea(lon="decimalLongitude", lat="decimalLatitude")
#  distinct(decimalLongitude, decimalLatitude, speciesKey, datasetKey, .keep_all = TRUE)

write_csv(fData, "data/cleanedData.csv")
