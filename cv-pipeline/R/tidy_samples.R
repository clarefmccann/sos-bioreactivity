tidy_samples <- function(path, sheet) {
  raw <- read_raw_sheet(path, sheet)
  fmt <- detect_format(raw)
  if (fmt != "xponent") {
    stop(sprintf("Sheet '%s' in '%s' is not xPONENT format (got '%s'). No ELISA parser is wired in yet -- stop and inspect manually.",
                 sheet, path, fmt), call. = FALSE)
  }

  block_index <- parse_block_index(raw)
  ctx <- build_sheet_context(raw, block_index)
  header <- ctx$header
  unknown_map <- ctx$unknown_map
  analytes <- ctx$analytes
  units <- ctx$units

  avg_result <- resolve_and_classify(extract_block(raw, block_index, "Avg Result"), unknown_map)
  avg_long <- pivot_measurement_block(avg_result, analytes) |>
    dplyr::rename(avg_result_raw = value)

  cv_block <- resolve_and_classify(extract_block(raw, block_index, "%CV Replicates"), unknown_map)
  cv_long <- pivot_measurement_block(cv_block, analytes) |>
    dplyr::select(sample_resolved, sample_type, analyte, cv_replicates_reported_raw = value)

  tidy <- avg_long |>
    dplyr::left_join(cv_long, by = c("sample_resolved", "sample_type", "analyte")) |>
    dplyr::left_join(units, by = "analyte") |>
    dplyr::mutate(
      avg_result_numeric = result_numeric(avg_result_raw),
      cv_replicates_reported = suppressWarnings(as.numeric(cv_replicates_reported_raw))
    )

  split_ids <- split_sample_id(tidy$sample_resolved)
  is_unknown <- tidy$sample_type == "unknown"
  unmatched <- unique(split_ids$sample_id_raw[is_unknown & is.na(split_ids$id_match_type)])
  if (length(unmatched) > 0) {
    warning(sprintf("[%s] Unparseable unknown sample ID(s) in Avg Result: %s", sheet, paste(unmatched, collapse = ", ")), call. = FALSE)
  }
  recovered <- unique(split_ids$sample_id_raw[is_unknown & !is.na(split_ids$id_match_type) & split_ids$id_match_type != "primary"])
  if (length(recovered) > 0) {
    warning(sprintf("[%s] Sample ID(s) in Avg Result recovered via a non-primary pattern -- verify: %s",
                    sheet, paste(recovered, collapse = ", ")), call. = FALSE)
  }

  tidy$sample_id_raw <- ifelse(is_unknown, split_ids$sample_id_raw, NA_character_)
  tidy$participant_id <- ifelse(is_unknown, split_ids$participant_id, NA_character_)
  tidy$timepoint <- ifelse(is_unknown, split_ids$timepoint, NA_character_)
  tidy$fluid_type <- ifelse(is_unknown, split_ids$fluid_type, NA_character_)

  tidy$sheet <- sheet
  tidy$batch <- header$batch
  tidy$run_date <- header$run_datetime

  dplyr::select(
    tidy,
    sheet, batch, run_date,
    sample_id_raw, participant_id, timepoint, fluid_type, sample_type, sample_resolved,
    analyte, units, avg_result_raw, avg_result_numeric,
    cv_replicates_reported_raw, cv_replicates_reported
  )
}
