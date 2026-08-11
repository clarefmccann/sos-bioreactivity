# The `Inter-assays`/`Inter-Assays` summary sheets in the cytokine and CRP
# workbooks hold the lab's own original inter-assay CV calculation -- one
# block per analyte, built from the highest and lowest STANDARD (not a real
# QC control, since neither workbook has one on most plates) across all
# plates. Layout: row 1 = analyte name; row 2 = "High"/"Mean"/"Low"/"Mean"
# headers; one row per plate; then "mean of means" / "std of means" /
# "high % of CV:" / "Inter-assay:" summary rows (often blank when the
# original calculation couldn't be completed -- that blankness is itself
# meaningful, not a parsing gap).
parse_cytokine_og_inter_assay <- function(path, sheet) {
  raw <- readxl::read_excel(path, sheet = sheet, col_names = FALSE, col_types = "text")
  col1 <- raw[[1]]
  # Analyte name rows are identified by what immediately follows them: a
  # "High"/"Low" column-header row.
  header_rows <- which(raw[[2]] == "High")
  analyte_rows <- header_rows - 1

  purrr::map_dfr(analyte_rows, function(ar) {
    # The CRP sheet covers a single analyte with no leading name row (the
    # "High" header sits at row 1), so `ar` can be 0 -- fall back to the
    # sheet's own analyte-less convention rather than indexing out of bounds.
    analyte <- if (ar >= 1 && !is.na(col1[ar])) col1[ar] else NA_character_
    h <- ar + 1
    plate_rows <- h + seq_len(8)
    plate_rows <- plate_rows[plate_rows <= nrow(raw) & grepl("^Plate", col1[plate_rows])]

    # "Inter-assay:" (and the other summary labels above it) live in column 3,
    # not column 1 -- confirmed against the actual sheet layout.
    search_rows <- (h + 1):min(h + 20, nrow(raw))
    inter_assay_row <- which(raw[[3]][search_rows] == "Inter-assay:")
    inter_assay_val <- if (length(inter_assay_row) == 1) {
      as.numeric(raw[[4]][search_rows[inter_assay_row]])
    } else NA_real_

    tibble::tibble(
      analyte = analyte,
      n_plates_with_data = sum(!is.na(raw[[2]][plate_rows]) | !is.na(raw[[5]][plate_rows])),
      og_inter_assay_cv = inter_assay_val
    )
  })
}
