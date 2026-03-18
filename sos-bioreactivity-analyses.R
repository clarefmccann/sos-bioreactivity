pacman::p_load(
  "dplyr",
  "ggplot2",
  "tidyr",
  "stringr",
  "purrr",
  "here",
  "lme4",
  "lmerTest",
  "broom",
  "broom.mixed",
  "readxl",
  "ggpubr",
  "Hmisc",
  "corrplot",
  "ggdist"
)

proj_path <- here()
data_path <- Sys.getenv("CAS_DIR")

# ---- Load data ---------------------------------------------------------------

sos_cytokines <- read.csv(file.path(
  data_path,
  "TAG/data/SOS/saliva/Cleaned_datasets/SOS_cytokines_cleaned.csv"
))
sos_crp <- read.csv(file.path(
  data_path,
  "TAG/data/SOS/saliva/Cleaned_datasets/SOS_CRP_cleaned.csv"
))
sos_hormones <- read.csv(file.path(
  data_path,
  "TAG/data/SOS/saliva/Cleaned_datasets/SOS_hormones_cleaned.csv"
)) |>
  select(-starts_with("Estradiol"))

hr_resting1_raw <- read.csv(file.path(
  data_path,
  "TAG/data/SOS/physio/Mean_HR_Resting1.csv"
))
hr_resting2_raw <- read.csv(file.path(
  data_path,
  "TAG/data/SOS/physio/Mean_HR_Resting2.csv"
))
hr_task_raw <- read.csv(file.path(
  data_path,
  "TAG/data/SOS/physio/Mean_HR_Task.csv"
))
hr_conditions_raw <- read_excel(file.path(
  data_path,
  "TAG/data/SOS/physio/Heart_Rate_Data_Task_Sequence_All_Slices_Conditions.xlsx"
))

# ==============================================================================
# Heart rate
# ==============================================================================

# TAG313p2 is a duplicate session; TAG077 and TAG188 had impossibly low task HRs
# (high 30s) despite normal resting HRs — likely artifact
hr_exclude <- c(
  "TAG313p2_20191117_151413",
  "TAG077_20190823_145422",
  "TAG188_20190731_145115"
)

hr_resting1 <- hr_resting1_raw |>
  rename(id = 1) |>
  filter(!id %in% hr_exclude) |>
  mutate(sequence = "Resting 1")

hr_resting2 <- hr_resting2_raw |>
  rename(id = 1) |>
  filter(!id %in% hr_exclude) |>
  mutate(sequence = "Resting 2")

hr_task <- hr_task_raw |>
  rename(id = 1) |>
  filter(!id %in% hr_exclude) |>
  mutate(sequence = "Task")

# Average both resting states (ID 080 uses resting 1 only — no resting 2)
hr_all_wide <- bind_rows(hr_resting1, hr_resting2, hr_task) |>
  pivot_wider(names_from = sequence, values_from = Mean_HR) |>
  mutate(
    resting_avg = if_else(
      is.na(`Resting 2`),
      `Resting 1`,
      (`Resting 1` + `Resting 2`) / 2
    )
  )

# Individual task conditions (long → per-person per-condition means)
hr_conditions_avg <- hr_conditions_raw |>
  pivot_longer(
    SOS068_20190303_150846:TAG223_20191116_145342,
    names_to = "id",
    values_to = "hr"
  ) |>
  rename(task_condition = Task_condition) |>
  group_by(id, task_condition) |>
  summarise(mean_hr = mean(hr, na.rm = TRUE), .groups = "drop") |>
  filter(!is.na(task_condition), task_condition != "NA") |>
  mutate(
    task_condition = factor(
      task_condition,
      levels = c("1", "2", "3", "R"),
      labels = c("Other", "Self-Disconnected", "Self-Connected", "Rest")
    )
  ) |>
  filter(!id %in% hr_exclude)

# ---- Descriptives ------------------------------------------------------------

meanhr_resting1 <- mean(hr_all_wide$`Resting 1`) # 73.439
meanhr_resting2 <- mean(hr_all_wide$`Resting 2`, na.rm = TRUE) # 72.371
meanhr_resting_avg <- mean(hr_all_wide$resting_avg) # 72.927
meanhr_task <- mean(hr_all_wide$Task) # 76.942

pull_hr <- function(cond) {
  filter(hr_conditions_avg, task_condition == cond)$mean_hr
}

meanhr_rest <- mean(pull_hr("Rest")) # 76.962
meanhr_other <- mean(pull_hr("Other")) # 76.009
meanhr_selfdis <- mean(pull_hr("Self-Disconnected")) # 77.145
meanhr_selfcon <- mean(pull_hr("Self-Connected")) # 77.519

# ---- Paired t-tests ----------------------------------------------------------

# Average task vs. average resting state
t.test(
  hr_all_wide$Task,
  hr_all_wide$resting_avg,
  alternative = "greater",
  paired = TRUE
) # t = 7.4707, df = 49, p-value = 6.21e-10

# Self-connected vs. Rest condition
t.test(
  pull_hr("Self-Connected"),
  pull_hr("Rest"),
  alternative = "greater",
  paired = TRUE
) # t = 2.8223, df = 49, p-value = 0.003435

# Self-connected vs. Self-Disconnected
t.test(
  pull_hr("Self-Connected"),
  pull_hr("Self-Disconnected"),
  alternative = "greater",
  paired = TRUE
) # t = 2.187, df = 49, p-value = 0.01677

# Self-connected vs. Other
t.test(
  pull_hr("Self-Connected"),
  pull_hr("Other"),
  alternative = "greater",
  paired = TRUE
) # t = 6.1557, df = 49, p-value = 6.731e-08

# ---- Helper: box annotation --------------------------------------------------

# Returns a function that annotates violin/box plots with mean and median.
# Captures the full dataset to set a consistent upper y limit across groups.
make_box_stats <- function(data, col) {
  function(y, upper_limit = max(data[[col]], na.rm = TRUE) * 1.15) {
    data.frame(
      y = 0.95 * upper_limit,
      label = paste(
        "Mean =",
        round(mean(y), 2),
        "\n",
        "Median =",
        round(median(y), 2),
        "\n"
      )
    )
  }
}

# ---- Plots: HR ---------------------------------------------------------------

hr_avg_long <- hr_all_wide |>
  select(id, Task, resting_avg) |>
  pivot_longer(
    c(Task, resting_avg),
    names_to = "condition",
    values_to = "mean_hr"
  ) |>
  mutate(
    condition = factor(
      condition,
      levels = c("Task", "resting_avg"),
      labels = c("SOS Task", "Resting State Scan")
    )
  )

compare_means(
  mean_hr ~ condition,
  data = hr_avg_long,
  method = "t.test",
  paired = TRUE
)

avg_hr_plot <- ggplot(hr_avg_long, aes(x = condition, y = mean_hr)) +
  stat_halfeye(
    aes(fill = condition),
    adjust = 0.5,
    width = 0.6,
    .width = 0,
    justification = -0.2,
    point_colour = NA,
    alpha = 0.8
  ) +
  geom_boxplot(
    width = 0.15,
    outlier.shape = NA,
    color = "gray30",
    linewidth = 0.5
  ) +
  geom_point(
    aes(color = condition),
    position = position_jitter(seed = 1, width = 0.1),
    size = 1.2,
    alpha = 0.3
  ) +
  scale_fill_viridis_d() +
  scale_color_viridis_d(guide = "none") +
  stat_compare_means(
    method = "t.test",
    paired = TRUE,
    comparisons = list(c("SOS Task", "Resting State Scan")),
    method.args = list(alternative = "greater")
  ) +
  ylab("Mean Heart Rate (bpm)") +
  xlab(NULL) +
  theme_minimal() +
  theme(legend.position = "none")

compare_means(
  mean_hr ~ task_condition,
  data = hr_conditions_avg,
  method = "t.test",
  paired = TRUE
)

task_hr_comparisons <- list(
  c("Self-Connected", "Rest"),
  c("Self-Connected", "Self-Disconnected"),
  c("Self-Connected", "Other"),
  c("Self-Disconnected", "Other"),
  c("Self-Disconnected", "Rest"),
  c("Other", "Rest")
)

task_hr_plot <- ggplot(
  hr_conditions_avg,
  aes(x = task_condition, y = mean_hr)
) +
  stat_halfeye(
    aes(fill = task_condition),
    adjust = 0.5,
    width = 0.6,
    .width = 0,
    justification = -0.2,
    point_colour = NA,
    alpha = 0.8
  ) +
  geom_boxplot(
    width = 0.15,
    outlier.shape = NA,
    color = "gray30",
    linewidth = 0.5
  ) +
  geom_point(
    aes(color = task_condition),
    position = position_jitter(seed = 1, width = 0.1),
    size = 1.2,
    alpha = 0.3
  ) +
  scale_fill_viridis_d() +
  scale_color_viridis_d(guide = "none") +
  stat_compare_means(
    method = "t.test",
    paired = TRUE,
    comparisons = task_hr_comparisons,
    method.args = list(alternative = "greater")
  ) +
  ylab("Mean Heart Rate (bpm)") +
  xlab(NULL) +
  theme_minimal() +
  theme(legend.position = "none")

# ---- HR difference scores ----------------------------------------------------

hr_final_wide <- hr_all_wide |>
  full_join(
    hr_conditions_avg |>
      pivot_wider(names_from = task_condition, values_from = mean_hr),
    by = "id"
  ) |>
  mutate(
    SampleID = case_when(
      str_sub(id, 1, 6) == "SOS068" ~ "TAG068",
      str_sub(id, 1, 6) == "SOS076" ~ "TAG076",
      .default = str_sub(id, 1, 6)
    ),
    task_rs_hr_diff = Task - resting_avg,
    conn_dis_hr_diff = `Self-Connected` - `Self-Disconnected`,
    conn_other_hr_diff = `Self-Connected` - Other,
    conn_rest_hr_diff = `Self-Connected` - Rest
  )

hr_difference <- hr_final_wide |>
  select(
    SampleID,
    task_rs_hr_diff,
    conn_dis_hr_diff,
    conn_other_hr_diff,
    conn_rest_hr_diff
  )

summary(hr_difference)
hr_difference |>
  select(-SampleID) |>
  summarise(across(everything(), \(x) sd(x, na.rm = TRUE)))

# ==============================================================================
# Salivary markers
# ==============================================================================

sos_crp_panel <- sos_crp |> select(SampleID, Time, CRP_log)
sos_cytokines_panel <- sos_cytokines |>
  select(SampleID, Time, IL10_log, IL6_log, TNFalpha_log)
sos_hormones_panel <- sos_hormones |>
  select(SampleID, Time, DHEA_log, Testosterone_log, Cortisol_log)

# ---- MLMs: linear and quadratic time trends ----------------------------------

run_mlm <- function(outcome, data) {
  f_lin <- as.formula(paste(outcome, "~ 1 + Time + (1 + Time | SampleID)"))
  f_quad <- as.formula(paste(
    outcome,
    "~ 1 + poly(Time, 2) + (1 + poly(Time, 2) | SampleID)"
  ))
  mlm_lin <- lmer(f_lin, na.action = na.omit, REML = TRUE, data = data)
  mlm_quad <- lmer(f_quad, na.action = na.omit, REML = TRUE, data = data)
  list(
    linear = mlm_lin,
    quadratic = mlm_quad,
    aic = AIC(mlm_lin, mlm_quad),
    bic = BIC(mlm_lin, mlm_quad)
  )
}

mlm_crp <- run_mlm("CRP_log", sos_crp_panel)
mlm_il10 <- run_mlm("IL10_log", sos_cytokines_panel)
mlm_il6 <- run_mlm("IL6_log", sos_cytokines_panel)
mlm_tnfalpha <- run_mlm("TNFalpha_log", sos_cytokines_panel)
mlm_dhea <- run_mlm("DHEA_log", sos_hormones_panel)
mlm_test <- run_mlm("Testosterone_log", sos_hormones_panel)
mlm_cort <- run_mlm("Cortisol_log", sos_hormones_panel)

summary(mlm_crp$linear) # Time does not linearly predict CRP (p = .173)
summary(mlm_crp$quadratic) # Time does not quadratically predict CRP (p = .125)
mlm_crp$aic
mlm_crp$bic

summary(mlm_il10$linear) # Time *DOES* linearly predict IL-10 (p = .027; possible singularity)
summary(mlm_il10$quadratic) # Time *DOES* quadratically predict IL-10 (p < .001)
mlm_il10$aic
mlm_il10$bic

summary(mlm_il6$linear) # Time does not linearly predict IL-6 (p = .291)
summary(mlm_il6$quadratic) # Time *DOES* quadratically predict IL-6 (p < .001)
mlm_il6$aic
mlm_il6$bic

summary(mlm_tnfalpha$linear) # Time does not linearly predict TNF-alpha (p = .616)
summary(mlm_tnfalpha$quadratic) # Time *DOES* quadratically predict TNF-alpha (p < .001)
mlm_tnfalpha$aic
mlm_tnfalpha$bic

summary(mlm_dhea$linear) # Time does not linearly predict DHEA (p = .070)
summary(mlm_dhea$quadratic) # Time *DOES* quadratically predict DHEA (p = .032)
mlm_dhea$aic
mlm_dhea$bic

summary(mlm_test$linear) # Time does not linearly predict testosterone (p = .167)
summary(mlm_test$quadratic) # Time *DOES* quadratically predict testosterone (p = .035)
mlm_test$aic
mlm_test$bic

summary(mlm_cort$linear) # Time *DOES* linearly predict cortisol (p = .022)
summary(mlm_cort$quadratic) # Time *DOES* quadratically predict cortisol (p < .001)
mlm_cort$aic
mlm_cort$bic

# ---- Plots: quadratic curves -------------------------------------------------

cytokines_long <- sos_cytokines_panel |>
  pivot_longer(
    c(IL10_log, IL6_log, TNFalpha_log),
    names_to = "biomarker",
    values_to = "log_conc"
  ) |>
  mutate(
    biomarker = case_match(
      biomarker,
      "IL10_log" ~ "IL-10",
      "IL6_log" ~ "IL-6",
      "TNFalpha_log" ~ "TNF-α"
    )
  )

cytokines_quad_plot <- ggplot(
  cytokines_long,
  aes(Time, log_conc, color = biomarker)
) +
  stat_smooth(
    method = "lm",
    formula = y ~ x + I(x^2),
    linewidth = 1,
    aes(fill = after_scale(colour)),
    alpha = 0.2
  ) +
  scale_colour_viridis_d() +
  ylab("Concentration (log-transformed)") +
  xlab("Time point") +
  ggtitle("Quadratic model for cytokines") +
  theme_minimal()

hormones_long <- sos_hormones_panel |>
  pivot_longer(
    c(DHEA_log, Testosterone_log, Cortisol_log),
    names_to = "biomarker",
    values_to = "log_conc"
  ) |>
  mutate(
    biomarker = case_match(
      biomarker,
      "DHEA_log" ~ "DHEA",
      "Testosterone_log" ~ "Testosterone",
      "Cortisol_log" ~ "Cortisol"
    )
  )

hormones_quad_plot <- ggplot(
  hormones_long,
  aes(Time, log_conc, color = biomarker)
) +
  stat_smooth(
    method = "lm",
    formula = y ~ x + I(x^2),
    linewidth = 1,
    aes(fill = after_scale(colour)),
    alpha = 0.2
  ) +
  scale_colour_viridis_d() +
  ylab("Concentration (log-transformed)") +
  xlab("Time point") +
  ggtitle("Quadratic model for hormones") +
  theme_minimal()

ggarrange(
  cytokines_quad_plot,
  hormones_quad_plot,
  labels = c("Cytokines", "Hormones"),
  ncol = 2
)

# CRP not significant — for reference only
ggplot(sos_crp_panel, aes(x = Time, y = CRP_log)) +
  geom_smooth(method = "lm", formula = y ~ x + I(x^2)) +
  scale_colour_viridis_d() +
  ylab("CRP (log-transformed)") +
  theme_minimal()

# All biomarkers combined
immune_all <- sos_crp_panel |>
  full_join(sos_cytokines_panel, by = c("SampleID", "Time"))
biomarkers_all <- immune_all |>
  full_join(sos_hormones_panel, by = c("SampleID", "Time"))

biomarkers_long <- biomarkers_all |>
  pivot_longer(
    c(
      CRP_log,
      IL10_log,
      IL6_log,
      TNFalpha_log,
      DHEA_log,
      Testosterone_log,
      Cortisol_log
    ),
    names_to = "biomarker",
    values_to = "log_conc"
  ) |>
  mutate(
    biomarker = case_match(
      biomarker,
      "CRP_log" ~ "CRP",
      "IL10_log" ~ "IL-10",
      "IL6_log" ~ "IL-6",
      "TNFalpha_log" ~ "TNF-α",
      "DHEA_log" ~ "DHEA",
      "Testosterone_log" ~ "Testosterone",
      "Cortisol_log" ~ "Cortisol"
    )
  )

ggplot(biomarkers_long, aes(Time, log_conc, color = biomarker)) +
  stat_smooth(
    method = "lm",
    formula = y ~ x + I(x^2),
    linewidth = 1,
    aes(fill = after_scale(colour)),
    alpha = 0.2
  ) +
  scale_colour_viridis_d() +
  ylab("Concentration (log-transformed)") +
  theme_minimal()

immune_long <- immune_all |>
  pivot_longer(
    c(CRP_log, IL10_log, IL6_log, TNFalpha_log),
    names_to = "biomarker",
    values_to = "log_conc"
  ) |>
  mutate(
    biomarker = case_match(
      biomarker,
      "CRP_log" ~ "CRP",
      "IL10_log" ~ "IL-10",
      "IL6_log" ~ "IL-6",
      "TNFalpha_log" ~ "TNF-α"
    )
  )

ggplot(immune_long, aes(Time, log_conc, color = biomarker)) +
  stat_smooth(
    method = "lm",
    formula = y ~ x + I(x^2),
    linewidth = 1,
    aes(fill = after_scale(colour)),
    alpha = 0.2
  ) +
  scale_colour_viridis_d() +
  ylab("Concentration (log-transformed)") +
  theme_minimal()

# ==============================================================================
# Peak values (T3 or T4) and reactivity
# ==============================================================================
#
# For each analyte, select the higher of T3 or T4 as each person's "peak."
# This is a simplified version of landmark registration (Kneip & Gasser, 1992)
# as applied in e.g. https://pubmed.ncbi.nlm.nih.gov/24754834/ — here we don't
# have enough time points for a full two-piece growth curve, so we just pick the
# observed peak from T3/T4. T2 is excluded as a candidate peak because it may
# reflect MRI scanner stress rather than the SOS task.

sos_crp_wide <- sos_crp_panel |>
  pivot_wider(
    names_from = Time,
    values_from = CRP_log,
    names_glue = "CRP_log_{Time}",
    values_fn = mean
  ) |>
  mutate(crp_peak = if_else(CRP_log_3 > CRP_log_4, CRP_log_3, CRP_log_4))

sos_cytokines_wide <- sos_cytokines_panel |>
  pivot_wider(
    names_from = Time,
    values_from = c(IL10_log, IL6_log, TNFalpha_log),
    values_fn = mean
  ) |>
  mutate(
    il10_peak = if_else(IL10_log_3 > IL10_log_4, IL10_log_3, IL10_log_4),
    il6_peak = if_else(IL6_log_3 > IL6_log_4, IL6_log_3, IL6_log_4),
    tnfa_peak = if_else(
      TNFalpha_log_3 > TNFalpha_log_4,
      TNFalpha_log_3,
      TNFalpha_log_4
    )
  )

sos_hormones_wide <- sos_hormones_panel |>
  pivot_wider(
    names_from = Time,
    values_from = c(DHEA_log, Testosterone_log, Cortisol_log),
    values_fn = mean
  ) |>
  mutate(
    dhea_peak = if_else(DHEA_log_3 > DHEA_log_4, DHEA_log_3, DHEA_log_4),
    test_peak = if_else(
      Testosterone_log_3 > Testosterone_log_4,
      Testosterone_log_3,
      Testosterone_log_4
    ),
    cort_peak = if_else(
      Cortisol_log_3 > Cortisol_log_4,
      Cortisol_log_3,
      Cortisol_log_4
    )
  )

# ---- Check: peak vs. T1 ------------------------------------------------------

run_peak_test <- function(peak_col, t1_col, data) {
  cat("Peak mean:", mean(data[[peak_col]], na.rm = TRUE), "\n")
  cat("T1 mean:  ", mean(data[[t1_col]], na.rm = TRUE), "\n")
  t.test(
    data[[peak_col]],
    data[[t1_col]],
    alternative = "greater",
    paired = TRUE
  )
}

run_peak_test("crp_peak", "CRP_log_1", sos_crp_wide) # Peak -2.052981, T1 -2.543955
run_peak_test("il10_peak", "IL10_log_1", sos_cytokines_wide) # Peak  1.626901, T1  1.089902
run_peak_test("il6_peak", "IL6_log_1", sos_cytokines_wide) # Peak  1.01348,  T1  0.7275804
run_peak_test("tnfa_peak", "TNFalpha_log_1", sos_cytokines_wide) # Peak  2.152535, T1  1.796177
run_peak_test("dhea_peak", "DHEA_log_1", sos_hormones_wide) # Peak  4.621193, T1  4.340595
run_peak_test("test_peak", "Testosterone_log_1", sos_hormones_wide) # Peak  3.741303, T1  3.684813
run_peak_test("cort_peak", "Cortisol_log_1", sos_hormones_wide) # Peak -1.904597, T1 -1.785707

# ---- Peak vs. T1 plots -------------------------------------------------------

my_comparisons_biomarkers <- list(c("T3/T4 peak", "T1"))

# Creates a two-row long dataset (T1 and T3/T4 peak) for a single analyte
make_peak_long <- function(wide_data, t1_col, peak_col, value_name) {
  wide_data |>
    select(SampleID, all_of(c(t1_col, peak_col))) |>
    pivot_longer(
      all_of(c(t1_col, peak_col)),
      names_to = "time_point",
      values_to = value_name
    ) |>
    mutate(
      time_point = factor(
        time_point,
        levels = c(t1_col, peak_col),
        labels = c("T1", "T3/T4 peak")
      )
    )
}

# Raincloud plot (half-violin + box + jittered points) for T1 vs peak comparisons
biomarker_plot <- function(data, y_col, y_label) {
  ggplot(data, aes(x = time_point, y = .data[[y_col]])) +
    stat_halfeye(
      aes(fill = time_point),
      adjust = 0.5,
      width = 0.6,
      .width = 0,
      justification = -0.2,
      point_colour = NA,
      alpha = 0.8
    ) +
    geom_boxplot(
      width = 0.15,
      outlier.shape = NA,
      color = "gray30",
      linewidth = 0.5
    ) +
    geom_point(
      aes(color = time_point),
      position = position_jitter(seed = 1, width = 0.1),
      size = 1.2,
      alpha = 0.3
    ) +
    scale_fill_viridis_d() +
    scale_color_viridis_d(guide = "none") +
    stat_compare_means(
      method = "t.test",
      paired = TRUE,
      comparisons = my_comparisons_biomarkers,
      method.args = list(alternative = "greater")
    ) +
    ylab(y_label) +
    xlab(NULL) +
    theme_minimal() +
    theme(legend.position = "none")
}

sos_crp_long <- make_peak_long(
  sos_crp_wide,
  "CRP_log_1",
  "crp_peak",
  "crp_log_conc"
)
sos_il10_long <- make_peak_long(
  sos_cytokines_wide,
  "IL10_log_1",
  "il10_peak",
  "il10_log_conc"
)
sos_il6_long <- make_peak_long(
  sos_cytokines_wide,
  "IL6_log_1",
  "il6_peak",
  "il6_log_conc"
)
sos_tnfa_long <- make_peak_long(
  sos_cytokines_wide,
  "TNFalpha_log_1",
  "tnfa_peak",
  "tnfa_log_conc"
)
sos_dhea_long <- make_peak_long(
  sos_hormones_wide,
  "DHEA_log_1",
  "dhea_peak",
  "dhea_log_conc"
)
sos_test_long <- make_peak_long(
  sos_hormones_wide,
  "Testosterone_log_1",
  "test_peak",
  "test_log_conc"
)
sos_cort_long <- make_peak_long(
  sos_hormones_wide,
  "Cortisol_log_1",
  "cort_peak",
  "cort_log_conc"
)

crp_plot <- biomarker_plot(
  sos_crp_long,
  "crp_log_conc",
  "CRP (log-transformed)"
)
il10_plot <- biomarker_plot(
  sos_il10_long,
  "il10_log_conc",
  "IL-10 (log-transformed)"
)
il6_plot <- biomarker_plot(
  sos_il6_long,
  "il6_log_conc",
  "IL-6 (log-transformed)"
)
tnfa_plot <- biomarker_plot(
  sos_tnfa_long,
  "tnfa_log_conc",
  "TNF-\u03b1 (log-transformed)"
)
dhea_plot <- biomarker_plot(
  sos_dhea_long,
  "dhea_log_conc",
  "DHEA (log-transformed)"
)
test_plot <- biomarker_plot(
  sos_test_long,
  "test_log_conc",
  "Testosterone (log-transformed)"
)
cort_plot <- biomarker_plot(
  sos_cort_long,
  "cort_log_conc",
  "Cortisol (log-transformed)"
)

immune_plots <- ggarrange(
  crp_plot,
  il10_plot,
  il6_plot,
  tnfa_plot,
  labels = c("CRP", "IL-10", "IL-6", "TNF-alpha"),
  ncol = 2,
  nrow = 2
)
hormone_plots <- ggarrange(
  dhea_plot,
  test_plot,
  cort_plot,
  labels = c("DHEA", "Testosterone", "Cortisol"),
  ncol = 3,
  nrow = 1
) # export as height ~300

# ---- FDR correction ----------------------------------------------------------

p_immune <- c(0.034, 0.000000013, 0.0013, 0.00066)
fdr_immune <- p.adjust(p_immune, method = "fdr")

p_hormones <- c(0.016, 0.4, 0.86)
fdr_hormones <- p.adjust(p_hormones, method = "fdr")

# ---- Reactivity difference scores (peak − T1) --------------------------------

crp_difference <- sos_crp_wide |>
  mutate(crp_difference = crp_peak - CRP_log_1) |>
  select(SampleID, crp_difference)

cytokines_difference <- sos_cytokines_wide |>
  mutate(
    il10_difference = il10_peak - IL10_log_1,
    il6_difference = il6_peak - IL6_log_1,
    tnfa_difference = tnfa_peak - TNFalpha_log_1
  ) |>
  select(SampleID, il10_difference, il6_difference, tnfa_difference)

hormones_difference <- sos_hormones_wide |>
  mutate(
    dhea_difference = dhea_peak - DHEA_log_1,
    test_difference = test_peak - Testosterone_log_1,
    cort_difference = cort_peak - Cortisol_log_1
  ) |>
  select(SampleID, dhea_difference, test_difference, cort_difference)

biomarkers_difference <- crp_difference |>
  full_join(cytokines_difference, by = "SampleID") |>
  full_join(hormones_difference, by = "SampleID")

summary(biomarkers_difference)
biomarkers_difference |>
  select(-SampleID) |>
  summarise(across(everything(), \(x) sd(x, na.rm = TRUE)))

bio_all_difference <- hr_difference |>
  full_join(biomarkers_difference, by = "SampleID")

# ==============================================================================
# Subjective stress ratings  (data not yet available — commented out)
# ==============================================================================

# sos_subj_stress <- read.csv(
#   file.path(
#     proj_path,
#     "TAG/data/SOS/questionnaires/sos_subjective_stress_ratings.csv"
#   )
# )
#
# subj_stress_long <- sos_subj_stress |>
#   pivot_longer(
#     c(selfconnected_subj_stress, selfdisconnected_subj_stress, other_subj_stress),
#     names_to = "condition", values_to = "stress"
#   ) |>
#   mutate(
#     condition = factor(
#       condition,
#       levels = c("selfconnected_subj_stress", "selfdisconnected_subj_stress", "other_subj_stress"),
#       labels = c("Self-Connected", "Self-Disconnected", "Other")
#     )
#   )
#
# # dplyr-based replacement for the plyr::summarySE pattern
# summarize_se <- function(data, measure_var, group_vars = NULL, na.rm = FALSE, conf.interval = 0.95) {
#   data |>
#     group_by(across(all_of(group_vars))) |>
#     summarise(
#       n             = sum(!is.na(.data[[measure_var]])),
#       !!measure_var := mean(.data[[measure_var]], na.rm = na.rm),
#       sd             = sd(.data[[measure_var]], na.rm = na.rm),
#       .groups = "drop"
#     ) |>
#     mutate(se = sd / sqrt(n), ci = se * qt(conf.interval / 2 + 0.5, n - 1))
# }
#
# summary_subj <- summarize_se(subj_stress_long, measure_var = "stress", group_vars = "condition", na.rm = TRUE)
#
# subj_comparisons <- list(
#   c("Self-Connected", "Self-Disconnected"),
#   c("Self-Connected", "Other"),
#   c("Self-Disconnected", "Other")
# )
#
# subj_plot <- ggplot(summary_subj, aes(x = condition, y = stress, fill = condition)) +
#   geom_bar(position = position_dodge(), stat = "identity") +
#   geom_errorbar(aes(ymin = stress - se, ymax = stress + se), width = 0.2, position = position_dodge(0.9)) +
#   scale_fill_viridis_d() +
#   stat_summary(
#     fun.data = make_box_stats(subj_stress_long, "stress"),
#     geom = "text", hjust = 0.5, vjust = 0.3, size = 3, na.rm = TRUE
#   ) +
#   stat_compare_means(
#     data = subj_stress_long, method = "wilcox.test", paired = TRUE,
#     comparisons = subj_comparisons, method.args = list(alternative = "greater")
#   ) +
#   ylab("Mean stress rating") + xlab("Condition") + theme(legend.position = "none")
#
# # Difference scores
# subjective_difference <- sos_subj_stress |>
#   mutate(
#     subj_scsd_difference    = selfconnected_subj_stress - selfdisconnected_subj_stress,
#     subj_scother_difference = selfconnected_subj_stress - other_subj_stress
#   ) |>
#   select(SampleID, subj_scsd_difference, subj_scother_difference)
#
# summary(subjective_difference)
# subjective_difference |> select(-SampleID) |> summarise(across(everything(), \(x) sd(x, na.rm = TRUE)))

# Subjective difference scores will be added here once data are available;
# for now all_difference contains only HR + biomarker reactivity
all_difference <- bio_all_difference

# ==============================================================================
# Correlations between reactivity (difference score) measures
# ==============================================================================

diff_matrix <- all_difference |> select(-SampleID) |> as.matrix()
colnames(diff_matrix) <- c(
  "ΔHR: Task vs. Rest",
  "ΔHR: SC vs. SD",
  "ΔHR: SC vs. Other",
  "ΔHR: SC vs. Rest",
  "ΔCRP",
  "ΔIL-10",
  "ΔIL-6",
  "ΔTNF-α",
  "ΔDHEA",
  "ΔTestosterone",
  "ΔCortisol"
)
difference_corrs <- cor(diff_matrix, use = "pairwise.complete.obs")
difference_rcorrs <- rcorr(diff_matrix)
difference_rcorrs$r
difference_rcorrs$P

corrplot(
  difference_corrs,
  method = "number",
  tl.col = "black",
  col = colorRampPalette(c("#FDE725FF", "#29AF7FFF", "#440154FF"))(100)
)

# ---- Save workspace ----------------------------------------------------------

save.image(file.path(proj_path, "biopaper_analyses.RData"))
