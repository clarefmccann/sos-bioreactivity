## UPDATING FOR SOS

# Part 1: Initial Setup ---------------------------------------------------

## Installing packages---------------------------------------------------
packages <- c(
  "tidyverse" # for select, left_join, mutate, rowwise, %>%
)


if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(
    setdiff(packages, rownames(installed.packages())),
    repos = "http://cran.us.r-project.org"
  )
}
invisible(lapply(packages, library, character.only = TRUE))

## Set directories---------------------------------------------------
proj_dir <- here::here()
data_dir <- paste0(proj_dir, "/data/")

# Part 2: Load PDS PBIP ---------------------------------------------------
puberty_data <- read.csv(Sys.glob(paste0(data_dir, 'SOS-tanner-stages.csv')))
pbip <- read.csv(Sys.glob(paste0(data_dir, 'SOS_questionnaire_data.csv'))) %>%
  select(SID, PBIP_1A, PBIP_2A)

full_puberty_data <- left_join(pbip, puberty_data, by = "SID")

# Part 3: Calculate Composites---------------------------------------------------
## Creating composite sheet---------------------------------------------------
PubertyComposite <- full_puberty_data %>% #changed to Allwaves_Puberty_Q since skipped over the age merge
  mutate(ADRENdiff = adrenf2 - PBIP_2A, GONADdiff = gonadf2 - PBIP_1A) %>%
  rowwise %>%
  mutate(
    ADRENcomp = mean(c(adrenf2, PBIP_2A), na.rm = T), #if only one measure (i.e. PDS or PBIP) is available, will use that instead of NA.
    GONADcomp = mean(c(gonadf2, PBIP_1A), na.rm = T),
    stage = mean(c(PBIP_1A, PBIP_2A), na.rm = T),
    PUBcomp = mean(c(PDSS, stage), na.rm = T)
  )

write.csv(PubertyComposite, file = paste0(data_dir, "SOS-pubcomp.csv"))
