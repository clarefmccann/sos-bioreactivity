excel_serial_to_datetime <- function(x) {
  as.POSIXct(as.numeric(x) * 86400, origin = "1899-12-30", tz = "UTC")
}

excel_serial_to_date <- function(x) {
  as.Date(as.numeric(x), origin = "1899-12-30")
}

# `Date` is split across two adjacent cells: a day serial and a separate
# time-of-day fraction. Combine them rather than converting the day cell alone,
# or every run_datetime truncates to midnight.
parse_header <- function(raw) {
  col1 <- raw[[1]]
  col2 <- raw[[2]]
  col3 <- raw[[3]]

  get_val <- function(key) {
    i <- which(col1 == key)[1]
    if (is.na(i)) NA_character_ else col2[i]
  }

  date_row <- which(col1 == "Date")[1]
  if (is.na(date_row)) stop("Header field 'Date' not found", call. = FALSE)
  date_serial <- suppressWarnings(as.numeric(col2[date_row]))
  time_frac <- suppressWarnings(as.numeric(col3[date_row]))
  run_datetime <- excel_serial_to_datetime(date_serial + ifelse(is.na(time_frac), 0, time_frac))

  ali_row <- which(col1 == "AssayLotInfo:")[1]
  if (is.na(ali_row)) {
    kit_name <- lot_number <- manufacturer <- NA_character_
    kit_expiration <- as.Date(NA)
  } else {
    ali_header <- as.character(raw[ali_row + 1L, ])
    ali_values <- as.character(raw[ali_row + 2L, ])
    names(ali_values) <- ali_header
    kit_name <- unname(ali_values["KitName"])
    lot_number <- unname(ali_values["LotNumber"])
    kit_expiration <- excel_serial_to_date(ali_values["ExpirationDate"])
    manufacturer <- unname(ali_values["Manufacturer"])
  }

  header <- list(
    batch = get_val("Batch"),
    run_datetime = run_datetime,
    sn = get_val("SN"),
    protocol_name = get_val("ProtocolName"),
    batch_start_time = excel_serial_to_datetime(get_val("BatchStartTime")),
    batch_stop_time = excel_serial_to_datetime(get_val("BatchStopTime")),
    kit_name = kit_name,
    lot_number = lot_number,
    kit_expiration = kit_expiration,
    manufacturer = manufacturer
  )

  missing <- names(header)[vapply(header, function(x) length(x) == 0 || all(is.na(x)), logical(1))]
  if (length(missing) > 0) {
    warning(sprintf("Header fields missing or unparseable: %s", paste(missing, collapse = ", ")), call. = FALSE)
  }

  header
}
