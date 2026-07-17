for (f in list.files("cv-pipeline/R", full.names = TRUE)) source(f)

raw_dir <- "/Volumes/psych-cog/dsnlab/SOS/SOS-study-monash/saliva/Raw_datasets"

# `Human cytokine raw data - Copy.xlsx` duplicates plt1-plt8 already present in
# Human_cytokine_rawdata.xlsx and is deliberately excluded (see cv-pipeline-prompt.md).
# Summary/rollup sheets (Average_Concentrations, Raw_Concentrations, Inter-Assays,
# Raw_with_undetected_imputed) are skipped -- everything is computed fresh from raw.
plate_sheets <- list(
  list(path = file.path(raw_dir, "Human_cytokine_rawdata.xlsx"),
       sheets = c("Hu Cytokine saliva plt1", "Hu Cytokine saliva plt2", "HU cytokine saliva plt 3",
                  "HU cytokine saliva plt 4", "Hu cytokine saliva plt 5", "Hu Cyto saliva plt 6",
                  "HU cytokine saliva plt 7", "Hu cytokine saliva plt 8")),
  list(path = file.path(raw_dir, "human_cvd_panel_crp_raw_data.xlsx"),
       sheets = c("Hu CRP saliva plt 2", "Hu CRP saliva plt 3", "Hu CRP saliva plt 4",
                  "Hu CRP saliva plt 5", "Hu CRP saliva plt 6", "Hu CRP saliva plt 7",
                  "Hu CRP saliva plt 8"))
)

results <- list()
failures <- list()

for (pset in plate_sheets) {
  for (sheet in pset$sheets) {
    key <- paste(basename(pset$path), sheet, sep = " :: ")
    out <- tryCatch(characterize(pset$path, sheet), error = function(e) e)
    if (inherits(out, "error")) {
      failures[[key]] <- conditionMessage(out)
    } else {
      results[[key]] <- out
    }
  }
}

cat(sprintf("Characterized %d/%d sheets successfully.\n", length(results), length(results) + length(failures)))
if (length(failures) > 0) {
  cat("Failed sheets:\n")
  for (k in names(failures)) cat(sprintf("  - %s: %s\n", k, failures[[k]]))
}

# Plates per batch is a cross-sheet property (one batch/box can span multiple
# plate sheets) -- compute it once all sheets are characterized, not per-sheet.
batch_counts <- table(vapply(results, function(r) r$header$batch, character(1)))

dir.create("cv-pipeline/derived", showWarnings = FALSE, recursive = TRUE)

report_lines <- c(
  "# CV pipeline -- characterization report",
  sprintf("_Generated %s_", format(Sys.time())),
  "",
  "## Plates per batch",
  knitr_table(tibble::tibble(batch = names(batch_counts), n_plates = as.integer(batch_counts))),
  ""
)

for (key in names(results)) {
  report_lines <- c(report_lines, render_characterization_report(results[[key]]), "", "---", "")
}

if (length(failures) > 0) {
  report_lines <- c(report_lines, "## Sheets not characterized", "",
                     paste(sprintf("- **%s**: %s", names(failures), unlist(failures)), collapse = "\n"))
}

writeLines(report_lines, "cv-pipeline/derived/characterization_report.md")
cat("\nWrote cv-pipeline/derived/characterization_report.md\n")
