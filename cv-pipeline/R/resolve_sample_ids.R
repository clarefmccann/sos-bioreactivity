# The ID-mapping block isn't consistent across sheets: some call it
# `Deducing IDs` / `Deducing IDs Single`, some `Deducing Sample IDs` /
# `Deducing Sample IDs Single`, some have only the paired (non-Single) form,
# and some have NEITHER block at all. When nothing is available, fall back to
# positional resolution against `Median` (which always carries real names
# directly): UnknownN numbering follows the order each distinct real unknown
# sample first appears in Location (well) order.
find_block_name <- function(block_index, candidates) {
  hit <- candidates[candidates %in% block_index$name]
  if (length(hit) == 0) NA_character_ else hit[1]
}

build_unknown_map <- function(raw, block_index, median_sample_ditto_resolved) {
  single_name <- find_block_name(block_index, c("Deducing IDs Single", "Deducing Sample IDs Single"))
  paired_name <- find_block_name(block_index, c("Deducing IDs", "Deducing Sample IDs"))

  if (!is.na(single_name)) {
    single <- extract_block(raw, block_index, single_name)
    if (nrow(single) == 0) stop(sprintf("`%s` block is empty", single_name), call. = FALSE)
    if (anyDuplicated(single$unknown_id)) stop(sprintf("Duplicate UnknownN entries in `%s`", single_name), call. = FALSE)
    map <- stats::setNames(single$real_name, single$unknown_id)
  } else if (!is.na(paired_name)) {
    paired <- extract_block(raw, block_index, paired_name)
    if (nrow(paired) == 0) stop(sprintf("`%s` block is empty", paired_name), call. = FALSE)
    # First row per unknown_id is the real name, the second is a ditto mark for
    # replicate 2 -- select by position rather than matching the ditto glyph
    # itself, which is prone to source-file encoding mismatches.
    paired_first <- paired[!duplicated(paired$unknown_id), ]
    map <- stats::setNames(paired_first$real_name, paired_first$unknown_id)
  } else {
    unknown_names <- unique(median_sample_ditto_resolved[classify_sample_type(median_sample_ditto_resolved) == "unknown"])
    if (length(unknown_names) == 0) {
      stop("No ID-mapping block found and no unknown samples in Median to derive one from", call. = FALSE)
    }
    map <- stats::setNames(unknown_names, paste0("Unknown", seq_along(unknown_names)))
  }

  if (!is.na(single_name) && !is.na(paired_name)) {
    paired <- extract_block(raw, block_index, paired_name)
    paired_first <- paired[!duplicated(paired$unknown_id), ]
    cross <- dplyr::inner_join(
      tibble::tibble(unknown_id = names(map), real_name = unname(map)),
      paired_first, by = "unknown_id", suffix = c("_single", "_paired")
    )
    mismatched <- cross[cross$real_name_single != cross$real_name_paired, ]
    if (nrow(mismatched) > 0) {
      stop(sprintf("`%s` and `%s` disagree for: %s", paired_name, single_name,
                    paste(mismatched$unknown_id, collapse = ", ")), call. = FALSE)
    }
  }

  map
}

resolve_sample_name <- function(sample, unknown_map) {
  hit <- unknown_map[sample]
  ifelse(is.na(hit), sample, unname(hit))
}

# The `Median` block itself uses a ditto mark for replicate 2 rather than
# repeating the real name -- resolve that positionally before anything else
# touches the Sample column, or every real sample looks like a singleton and
# all replicate-2 rows collapse into one bogus "↓" group.
resolve_ditto <- function(sample, ditto = intToUtf8(8595)) {
  out <- sample
  for (i in seq_along(out)) {
    if (i > 1 && !is.na(out[i]) && out[i] == ditto) out[i] <- out[i - 1]
  }
  out
}

classify_sample_type <- function(sample_name) {
  dplyr::case_when(
    grepl("^Background", sample_name, ignore.case = TRUE) ~ "background",
    grepl("^Standard", sample_name, ignore.case = TRUE) ~ "standard",
    grepl("^Control", sample_name, ignore.case = TRUE) ~ "control",
    TRUE ~ "unknown"
  )
}

# Two malformed-but-unambiguous ID shapes turned up in the raw data on top of
# the canonical "TAG076 3i" form: a missing space ("TAG0193i") and the
# timepoint/fluid_type reversed to the front ("4iTAG238"). Both are
# recoverable without guessing -- the lazy quantifier on the missing-space
# pattern backtracks to leave exactly one digit for the timepoint, and the
# reversed pattern is a distinct, unambiguous shape. Anything that still
# doesn't match after both fallbacks stays NA and gets reported, per rule 5.
split_sample_id <- function(sample_id,
                             pattern = "^([A-Za-z]+\\d+)\\s+(\\d+)([ih])$",
                             pattern_missing_space = "^([A-Za-z]+\\d+?)(\\d)([ih])$",
                             pattern_reversed = "^(\\d)([ih])([A-Za-z]+\\d+)$") {
  extract <- function(m, idx) vapply(m, function(x) if (length(x) == 4) x[idx] else NA_character_, character(1))

  m1 <- regmatches(sample_id, regexec(pattern, sample_id))
  participant_id <- extract(m1, 2)
  timepoint <- extract(m1, 3)
  fluid_type <- extract(m1, 4)
  id_match_type <- ifelse(!is.na(participant_id), "primary", NA_character_)

  remaining <- is.na(id_match_type)
  if (any(remaining)) {
    m2 <- regmatches(sample_id, regexec(pattern_reversed, sample_id))
    hit <- remaining & !is.na(extract(m2, 4))
    participant_id[hit] <- extract(m2, 4)[hit]
    timepoint[hit] <- extract(m2, 2)[hit]
    fluid_type[hit] <- extract(m2, 3)[hit]
    id_match_type[hit] <- "reversed"
    remaining <- remaining & !hit
  }

  if (any(remaining)) {
    m3 <- regmatches(sample_id, regexec(pattern_missing_space, sample_id))
    hit <- remaining & !is.na(extract(m3, 2))
    participant_id[hit] <- extract(m3, 2)[hit]
    timepoint[hit] <- extract(m3, 3)[hit]
    fluid_type[hit] <- extract(m3, 4)[hit]
    id_match_type[hit] <- "missing_space"
  }

  tibble::tibble(
    sample_id_raw = sample_id,
    participant_id = participant_id,
    timepoint = timepoint,
    fluid_type = fluid_type,
    id_match_type = id_match_type
  )
}
