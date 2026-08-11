# The `<hormone> inter-assay CV` sheets in the Masterfile are already
# organized as a stack of per-plate control blocks -- each block header row
# (`Well ID` in column 1) carries the plate/tray name in the last column, and
# the two data rows with a populated `Well ID` (the control names -- some
# sheets use CtrlH/CtrlL, Testosterone uses CTLH/CTLL) already have the
# replicate Mean pre-computed. No raw well-pairing needed here, unlike the
# xPONENT sheets.
parse_hormone_control_blocks <- function(path, sheet) {
  raw <- readxl::read_excel(path, sheet = sheet, col_names = FALSE, col_types = "text")
  header_rows <- which(raw[[1]] == "Well ID")
  last_col <- ncol(raw)

  purrr::map_dfr(header_rows, function(h) {
    plate_name <- raw[[last_col]][h]
    next_h <- header_rows[header_rows > h][1]
    end_row <- if (is.na(next_h)) nrow(raw) else next_h - 1
    block <- raw[(h + 1):end_row, 1:8]
    names(block) <- as.character(raw[h, 1:8])

    is_high <- toupper(block[["Well ID"]]) %in% c("CTRLH", "CTLH")
    is_low <- toupper(block[["Well ID"]]) %in% c("CTRLL", "CTLL")
    ctrl <- block[!is.na(block[["Well ID"]]) & (is_high | is_low), ]

    tibble::tibble(
      plate = plate_name,
      control_level = ifelse(toupper(ctrl[["Well ID"]]) %in% c("CTRLH", "CTLH"), "CtrlH", "CtrlL"),
      mean_conc = as.numeric(ctrl[["Mean"]]),
      cv_reported_intra = as.numeric(ctrl[["Concentration CV (%)"]])
    )
  })
}

# Some plates are shared with other studies (a different project's samples run
# alongside SOS's on the same physical tray, e.g. "Mixedplate_SOS_GBT2Hair...")
# or are reruns ("Redoplate_..."). Flagged rather than silently dropped, so the
# choice of which to include in the paper's reported CV is explicit.
flag_shared_plates <- function(blocks) {
  dplyr::mutate(blocks, shared_or_redo = grepl("Mixedplate|Redoplate", plate, ignore.case = TRUE))
}

compute_hormone_inter_cv <- function(blocks) {
  blocks |>
    dplyr::group_by(control_level) |>
    dplyr::summarise(
      n_plates = dplyr::n(),
      cv = 100 * stats::sd(mean_conc, na.rm = TRUE) / mean(mean_conc, na.rm = TRUE),
      mean_conc = mean(mean_conc, na.rm = TRUE),
      .groups = "drop"
    )
}
