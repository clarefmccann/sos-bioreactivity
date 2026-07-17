# `Invalid(x)` wraps a value that WOULD have been quantifiable/censored had
# the well not been manually invalidated. We classify what's inside the
# wrapper so "invalidated but otherwise quantifiable" and "invalidated and
# also censored" stay distinguishable downstream (see Task 1's quantifiability
# report and Task 2 rule 2).
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

result_numeric <- function(result_raw) {
  inner <- strip_invalid_wrapper(trimws(result_raw))
  inner_num <- sub("^[<>]\\s*", "", inner)
  ifelse(
    classify_censor(result_raw) == "ok" & !is_invalidated_value(result_raw),
    suppressWarnings(as.numeric(inner_num)),
    NA_real_
  )
}
