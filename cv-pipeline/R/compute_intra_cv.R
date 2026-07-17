# Pair each sample's two replicate wells into one row. Closed-form SD of two
# values is |a-b|/sqrt(2) -- avoids the overhead of stats::sd() on a
# two-element vector and makes the row-wise vectorized math straightforward.
pair_replicates <- function(wells_tidy) {
  n_wells <- wells_tidy |>
    dplyr::count(sheet, analyte, sample_type, sample_resolved, name = "n_wells")

  bad <- n_wells |> dplyr::filter(n_wells != 2)
  if (nrow(bad) > 0) {
    warning(sprintf("Excluding %d sample(s) from replicate pairing with != 2 wells: %s",
                    nrow(bad), paste(unique(paste0(bad$sheet, "/", bad$sample_resolved)), collapse = "; ")),
            call. = FALSE)
  }

  wells_tidy |>
    dplyr::semi_join(dplyr::filter(n_wells, n_wells == 2), by = c("sheet", "analyte", "sample_type", "sample_resolved")) |>
    dplyr::group_by(sheet, analyte, sample_type, sample_resolved, units) |>
    dplyr::summarise(
      rep1 = result_numeric[1], rep2 = result_numeric[2],
      rep1_censor = censor_flag[1], rep2_censor = censor_flag[2],
      any_invalidated = any(invalidated_flag),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      any_censored = rep1_censor != "ok" | rep2_censor != "ok",
      any_below_lloq = rep1_censor == "below_lloq" | rep2_censor == "below_lloq",
      mean_conc = (rep1 + rep2) / 2,
      sd_conc = abs(rep1 - rep2) / sqrt(2),
      cv_computed = 100 * sd_conc / mean_conc,
      # Both replicates censored -> xPONENT reports %CV Replicates as exactly
      # 0.00 (nothing to compare, not real agreement). Excluding on
      # any_censored/any_invalidated already keeps these out of cv_computed
      # for the summary, but the reason is kept distinct for the exclusion
      # report so "20 of 36 IL-6 CVs were fake zeros" stays legible.
      excluded_reason = dplyr::case_when(
        any_invalidated ~ "invalidated",
        any_censored ~ "censored_or_na",
        TRUE ~ NA_character_
      )
    )
}

# Recomputing %CV Replicates from Result and asserting agreement with the
# reported column is a parser correctness check, not a scientific step.
check_cv_agreement <- function(pairs, samples_tidy, tolerance = 0.1) {
  reported <- samples_tidy |>
    dplyr::select(sheet, analyte, sample_resolved, cv_replicates_reported) |>
    dplyr::distinct()

  checked <- pairs |>
    dplyr::left_join(reported, by = c("sheet", "analyte", "sample_resolved")) |>
    dplyr::filter(!is.na(cv_computed), !is.na(cv_replicates_reported)) |>
    dplyr::mutate(diff_pp = abs(cv_computed - cv_replicates_reported))

  disagreements <- checked |> dplyr::filter(diff_pp > tolerance)
  if (nrow(disagreements) > 0) {
    warning(sprintf("CV agreement check failed for %d sample(s) (tolerance %.2f pp), e.g. %s",
                    nrow(disagreements), tolerance,
                    paste(utils::head(sprintf("%s/%s/%s (computed=%.3f, reported=%.3f)",
                                              disagreements$sheet, disagreements$analyte, disagreements$sample_resolved,
                                              disagreements$cv_computed, disagreements$cv_replicates_reported), 5),
                          collapse = "; ")),
            call. = FALSE)
  }
  disagreements
}

summarise_cv <- function(pairs) {
  pairs |>
    dplyr::filter(is.na(excluded_reason)) |>
    dplyr::group_by(analyte, level, units) |>
    dplyr::summarise(
      n = dplyr::n(),
      mean_cv = mean(cv_computed, na.rm = TRUE),
      median_cv = stats::median(cv_computed, na.rm = TRUE),
      rms_cv = sqrt(mean(cv_computed^2, na.rm = TRUE)),
      max_cv = max(cv_computed, na.rm = TRUE),
      n_over_20 = sum(cv_computed > 20, na.rm = TRUE),
      mean_conc = mean(mean_conc, na.rm = TRUE),
      .groups = "drop"
    )
}

# Never report the standard-curve CV as the assay's intra-assay CV -- standards
# and controls are summarised as separate `level`s from "unknown", which is
# the only level a downstream reader should treat as the assay's real
# intra-assay precision.
compute_intra_cv <- function(wells_tidy, samples_tidy) {
  pairs <- pair_replicates(wells_tidy)
  disagreements <- check_cv_agreement(pairs, samples_tidy)

  exclusions <- pairs |>
    dplyr::filter(!is.na(excluded_reason)) |>
    dplyr::count(sample_type, analyte, excluded_reason, name = "n_excluded")

  labeled <- pairs |>
    dplyr::mutate(level = ifelse(sample_type == "unknown", "unknown", sample_resolved))

  summary <- summarise_cv(labeled) |> dplyr::mutate(cv_type = "intra")

  tertiles <- labeled |>
    dplyr::filter(sample_type == "unknown", is.na(excluded_reason)) |>
    dplyr::group_by(analyte) |>
    dplyr::mutate(tertile = dplyr::ntile(mean_conc, 3)) |>
    dplyr::group_by(analyte, tertile) |>
    dplyr::summarise(
      n = dplyr::n(),
      mean_cv = mean(cv_computed, na.rm = TRUE),
      median_cv = stats::median(cv_computed, na.rm = TRUE),
      rms_cv = sqrt(mean(cv_computed^2, na.rm = TRUE)),
      mean_conc = mean(mean_conc, na.rm = TRUE),
      .groups = "drop"
    )

  # Methods-sentence LLOQ tally is per SAMPLE (participant-timepoint), not per
  # well -- distinct from Task 1's well-level quantifiability report.
  lloq_tally <- pairs |>
    dplyr::filter(sample_type == "unknown") |>
    dplyr::group_by(analyte) |>
    dplyr::summarise(n_samples = dplyr::n(), n_below_lloq = sum(any_below_lloq), .groups = "drop") |>
    dplyr::mutate(pct_below_lloq = round(100 * n_below_lloq / n_samples, 1))

  list(pairs = pairs, disagreements = disagreements, exclusions = exclusions,
       summary = summary, tertiles = tertiles, lloq_tally = lloq_tally)
}
