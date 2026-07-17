# Audit Logs is a chronological event log, not a static list: an operator can
# invalidate a well and later re-validate it (confirmed in real data -- both
# "Invalidated results for well: ..." and "Validated results for well: ..."
# messages occur for the same well/analyte/sample). Only the LAST action per
# (plate, well, analyte, sample_name) determines its current invalidation
# status.
parse_audit_logs <- function(raw, block_index) {
  block <- tryCatch(extract_block(raw, block_index, "Audit Logs"), error = function(e) NULL)
  empty <- tibble::tibble(
    action = character(), plate = character(), well = character(),
    analyte = character(), sample_name = character(), date = as.POSIXct(character())
  )
  if (is.null(block) || nrow(block) == 0) return(empty)

  pattern <- "^(Invalidated|Validated) results for well: (\\d+),([A-Za-z]+[0-9]+), Analyte name: (.+), Sample Name: (.+)$"
  m <- regmatches(block$Message, regexec(pattern, block$Message))
  ok <- vapply(m, length, integer(1)) == 6
  if (!all(ok)) {
    warning(sprintf("Unparseable Audit Logs message(s): %s", paste(block$Message[!ok], collapse = " | ")), call. = FALSE)
  }

  tibble::tibble(
    action = vapply(m[ok], `[`, character(1), 2),
    plate = vapply(m[ok], `[`, character(1), 3),
    well = vapply(m[ok], `[`, character(1), 4),
    analyte = vapply(m[ok], `[`, character(1), 5),
    sample_name = vapply(m[ok], `[`, character(1), 6),
    date = excel_serial_to_datetime(block$Date[ok])
  )
}

final_invalidations <- function(audit) {
  if (nrow(audit) == 0) return(audit)
  audit |>
    dplyr::group_by(plate, well, analyte, sample_name) |>
    dplyr::slice_max(date, n = 1, with_ties = FALSE) |>
    dplyr::ungroup() |>
    dplyr::filter(action == "Invalidated")
}
