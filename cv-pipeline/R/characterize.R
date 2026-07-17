characterize <- function(path, sheet) {
  raw <- read_raw_sheet(path, sheet)
  fmt <- detect_format(raw)
  if (fmt != "xponent") {
    stop(sprintf("Sheet '%s' in '%s' is not xPONENT format (got '%s'). No ELISA parser is wired in yet -- stop and inspect manually.",
                 sheet, path, fmt), call. = FALSE)
  }

  block_index <- parse_block_index(raw)
  ctx <- build_sheet_context(raw, block_index)
  header <- ctx$header
  median <- ctx$median
  unknown_map <- ctx$unknown_map
  units <- ctx$units
  analytes <- ctx$analytes
  per_bead_threshold <- ctx$per_bead_threshold
  audit <- ctx$audit
  invalid_final <- ctx$invalid_final

  # --- per-analyte metadata ---
  analysis_type <- pivot_wide_block(extract_block(raw, block_index, "Analysis Types"), "attribute") |>
    dplyr::filter(attribute == "AnalysisType") |>
    dplyr::select(analyte, curve_model = value)

  r_squared <- pivot_wide_block(extract_block(raw, block_index, "R^2"), "attribute") |>
    dplyr::filter(attribute == "Value") |>
    dplyr::mutate(r_squared = as.numeric(value)) |>
    dplyr::select(analyte, r_squared)

  curve_fit <- analysis_type |>
    dplyr::left_join(r_squared, by = "analyte")

  # --- standard / control reference values ---
  std_expected <- pivot_wide_block(extract_block(raw, block_index, "Standard Expected Concentration"), "standard_level") |>
    dplyr::mutate(nominal_conc = as.numeric(value)) |>
    dplyr::select(analyte, standard_level, nominal_conc)

  ctrl_expected <- pivot_wide_block(extract_block(raw, block_index, "Control Expected Concentration"), "control_level") |>
    dplyr::mutate(expected_conc = as.numeric(value)) |>
    dplyr::select(analyte, control_level, expected_conc)

  ctrl_low <- pivot_wide_block(extract_block(raw, block_index, "Control Range - Low"), "control_level") |>
    dplyr::mutate(range_low = as.numeric(value)) |>
    dplyr::select(analyte, control_level, range_low)

  ctrl_high <- pivot_wide_block(extract_block(raw, block_index, "Control Range - High"), "control_level") |>
    dplyr::mutate(range_high = as.numeric(value)) |>
    dplyr::select(analyte, control_level, range_high)

  ctrl_range <- ctrl_expected |>
    dplyr::left_join(ctrl_low, by = c("analyte", "control_level")) |>
    dplyr::left_join(ctrl_high, by = c("analyte", "control_level"))

  # --- per-well / per-sample measurement blocks ---
  count_block <- extract_block(raw, block_index, "Count")
  count_block <- dplyr::bind_cols(count_block, parse_location(count_block$Location))

  result_block <- extract_block(raw, block_index, "Result")
  result_block <- dplyr::bind_cols(result_block, parse_location(result_block$Location))
  result_block <- resolve_and_classify(result_block, unknown_map)

  cv_block <- resolve_and_classify(extract_block(raw, block_index, "%CV Replicates"), unknown_map)
  avg_result_block <- resolve_and_classify(extract_block(raw, block_index, "Avg Result"), unknown_map)

  recovery_block <- tryCatch(extract_block(raw, block_index, "% Recovery"), error = function(e) NULL)
  if (!is.null(recovery_block) && nrow(recovery_block) > 0) {
    recovery_block <- dplyr::bind_cols(recovery_block, parse_location(recovery_block$Location))
    recovery_block <- resolve_and_classify(recovery_block, unknown_map)
  }

  # --- layout inventory ---
  well_counts <- median |> dplyr::count(sample_type, name = "n_wells")

  replicate_depth <- median |> dplyr::count(sample_resolved, sample_type, name = "n_replicates")
  bad_depth <- replicate_depth |> dplyr::filter(n_replicates != 2)
  if (nrow(bad_depth) > 0) {
    warning(sprintf("[%s] Replicate depth != 2 for: %s", sheet,
                    paste(sprintf("%s (n=%d)", bad_depth$sample_resolved, bad_depth$n_replicates), collapse = ", ")),
            call. = FALSE)
  }

  layout <- list(n_wells = nrow(median), well_counts = well_counts,
                 replicate_depth = replicate_depth, replicate_depth_flagged = bad_depth)

  # --- standard curve health ---
  std_invalid <- invalid_final |>
    dplyr::filter(grepl("^Standard", sample_name)) |>
    dplyr::select(analyte, standard_level = sample_name) |>
    dplyr::distinct()

  std_effective_range <- std_expected |>
    dplyr::left_join(std_invalid |> dplyr::mutate(excluded = TRUE), by = c("analyte", "standard_level")) |>
    dplyr::mutate(excluded = !is.na(excluded)) |>
    dplyr::group_by(analyte) |>
    dplyr::summarise(
      nominal_range_low = min(nominal_conc, na.rm = TRUE),
      nominal_range_high = max(nominal_conc, na.rm = TRUE),
      effective_range_low = suppressWarnings(min(nominal_conc[!excluded], na.rm = TRUE)),
      effective_range_high = suppressWarnings(max(nominal_conc[!excluded], na.rm = TRUE)),
      n_levels_excluded = sum(excluded),
      .groups = "drop"
    )

  standard_recovery <- if (!is.null(recovery_block) && nrow(recovery_block) > 0) {
    pivot_measurement_block(recovery_block, analytes) |>
      dplyr::filter(sample_type == "standard") |>
      dplyr::mutate(value = result_numeric(value)) |>
      dplyr::group_by(analyte, standard_level = sample_resolved) |>
      dplyr::summarise(mean_recovery_pct = mean(value, na.rm = TRUE), .groups = "drop")
  } else {
    tibble::tibble(analyte = character(), standard_level = character(), mean_recovery_pct = double())
  }

  standard_cv_reported <- cv_block |>
    dplyr::filter(sample_type == "standard") |>
    pivot_measurement_block(analytes) |>
    dplyr::mutate(value = result_numeric(value)) |>
    dplyr::select(analyte, standard_level = sample_resolved, cv_reported = value)

  standard_curve_health <- std_effective_range |>
    dplyr::left_join(curve_fit, by = "analyte") |>
    dplyr::left_join(std_invalid |> dplyr::count(analyte, name = "n_standards_invalidated"), by = "analyte") |>
    tidyr::replace_na(list(n_standards_invalidated = 0L))

  # --- control performance ---
  ctrl_observed <- avg_result_block |>
    dplyr::filter(sample_type == "control") |>
    pivot_measurement_block(analytes) |>
    dplyr::mutate(value = result_numeric(value)) |>
    dplyr::select(analyte, control_level = sample_resolved, observed_avg = value)

  ctrl_cv_reported <- cv_block |>
    dplyr::filter(sample_type == "control") |>
    pivot_measurement_block(analytes) |>
    dplyr::mutate(value = result_numeric(value)) |>
    dplyr::select(analyte, control_level = sample_resolved, cv_reported = value)

  control_performance <- ctrl_observed |>
    dplyr::left_join(ctrl_range, by = c("analyte", "control_level")) |>
    dplyr::left_join(ctrl_cv_reported, by = c("analyte", "control_level")) |>
    dplyr::mutate(pass = observed_avg >= range_low & observed_avg <= range_high)

  # --- quantifiability (unknowns only) ---
  unknown_results <- result_block |>
    dplyr::filter(sample_type == "unknown") |>
    pivot_measurement_block(analytes) |>
    dplyr::mutate(censor_flag = classify_censor(value), invalidated_flag = is_invalidated_value(value))

  quantifiability <- unknown_results |>
    dplyr::count(analyte, censor_flag, name = "n") |>
    dplyr::group_by(analyte) |>
    dplyr::mutate(pct = round(100 * n / sum(n), 1)) |>
    dplyr::ungroup()

  quantifiability_invalidated <- unknown_results |>
    dplyr::group_by(analyte) |>
    dplyr::summarise(n_invalidated = sum(invalidated_flag), .groups = "drop")

  # --- bead counts ---
  bead_long <- pivot_measurement_block(count_block, analytes) |>
    dplyr::mutate(value = as.numeric(value)) |>
    dplyr::left_join(per_bead_threshold, by = "analyte")

  bead_summary <- bead_long |>
    dplyr::group_by(analyte) |>
    dplyr::summarise(
      min_count = min(value, na.rm = TRUE),
      median_count = stats::median(value, na.rm = TRUE),
      max_count = max(value, na.rm = TRUE),
      n_below_threshold = sum(value < threshold, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::left_join(per_bead_threshold, by = "analyte")

  structure(
    list(
      sheet = sheet, path = path,
      header = header,
      analytes = units,
      curve_fit = curve_fit,
      layout = layout,
      standard_curve_health = standard_curve_health,
      standard_recovery = standard_recovery,
      standard_cv_reported = standard_cv_reported,
      control_performance = control_performance,
      quantifiability = quantifiability,
      quantifiability_invalidated = quantifiability_invalidated,
      bead_summary = bead_summary,
      audit = audit,
      invalid_final = invalid_final
    ),
    class = "cv_characterization"
  )
}
