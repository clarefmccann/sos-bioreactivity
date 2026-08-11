# Documented assay-protocol substitution values for below-LLOQ censoring, per
# the study's published methods (Millipore Milliplex kits: immune markers
# imputed at HALF the lower limit of detection; Salimetrics kits: hormones
# imputed at the FULL lower limit). This is for the analysis-ready dataset
# only -- Task 3's CV calculation deliberately keeps excluding these as
# censored, because imputing both replicates of a fully-undetectable pair to
# the same constant would collapse their CV to a fake 0%, the exact artifact
# the intra-assay CV logic already guards against for xPONENT's own reported
# zeros. Two different purposes: this is for turning censored values into an
# analyzable continuous variable, not for assessing assay precision.
LLOQ_IMPUTATION_VALUES <- c(
  "IL-10" = 0.55, "IL-6" = 0.45, "TNF-alpha" = 0.35, "CRP" = 0.0005,
  "DHEA" = 5, "Testosterone" = 1, "Cortisol" = 0.007
)

impute_below_lloq <- function(result_numeric, censor_flag, analyte, lookup = LLOQ_IMPUTATION_VALUES) {
  imputed <- result_numeric
  is_below <- censor_flag == "below_lloq"
  unmapped <- unique(analyte[is_below & is.na(lookup[analyte])])
  if (length(unmapped) > 0) {
    warning(sprintf("No documented imputation value for analyte(s): %s -- left as NA", paste(unmapped, collapse = ", ")), call. = FALSE)
  }
  imputed[is_below] <- lookup[analyte[is_below]]
  imputed
}

log_transform <- function(x) ifelse(!is.na(x) & x > 0, log(x), NA_real_)
