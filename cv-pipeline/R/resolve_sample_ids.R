# The ID-mapping block's naming is not just inconsistent across sheets --
# confirmed to be actively unreliable within a single sheet (one real example:
# a sheet with two coda blocks both literally named "Deducing Sample IDs",
# where the second one is the deduplicated "Single" form despite not carrying
# that suffix). Trusting the name string to tell single from paired is
# therefore not safe. Instead, every coda block present is extracted and
# classified by its actual structure -- a block where no `UnknownN` repeats is
# a "single" form; one where every `UnknownN` appears exactly twice is
# "paired" (real name + ditto). All available blocks are cross-checked against
# each other for disagreement, regardless of what any of them are named. When
# no coda block exists at all, fall back to positional resolution against
# `Median` (which always carries real names directly): UnknownN numbering
# follows the order each distinct real unknown sample first appears in
# Location (well) order.
extract_coda_rows <- function(raw, block_row) {
  data_start <- block_row$start + 1L
  data_end <- block_row$end
  if (data_end < data_start) return(tibble::tibble(unknown_id = character(), real_name = character()))
  body <- raw[data_start:data_end, 1:2]
  names(body) <- c("unknown_id", "real_name")
  body <- body[!is.na(body$unknown_id) & !is.na(body$real_name), ]
  tibble::as_tibble(body)
}

build_unknown_map <- function(raw, block_index, median_sample_ditto_resolved) {
  coda_rows <- block_index[block_index$kind == "coda", ]

  if (nrow(coda_rows) == 0) {
    unknown_names <- unique(median_sample_ditto_resolved[classify_sample_type(median_sample_ditto_resolved) == "unknown"])
    if (length(unknown_names) == 0) {
      stop("No ID-mapping block found and no unknown samples in Median to derive one from", call. = FALSE)
    }
    return(stats::setNames(unknown_names, paste0("Unknown", seq_along(unknown_names))))
  }

  extracted <- lapply(seq_len(nrow(coda_rows)), function(i) extract_coda_rows(raw, coda_rows[i, ]))
  extracted <- extracted[vapply(extracted, nrow, integer(1)) > 0]
  if (length(extracted) == 0) {
    stop("ID-mapping block(s) found but all are empty", call. = FALSE)
  }

  # First row per unknown_id in a paired block is the real name, the second is
  # a ditto mark -- select by position rather than matching the ditto glyph
  # itself, which is prone to source-file encoding mismatches. Deduplicating
  # every block the same way (a no-op on an already-single block) sidesteps
  # needing to classify single vs. paired explicitly.
  dedup <- function(d) d[!duplicated(d$unknown_id), ]
  maps <- lapply(extracted, function(d) stats::setNames(dedup(d)$real_name, dedup(d)$unknown_id))

  if (length(maps) > 1) {
    for (i in 2:length(maps)) {
      common <- intersect(names(maps[[1]]), names(maps[[i]]))
      mismatched <- common[maps[[1]][common] != maps[[i]][common]]
      if (length(mismatched) > 0) {
        stop(sprintf("ID-mapping blocks disagree for: %s", paste(mismatched, collapse = ", ")), call. = FALSE)
      }
    }
  }

  # Prefer whichever map is most complete (a "single" block is never longer
  # than its paired counterpart, but ties break toward more entries either way).
  maps[[which.max(vapply(maps, length, integer(1)))]]
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
