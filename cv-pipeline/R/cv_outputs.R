build_cv_summary <- function(intra_summary, inter_summary, inter_proxy_summary, units_lookup) {
  inter_labeled <- inter_summary |>
    dplyr::mutate(
      cv_type = "inter", n = n_plates, mean_cv = cv, median_cv = NA_real_, rms_cv = NA_real_,
      note = ifelse(n_plates < 2, sprintf("insufficient data: only %d plate(s) have a control well for this level", n_plates), NA_character_)
    ) |>
    dplyr::left_join(units_lookup, by = "analyte") |>
    dplyr::select(analyte, level, cv_type, n, mean_cv, median_cv, rms_cv, mean_conc, units, note)

  proxy_labeled <- inter_proxy_summary |>
    dplyr::mutate(cv_type = "inter_proxy", n = n_plates, mean_cv = cv, median_cv = NA_real_, rms_cv = NA_real_,
                  note = "standards-as-proxy -- NOT a validated inter-assay CV, see caveat") |>
    dplyr::left_join(units_lookup, by = "analyte") |>
    dplyr::select(analyte, level, cv_type, n, mean_cv, median_cv, rms_cv, mean_conc, units, note)

  intra_labeled <- intra_summary |>
    dplyr::mutate(note = NA_character_) |>
    dplyr::select(analyte, level, cv_type, n, mean_cv, median_cv, rms_cv, mean_conc, units, note)

  dplyr::bind_rows(intra_labeled, inter_labeled, proxy_labeled)
}

# Conventional kit-ELISA thresholds are stricter than regulated ligand-binding
# assay guidance -- print both so a reader doesn't over-interpret a "FAIL"
# against the wrong standard. Only the TRUE inter-assay CV (not the standards
# proxy) is checked against the 15% convention -- the proxy isn't a validated
# metric and shouldn't be graded as if it were one.
flag_thresholds <- function(cv_summary) {
  intra_unknown <- cv_summary |> dplyr::filter(cv_type == "intra", level == "unknown") |>
    dplyr::transmute(analyte, intra_cv = mean_cv, intra_flag = ifelse(intra_cv < 10, "PASS (<10%)", "FAIL (>=10%)"))

  inter_overall <- cv_summary |> dplyr::filter(cv_type == "inter", level == "average_across_levels") |>
    dplyr::transmute(analyte, inter_cv = mean_cv,
                      inter_flag = ifelse(is.na(inter_cv), "insufficient data",
                                           ifelse(inter_cv < 15, "PASS (<15%)", "FAIL (>=15%)")))

  dplyr::full_join(intra_unknown, inter_overall, by = "analyte")
}

THRESHOLD_CAVEAT <- paste(
  "Thresholds shown (intra <10%, inter <15%) are conventional kit-ELISA conventions.",
  "Regulated ligand-binding assay guidance (e.g. FDA/EMA bioanalytical method validation)",
  "allows CVs up to 20% (25% at the LLOQ) -- a 'FAIL' above is not automatically",
  "disqualifying under that standard."
)

# Uses the TRUE inter-assay CV when computable; otherwise states plainly that
# it wasn't, and reports the standards-proxy value as a separate, clearly
# labeled indicative estimate rather than blending it into the primary claim.
methods_sentences <- function(cv_summary, lloq_tally) {
  intra_unknown <- cv_summary |> dplyr::filter(cv_type == "intra", level == "unknown")
  inter_overall <- cv_summary |> dplyr::filter(cv_type == "inter", level == "average_across_levels")
  proxy_overall <- cv_summary |> dplyr::filter(cv_type == "inter_proxy", level == "average_across_levels (standards proxy)")

  merged <- intra_unknown |>
    dplyr::select(analyte, intra_cv = mean_cv, intra_conc = mean_conc, units) |>
    dplyr::left_join(dplyr::select(inter_overall, analyte, inter_cv = mean_cv, inter_conc = mean_conc), by = "analyte") |>
    dplyr::left_join(dplyr::select(proxy_overall, analyte, proxy_cv = mean_cv), by = "analyte") |>
    dplyr::left_join(lloq_tally, by = "analyte")

  vapply(seq_len(nrow(merged)), function(i) {
    r <- merged[i, ]
    inter_clause <- if (is.na(r$inter_cv)) {
      sprintf("Inter-assay CV could not be computed (insufficient repeated control data across plates; a standards-based proxy estimate was %.1f%%, see caveat)", r$proxy_cv)
    } else {
      sprintf("inter-assay CV was %.1f%% at a mean concentration of %.2f %s", r$inter_cv, r$inter_conc, r$units)
    }
    sprintf(
      "Intra-assay CV for %s was %.1f%% at a mean concentration of %.2f %s. %s. Of %d samples, %d (%.1f%%) fell below the lower limit of quantification.",
      r$analyte, r$intra_cv, r$intra_conc, r$units,
      paste0(toupper(substr(inter_clause, 1, 1)), substr(inter_clause, 2, nchar(inter_clause))),
      r$n_samples, r$n_below_lloq, r$pct_below_lloq
    )
  }, character(1))
}
