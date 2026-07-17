# Shared setup used by characterize(), tidy_wells(), and tidy_samples() --
# header, the resolved Median block (source of truth for real sample names),
# the UnknownN lookup, per-analyte units, and the audit-log invalidation
# ledger. Keeping this in one place means the three consumers can't drift out
# of sync on how a sample name gets resolved.
build_sheet_context <- function(raw, block_index) {
  header <- parse_header(raw)

  median <- extract_block(raw, block_index, "Median")
  median <- dplyr::bind_cols(median, parse_location(median$Location))
  median_ditto <- resolve_ditto(median$Sample)
  unknown_map <- build_unknown_map(raw, block_index, median_ditto)

  # When there's no authoritative Deducing IDs block, the positional fallback
  # infers UnknownN from distinct names in Median -- but if Median itself has
  # the SAME label typed at two physically different wells (confirmed to
  # happen: "TAG309 3i" at two well-pairs on one plate with no Deducing IDs
  # block), the fallback silently collapses them into one entry and every
  # later UnknownN shifts by one, misattributing results to the wrong person.
  # Cross-check against what Result actually references and fail loudly
  # rather than let that shift pass silently.
  result_unknown_ids <- unique(extract_block(raw, block_index, "Result")$Sample)
  result_unknown_ids <- result_unknown_ids[grepl("^Unknown", result_unknown_ids)]
  missing <- setdiff(result_unknown_ids, names(unknown_map))
  if (length(missing) > 0) {
    stop(sprintf(
      "Unknown ID map is incomplete: missing %s (map has %d entries, Result references %d distinct UnknownN). This usually means Median has the SAME sample label typed at two different wells, which breaks positional inference when no Deducing IDs block exists -- check Median for a duplicated label and resolve against the plate loading manifest.",
      paste(missing, collapse = ", "), length(unknown_map), length(result_unknown_ids)
    ), call. = FALSE)
  }

  median$sample_resolved <- resolve_sample_name(median_ditto, unknown_map)
  median$sample_type <- classify_sample_type(median$sample_resolved)

  units <- pivot_wide_block(extract_block(raw, block_index, "Units"), "attribute") |>
    tidyr::pivot_wider(names_from = attribute, values_from = value) |>
    dplyr::rename(bead_id = `BeadID:`, units = `Units:`) |>
    dplyr::select(analyte, bead_id, units)

  per_bead_threshold <- pivot_wide_block(extract_block(raw, block_index, "Per Bead Count"), "attribute") |>
    dplyr::filter(attribute == "Per Bead:") |>
    dplyr::mutate(threshold = as.numeric(value)) |>
    dplyr::select(analyte, threshold)

  audit <- parse_audit_logs(raw, block_index)
  invalid_final <- final_invalidations(audit)

  list(
    header = header,
    median = median,
    unknown_map = unknown_map,
    analytes = units$analyte,
    units = units,
    per_bead_threshold = per_bead_threshold,
    audit = audit,
    invalid_final = invalid_final
  )
}

resolve_and_classify <- function(block, unknown_map) {
  block$sample_resolved <- resolve_sample_name(block$Sample, unknown_map)
  block$sample_type <- classify_sample_type(block$sample_resolved)
  block
}
