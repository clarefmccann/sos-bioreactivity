tidy_wells <- function(path, sheet) {
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
  per_bead_threshold <- ctx$per_bead_threshold
  invalid_final <- ctx$invalid_final

  median <- extract_block(raw, block_index, "Median")
  median <- dplyr::bind_cols(median, parse_location(median$Location))
  median_long <- pivot_measurement_block(median, analytes) |>
    dplyr::mutate(median_mfi = suppressWarnings(as.numeric(value))) |>
    dplyr::select(location_raw, analyte, median_mfi)

  net_mfi <- extract_block(raw, block_index, "Net MFI")
  net_mfi <- dplyr::bind_cols(net_mfi, parse_location(net_mfi$Location))
  net_mfi_long <- pivot_measurement_block(net_mfi, analytes) |>
    dplyr::mutate(net_mfi = suppressWarnings(as.numeric(value))) |>
    dplyr::select(location_raw, analyte, net_mfi)

  count_block <- extract_block(raw, block_index, "Count")
  count_block <- dplyr::bind_cols(count_block, parse_location(count_block$Location))
  count_long <- pivot_measurement_block(count_block, analytes) |>
    dplyr::mutate(bead_count = suppressWarnings(as.numeric(value))) |>
    dplyr::select(location_raw, analyte, bead_count)

  result_block <- extract_block(raw, block_index, "Result")
  result_block <- dplyr::bind_cols(result_block, parse_location(result_block$Location))
  result_block <- resolve_and_classify(result_block, unknown_map)

  tidy <- pivot_measurement_block(result_block, analytes) |>
    dplyr::rename(result_raw = value) |>
    dplyr::left_join(median_long, by = c("location_raw", "analyte")) |>
    dplyr::left_join(net_mfi_long, by = c("location_raw", "analyte")) |>
    dplyr::left_join(count_long, by = c("location_raw", "analyte")) |>
    dplyr::left_join(units, by = "analyte") |>
    dplyr::left_join(per_bead_threshold, by = "analyte") |>
    dplyr::mutate(
      censor_flag = classify_censor(result_raw),
      invalidated_flag = is_invalidated_value(result_raw),
      result_numeric = result_numeric(result_raw),
      below_bead_threshold = bead_count < threshold
    )

  # Rule 3: cross-reference Audit Logs -- a well can be invalidated there even
  # when the Result cell itself was never wrapped in Invalid().
  if (nrow(invalid_final) > 0) {
    audit_keys <- invalid_final |>
      dplyr::select(plate, well, analyte) |>
      dplyr::distinct() |>
      dplyr::mutate(audit_invalidated = TRUE)
    tidy <- tidy |>
      dplyr::left_join(audit_keys, by = c("plate", "well", "analyte")) |>
      dplyr::mutate(invalidated_flag = invalidated_flag | !is.na(audit_invalidated)) |>
      dplyr::select(-audit_invalidated)
  }

  # Rule 5: split unknown IDs only -- standards/controls/background never
  # match a participant-ID pattern and aren't parse failures. Recovered
  # non-primary shapes (missing space, reversed fields) are reported too, so
  # the correction is auditable rather than silent.
  split_ids <- split_sample_id(tidy$sample_resolved)
  is_unknown <- tidy$sample_type == "unknown"
  unmatched <- unique(split_ids$sample_id_raw[is_unknown & is.na(split_ids$id_match_type)])
  if (length(unmatched) > 0) {
    warning(sprintf("[%s] Unparseable unknown sample ID(s): %s", sheet, paste(unmatched, collapse = ", ")), call. = FALSE)
  }
  recovered <- unique(split_ids$sample_id_raw[is_unknown & !is.na(split_ids$id_match_type) & split_ids$id_match_type != "primary"])
  if (length(recovered) > 0) {
    warning(sprintf("[%s] Sample ID(s) recovered via a non-primary pattern (missing space / reversed fields) -- verify: %s",
                    sheet, paste(recovered, collapse = ", ")), call. = FALSE)
  }

  tidy$sample_id_raw <- ifelse(is_unknown, split_ids$sample_id_raw, NA_character_)
  tidy$participant_id <- ifelse(is_unknown, split_ids$participant_id, NA_character_)
  tidy$timepoint <- ifelse(is_unknown, split_ids$timepoint, NA_character_)
  tidy$fluid_type <- ifelse(is_unknown, split_ids$fluid_type, NA_character_)

  # Extra beyond the spec: flag any unknown sample name that maps to more (or
  # fewer) than 2 distinct wells within this sheet. A normal ID-resolution or
  # replicate-depth issue would already be caught above; this catches the case
  # where TWO physically different wells were given the SAME sample label
  # (e.g. a plate-loading/mislabeling error) -- confirmed to happen in this
  # data (see TAG309 3i on plt7). Never resolved automatically -- flagged so
  # analysis code can exclude by default until the lab record is checked.
  well_counts <- tidy |>
    dplyr::filter(is_unknown) |>
    dplyr::distinct(sample_resolved, location_raw) |>
    dplyr::count(sample_resolved, name = "n_wells")
  conflict_samples <- well_counts$sample_resolved[well_counts$n_wells != 2]
  if (length(conflict_samples) > 0) {
    warning(sprintf("[%s] sample(s) mapped to != 2 distinct wells (possible ID conflict): %s",
                    sheet, paste(conflict_samples, collapse = ", ")), call. = FALSE)
  }
  tidy$duplicate_id_conflict <- tidy$sample_resolved %in% conflict_samples

  tidy$sheet <- sheet
  tidy$batch <- header$batch
  tidy$run_date <- header$run_datetime

  dplyr::select(
    tidy,
    sheet, batch, run_date, plate, well, location_raw,
    sample_id_raw, participant_id, timepoint, fluid_type, sample_type, sample_resolved,
    analyte, units, median_mfi, net_mfi, bead_count,
    result_raw, result_numeric, censor_flag, invalidated_flag, below_bead_threshold,
    duplicate_id_conflict
  )
}
