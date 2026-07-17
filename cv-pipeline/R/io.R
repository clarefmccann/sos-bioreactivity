read_raw_sheet <- function(path, sheet) {
  suppressMessages(readxl::read_excel(path, sheet = sheet, col_names = FALSE, col_types = "text"))
}
