get_standard_nominal <- function(path, sheet) {
  raw <- read_raw_sheet(path, sheet)
  block_index <- parse_block_index(raw)
  pivot_wide_block(extract_block(raw, block_index, "Standard Expected Concentration"), "standard_level") |>
    dplyr::mutate(nominal_conc = as.numeric(value)) |>
    dplyr::select(analyte, standard_level, nominal_conc)
}

plot_cv_vs_concentration <- function(intra_pairs) {
  d <- intra_pairs |> dplyr::filter(sample_type == "unknown", is.na(excluded_reason))
  ggplot2::ggplot(d, ggplot2::aes(x = mean_conc, y = cv_computed)) +
    ggplot2::geom_point(alpha = 0.4) +
    ggplot2::geom_hline(yintercept = 20, linetype = "dashed", color = "firebrick") +
    ggplot2::scale_x_log10() +
    ggplot2::facet_wrap(~analyte, scales = "free") +
    ggplot2::labs(x = "Mean concentration (log scale)", y = "Intra-assay CV (%)",
                  title = "CV vs concentration (unknowns, non-excluded)") +
    ggplot2::theme_minimal()
}

plot_levey_jennings <- function(control_performance_all) {
  d <- control_performance_all |>
    dplyr::arrange(run_date) |>
    dplyr::mutate(plate_order = as.integer(factor(sheet, levels = unique(sheet))))

  ggplot2::ggplot(d, ggplot2::aes(x = plate_order, y = observed_avg)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = range_low, ymax = range_high), fill = "grey80", alpha = 0.5) +
    ggplot2::geom_hline(ggplot2::aes(yintercept = expected_conc), linetype = "dashed") +
    ggplot2::geom_line() +
    ggplot2::geom_point(ggplot2::aes(color = pass)) +
    ggplot2::facet_wrap(analyte ~ control_level, scales = "free_y") +
    ggplot2::scale_color_manual(values = c(`TRUE` = "black", `FALSE` = "firebrick")) +
    ggplot2::labs(x = "Plate (run order)", y = "Observed Avg Result", color = "Passed range",
                  title = "Levey-Jennings: control values by plate") +
    ggplot2::theme_minimal()
}

# Not a reproduction of xPONENT's fitted 5PL curve (that requires its exact
# weighted-logistic implementation) -- this shows the raw standard points and
# which ones were invalidated, which is what the report calls for.
plot_standard_curve <- function(wells_tidy_sheet, nominal, sheet_name) {
  d <- wells_tidy_sheet |>
    dplyr::filter(sample_type == "standard") |>
    dplyr::left_join(nominal, by = c("analyte", "sample_resolved" = "standard_level"))

  ggplot2::ggplot(d, ggplot2::aes(x = nominal_conc, y = net_mfi, color = invalidated_flag)) +
    ggplot2::geom_point(size = 2) +
    ggplot2::scale_x_log10() +
    ggplot2::scale_color_manual(values = c(`FALSE` = "steelblue", `TRUE` = "firebrick")) +
    ggplot2::facet_wrap(~analyte, scales = "free_y") +
    ggplot2::labs(x = "Nominal concentration (log scale)", y = "Net MFI", color = "Invalidated",
                  title = paste("Standard points --", sheet_name)) +
    ggplot2::theme_minimal()
}
