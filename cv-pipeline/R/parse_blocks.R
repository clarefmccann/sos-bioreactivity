# Most blocks are introduced by a `DataType:` row (name in column 2). The two
# ID-mapping blocks at the end of the sheet break that convention: they sit
# after the `-- CRC --` sentinel with the block name directly in column 1 and
# no separate column-header row.
parse_block_index <- function(raw) {
  col1 <- raw[[1]]
  col2 <- raw[[2]]

  dt_rows <- which(col1 == "DataType:")
  coda_rows <- which(col1 %in% c("Deducing IDs", "Deducing IDs Single"))
  crc_row <- which(col1 == "-- CRC --")

  if (length(dt_rows) == 0) stop("No `DataType:` blocks found in sheet", call. = FALSE)

  starts <- sort(c(dt_rows, coda_rows))
  kind <- ifelse(starts %in% dt_rows, "dtype", "coda")
  block_names <- ifelse(kind == "dtype", col2[starts], col1[starts])

  ends <- c(starts[-1] - 1L, nrow(raw))

  if (length(crc_row) == 1) {
    truncated <- starts <= crc_row & ends >= crc_row
    ends[truncated] <- crc_row - 1L
  }

  tibble::tibble(name = block_names, kind = kind, start = starts, end = ends)
}

extract_block <- function(raw, block_index, name) {
  row <- block_index[block_index$name == name, ]
  if (nrow(row) == 0) stop(sprintf("Block '%s' not found in sheet", name), call. = FALSE)
  if (nrow(row) > 1) stop(sprintf("Block '%s' matched multiple times", name), call. = FALSE)

  if (row$kind == "coda") {
    data_start <- row$start + 1L
    data_end <- row$end
    if (data_end < data_start) return(tibble::tibble(unknown_id = character(), real_name = character()))
    body <- raw[data_start:data_end, 1:2]
    names(body) <- c("unknown_id", "real_name")
    body <- body[!is.na(body$unknown_id) & !is.na(body$real_name), ]
    return(tibble::as_tibble(body))
  }

  header_row <- row$start + 1L
  data_start <- row$start + 2L
  data_end <- row$end
  header <- as.character(raw[header_row, ])
  last_col <- suppressWarnings(max(which(!is.na(header))))
  if (!is.finite(last_col)) stop(sprintf("Block '%s' has no column headers at row %d", name, header_row), call. = FALSE)
  header <- header[1:last_col]

  if (data_end < data_start) {
    body <- raw[0, 1:last_col]
  } else {
    body <- raw[data_start:data_end, 1:last_col]
  }
  names(body) <- header
  body <- body[!apply(body, 1, function(r) all(is.na(r))), ]
  tibble::as_tibble(body)
}
