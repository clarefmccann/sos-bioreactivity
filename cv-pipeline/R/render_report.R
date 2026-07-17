knitr_table <- function(df) {
  if (is.null(df) || nrow(df) == 0) return("_(no rows)_")
  suppressWarnings(paste(knitr::kable(df, format = "pipe", digits = 3), collapse = "\n"))
}

render_characterization_report <- function(x) {
  h <- x$header
  c(
    sprintf("# Characterization: %s", x$sheet),
    "",
    "## Run metadata",
    sprintf("- Batch: %s", h$batch),
    sprintf("- Run date: %s", format(h$run_datetime)),
    sprintf("- Instrument SN: %s", h$sn),
    sprintf("- Protocol: %s", h$protocol_name),
    sprintf("- Kit: %s (lot %s, expires %s, %s)", h$kit_name, h$lot_number, format(h$kit_expiration), h$manufacturer),
    "",
    "### Analytes",
    knitr_table(dplyr::left_join(x$analytes, x$curve_fit, by = "analyte")),
    "",
    "## Layout inventory",
    sprintf("- Total wells: %d", x$layout$n_wells),
    knitr_table(x$layout$well_counts),
    if (nrow(x$layout$replicate_depth_flagged) > 0) {
      sprintf("- **WARNING**: %d sample(s) do not have replicate depth 2 (see warnings)", nrow(x$layout$replicate_depth_flagged))
    } else {
      "- Replicate depth: confirmed 2 for all samples"
    },
    "",
    "## Standard curve health",
    "_R² is the instrument-reported value, computed on the post-exclusion curve (xPONENT refits after invalidation)._",
    knitr_table(x$standard_curve_health),
    "",
    "### Standard %Recovery (mean across replicates)",
    knitr_table(x$standard_recovery),
    "",
    "### Standard %CV Replicates (as reported by xPONENT)",
    knitr_table(x$standard_cv_reported),
    "",
    "## Control performance",
    knitr_table(x$control_performance),
    "",
    "## Quantifiability (unknowns only)",
    "_This is the single most important number in the report -- an analyte where most samples are below the LLOQ cannot be reported as continuous regardless of CV quality._",
    knitr_table(x$quantifiability),
    "",
    "### Invalidated unknown wells",
    knitr_table(x$quantifiability_invalidated),
    "",
    "## Bead counts",
    knitr_table(x$bead_summary)
  )
}
