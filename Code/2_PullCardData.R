#Pull data from ICOS towers for cards
  #network, site id, year est, site years, max annual NEE, sensor height, MAP, MAT

#using data downloaded from 1_DownloadData.R


library(dplyr)
library(tidyr)
library(fs)
library(stringr)
library(purrr)
library(ggplot2)


#unzipped file folder from 1_DownloadData.R
unzipped_folder <- "X:/moore/FLUXNETunzipped"

site_dirs <- fs::dir_ls(unzipped_folder, type = "directory")

#function to extract card info
extract_site_info <- function(site_dir){
  
  # Flux and BIF files
  flux_file <- fs::dir_ls(site_dir, regexp = "FLUXMET_YY.*\\.csv$")
  bif_file  <- fs::dir_ls(site_dir, regexp = "BIF_.*\\.csv$")
  varinfo_file <- fs::dir_ls(site_dir, regexp = "BIFVARINFO_.*\\.csv$")
  
  site_data <- read.csv(flux_file, na.strings = "-9999")
  
  # Network from folder name
  network <- stringr::str_split(fs::path_file(site_dir), "_", simplify = TRUE)[1]
  
  # NEE column selection
  nee_col <- if ("NEE_VUT_REF" %in% names(site_data)) {
    "NEE_VUT_REF"
  } else if ("NEE_CUT_REF" %in% names(site_data)) {
    "NEE_CUT_REF"
  } else {
    NA
  }
  
  # Flux summary
  flux_summary <- site_data %>%
    summarize(
      year_est = min(as.numeric(substr(TIMESTAMP,1,4)), na.rm = TRUE),
      site_yrs = n(),
      minNEE = if (!is.na(nee_col) && any(!is.na(.data[[nee_col]]))) {
        -1 * min(.data[[nee_col]], na.rm = TRUE)
      } else {
        NA_real_
      },
      MAP = mean(P_ERA, na.rm = TRUE),
      MAT = mean(TA_ERA, na.rm = TRUE)
    )
  
  # Site metadata (lat/long/IGBP)
  site_metadata <- read.csv(bif_file)
  
  meta_summary <- site_metadata %>%
    filter(VARIABLE %in% c("LOCATION_LAT","LOCATION_LONG","IGBP")) %>%
    group_by(SITE_ID, VARIABLE) %>%
    summarize(DATAVALUE = first(DATAVALUE), .groups = "drop") %>%
    pivot_wider(names_from = VARIABLE,
                values_from = DATAVALUE)
  
  # pull max sensor height from BIF VARINFO
  heightmeta <- read.csv(varinfo_file)
  
  sensor_height <- heightmeta %>%
    filter(VARIABLE == "VAR_INFO_HEIGHT") %>%
    group_by(SITE_ID) %>%
    summarize(sensor_height = max(as.numeric(DATAVALUE), na.rm = TRUE), .groups = "drop")
  
  #combine all summaries: join meta + flux + height
  combined <- meta_summary %>%
    left_join(flux_summary, by = character()) %>%   # flux_summary has no SITE_ID, so join by position
    left_join(sensor_height, by = "SITE_ID") %>%
    mutate(network = network, .before = SITE_ID)
  
  return(combined)
}

#apply function across sites
site_summary_df <- map_dfr(site_dirs, extract_site_info)

#check data by plotting
ggplot(site_summary_df, aes(MAT, MAP)) +
  geom_point(aes(fill = minNEE), shape = 21, size = 3) +
  scale_fill_viridis_c()

write.csv(site_summary_df, "X:/moore/TowerTango/AllSitesCardData.csv")

