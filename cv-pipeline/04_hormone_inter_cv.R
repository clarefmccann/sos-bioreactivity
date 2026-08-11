for (f in list.files("cv-pipeline/R", full.names = TRUE)) source(f)

masterfile <- "/Volumes/psych-cog/dsnlab/SOS/SOS-study-monash/saliva/Raw_datasets/Masterfile_SOS_Saliva_12.04.2020_updated.xlsx"
hormones <- c("DHEA", "Testosterone", "Cortisol", "Estradiol")

blocks_all <- purrr::map_dfr(hormones, function(h) {
  parse_hormone_control_blocks(masterfile, paste0(h, " inter-assay CV")) |>
    dplyr::mutate(hormone = h, .before = 1)
})
blocks_all <- flag_shared_plates(blocks_all)

# Two summaries: every plate (including cross-study shared trays and reruns),
# and excluding them. Both are reported -- which one belongs in a methods
# section is the analyst's call, not something to decide silently here.
summary_all_plates <- blocks_all |>
  dplyr::group_by(hormone) |>
  dplyr::group_modify(~ compute_hormone_inter_cv(.x)) |>
  dplyr::ungroup() |>
  dplyr::mutate(plate_set = "all_plates")

summary_excl_shared <- blocks_all |>
  dplyr::filter(!shared_or_redo) |>
  dplyr::group_by(hormone) |>
  dplyr::group_modify(~ compute_hormone_inter_cv(.x)) |>
  dplyr::ungroup() |>
  dplyr::mutate(plate_set = "excluding_shared_or_redo_plates")

hormone_inter_cv_summary <- dplyr::bind_rows(summary_all_plates, summary_excl_shared) |>
  dplyr::select(hormone, control_level, plate_set, n_plates, cv, mean_conc)

dir.create("cv-pipeline/derived", showWarnings = FALSE, recursive = TRUE)
readr::write_csv(blocks_all, "cv-pipeline/derived/hormone_inter_cv_blocks.csv")
readr::write_csv(hormone_inter_cv_summary, "cv-pipeline/derived/hormone_inter_cv_summary.csv")

report <- c(
  "# Hormone inter-assay CV",
  sprintf("_Generated %s_", format(Sys.time())),
  "",
  "Computed directly from the `<hormone> inter-assay CV` sheets in the Masterfile: each sheet is",
  "already organized as one control-well block per plate, so this is SD/mean x 100 of the per-plate",
  "control means across plates -- the same method used for cytokines/CRP.",
  "",
  "`shared_or_redo` plates are trays shared with a different study (`Mixedplate_...`) or reruns",
  "(`Redoplate_...`). Both an all-plates and an excluding-shared/redo summary are reported below;",
  "which to use in a methods section is a judgment call, not decided here.",
  "",
  "## Summary",
  knitr_table(hormone_inter_cv_summary),
  "",
  "## Per-plate control detail",
  knitr_table(blocks_all)
)
writeLines(report, "cv-pipeline/derived/hormone_inter_cv_report.md")

cat("Wrote cv-pipeline/derived/hormone_inter_cv_blocks.csv, hormone_inter_cv_summary.csv, hormone_inter_cv_report.md\n\n")
cat(paste(report, collapse = "\n"), "\n")
