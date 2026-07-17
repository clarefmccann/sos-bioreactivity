here <- function(...) file.path("cv-pipeline", ...)

source(here("R/io.R"))
source(here("R/detect_format.R"))
source(here("R/parse_header.R"))
source(here("R/parse_blocks.R"))
source(here("R/resolve_sample_ids.R"))

path <- "/Volumes/psych-cog/dsnlab/SOS/SOS-study-monash/saliva/Raw_datasets/Human_cytokine_rawdata.xlsx"
sheet <- "Hu Cytokine saliva plt1"

raw <- read_raw_sheet(path, sheet)
stopifnot(detect_format(raw) == "xponent")

block_index <- parse_block_index(raw)
cat("=== Block index ===\n")
print(block_index, n = Inf)

header <- parse_header(raw)
cat("\n=== Header ===\n")
str(header)

median_sample <- extract_block(raw, block_index, "Median")$Sample
unknown_map <- build_unknown_map(raw, block_index, resolve_ditto(median_sample))
cat(sprintf("\n=== Unknown -> real name map (%d entries, first 6) ===\n", length(unknown_map)))
print(head(unknown_map, 6))

result_block <- extract_block(raw, block_index, "Result")
cat("\n=== Result block (first 8 rows) ===\n")
print(head(result_block, 8))

cv_block <- extract_block(raw, block_index, "%CV Replicates")
cat("\n=== %CV Replicates block (first 8 rows) ===\n")
print(head(cv_block, 8))

cat("\n=== Result block, resolved unknown names (first 8 unknown rows) ===\n")
result_block$sample_resolved <- resolve_sample_name(result_block$Sample, unknown_map)
print(head(result_block[grepl("^Unknown", result_block$Sample), c("Location", "Sample", "sample_resolved")], 8))
