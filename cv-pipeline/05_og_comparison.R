for (f in list.files("cv-pipeline/R", full.names = TRUE)) source(f)
library(dplyr)

raw_dir <- "/Volumes/psych-cog/dsnlab/SOS/SOS-study-monash/saliva/Raw_datasets"

## ---- Cytokine/CRP: OG inter-assay values ----
og_cytokine <- parse_cytokine_og_inter_assay(file.path(raw_dir, "Human_cytokine_rawdata.xlsx"), "Inter-assays")
og_crp <- parse_cytokine_og_inter_assay(file.path(raw_dir, "human_cvd_panel_crp_raw_data.xlsx"), "Inter-Assays") |>
  mutate(analyte = "CRP")
og_inter_all <- bind_rows(og_cytokine, og_crp)

cat("=== OG inter-assay values (from Inter-assays/Inter-Assays sheets) ===\n")
print(og_inter_all)

## ---- Cytokine/CRP: intra-assay CV on Net MFI vs Result, both vs OG ----
w <- readr::read_csv("cv-pipeline/derived/wells_tidy.csv", show_col_types = FALSE)

intra_result <- w |>
  filter(sample_type == "unknown") |>
  group_by(sheet, analyte, sample_resolved) |>
  filter(n() == 2) |>
  summarise(v1 = result_numeric[1], v2 = result_numeric[2],
            any_censored = any(censor_flag != "ok"), .groups = "drop") |>
  filter(!any_censored) |>
  mutate(cv = 100 * abs(v1 - v2) / sqrt(2) / ((v1 + v2) / 2)) |>
  group_by(analyte) |>
  summarise(n = n(), result_based_cv = round(mean(cv, na.rm = TRUE), 2), .groups = "drop")

intra_mfi <- w |>
  filter(sample_type == "unknown") |>
  group_by(sheet, analyte, sample_resolved) |>
  filter(n() == 2) |>
  summarise(v1 = net_mfi[1], v2 = net_mfi[2],
            any_censored = any(censor_flag != "ok"), .groups = "drop") |>
  filter(!any_censored) |>
  mutate(cv = 100 * abs(v1 - v2) / sqrt(2) / ((v1 + v2) / 2)) |>
  group_by(analyte) |>
  summarise(net_mfi_based_cv = round(mean(cv, na.rm = TRUE), 2), .groups = "drop")

cytokine_intra_comparison <- intra_result |>
  left_join(intra_mfi, by = "analyte") |>
  left_join(
    tibble(analyte = c("CRP", "IL-6", "IL-10", "TNF-alpha"),
           og_intra_cv = c(9.08, 9.90, 12.26, 10.40)),
    by = "analyte"
  )

cat("\n=== Cytokine/CRP intra-assay CV: Result-based vs Net-MFI-based vs OG ===\n")
print(cytokine_intra_comparison)

## ---- Hormones: intra-assay CV on OD(450) vs Concentration, both vs adopted ----
masterfile <- file.path(raw_dir, "Masterfile_SOS_Saliva_12.04.2020_updated.xlsx")
hormones <- c("DHEA", "Testosterone", "Cortisol", "Estradiol")
adopted_hormone_intra <- c(DHEA = 1.58, Testosterone = 1.79, Cortisol = 2.26, Estradiol = NA)

hormone_intra_comparison <- purrr::map_dfr(hormones, function(h) {
  d <- parse_hormone_intra_sheet(masterfile, paste0(h, " intra-assay CV"))
  od <- compute_hormone_intra_cv(d, "od")
  conc <- compute_hormone_intra_cv(d, "concentration")
  tibble::tibble(
    hormone = h, n = od$n,
    od_based_cv = od$mean_cv,
    concentration_based_cv = conc$mean_cv,
    adopted_cv = unname(adopted_hormone_intra[h])
  )
})

cat("\n=== Hormone intra-assay CV: OD-based vs Concentration-based vs adopted ===\n")
print(hormone_intra_comparison)

dir.create("cv-pipeline/derived", showWarnings = FALSE, recursive = TRUE)
readr::write_csv(og_inter_all, "cv-pipeline/derived/og_cytokine_inter_assay.csv")
readr::write_csv(cytokine_intra_comparison, "cv-pipeline/derived/cytokine_intra_basis_comparison.csv")
readr::write_csv(hormone_intra_comparison, "cv-pipeline/derived/hormone_intra_basis_comparison.csv")
cat("\nWrote comparison CSVs to cv-pipeline/derived/\n")
