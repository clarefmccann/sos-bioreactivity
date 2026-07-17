# Inter-assay CV: plate-to-plate variability of the control's Avg Result,
# across sheets, for controls that actually passed their expected range on
# that plate. `control_performance_all` is characterize()'s per-sheet control
# table stacked across sheets (sheet, analyte, control_level, observed_avg,
# range_low, range_high, pass).
compute_inter_cv <- function(control_performance_all) {
  included <- control_performance_all |> dplyr::filter(pass)
  excluded <- control_performance_all |> dplyr::filter(!pass)

  by_level <- included |>
    dplyr::group_by(analyte, level = control_level) |>
    dplyr::summarise(
      n_plates = dplyr::n(),
      mean_conc = mean(observed_avg, na.rm = TRUE),
      cv = 100 * stats::sd(observed_avg, na.rm = TRUE) / mean(observed_avg, na.rm = TRUE),
      .groups = "drop"
    )

  overall <- by_level |>
    dplyr::group_by(analyte) |>
    dplyr::summarise(
      level = "average_across_levels",
      n_plates = sum(n_plates),
      mean_conc = mean(mean_conc, na.rm = TRUE),
      cv = mean(cv, na.rm = TRUE),
      .groups = "drop"
    )

  list(summary = dplyr::bind_rows(by_level, overall), excluded_plates = excluded)
}

# Variances add, CVs don't -- inter-assay CV should never be smaller than
# intra-assay CV for the same analyte/control level. A violation means
# something upstream is wrong (wrong plates excluded, a parsing error, etc.),
# not a real biological result.
check_inter_ge_intra <- function(inter_summary, intra_summary) {
  intra_ctrl <- intra_summary |> dplyr::filter(cv_type == "intra")
  cmp <- inter_summary |>
    dplyr::filter(level != "average_across_levels") |>
    dplyr::inner_join(intra_ctrl, by = c("analyte", "level"), suffix = c("_inter", "_intra"))

  violations <- cmp |> dplyr::filter(cv < mean_cv)
  if (nrow(violations) > 0) {
    warning(sprintf("Inter-assay CV < intra-assay CV (should be impossible if variances add correctly) for: %s",
                    paste(sprintf("%s/%s (inter=%.2f%%, intra=%.2f%%)", violations$analyte, violations$level, violations$cv, violations$mean_cv),
                          collapse = "; ")),
            call. = FALSE)
  }
  violations
}

# This dataset has almost no repeated-control structure: only 1 of 8 cytokine
# plates has control wells at all, and the CRP workbook has none (its plate 1
# sheet doesn't exist). True inter-assay CV via controls is therefore not
# computable for nearly everything -- this substitutes Standard1-6 Avg Result
# across plates as a rough proxy. It is NOT equivalent to a real QC-pool
# inter-assay CV: standards are frequently reconstituted once per box and
# reused across several same-day plates, so cross-plate agreement here can
# look artificially tight and may understate true day-to-day/kit-lot
# variability. Every level is suffixed "(proxy)" so it can never be confused
# with the real metric downstream.
INTER_PROXY_CAVEAT <- paste(
  "Standards-as-proxy inter-assay CV substitutes Standard1-6 Avg Result across plates",
  "for a true QC-pool inter-assay CV, because this dataset has essentially no repeated",
  "control data (only 1 of 8 cytokine plates has control wells; CRP has none at all).",
  "This is NOT equivalent to a proper inter-assay CV: standards are often reconstituted",
  "once per box and reused across several plates run the same day, so cross-plate",
  "agreement here can look artificially tight and may not capture true day-to-day or",
  "kit-lot variability. Treat as a rough indicative estimate, not a validated metric."
)

compute_inter_cv_standards_proxy <- function(samples_tidy) {
  d <- samples_tidy |> dplyr::filter(sample_type == "standard", !is.na(avg_result_numeric))

  by_level <- d |>
    dplyr::group_by(analyte, level = sample_resolved) |>
    dplyr::summarise(
      n_plates = dplyr::n(),
      mean_conc = mean(avg_result_numeric, na.rm = TRUE),
      cv = 100 * stats::sd(avg_result_numeric, na.rm = TRUE) / mean(avg_result_numeric, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(level = paste0(level, " (proxy)"))

  overall <- by_level |>
    dplyr::mutate(level_base = sub(" \\(proxy\\)$", "", level)) |>
    dplyr::group_by(analyte) |>
    dplyr::summarise(
      level = "average_across_levels (standards proxy)",
      n_plates = sum(n_plates),
      mean_conc = mean(mean_conc, na.rm = TRUE),
      cv = mean(cv, na.rm = TRUE),
      .groups = "drop"
    )

  dplyr::bind_rows(by_level, overall)
}

# Supplementary CLSI EP05-style decomposition: with exactly 2 replicates per
# plate across >=3 plates, a one-way random-effects ANOVA (plate as the
# random factor) separates within-run (repeatability) variance from
# between-run variance, which the plain plate-mean CV above conflates.
anova_variance_decomposition <- function(wells_tidy, analyte_name, level, type = "control") {
  d <- wells_tidy |>
    dplyr::filter(analyte == analyte_name, sample_resolved == level, sample_type == type, !is.na(result_numeric))

  n_plates <- dplyr::n_distinct(d$sheet)
  if (n_plates < 3) return(NULL)

  fit <- stats::aov(result_numeric ~ factor(sheet), data = d)
  tab <- summary(fit)[[1]]
  ms_between <- tab[["Mean Sq"]][1]
  ms_within <- tab[["Mean Sq"]][2]
  n_per_run <- mean(table(d$sheet))

  var_within <- ms_within
  var_between <- max(0, (ms_between - ms_within) / n_per_run)
  var_total <- var_within + var_between
  grand_mean <- mean(d$result_numeric, na.rm = TRUE)

  tibble::tibble(
    analyte = analyte_name, level = level, n_plates = n_plates,
    var_repeatability = var_within, var_between_run = var_between,
    var_within_lab = var_total, sd_within_lab = sqrt(var_total),
    cv_within_lab = 100 * sqrt(var_total) / grand_mean, grand_mean = grand_mean
  )
}
