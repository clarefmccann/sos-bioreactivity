# `Invalid(x)` wraps a value the operator manually flagged during the run.
# Per an explicit decision to trust the underlying measurement over the
# operator's manual flag, `result_numeric` now uses that inner value whenever
# it's genuinely quantifiable -- `invalidated_flag` still records that xPONENT
# marked it Invalid (kept for provenance/auditability), it just no longer
# blocks the value from being used.
strip_invalid_wrapper <- function(x) {
  ifelse(grepl("^Invalid\\(", x), sub("^Invalid\\(([^)]*)\\)$", "\\1", x), x)
}

is_invalidated_value <- function(result_raw) {
  grepl("^Invalid\\(", trimws(result_raw))
}

classify_censor <- function(result_raw) {
  inner <- strip_invalid_wrapper(trimws(result_raw))
  dplyr::case_when(
    is.na(inner) ~ "nan",
    grepl("^NaN$", inner, ignore.case = TRUE) ~ "nan",
    grepl("^N/A$", inner, ignore.case = TRUE) ~ "not_applicable",
    grepl("^<", inner) ~ "below_lloq",
    grepl("^>", inner) ~ "above_uloq",
    TRUE ~ "ok"
  )
}

# `Avg Result` (unlike per-well `Result`) is defined as the average of the two
# replicates -- if one is invalidated there's no well-defined "average
# excluding the bad one" for xPONENT to report, so it falls back to a fixed
# `Invalid(0)` placeholder. Confirmed empirically: every Invalid()-wrapped
# value anywhere in this dataset's Avg Result data is exactly `Invalid(0)`,
# never a genuine average. This is a sentinel, not a measurement, and must
# stay excluded even under the "trust the value inside Invalid()" decision --
# that decision applies to Result's real per-well values, not this artifact.
is_avg_invalid_placeholder <- function(result_raw) {
  inner <- strip_invalid_wrapper(trimws(result_raw))
  is_invalidated_value(result_raw) & suppressWarnings(as.numeric(inner)) == 0
}

result_numeric <- function(result_raw) {
  inner <- strip_invalid_wrapper(trimws(result_raw))
  inner_num <- sub("^[<>]\\s*", "", inner)
  ifelse(
    classify_censor(result_raw) == "ok",
    suppressWarnings(as.numeric(inner_num)),
    NA_real_
  )
}
