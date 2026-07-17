for (f in list.files("cv-pipeline/R", full.names = TRUE)) source(f)

raw_dir <- "/Volumes/psych-cog/dsnlab/SOS/SOS-study-monash/saliva/Raw_datasets"

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

wells <- list()
samples <- list()
failures <- list()

for (pset in plate_sheets) {
  for (sheet in pset$sheets) {
    key <- paste(basename(pset$path), sheet, sep = " :: ")
    w <- tryCatch(tidy_wells(pset$path, sheet), error = function(e) e)
    s <- tryCatch(tidy_samples(pset$path, sheet), error = function(e) e)
    if (inherits(w, "error") || inherits(s, "error")) {
      failures[[key]] <- c(if (inherits(w, "error")) conditionMessage(w), if (inherits(s, "error")) conditionMessage(s))
    } else {
      wells[[key]] <- w
      samples[[key]] <- s
    }
  }
}

cat(sprintf("Tidied %d/%d sheets successfully.\n", length(wells), length(wells) + length(failures)))
if (length(failures) > 0) {
  cat("Failed sheets:\n")
  for (k in names(failures)) cat(sprintf("  - %s: %s\n", k, paste(failures[[k]], collapse = "; ")))
}

wells_tidy <- dplyr::bind_rows(wells)
samples_tidy <- dplyr::bind_rows(samples)

dir.create("cv-pipeline/derived", showWarnings = FALSE, recursive = TRUE)
readr::write_csv(wells_tidy, "cv-pipeline/derived/wells_tidy.csv")
readr::write_csv(samples_tidy, "cv-pipeline/derived/samples_tidy.csv")

cat(sprintf("\nwells_tidy: %d rows, %d cols\n", nrow(wells_tidy), ncol(wells_tidy)))
cat(sprintf("samples_tidy: %d rows, %d cols\n", nrow(samples_tidy), ncol(samples_tidy)))
cat("\nWrote cv-pipeline/derived/wells_tidy.csv and samples_tidy.csv\n")
