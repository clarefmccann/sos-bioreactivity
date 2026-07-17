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
control_perf <- list()
nominal_by_sheet <- list()

for (pset in plate_sheets) {
  for (sheet in pset$sheets) {
    key <- paste(basename(pset$path), sheet, sep = " :: ")
    w <- tryCatch(tidy_wells(pset$path, sheet), error = function(e) e)
    if (inherits(w, "error")) next
    s <- tryCatch(tidy_samples(pset$path, sheet), error = function(e) e)
    ch <- tryCatch(characterize(pset$path, sheet), error = function(e) e)
    if (inherits(s, "error") || inherits(ch, "error")) next

    wells[[key]] <- w
    samples[[key]] <- s
    control_perf[[key]] <- ch$control_performance |>
      dplyr::mutate(sheet = sheet, run_date = ch$header$run_datetime)
    nominal_by_sheet[[key]] <- get_standard_nominal(pset$path, sheet) |> dplyr::mutate(sheet = sheet, path = pset$path)
  }
}

cat(sprintf("Loaded %d/%d sheets for CV calculation.\n", length(wells),
            sum(vapply(plate_sheets, function(p) length(p$sheets), integer(1)))))

wells_tidy <- dplyr::bind_rows(wells)
samples_tidy <- dplyr::bind_rows(samples)
control_performance_all <- dplyr::bind_rows(control_perf)

units_lookup <- wells_tidy |> dplyr::distinct(analyte, units)

intra <- compute_intra_cv(wells_tidy, samples_tidy)
inter <- compute_inter_cv(control_performance_all)
inter_proxy <- compute_inter_cv_standards_proxy(samples_tidy)
violations <- check_inter_ge_intra(inter$summary, intra$summary)

anova_grid <- inter$summary |>
  dplyr::filter(level != "average_across_levels") |>
  dplyr::distinct(analyte, level)
anova_results <- purrr::pmap(anova_grid, function(analyte, level) {
  anova_variance_decomposition(wells_tidy, analyte, level, type = "control")
})
anova_results <- dplyr::bind_rows(anova_results)

cv_summary <- build_cv_summary(intra$summary, inter$summary, inter_proxy, units_lookup)
thresholds <- flag_thresholds(cv_summary)
sentences <- methods_sentences(cv_summary, intra$lloq_tally)

dir.create("cv-pipeline/derived/plots", showWarnings = FALSE, recursive = TRUE)

ggplot2::ggsave("cv-pipeline/derived/plots/cv_vs_concentration.png",
                 plot_cv_vs_concentration(intra$pairs), width = 9, height = 6, dpi = 150)
ggplot2::ggsave("cv-pipeline/derived/plots/levey_jennings.png",
                 plot_levey_jennings(control_performance_all), width = 10, height = 8, dpi = 150)

nominal_all <- dplyr::bind_rows(nominal_by_sheet)
for (sheet in unique(wells_tidy$sheet)) {
  nom <- nominal_all |> dplyr::filter(sheet == !!sheet)
  wt_sheet <- wells_tidy |> dplyr::filter(sheet == !!sheet)
  p <- plot_standard_curve(wt_sheet, nom, sheet)
  fname <- sprintf("cv-pipeline/derived/plots/standard_curve_%s.png", gsub("[^A-Za-z0-9]+", "_", sheet))
  ggplot2::ggsave(fname, p, width = 8, height = 5, dpi = 150)
}

readr::write_csv(cv_summary, "cv-pipeline/derived/cv_summary.csv")

report <- render_cv_report(cv_summary, thresholds, sentences, intra, inter, anova_results, violations)
writeLines(report, "cv-pipeline/derived/cv_report.md")

cat("\nWrote cv-pipeline/derived/cv_summary.csv, cv_report.md, and plots/\n")
cat(paste(report, collapse = "\n"), "\n")
