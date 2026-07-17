# The per-analyte metadata blocks (Units, Standard/Control Expected
# Concentration, Control Range, Per Bead Count, Analysis Types/Coefficients,
# R^2) all share one shape: a row-label column (attribute or reagent name)
# followed by one column per analyte. This pivots any of them to long form.
pivot_wide_block <- function(block, key_name) {
  key_col <- names(block)[1]
  block |>
    dplyr::rename(!!key_name := dplyr::all_of(key_col)) |>
    tidyr::pivot_longer(-dplyr::all_of(key_name), names_to = "analyte", values_to = "value")
}

# Per-well / per-sample measurement blocks (Median, Result, Avg Result, ...)
# have one row per well/sample and one column per analyte, but which other
# columns are present varies by block (e.g. `% Recovery` has no `Total
# Events`). Select the analyte columns directly instead of guessing at the
# rest.
pivot_measurement_block <- function(block, analytes) {
  tidyr::pivot_longer(block, cols = dplyr::all_of(analytes), names_to = "analyte", values_to = "value")
}
