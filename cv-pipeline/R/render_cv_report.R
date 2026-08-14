render_cv_report <- function(cv_summary, thresholds, sentences, intra, inter, anova_results, inter_ge_intra_violations) {
  c(
    "# CV pipeline -- CV report",
    sprintf("_Generated %s_", format(Sys.time())),
    "",
    "## cv_summary",
    knitr_table(cv_summary),
    "",
    "## Threshold flags",
    THRESHOLD_CAVEAT,
    knitr_table(thresholds),
    "",
    "## Methods sentences",
    paste0("- ", sentences),
    "",
    "## Intra-assay CV -- concentration tertiles (unknowns)",
    knitr_table(intra$tertiles),
    "",
    "## Intra-assay CV -- exclusions (fake-zero / censored / invalidated replicate pairs)",
    knitr_table(intra$exclusions),
    "",
    "## Parser correctness: %CV Replicates agreement check",
    if (nrow(intra$disagreements) == 0) {
      "All recomputed CVs agreed with xPONENT's reported `%CV Replicates` within tolerance."
    } else {
      c(sprintf("**%d disagreement(s) found:**", nrow(intra$disagreements)), knitr_table(intra$disagreements))
    },
    "",
    "## Inter-assay CV -- plates excluded (control failed expected range)",
    knitr_table(inter$excluded_plates),
    "",
    "## Inter-assay CV -- standards-based (primary for cytokines/CRP, see methodology note)",
    INTER_PROXY_CAVEAT,
    "",
    "## Inter >= intra sanity check",
    if (nrow(inter_ge_intra_violations) == 0) {
      "Inter-assay CV was >= intra-assay CV for every analyte/control level checked, as expected."
    } else {
      c("**Violations found (unexpected -- investigate):**", knitr_table(inter_ge_intra_violations))
    },
    "",
    "## Supplementary: CLSI EP05-style variance decomposition",
    "_Plate-mean CV above conflates within-run and between-run variance; this decomposes them where >=3 plates share a control level._",
    knitr_table(anova_results)
  )
}
