parse_location <- function(location) {
  m <- regmatches(location, regexec("^(\\d+)\\((\\d+),([A-Za-z]+[0-9]+)\\)$", location))
  ok <- vapply(m, length, integer(1)) == 4
  if (!all(ok)) {
    stop(sprintf("Unparseable Location value(s): %s", paste(unique(location[!ok]), collapse = ", ")), call. = FALSE)
  }
  tibble::tibble(
    location_raw = location,
    well_index = vapply(m, function(x) x[2], character(1)),
    plate = vapply(m, function(x) x[3], character(1)),
    well = vapply(m, function(x) x[4], character(1))
  )
}
