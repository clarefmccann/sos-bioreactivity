# The `<hormone> intra-assay CV` sheets already carry a per-sample
# `Concentration CV (%)` column, but also the raw inputs (`450` = OD,
# `[Concentration]` = back-calculated concentration) needed to recompute CV on
# either basis -- useful because this lab's convention turned out to be
# raw-signal-based (OD/MFI), not concentration-based, confirmed by matching
# previously-reported values almost exactly.
parse_hormone_intra_sheet <- function(path, sheet) {
  raw <- readxl::read_excel(path, sheet = sheet, col_names = FALSE, col_types = "text")
  header_rows <- which(raw[[1]] == "Well ID")
  last_col <- ncol(raw)

  purrr::map_dfr(header_rows, function(h) {
    plate_name <- raw[[last_col]][h]
    next_h <- header_rows[header_rows > h][1]
    end_row <- if (is.na(next_h)) nrow(raw) else next_h - 1
    block <- raw[(h + 1):end_row, 1:11]
    names(block) <- as.character(raw[h, 1:11])

    spl_rows <- which(!is.na(block[["Well ID"]]))
    tibble::tibble(
      plate = plate_name,
      sample = block[["Well ID"]][spl_rows],
      od1_raw = block[["450"]][spl_rows], od2_raw = block[["450"]][spl_rows + 1],
      conc1_raw = block[["[Concentration]"]][spl_rows], conc2_raw = block[["[Concentration]"]][spl_rows + 1]
    )
  })
}

compute_hormone_intra_cv <- function(intra_data, basis = c("od", "concentration")) {
  basis <- match.arg(basis)
  d <- intra_data |>
    dplyr::mutate(censored = grepl("^<", conc1_raw) | grepl("^<", conc2_raw))

  if (basis == "od") {
    d <- d |> dplyr::mutate(v1 = as.numeric(od1_raw), v2 = as.numeric(od2_raw))
  } else {
    d <- d |> dplyr::mutate(v1 = as.numeric(conc1_raw), v2 = as.numeric(conc2_raw))
  }

  d |>
    dplyr::filter(!censored) |>
    dplyr::mutate(mean_v = (v1 + v2) / 2, cv = 100 * abs(v1 - v2) / sqrt(2) / mean_v) |>
    dplyr::summarise(
      n = dplyr::n(),
      mean_cv = round(mean(cv, na.rm = TRUE), 2),
      median_cv = round(median(cv, na.rm = TRUE), 2),
      .groups = "drop"
    )
}
