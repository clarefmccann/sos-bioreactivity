detect_format <- function(raw) {
  if (any(raw[[1]] == "DataType:", na.rm = TRUE)) "xponent" else "unknown"
}
