# peta: 'growth in height' (PDS_1)
# petb: 'growth of body hair' (PDS_2)
# petc: 'noticed skin changes' (PDS_3)
# petd: 'breasts begun to grow' (PDS_4)
# pete: 'begun to menstruate'

library(dplyr)

proj_dir <- here::here()
data_dir <- paste0(proj_dir, "/data/")
output_dir <- paste0(proj_dir, '/output/')

raw_PDS <- read.csv(Sys.glob(paste0(data_dir, 'SOS_questionnaire_data.csv'))) %>%
  select(SID, PDS_F1, PDS_F2, PDS_F3, PDS_F4, PDS_F6) %>%
  rename(peta = PDS_F1, petb = PDS_F2, petc = PDS_F3, petd = PDS_F4, pete = PDS_F6)

raw_PDS <- raw_PDS %>%
  mutate(
    petb = ifelse(
      petb == 1,
      1,
      ifelse(petb == 2, 2, ifelse(petb == 3, 4, ifelse(petb == 4, 5, NA)))
    )
  ) %>%
  mutate(
    petc = ifelse(
      petc == 1,
      1,
      ifelse(petc == 2, 2, ifelse(petc == 3, 4, ifelse(petc == 4, 5, NA)))
    )
  )

raw_PDS$adrenf <- rowMeans(
  cbind(raw_PDS$petb, raw_PDS$petc),
  na.rm = TRUE
)
raw_PDS$adrenf2 <- raw_PDS$adrenf
raw_PDS$adrenf2[raw_PDS$petb %in% 1 & raw_PDS$adrenf %in% 1.5] <- 1
raw_PDS$adrenf2[raw_PDS$petb %in% 2 & raw_PDS$adrenf %in% 1.5] <- 2
raw_PDS$adrenf2[raw_PDS$adrenf %in% 2.5] <- 3
raw_PDS$adrenf2[raw_PDS$adrenf %in% 3.5] <- 4
raw_PDS$adrenf2[raw_PDS$adrenf %in% 4.5] <- 5
raw_PDS$adrenf2[raw_PDS$adrenf %in% 5.5] <- 5

raw_PDS <- raw_PDS %>%
  mutate(
    peta = ifelse(
      peta == 1,
      1,
      ifelse(peta == 2, 2, ifelse(peta == 3, 3, ifelse(peta == 4, 5, NA)))
    )
  ) %>%
  mutate(
    petd = ifelse(
      petd == 1,
      1,
      ifelse(petd == 2, 3, ifelse(petd == 3, 4, ifelse(petd == 4, 5, NA)))
    )
  ) %>%
  mutate(pete = ifelse(pete == 0, 1, ifelse(pete == 1, 5, NA)))

raw_PDS$gonadf <- rowMeans(
  cbind(raw_PDS$peta, raw_PDS$petd),
  na.rm = TRUE
)
raw_PDS$gonadf2 <- raw_PDS$gonadf
raw_PDS$gonadf2[raw_PDS$gonadf %in% 1 & raw_PDS$pete %in% 1] <- 1
raw_PDS$gonadf2[raw_PDS$gonadf %in% 1.5 & raw_PDS$pete %in% 1] <- 1
raw_PDS$gonadf2[raw_PDS$gonadf %in% 2 & raw_PDS$pete %in% 1] <- 2
raw_PDS$gonadf2[raw_PDS$gonadf %in% 2.5 & raw_PDS$pete %in% 1] <- 2
raw_PDS$gonadf2[raw_PDS$gonadf %in% 3 & raw_PDS$pete %in% 1] <- 3
raw_PDS$gonadf2[raw_PDS$gonadf %in% 3.5 & raw_PDS$pete %in% 1] <- 3
raw_PDS$gonadf2[raw_PDS$gonadf %in% 4 & raw_PDS$pete %in% 1] <- 3
raw_PDS$gonadf2[raw_PDS$gonadf %in% 4.5 & raw_PDS$pete %in% 1] <- 4
raw_PDS$gonadf2[raw_PDS$gonadf %in% 5 & raw_PDS$pete %in% 1] <- 4
raw_PDS$gonadf2[raw_PDS$gonadf %in% 1 & raw_PDS$pete %in% 5] <- 2
raw_PDS$gonadf2[raw_PDS$gonadf %in% 1.5 & raw_PDS$pete %in% 5] <- 3
raw_PDS$gonadf2[raw_PDS$gonadf %in% 2 & raw_PDS$pete %in% 5] <- 4
raw_PDS$gonadf2[raw_PDS$gonadf %in% 2.5 & raw_PDS$pete %in% 5] <- 4
raw_PDS$gonadf2[raw_PDS$gonadf %in% 3 & raw_PDS$pete %in% 5] <- 4
raw_PDS$gonadf2[raw_PDS$gonadf %in% 3.5 & raw_PDS$pete %in% 5] <- 5
raw_PDS$gonadf2[raw_PDS$gonadf %in% 4 & raw_PDS$pete %in% 5] <- 5
raw_PDS$gonadf2[raw_PDS$gonadf %in% 4.5 & raw_PDS$pete %in% 5] <- 5
raw_PDS$gonadf2[raw_PDS$gonadf %in% 5 & raw_PDS$pete %in% 5] <- 5

raw_PDS$PDSS <- rowMeans(
  cbind(raw_PDS$gonadf2, raw_PDS$adrenf2),
  na.rm = TRUE
)

## creating scored dataframe

PDS_f <- raw_PDS

write.csv(
  PDS_f,
  file = paste0(
    data_dir,
    "SOS-tanner-stages.csv"
  )
)
