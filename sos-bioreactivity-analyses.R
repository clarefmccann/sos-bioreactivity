## ----setup, echo=FALSE--------------------------------------------------------
# quarto render sos-bioreactivity-analyses.qmd

# knitr::purl(
#   "sos-bioreactivity-analyses.qmd",
#   output = "sos-bioreactivity-analyses.R",
#   quiet = TRUE
# )


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
  "ggsignif",
  "Hmisc",
  "corrplot",
  "knitr",
  "kableExtra",
  "ggdist",
  "tidyLPA",
  "mclust",
  "nnet"
)

proj_path <- here()
data_path <- Sys.getenv("CAS_DIR")
options(knitr.table.format = "html", scipen = 999)

# mclust masks purrr::map — restore purrr versions explicitly
map <- purrr::map
map_dbl <- purrr::map_dbl
map_dfr <- purrr::map_dfr
map2_dfr <- purrr::map2_dfr
iwalk <- purrr::iwalk
imap <- purrr::imap
imap_dfr <- purrr::imap_dfr


## ----load-data, echo=FALSE----------------------------------------------------
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
sos_subj_stress <- read.csv(file.path(
  data_path,
  "SOS/SOS-study-monash/questionnaires/sos_subjective_stress_ratings.csv"
))
sos_session_runner <- read.csv(file.path(
  data_path,
  "SOS/SOS-study-monash/questionnaires/sos-session-runner-qual-data.csv"
)) # has oral health info & wake up time in it
sos_saliva_times <- read.csv(file.path(
  data_path,
  "SOS/SOS-study-monash/saliva/Raw_datasets/SOS_sample_report.csv"
)) # has sample start times

# Questionnaire scores (loaded early so available throughout, incl. LPA section)
dep <- read.csv(file.path(
  data_path,
  "SOS/SOS-study-monash/questionnaires/CESD_total.csv"
)) |>
  select(SampleID, CESD_total)

quest_raw_q <- read.csv(file.path(proj_path, "data", "SOS_questionnaire_data.csv"))
bfnes <- quest_raw_q |>
  select(SampleID = SID, starts_with("BFNES_")) |>
  mutate(across(starts_with("BFNES_"), \(x) suppressWarnings(as.numeric(x)))) |>
  mutate(
    BFNES_2     = 6 - BFNES_2,
    BFNES_6     = 6 - BFNES_6,
    BFNES_7     = 6 - BFNES_7,
    BFNES_10    = 6 - BFNES_10,
    BFNES_total = rowSums(across(starts_with("BFNES_")), na.rm = FALSE)
  ) |>
  select(SampleID, BFNES_total)


## ----hr-processing, echo=FALSE------------------------------------------------
hr_exclude <- c(
  "TAG313p2_20191117_151413",   # duplicate session
  "TAG077_20190823_145422",     # artifact: impossibly low task HR
  "TAG188_20190731_145115"      # artifact: impossibly low task HR
)

hr_resting1 <- hr_resting1_raw |> rename(id = 1) |> filter(!id %in% hr_exclude) |> mutate(sequence = "Resting 1")
hr_resting2 <- hr_resting2_raw |> rename(id = 1) |> filter(!id %in% hr_exclude) |> mutate(sequence = "Resting 2")
hr_task      <- hr_task_raw    |> rename(id = 1) |> filter(!id %in% hr_exclude) |> mutate(sequence = "Task")

hr_all_wide <- bind_rows(hr_resting1, hr_resting2, hr_task) |>
  pivot_wider(names_from = sequence, values_from = Mean_HR) |>
  mutate(resting_avg = if_else(is.na(`Resting 2`), `Resting 1`, (`Resting 1` + `Resting 2`) / 2))

hr_conditions_avg <- hr_conditions_raw |>
  pivot_longer(SOS068_20190303_150846:TAG223_20191116_145342, names_to = "id", values_to = "hr") |>
  rename(task_condition = Task_condition) |>
  group_by(id, task_condition) |>
  summarise(mean_hr = mean(hr, na.rm = TRUE), .groups = "drop") |>
  filter(!is.na(task_condition), task_condition != "NA") |>
  mutate(task_condition = factor(task_condition,
    levels = c("1", "2", "3", "R"),
    labels = c("Other", "Self-Disconnected", "Self-Connected", "Rest")
  )) |>
  filter(!id %in% hr_exclude)

pull_hr <- function(cond) filter(hr_conditions_avg, task_condition == cond)$mean_hr

make_box_stats <- function(data, col) {
  function(y, ...) {
    m <- mean(y, na.rm = TRUE)
    data.frame(
      y     = m + 0.08,
      label = paste0("M = ", round(m, 2))
    )
  }
}


## ----hr-difference, echo=FALSE------------------------------------------------
hr_final_wide <- hr_all_wide |>
  full_join(
    hr_conditions_avg |> pivot_wider(names_from = task_condition, values_from = mean_hr),
    by = "id"
  ) |>
  mutate(
    SampleID = case_when(
      str_sub(id, 1, 6) == "SOS068" ~ "TAG068",
      str_sub(id, 1, 6) == "SOS076" ~ "TAG076",
      .default = str_sub(id, 1, 6)
    ),
    task_rs_hr_diff    = Task - resting_avg,
    conn_dis_hr_diff   = `Self-Connected` - `Self-Disconnected`,
    conn_other_hr_diff = `Self-Connected` - Other,
    conn_rest_hr_diff  = `Self-Connected` - Rest
  )

hr_difference <- hr_final_wide |>
  select(SampleID, task_rs_hr_diff, conn_dis_hr_diff, conn_other_hr_diff, conn_rest_hr_diff)


## ----biomarker-processing, echo=FALSE-----------------------------------------
sos_crp_panel       <- sos_crp       |> select(SampleID, Time, CRP_log)
sos_cytokines_panel <- sos_cytokines |> select(SampleID, Time, IL10_log, IL6_log, TNFalpha_log)
sos_hormones_panel  <- sos_hormones  |> select(SampleID, Time, DHEA_log, Testosterone_log, Cortisol_log)

run_mlm <- function(outcome, data) {
  f_lin  <- as.formula(paste(outcome, "~ 1 + Time + (1 + Time | SampleID)"))
  f_quad <- as.formula(paste(outcome, "~ 1 + poly(Time, 2) + (1 + poly(Time, 2) | SampleID)"))
  mlm_lin  <- lmer(f_lin,  na.action = na.omit, REML = TRUE, data = data)
  mlm_quad <- lmer(f_quad, na.action = na.omit, REML = TRUE, data = data)
  list(linear = mlm_lin, quadratic = mlm_quad, aic = AIC(mlm_lin, mlm_quad), bic = BIC(mlm_lin, mlm_quad))
}

mlm_crp      <- run_mlm("CRP_log",          sos_crp_panel)
mlm_il10     <- run_mlm("IL10_log",         sos_cytokines_panel)
mlm_il6      <- run_mlm("IL6_log",          sos_cytokines_panel)
mlm_tnfalpha <- run_mlm("TNFalpha_log",     sos_cytokines_panel)
mlm_dhea     <- run_mlm("DHEA_log",         sos_hormones_panel)
mlm_test     <- run_mlm("Testosterone_log", sos_hormones_panel)
mlm_cort     <- run_mlm("Cortisol_log",     sos_hormones_panel)


## ----peaks-processing, echo=FALSE---------------------------------------------
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

fmt_p_fdr   <- function(p) {
  if (p < 0.001) "p[FDR] < 0.001" else paste0("p[FDR] == ", round(p, 4))
}
fmt_p_plain <- function(p) {
  if (p < 0.001) "p < 0.001" else sprintf("p = %.3f", p)
}

biomarker_plot <- function(data, y_col, y_label, p_fdr) {
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
    geom_signif(
      comparisons = list(c("T1", "T3/T4 peak")),
      annotations = fmt_p_fdr(p_fdr),
      textsize = 3.5,
      vjust = 0.1,
      tip_length = 0.02,
      parse = TRUE
    ) +
    ylab(y_label) +
    xlab(NULL) +
    theme_minimal() +
    theme(legend.position = "none",
          plot.margin = margin(t = 20, r = 5, b = 5, l = 5))
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

run_peak_test <- function(peak_col, t1_col, data) {
  t.test(
    data[[peak_col]],
    data[[t1_col]],
    alternative = "greater",
    paired = TRUE
  )
}

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

bio_all_difference <- hr_difference |>
  full_join(biomarkers_difference, by = "SampleID")

subj_stress_long <- sos_subj_stress |>
  pivot_longer(
    c(
      selfconnected_subj_stress,
      selfdisconnected_subj_stress,
      other_subj_stress
    ),
    names_to = "condition",
    values_to = "stress"
  ) |>
  mutate(
    condition = factor(
      condition,
      levels = c(
        "selfconnected_subj_stress",
        "selfdisconnected_subj_stress",
        "other_subj_stress"
      ),
      labels = c("Self-Connected", "Self-Disconnected", "Other")
    )
  )

summarize_se <- function(
  data,
  measure_var,
  group_vars = NULL,
  na.rm = FALSE,
  conf.interval = 0.95
) {
  data |>
    group_by(across(all_of(group_vars))) |>
    summarise(
      n = sum(!is.na(.data[[measure_var]])),
      !!measure_var := mean(.data[[measure_var]], na.rm = na.rm),
      sd = sd(.data[[measure_var]], na.rm = na.rm),
      .groups = "drop"
    ) |>
    mutate(se = sd / sqrt(n), ci = se * qt(conf.interval / 2 + 0.5, n - 1))
}

summary_subj <- summarize_se(
  subj_stress_long,
  measure_var = "stress",
  group_vars = "condition",
  na.rm = TRUE
)

wt_plt_sc_sd  <- wilcox.test(sos_subj_stress$selfconnected_subj_stress,
                              sos_subj_stress$selfdisconnected_subj_stress,
                              alternative = "greater", paired = TRUE)
wt_plt_sc_oth <- wilcox.test(sos_subj_stress$selfconnected_subj_stress,
                              sos_subj_stress$other_subj_stress,
                              alternative = "greater", paired = TRUE)
wt_plt_sd_oth <- wilcox.test(sos_subj_stress$selfdisconnected_subj_stress,
                              sos_subj_stress$other_subj_stress,
                              alternative = "greater", paired = TRUE)

subj_comparisons <- list(
  c("Self-Connected", "Self-Disconnected"),
  c("Self-Connected", "Other"),
  c("Self-Disconnected", "Other")
)

subj_plot <- ggplot(
  summary_subj,
  aes(x = condition, y = stress, fill = condition)
) +
  geom_bar(position = position_dodge(), stat = "identity") +
  geom_errorbar(
    aes(ymin = stress - se, ymax = stress + se),
    width = 0.2,
    position = position_dodge(0.9)
  ) +
  scale_fill_viridis_d() +
  stat_summary(
    fun.data = make_box_stats(subj_stress_long, "stress"),
    geom = "text",
    hjust = 0.5,
    vjust = 0,
    size = 4,
    na.rm = TRUE,
    textsize = 3
  ) +
  geom_signif(
    comparisons = subj_comparisons,
    annotations = c(
      fmt_p_plain(wt_plt_sc_sd$p.value),
      fmt_p_plain(wt_plt_sc_oth$p.value),
      fmt_p_plain(wt_plt_sd_oth$p.value)
    ),
    tip_length = 0.02, vjust = -0.4, textsize = 4, y_position = c(3.5, 4.5, 4)
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.45))) +
  ylab("Mean stress rating") +
  xlab("Condition") +
  theme(legend.position = "none") +
  theme_minimal()

subjective_difference <- sos_subj_stress |>
  mutate(
    subj_scsd_difference = selfconnected_subj_stress -
      selfdisconnected_subj_stress,
    subj_scother_difference = selfconnected_subj_stress - other_subj_stress
  ) |>
  select(SampleID, subj_scsd_difference, subj_scother_difference)

all_difference <- bio_all_difference |>
  full_join(subjective_difference, by = "SampleID")

# Peak t-tests and FDR correction (immune and hormones corrected separately)
peak_tests_raw <- list(
  crp = run_peak_test("crp_peak", "CRP_log_1", sos_crp_wide),
  il10 = run_peak_test("il10_peak", "IL10_log_1", sos_cytokines_wide),
  il6 = run_peak_test("il6_peak", "IL6_log_1", sos_cytokines_wide),
  tnfa = run_peak_test("tnfa_peak", "TNFalpha_log_1", sos_cytokines_wide),
  dhea = run_peak_test("dhea_peak", "DHEA_log_1", sos_hormones_wide),
  test = run_peak_test("test_peak", "Testosterone_log_1", sos_hormones_wide),
  cort = run_peak_test("cort_peak", "Cortisol_log_1", sos_hormones_wide)
)
peak_praw <- map_dbl(peak_tests_raw, \(t) t$p.value)
peak_pfdr <- setNames(
  c(
    p.adjust(peak_praw[1:4], method = "fdr"),
    p.adjust(peak_praw[5:7], method = "fdr")
  ),
  names(peak_praw)
)


## ----hr-descriptives----------------------------------------------------------
tibble(
  Condition = c(
    "Resting 1", "Resting 2", "Resting Average", "Task (overall)",
    "Within-task: Rest", "Within-task: Other",
    "Within-task: Self-Disconnected", "Within-task: Self-Connected"
  ),
  `Mean HR (bpm)` = round(c(
    mean(hr_all_wide$`Resting 1`),
    mean(hr_all_wide$`Resting 2`, na.rm = TRUE),
    mean(hr_all_wide$resting_avg),
    mean(hr_all_wide$Task),
    mean(pull_hr("Rest")),
    mean(pull_hr("Other")),
    mean(pull_hr("Self-Disconnected")),
    mean(pull_hr("Self-Connected"))
  ), 2)
) |>
  kable()


## ----hr-diff-descriptives-----------------------------------------------------
bind_rows(
  hr_difference |> select(-SampleID) |> summarise(across(everything(), \(x) mean(x, na.rm = TRUE))) |> mutate(stat = "Mean"),
  hr_difference |> select(-SampleID) |> summarise(across(everything(), \(x) sd(x,   na.rm = TRUE))) |> mutate(stat = "SD")
) |>
  select(stat, everything()) |>
  rename(
    `ΔHR: Task vs. Rest`  = task_rs_hr_diff,
    `ΔHR: SC vs. SD`      = conn_dis_hr_diff,
    `ΔHR: SC vs. Other`   = conn_other_hr_diff,
    `ΔHR: SC vs. Rest`    = conn_rest_hr_diff
  ) |>
  kable(digits = 3, caption = "HR reactivity difference scores (positive = higher during more self-connected/active condition)")


## ----hr-ttests----------------------------------------------------------------
hr_ttest_tbl <- list(
  "Task vs. Resting" = t.test(hr_all_wide$Task, hr_all_wide$resting_avg, alternative = "greater", paired = TRUE),
  "Self-Connected vs. Rest" = t.test(pull_hr("Self-Connected"), pull_hr("Rest"), alternative = "greater", paired = TRUE),
  "Self-Connected vs. Self-Disconnected" = t.test(pull_hr("Self-Connected"), pull_hr("Self-Disconnected"), alternative = "greater", paired = TRUE),
  "Self-Connected vs. Other" = t.test(pull_hr("Self-Connected"), pull_hr("Other"), alternative = "greater", paired = TRUE)
) |>
  map(broom::tidy) |>
  list_rbind(names_to = "comparison") |>
  select(comparison, estimate, statistic, parameter, p.value) |>
  mutate(across(where(is.numeric), \(x) round(x, 3)))

hr_ttest_tbl |>
  mutate(p.value = cell_spec(p.value, bold = p.value < 0.05,
    color = if_else(p.value < 0.05, "#2166ac", "black"))) |>
  kable(col.names = c("Comparison", "Mean diff", "t", "df", "p"), escape = FALSE) |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----hr-results-vals, echo=FALSE, include=FALSE-------------------------------
hr_task_rest <- hr_ttest_tbl |> filter(comparison == "Task vs. Resting")
hr_sc_sd     <- hr_ttest_tbl |> filter(comparison == "Self-Connected vs. Self-Disconnected")
hr_sc_oth    <- hr_ttest_tbl |> filter(comparison == "Self-Connected vs. Other")
hr_sc_rest   <- hr_ttest_tbl |> filter(comparison == "Self-Connected vs. Rest")
fmt_p_txt    <- function(p) ifelse(p < .001, "< .001", paste0("= ", round(p, 3)))


## ----avg-hr-plot, fig.width=5, fig.height=5-----------------------------------
hr_avg_long <- hr_all_wide |>
  select(id, resting_avg, Task) |>
  pivot_longer(
    c(resting_avg, Task),
    names_to = "condition",
    values_to = "mean_hr"
  ) |>
  mutate(
    condition = factor(
      condition,
      levels = c("resting_avg", "Task"),
      labels = c("Resting State Scan", "SOS Task")
    )
  )

ggplot(hr_avg_long, aes(x = condition, y = mean_hr)) +
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
  geom_signif(
    comparisons = list(c("Resting State Scan", "SOS Task")),
    annotations = fmt_p_plain(
      hr_ttest_tbl |> filter(comparison == "Task vs. Resting") |> pull(p.value)
    ),
    tip_length = 0.02, vjust = 0.3, textsize = 3.5
  ) +
  ylab("Mean Heart Rate (bpm)") +
  xlab(NULL) +
  theme_minimal() +
  theme(legend.position = "none")


## ----task-hr-plot, fig.width=7, fig.height=5----------------------------------
task_hr_comparisons <- list(
  c("Self-Connected", "Self-Disconnected"),
  c("Self-Connected", "Other"),
  c("Self-Connected", "Rest")
)

ggplot(hr_conditions_avg, aes(x = task_condition, y = mean_hr)) +
  stat_halfeye(
    aes(fill = task_condition),
    adjust = 0.5, width = 0.6, .width = 0,
    justification = -0.2, point_colour = NA, alpha = 0.8
  ) +
  geom_boxplot(width = 0.15, outlier.shape = NA, color = "gray30", linewidth = 0.5) +
  geom_point(
    aes(color = task_condition),
    position = position_jitter(seed = 1, width = 0.1),
    size = 1.2, alpha = 0.3
  ) +
  scale_fill_viridis_d() +
  scale_color_viridis_d(guide = "none") +
  geom_signif(
    comparisons = task_hr_comparisons,
    annotations = c(
      fmt_p_plain(hr_ttest_tbl |> filter(comparison == "Self-Connected vs. Self-Disconnected") |> pull(p.value)),
      fmt_p_plain(hr_ttest_tbl |> filter(comparison == "Self-Connected vs. Other")             |> pull(p.value)),
      fmt_p_plain(hr_ttest_tbl |> filter(comparison == "Self-Connected vs. Rest")              |> pull(p.value))
    ),
    step_increase = 0.12, tip_length = 0.02, vjust = 0.3, textsize = 3.5
  ) +
  ylab("Mean Heart Rate (bpm)") + xlab(NULL) + theme_minimal() + theme(legend.position = "none")


## ----model-comparison---------------------------------------------------------
mlm_list <- list(
  CRP = mlm_crp, `IL-10` = mlm_il10, `IL-6` = mlm_il6, `TNF-alpha` = mlm_tnfalpha,
  DHEA = mlm_dhea, Testosterone = mlm_test, Cortisol = mlm_cort
)

model_comp_tbl <- imap_dfr(mlm_list, function(res, name) {
  tibble(
    Analyte = name,
    Model   = c("Linear", "Quadratic"),
    df      = res$aic$df,
    AIC     = round(res$aic$AIC, 1),
    BIC     = round(res$bic$BIC, 1)
  )
})

best_rows <- model_comp_tbl |>
  group_by(Analyte) |>
  mutate(is_best = AIC == min(AIC)) |>
  ungroup() |>
  pull(is_best)

model_comp_tbl |>
  kable() |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE) |>
  row_spec(which(best_rows), bold = TRUE, color = "#2166ac")


## ----model-lrt----------------------------------------------------------------
lrt_tbl <- imap_dfr(mlm_list, function(res, name) {
  a       <- anova(res$linear, res$quadratic, refit = TRUE)
  p_col   <- grep("Pr", colnames(a), value = TRUE)[1]
  tibble(
    Analyte = name,
    chisq   = round(a$Chisq[2], 2),
    p_raw   = as.numeric(a[2, p_col])
  )
}) |>
  mutate(
    group = c(rep("Immune", 4), rep("Hormones", 3)),
    p_fdr = c(
      p.adjust(p_raw[1:4], method = "fdr"),
      p.adjust(p_raw[5:7], method = "fdr")
    )
  )

lrt_tbl |>
  mutate(
    p_raw_disp = round(p_raw, 4),
    p_fdr_disp = cell_spec(round(p_fdr, 4), bold = p_fdr < 0.05,
      color = if_else(p_fdr < 0.05, "#2166ac", "black"))
  ) |>
  select(Analyte, group, chisq, p_raw_disp, p_fdr_disp) |>
  kable(escape = FALSE,
        col.names = c("Analyte", "Group", "chi-sq", "p (raw)", "p (FDR)"),
        caption = "Likelihood ratio test: quadratic vs. linear (FDR-corrected within immune and hormone groups; bold = p_FDR < .05)") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----biomarker-trends-results-vals, echo=FALSE, include=FALSE-----------------
best_model_tbl <- model_comp_tbl |>
  group_by(Analyte) |>
  slice_min(AIC, n = 1) |>
  ungroup()
n_quad <- sum(best_model_tbl$Model == "Quadratic")
n_lin  <- sum(best_model_tbl$Model == "Linear")
quad_analytes <- best_model_tbl |> filter(Model == "Quadratic") |> pull(Analyte) |> paste(collapse = ", ")
lin_analytes  <- best_model_tbl |> filter(Model == "Linear")    |> pull(Analyte) |> paste(collapse = ", ")

n_lrt_sig     <- sum(lrt_tbl$p_fdr < 0.05, na.rm = TRUE)
lrt_sig_names <- lrt_tbl |> filter(p_fdr < 0.05) |> pull(Analyte) |> paste(collapse = ", ")
lrt_ns_names  <- lrt_tbl |> filter(p_fdr >= 0.05) |> pull(Analyte) |> paste(collapse = ", ")


## ----quad-fixed-effects, results='asis'---------------------------------------
# Collect all fixed effects, then FDR-correct within term × group
all_fixed_effects <- imap_dfr(mlm_list, function(res, name) {
  broom.mixed::tidy(res$quadratic, effects = "fixed") |>
    mutate(Analyte = name)
}) |>
  mutate(group = if_else(
    Analyte %in% c("CRP", "IL-10", "IL-6", "TNF-alpha"), "Immune", "Hormones"
  )) |>
  group_by(term, group) |>
  mutate(p_fdr = p.adjust(p.value, method = "fdr")) |>
  ungroup()

iwalk(mlm_list, function(res, name) {
  cat("\n\n### ", name, "\n\n")
  tbl <- all_fixed_effects |>
    filter(Analyte == name) |>
    select(term, estimate, std.error, statistic, df, p.value, p_fdr) |>
    mutate(
      across(c(estimate, std.error, statistic, df), \(x) round(x, 3)),
      p.value = round(p.value, 4),
      p_fdr   = round(p_fdr,   4)
    )
  tbl |>
    mutate(p_fdr = cell_spec(p_fdr, bold = !is.na(p_fdr) & p_fdr < 0.05,
      color = if_else(!is.na(p_fdr) & p_fdr < 0.05, "#2166ac", "black"))) |>
    kable(escape = FALSE,
          col.names = c("Term", "b", "SE", "t", "df", "p (raw)", "p (FDR)")) |>
    kable_styling(bootstrap_options = "hover", full_width = FALSE) |>
    print()
})


## ----quad-plots, fig.width=10, fig.height=4-----------------------------------
cytokines_long <- sos_cytokines_panel |>
  pivot_longer(c(IL10_log, IL6_log, TNFalpha_log), names_to = "biomarker", values_to = "log_conc") |>
  mutate(biomarker = case_match(
    biomarker,
    "IL10_log"     ~ "IL-10",
    "IL6_log"      ~ "IL-6",
    "TNFalpha_log" ~ "TNF-\u03b1"
  ))

cytokines_quad_plot <- ggplot(cytokines_long, aes(Time, log_conc, color = biomarker)) +
  stat_smooth(method = "lm", formula = y ~ x + I(x^2), linewidth = 1,
              aes(fill = after_scale(colour)), alpha = 0.2) +
  scale_colour_viridis_d() +
  ylab("Concentration (log-transformed)") + xlab("Time point") + ggtitle("Cytokines") + theme_minimal()

hormones_long <- sos_hormones_panel |>
  pivot_longer(c(DHEA_log, Testosterone_log, Cortisol_log), names_to = "biomarker", values_to = "log_conc") |>
  mutate(biomarker = case_match(
    biomarker,
    "DHEA_log"         ~ "DHEA",
    "Testosterone_log" ~ "Testosterone",
    "Cortisol_log"     ~ "Cortisol"
  ))

hormones_quad_plot <- ggplot(hormones_long, aes(Time, log_conc, color = biomarker)) +
  stat_smooth(method = "lm", formula = y ~ x + I(x^2), linewidth = 1,
              aes(fill = after_scale(colour)), alpha = 0.2) +
  scale_colour_viridis_d() +
  ylab("Concentration (log-transformed)") + xlab("Time point") + ggtitle("Hormones") + theme_minimal()

ggarrange(cytokines_quad_plot, hormones_quad_plot, ncol = 2)


## ----ind-growth-curves, fig.width=12, fig.height=8----------------------------
panel_map <- list(
  "CRP"          = list(data = sos_crp_panel,       col = "CRP_log"),
  "IL-10"        = list(data = sos_cytokines_panel, col = "IL10_log"),
  "IL-6"         = list(data = sos_cytokines_panel, col = "IL6_log"),
  "TNF-alpha"    = list(data = sos_cytokines_panel, col = "TNFalpha_log"),
  "DHEA"         = list(data = sos_hormones_panel,  col = "DHEA_log"),
  "Testosterone" = list(data = sos_hormones_panel,  col = "Testosterone_log"),
  "Cortisol"     = list(data = sos_hormones_panel,  col = "Cortisol_log")
)

ind_curve_data <- imap_dfr(mlm_list, function(res, name) {
  pm      <- panel_map[[name]]
  obs_dat <- pm$data |>
    select(SampleID, Time, value = all_of(pm$col)) |>
    filter(!is.na(value))

  obs_dat |>
    mutate(
      fitted_ind = predict(res$quadratic, newdata = obs_dat),
      fitted_pop = predict(res$quadratic, newdata = obs_dat, re.form = NA),
      analyte    = name
    )
}) |>
  mutate(
    analyte = recode(analyte, "TNF-alpha" = "TNF-α"),
    analyte = factor(analyte,
      levels = c("CRP", "IL-10", "IL-6", "TNF-α", "DHEA", "Testosterone", "Cortisol"))
  )

pop_curve <- ind_curve_data |>
  group_by(analyte, Time) |>
  summarise(fitted_pop = mean(fitted_pop, na.rm = TRUE), .groups = "drop")

ggplot(ind_curve_data, aes(x = Time, group = SampleID)) +
  geom_line(aes(y = value),      color = "gray70", linewidth = 0.35, alpha = 0.6) +
  geom_point(aes(y = value),     color = "gray70", size = 0.7,       alpha = 0.5) +
  geom_line(aes(y = fitted_ind, color = SampleID),
            linewidth = 0.5, alpha = 0.45, show.legend = FALSE) +
  geom_line(data = pop_curve,
            aes(x = Time, y = fitted_pop, group = NULL),
            color = "black", linewidth = 1.3, inherit.aes = FALSE) +
  scale_x_continuous(breaks = 1:4, labels = paste0("T", 1:4)) +
  scale_color_viridis_d() +
  facet_wrap(~analyte, scales = "free_y", ncol = 4) +
  labs(x = "Timepoint", y = "Concentration (log-transformed)") +
  theme_minimal() +
  theme(panel.grid.minor = element_blank(),
        strip.text = element_text(face = "bold"))


## ----peak-ttests--------------------------------------------------------------
peak_ttest_tbl <- peak_tests_raw |>
  map(broom::tidy) |>
  list_rbind(names_to = "analyte") |>
  mutate(analyte = case_match(
    analyte,
    "crp" ~ "CRP", "il10" ~ "IL-10", "il6" ~ "IL-6", "tnfa" ~ "TNF-alpha",
    "dhea" ~ "DHEA", "test" ~ "Testosterone", "cort" ~ "Cortisol"
  )) |>
  select(analyte, estimate, statistic, parameter, p.value) |>
  mutate(across(where(is.numeric), \(x) round(x, 3)))

peak_ttest_tbl |>
  mutate(p.value = cell_spec(p.value, bold = p.value < 0.05,
    color = if_else(p.value < 0.05, "#2166ac", "black"))) |>
  kable(col.names = c("Analyte", "Mean diff (peak − T1)", "t", "df", "p (one-tailed)"), escape = FALSE) |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----fdr----------------------------------------------------------------------
fdr_tbl <- tibble(
  group   = c(rep("Immune", 4), rep("Hormones", 3)),
  analyte = c("CRP", "IL-10", "IL-6", "TNF-alpha", "DHEA", "Testosterone", "Cortisol"),
  p_raw   = round(peak_praw, 6),
  p_fdr   = peak_pfdr
)

fdr_tbl |>
  mutate(p_fdr = cell_spec(round(p_fdr, 4), bold = p_fdr < 0.05,
    color = if_else(p_fdr < 0.05, "#2166ac", "black"))) |>
  kable(col.names = c("Group", "Analyte", "p (raw)", "p (FDR)"), escape = FALSE) |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----reactivity-results-vals, echo=FALSE, include=FALSE-----------------------
sig_immune  <- fdr_tbl |> filter(group == "Immune",   p_fdr < 0.05) |> pull(analyte)
sig_hormone <- fdr_tbl |> filter(group == "Hormones", p_fdr < 0.05) |> pull(analyte)
ns_immune   <- fdr_tbl |> filter(group == "Immune",   p_fdr >= 0.05) |> pull(analyte)
ns_hormone  <- fdr_tbl |> filter(group == "Hormones", p_fdr >= 0.05) |> pull(analyte)

fmt_sig <- function(x) if (length(x) == 0) "none" else paste(x, collapse = ", ")

react_means <- biomarkers_difference |>
  summarise(across(-SampleID, \(x) round(mean(x, na.rm = TRUE), 3)))
react_sds <- biomarkers_difference |>
  summarise(across(-SampleID, \(x) round(sd(x, na.rm = TRUE), 3)))

peak_tbl_lookup <- peak_ttest_tbl
get_peak <- function(analyte_name, col) {
  peak_tbl_lookup[peak_tbl_lookup$analyte == analyte_name, col]
}


## ----immune-grid, fig.width=10, fig.height=9----------------------------------
crp_plot  <- biomarker_plot(sos_crp_long,  "crp_log_conc",  "CRP (log-transformed)",        peak_pfdr["crp"])
il10_plot <- biomarker_plot(sos_il10_long, "il10_log_conc", "IL-10 (log-transformed)",       peak_pfdr["il10"])
il6_plot  <- biomarker_plot(sos_il6_long,  "il6_log_conc",  "IL-6 (log-transformed)",        peak_pfdr["il6"])
tnfa_plot <- biomarker_plot(sos_tnfa_long, "tnfa_log_conc", "TNF-\u03b1 (log-transformed)",  peak_pfdr["tnfa"])

ggarrange(crp_plot, il10_plot, il6_plot, tnfa_plot,
  labels = c("CRP", "IL-10", "IL-6", "TNF-alpha"), ncol = 2, nrow = 2,
  hjust = -0.3, vjust = 2)


## ----crp-plot, fig.width=5, fig.height=5--------------------------------------
crp_plot


## ----il10-plot, fig.width=5, fig.height=5-------------------------------------
il10_plot


## ----il6-plot, fig.width=5, fig.height=5--------------------------------------
il6_plot


## ----tnfa-plot, fig.width=5, fig.height=5-------------------------------------
tnfa_plot


## ----hormone-grid, fig.width=12, fig.height=5---------------------------------
dhea_plot <- biomarker_plot(sos_dhea_long, "dhea_log_conc", "DHEA (log-transformed)",          peak_pfdr["dhea"])
test_plot <- biomarker_plot(sos_test_long, "test_log_conc", "Testosterone (log-transformed)",   peak_pfdr["test"])
cort_plot <- biomarker_plot(sos_cort_long, "cort_log_conc", "Cortisol (log-transformed)",       peak_pfdr["cort"])

ggarrange(dhea_plot, test_plot, cort_plot,
  labels = c("DHEA", "Testosterone", "Cortisol"), ncol = 3, nrow = 1,
  hjust = -0.3, vjust = 2)


## ----dhea-plot, fig.width=5, fig.height=5-------------------------------------
dhea_plot


## ----test-plot, fig.width=5, fig.height=5-------------------------------------
test_plot


## ----cort-plot, fig.width=5, fig.height=5-------------------------------------
cort_plot


## ----reactivity-descriptives--------------------------------------------------
bind_rows(
  biomarkers_difference |> select(-SampleID) |> summarise(across(everything(), \(x) mean(x, na.rm = TRUE))) |> mutate(stat = "Mean"),
  biomarkers_difference |> select(-SampleID) |> summarise(across(everything(), \(x) sd(x,   na.rm = TRUE))) |> mutate(stat = "SD")
) |>
  select(stat, everything()) |>
  rename(
    `ΔCRP`          = crp_difference,
    `ΔIL-10`        = il10_difference,
    `ΔIL-6`         = il6_difference,
    `ΔTNF-α`        = tnfa_difference,
    `ΔDHEA`         = dhea_difference,
    `ΔTestosterone` = test_difference,
    `ΔCortisol`     = cort_difference
  ) |>
  kable(digits = 3)


## ----subj-stress-descriptives-------------------------------------------------
bind_rows(
  subjective_difference |> select(-SampleID) |> summarise(across(everything(), \(x) mean(x, na.rm = TRUE))) |> mutate(stat = "Mean"),
  subjective_difference |> select(-SampleID) |> summarise(across(everything(), \(x) sd(x,   na.rm = TRUE))) |> mutate(stat = "SD")
) |>
  select(stat, everything()) |>
  rename(
    `ΔSubjective Stress: SC vs. SD`    = subj_scsd_difference,
    `ΔSubjective Stress: SC vs. Other` = subj_scother_difference
  ) |>
  kable(digits = 3, caption = "Subjective stress difference scores (positive = higher stress during Self-Connected)")


## ----subj-stress-plot, fig.width=6, fig.height=6------------------------------
subj_plot


## ----subj-results-vals, echo=FALSE, include=FALSE-----------------------------
# Run Wilcoxon tests explicitly so values are available for inline text
subj_wide <- sos_subj_stress
wt_sc_sd  <- wilcox.test(subj_wide$selfconnected_subj_stress,
                          subj_wide$selfdisconnected_subj_stress,
                          paired = TRUE, alternative = "greater")
wt_sc_oth <- wilcox.test(subj_wide$selfconnected_subj_stress,
                          subj_wide$other_subj_stress,
                          paired = TRUE, alternative = "greater")
m_sc  <- round(mean(subj_wide$selfconnected_subj_stress,  na.rm = TRUE), 2)
m_sd2 <- round(mean(subj_wide$selfdisconnected_subj_stress, na.rm = TRUE), 2)
m_oth <- round(mean(subj_wide$other_subj_stress,           na.rm = TRUE), 2)
sd_sc  <- round(sd(subj_wide$selfconnected_subj_stress,    na.rm = TRUE), 2)
sd_sd2 <- round(sd(subj_wide$selfdisconnected_subj_stress, na.rm = TRUE), 2)
sd_oth <- round(sd(subj_wide$other_subj_stress,            na.rm = TRUE), 2)


## ----corr-matrix, fig.width=10, fig.height=9----------------------------------
diff_matrix <- all_difference |> select(-SampleID) |> as.matrix()
colnames(diff_matrix) <- c(
  "ΔHR: Task vs. Rest", "ΔHR: SC vs. SD", "ΔHR: SC vs. Other", "ΔHR: SC vs. Rest",
  "ΔCRP", "ΔIL-10", "ΔIL-6", "ΔTNF-α", "ΔDHEA", "ΔTestosterone", "ΔCortisol",
  "ΔSubj Stress: SC vs. SD", "ΔSubj Stress: SC vs. Other"
)
difference_rcorrs <- rcorr(diff_matrix)

plot_sig_corrplot <- function(r_mat, p_mat, title = "", type = "upper",
                              cl.ratio = 0.15, cl.cex = 0.9,
                              tl.cex = 0.8, mar = NULL) {
  if (is.null(mar)) {
    mar <- c(0, 0, if (nchar(title) > 0) 2 else 0, 0)
  }
  corrplot(
    r_mat,
    p.mat     = p_mat,
    sig.level = 0.05,
    insig     = "pch",
    pch       = 4,
    pch.col   = "black",
    pch.cex   = 2.5,
    method    = "circle",
    type      = type,
    tl.col    = "black",
    tl.srt    = 45,
    tl.cex    = tl.cex,
    col       = colorRampPalette(c("#d73027", "white", "#4575b4"))(200),
    diag      = FALSE,
    title     = title,
    mar       = mar,
    cl.ratio  = cl.ratio,
    cl.cex    = cl.cex
  )
}

plot_sig_corrplot(difference_rcorrs$r, difference_rcorrs$P)


## ----corr-pvalues-------------------------------------------------------------
difference_rcorrs <- rcorr(diff_matrix)

difference_rcorrs$P |>
  as.data.frame() |>
  mutate(across(everything(), \(x) round(x, 3))) |>
  mutate(across(everything(), \(x) {
    sig  <- !is.na(x) & x < 0.05
    xlab <- if_else(is.na(x), "—", as.character(x))
    cell_spec(xlab, bold = sig, color = if_else(sig, "#2166ac", "black"))
  })) |>
  kable(escape = FALSE) |>
  kable_styling(bootstrap_options = "hover")


## ----corr-results-vals, echo=FALSE, include=FALSE-----------------------------
p_upper <- difference_rcorrs$P
p_upper[lower.tri(p_upper, diag = TRUE)] <- NA
r_upper <- difference_rcorrs$r
r_upper[lower.tri(r_upper, diag = TRUE)] <- NA

n_corr_pairs_total <- sum(!is.na(p_upper))
n_corr_sig         <- sum(p_upper < 0.05, na.rm = TRUE)

# Largest positive and negative r among sig pairs
sig_r_vals <- r_upper[!is.na(p_upper) & p_upper < 0.05]
corr_r_range <- if (length(sig_r_vals) > 0) {
  paste0("ranging from r = ", round(min(sig_r_vals), 2), " to r = ", round(max(sig_r_vals), 2))
} else {
  ""
}


## ----puberty-load, echo=FALSE-------------------------------------------------
sos_puberty <- read.csv(paste0(data_path, "/SOS/SOS-study-monash/SOS_LD_avg.csv"))

# Age at session (for computing pubertal timing residuals)
dob_session_raw <- read.csv(file.path(
  data_path, "SOS/SOS-study-monash/questionnaires/SOS_DOB_sessiondate.csv"
)) |>
  mutate(SampleID = sub("_", "", subject_spit_id))

age_df <- dob_session_raw |>
  filter(redcap_event_name == "ongoing_records_arm_1") |>
  select(SampleID, dob) |>
  mutate(dob = as.Date(dob)) |>
  inner_join(
    dob_session_raw |>
      filter(redcap_event_name == "sos_arm_1") |>
      select(SampleID, sos_session_date) |>
      mutate(sos_session_date = as.Date(sos_session_date)),
    by = "SampleID"
  ) |>
  mutate(age_at_session = as.numeric(sos_session_date - dob) / 365.25) |>
  select(SampleID, age_at_session)

# Pubertal timing: residuals from LD_avg ~ age (positive = advanced for age)
timing_base <- sos_puberty |>
  left_join(age_df, by = "SampleID") |>
  filter(!is.na(LD_avg), !is.na(age_at_session))

timing_model  <- lm(LD_avg ~ age_at_session, data = timing_base, na.action = na.exclude)
timing_base$pub_timing <- residuals(timing_model)

# Age at menarche: parse PDS_F9 (free-text date of first period) + DOB → age in years
pds_raw <- read.csv(file.path(
  data_path, "SOS/SOS-study-monash/questionnaires/CESD_PDS.csv"
)) |>
  select(SampleID, menarche_date_raw = PDS_F9)

parse_menarche_date <- function(x) {
  x <- trimws(x)
  x <- gsub("(\\d+)(st|nd|rd|th)", "\\1", x, ignore.case = TRUE)  # strip ordinals
  suppressWarnings(lubridate::parse_date_time(
    x,
    orders = c("mdy", "mdY", "BdY", "bdY",
               "YBd", "Ybd", "BY", "bY", "by",   # "by" catches "Sep-17"
               "Y", "dBY", "dbY"),
    quiet  = TRUE
  ))
}

dob_df <- dob_session_raw |>
  filter(redcap_event_name == "ongoing_records_arm_1") |>
  select(SampleID, dob) |>
  mutate(dob = as.Date(dob))

menarche_df <- pds_raw |>
  left_join(dob_df, by = "SampleID") |>
  mutate(
    menarche_date = as.Date(parse_menarche_date(menarche_date_raw)),
    age_menarche  = as.numeric(menarche_date - dob) / 365.25
  ) |>
  select(SampleID, age_menarche)

timing_df <- timing_base |>
  left_join(menarche_df, by = "SampleID") |>
  mutate(
    LD_avg_c          = LD_avg          - mean(LD_avg,          na.rm = TRUE),
    age_at_session_c  = age_at_session  - mean(age_at_session,  na.rm = TRUE),
    age_menarche_c    = age_menarche    - mean(age_menarche,    na.rm = TRUE)
  ) |>
  select(SampleID, age_at_session, age_at_session_c, LD_avg, LD_avg_c,
         pub_timing, age_menarche, age_menarche_c)


## ----puberty-processing, echo=FALSE-------------------------------------------
# Join puberty data with reactivity difference scores
puberty_reactivity <- all_difference |>
  left_join(
    sos_puberty |>
      mutate(LD_avg_c = LD_avg - mean(LD_avg, na.rm = TRUE)),
    by = "SampleID"
  )

# Identify puberty variable names
puberty_vars <- sos_puberty |> select(-SampleID) |> names()

# Timing variables (defined here so they are available for the combined matrix below)
timing_vars        <- c("pub_timing", "age_menarche_c")
timing_labels      <- c("Off-time (stage residualised on age)", "Age at menarche (centred, years)")
timing_reactivity  <- all_difference |> left_join(timing_df, by = "SampleID")

reactivity_vars <- c(
  "task_rs_hr_diff", "conn_dis_hr_diff", "conn_other_hr_diff", "conn_rest_hr_diff",
  "crp_difference", "il10_difference", "il6_difference", "tnfa_difference",
  "dhea_difference", "test_difference", "cort_difference",
  "subj_scsd_difference", "subj_scother_difference"
)

reactivity_labels <- c(
  "ΔHR: Task vs. Rest", "ΔHR: SC vs. SD", "ΔHR: SC vs. Other", "ΔHR: SC vs. Rest",
  "ΔCRP", "ΔIL-10", "ΔIL-6", "ΔTNF-α", "ΔDHEA", "ΔTestosterone", "ΔCortisol",
  "ΔSubj Stress: SC vs. SD", "ΔSubj Stress: SC vs. Other"
)


## ----puberty-descriptives-----------------------------------------------------
sos_puberty |>
  select(-SampleID) |>
  summarise(across(everything(), list(
    Mean = \(x) round(mean(x, na.rm = TRUE), 2),
    SD   = \(x) round(sd(x,   na.rm = TRUE), 2),
    Min  = \(x) round(min(x,  na.rm = TRUE), 2),
    Max  = \(x) round(max(x,  na.rm = TRUE), 2),
    N    = \(x) sum(!is.na(x))
  ))) |>
  pivot_longer(everything(), names_to = c("variable", "stat"), names_sep = "_(?=[^_]+$)") |>
  pivot_wider(names_from = stat, values_from = value) |>
  kable(caption = "Puberty variable descriptives") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----all-puberty-corr-matrix, fig.width=14, fig.height=5----------------------
# Combine stage + timing vars; timing_reactivity already contains LD_avg via timing_df
all_pub_vars   <- c(puberty_vars, timing_vars)
all_pub_labels <- c(puberty_vars, timing_labels)

all_pub_mat <- timing_reactivity |>
  select(all_of(c(all_pub_vars, reactivity_vars))) |>
  as.matrix()
colnames(all_pub_mat) <- c(all_pub_labels, reactivity_labels)

all_pub_corrs <- rcorr(all_pub_mat)

# Also keep pub_react_corrs for downstream inline results text
pub_react_corrs <- all_pub_corrs

plot_sig_corrplot(
  all_pub_corrs$r[all_pub_labels, reactivity_labels, drop = FALSE],
  all_pub_corrs$P[all_pub_labels, reactivity_labels, drop = FALSE],
  type = "full", cl.ratio = 0.06, cl.cex = 0.85,
  tl.cex = 0.72, mar = c(0, 0, 1, 6)
)


## ----all-puberty-corr-pvalues-------------------------------------------------
hr_cols   <- reactivity_labels[1:4]
imm_cols  <- reactivity_labels[5:8]
horm_cols <- reactivity_labels[9:11]
subj_cols <- reactivity_labels[12:13]

raw_allpub_mat <- all_pub_corrs$P[all_pub_labels, reactivity_labels, drop = FALSE]

fdr_allpub_mat <- raw_allpub_mat
for (cols in list(hr_cols, imm_cols, horm_cols, subj_cols)) {
  sub <- raw_allpub_mat[, cols, drop = FALSE]
  fdr_allpub_mat[, cols] <- matrix(
    p.adjust(as.vector(sub), method = "fdr"),
    nrow = nrow(sub), ncol = ncol(sub)
  )
}

fdr_allpub_mat |>
  as.data.frame() |>
  mutate(across(everything(), \(x) {
    sig  <- !is.na(x) & x < 0.05
    xlab <- if_else(is.na(x), "—", as.character(round(x, 4)))
    cell_spec(xlab, bold = sig, color = if_else(sig, "#2166ac", "black"))
  })) |>
  kable(escape = FALSE,
        caption = "FDR-adjusted p-values: all puberty variables × reactivity (bold = p_FDR < .05)") |>
  kable_styling(bootstrap_options = "hover")


## ----puberty-regressions, results='asis'--------------------------------------
pv_c <- paste0(puberty_vars, "_c")   # centered counterparts

for (i in seq_along(puberty_vars)) {
  pv  <- puberty_vars[i]
  pvc <- pv_c[i]
  cat("\n\n###", pv, "(centred)\n\n")
  reg_tbl <- map_dfr(setNames(reactivity_vars, reactivity_labels), function(rv) {
    dat <- puberty_reactivity |> select(all_of(c(rv, pvc))) |> na.omit()
    if (nrow(dat) < 5) return(NULL)
    fit <- lm(as.formula(paste(rv, "~", pvc)), data = dat)
    broom::tidy(fit) |>
      filter(term != "(Intercept)") |>
      mutate(term = pv, outcome = rv, .before = 1)
  }, .id = "Reactivity") |>
    select(Reactivity, estimate, std.error, statistic, p.value) |>
    mutate(p_fdr = round(p.adjust(p.value, method = "fdr"), 4)) |>
    mutate(across(c(estimate, std.error, statistic), \(x) round(x, 3))) |>
    mutate(p.value = round(p.value, 4))

  reg_tbl |>
    mutate(
      p.value = as.character(p.value),
      p_fdr   = cell_spec(p_fdr, bold = !is.na(p_fdr) & p_fdr < 0.05,
        color = if_else(!is.na(p_fdr) & p_fdr < 0.05, "#2166ac", "black"))
    ) |>
    kable(escape = FALSE,
          col.names = c("Reactivity outcome", "b", "SE", "t", "p (raw)", "p (FDR)")) |>
    kable_styling(bootstrap_options = "hover", full_width = FALSE) |>
    print()
}


## ----puberty-reactivity-scatter, results='asis', fig.width=10, fig.height=5----
bio_react_labels <- c(
  crp_difference = "ΔCRP",
  il10_difference = "ΔIL-10",
  il6_difference = "ΔIL-6",
  tnfa_difference = "ΔTNF-α",
  dhea_difference = "ΔDHEA",
  test_difference = "ΔTestosterone",
  cort_difference = "ΔCortisol"
)
bio_react_vars <- names(bio_react_labels)

for (pv in puberty_vars) {
  cat("\n\n###", pv, "\n\n")
  pdat <- puberty_reactivity |>
    select(all_of(c(pv, bio_react_vars))) |>
    pivot_longer(
      -all_of(pv),
      names_to = "biomarker",
      values_to = "reactivity"
    ) |>
    mutate(
      biomarker = factor(
        biomarker,
        levels = bio_react_vars,
        labels = unname(bio_react_labels)
      )
    )

  p <- ggplot(pdat, aes(x = .data[[pv]], y = reactivity)) +
    geom_point(alpha = 0.35, size = 1.5) +
    geom_smooth(
      method = "loess",
      formula = y ~ x,
      se = TRUE,
      color = "#440154FF",
      fill = "#440154FF",
      alpha = 0.15,
      linewidth = 0.9
    ) +
    facet_wrap(~biomarker, nrow = 2, scales = "free_y") +
    labs(x = pv, y = "Reactivity (peak − T1, log scale)") +
    theme_minimal(base_size = 10)
  print(p)
}


## ----puberty-reactivity-results-vals, echo=FALSE, include=FALSE---------------
pub_r_mat <- pub_react_corrs$r
pub_p_mat <- pub_react_corrs$P

# The matrix uses reactivity_labels as column names — biomarker reactivity subset
bio_rlabels <- c("ΔCRP", "ΔIL-10", "ΔIL-6", "ΔTNF-α", "ΔDHEA", "ΔTestosterone", "ΔCortisol")

sig_pub_pairs <- expand.grid(pv = puberty_vars, rv = bio_rlabels,
                             stringsAsFactors = FALSE) |>
  rowwise() |>
  mutate(
    r   = round(pub_r_mat[pv, rv], 2),
    p   = round(pub_p_mat[pv, rv], 3),
    sig = !is.na(p) & p < .05,
    label = paste0(pv, " × ", rv, " (r = ", r, ", p = ", p, ")")
  ) |>
  ungroup() |>
  filter(sig)

n_sig_pairs <- nrow(sig_pub_pairs)
sig_pair_text <- if (n_sig_pairs == 0) "none reached statistical significance" else
  paste(sig_pub_pairs$label, collapse = "; ")

# Also summarise across all 13 reactivity outcomes (not just biomarkers)
sig_pub_all <- expand.grid(pv = puberty_vars, rv = reactivity_labels,
                           stringsAsFactors = FALSE) |>
  rowwise() |>
  mutate(
    r   = round(all_pub_corrs$r[pv, rv], 2),
    p   = round(all_pub_corrs$P[pv, rv], 3),
    sig = !is.na(p) & p < .05,
    label = paste0(rv, " (r = ", r, ", p = ", p, ")")
  ) |>
  ungroup() |>
  filter(sig)

n_sig_pub_all    <- nrow(sig_pub_all)
sig_pub_all_text <- if (n_sig_pub_all == 0) "none reached statistical significance" else
  paste(sig_pub_all$label, collapse = "; ")


## ----timing-processing, echo=FALSE--------------------------------------------
# timing_reactivity, timing_vars, timing_labels defined in puberty-processing chunk


## ----timing-descriptives------------------------------------------------------
timing_df |>
  select(age_at_session, LD_avg, pub_timing, age_menarche) |>
  psych::describe() |>
  as.data.frame() |>
  select(n, mean, sd, min, max, skew, kurtosis) |>
  mutate(across(where(is.numeric), \(x) round(x, 2))) |>
  tibble::rownames_to_column("Variable") |>
  mutate(Variable = recode(Variable,
    age_at_session = "Age at session (years)",
    LD_avg         = "Pubertal stage (LD avg)",
    pub_timing     = "Off-time (stage ~ age residual)",
    age_menarche   = "Age at menarche (years)"
  )) |>
  kable(caption = "Pubertal timing descriptives") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----timing-stage-age-reg-----------------------------------------------------
broom::tidy(timing_model) |>
  mutate(across(where(is.numeric), \(x) round(x, 3))) |>
  kable(caption = "Pubertal stage ~ age regression") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----timing-regressions, results='asis'---------------------------------------
timing_joint_tbl <- map_dfr(setNames(reactivity_vars, reactivity_labels), function(rv) {
  dat <- timing_reactivity |>
    select(all_of(c(rv, "LD_avg_c", "age_at_session_c"))) |>
    na.omit()
  if (nrow(dat) < 5) return(NULL)
  fit <- lm(as.formula(paste(rv, "~ LD_avg_c + age_at_session_c")), data = dat)
  broom::tidy(fit) |>
    filter(term != "(Intercept)") |>
    mutate(
      term    = recode(term,
        LD_avg_c         = "Pubertal stage (centred)",
        age_at_session_c = "Age at session (centred)"
      ),
      across(c(estimate, std.error, statistic), \(x) round(x, 3)),
      p.value = round(p.value, 4)
    )
}, .id = "Reactivity") |>
  group_by(term) |>
  mutate(p_fdr = round(p.adjust(p.value, method = "fdr"), 4)) |>
  ungroup()

for (trm in unique(timing_joint_tbl$term)) {
  cat("\n\n###", trm, "\n\n")
  timing_joint_tbl |>
    filter(term == trm) |>
    select(Reactivity, estimate, std.error, statistic, p.value, p_fdr) |>
    mutate(p_fdr = cell_spec(p_fdr, bold = !is.na(p_fdr) & p_fdr < 0.05,
      color = if_else(!is.na(p_fdr) & p_fdr < 0.05, "#2166ac", "black"))) |>
    kable(escape = FALSE,
          col.names = c("Reactivity outcome", "b", "SE", "t", "p (raw)", "p (FDR)"),
          caption = paste("Reactivity ~", trm, "+ other term (both centred); FDR within term")) |>
    kable_styling(bootstrap_options = "hover", full_width = FALSE) |>
    print()
}


## ----timing-results-vals, echo=FALSE, include=FALSE---------------------------
sig_timing_stage <- timing_joint_tbl |>
  filter(term == "Pubertal stage (centred)", p_fdr < 0.05)
sig_timing_age   <- timing_joint_tbl |>
  filter(term == "Age at session (centred)", p_fdr < 0.05)

n_timing_stage_sig <- nrow(sig_timing_stage)
n_timing_age_sig   <- nrow(sig_timing_age)

fmt_timing_sig <- function(df) {
  if (nrow(df) == 0) return("none reached statistical significance after FDR correction")
  paste(
    paste0(df$Reactivity, " (*b* = ", df$estimate, ", *p*~FDR~ = ", df$p_fdr, ")"),
    collapse = "; "
  )
}


## ----timing-reactivity-scatter, results='asis', fig.width=10, fig.height=5----
bio_react_vars   <- names(bio_react_labels)

for (tv in timing_vars) {
  tv_label <- timing_labels[which(timing_vars == tv)]
  cat("\n\n###", tv_label, "\n\n")

  pdat <- timing_reactivity |>
    select(all_of(c(tv, bio_react_vars))) |>
    pivot_longer(-all_of(tv), names_to = "biomarker", values_to = "reactivity") |>
    mutate(biomarker = factor(biomarker, levels = bio_react_vars,
                              labels = unname(bio_react_labels)))

  p <- ggplot(pdat, aes(x = .data[[tv]], y = reactivity)) +
    geom_point(alpha = 0.35, size = 1.5) +
    geom_smooth(method = "loess", formula = y ~ x, se = TRUE,
                color = "#440154FF", fill = "#440154FF", alpha = 0.15, linewidth = 0.9) +
    facet_wrap(~biomarker, nrow = 2, scales = "free_y") +
    labs(x = tv_label, y = "Reactivity (peak − T1, log scale)") +
    theme_minimal(base_size = 10)
  print(p)
}


## ----lpa-data-prep, echo=FALSE------------------------------------------------
lpa_input <- bio_all_difference |>
  select(SampleID, cort_difference, crp_difference, il6_difference, tnfa_difference, il10_difference) |>
  na.omit()


## ----lpa-fit------------------------------------------------------------------
lpa_models <- lpa_input |>
  select(-SampleID) |>
  scale() |>
  as.data.frame() |>
  estimate_profiles(1:5, package = "mclust")

compare_solutions(lpa_models)


## ----lpa-select, echo=FALSE---------------------------------------------------
# Inspect BIC/entropy table above and set n_profiles to your chosen solution
n_profiles <- 2

lpa_final <- lpa_input |>
  select(-SampleID) |>
  scale() |>
  as.data.frame() |>
  estimate_profiles(n_profiles, package = "mclust")

lpa_assignments <- lpa_input |>
  select(SampleID) |>
  bind_cols(get_data(lpa_final) |> select(Class))  |>
  rename(profile = Class) |>
  mutate(profile = factor(profile, labels = paste("Profile", 1:n_profiles)))


## ----lpa-profile-plot, fig.width=9, fig.height=5------------------------------
profile_means <- lpa_assignments |>
  left_join(lpa_input, by = "SampleID") |>
  pivot_longer(
    c(cort_difference, crp_difference, il6_difference, tnfa_difference, il10_difference),
    names_to  = "biomarker",
    values_to = "reactivity"
  ) |>
  mutate(biomarker = case_match(
    biomarker,
    "cort_difference" ~ "Cortisol",
    "crp_difference"  ~ "CRP",
    "il6_difference"  ~ "IL-6",
    "tnfa_difference" ~ "TNF-α",
    "il10_difference" ~ "IL-10"
  )) |>
  group_by(profile, biomarker) |>
  summarise(
    mean_react = mean(reactivity, na.rm = TRUE),
    se_react   = sd(reactivity,   na.rm = TRUE) / sqrt(n()),
    .groups    = "drop"
  )

ggplot(profile_means, aes(x = biomarker, y = mean_react, color = profile, group = profile)) +
  geom_line(linewidth = 1) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = mean_react - se_react, ymax = mean_react + se_react), width = 0.15) +
  scale_color_viridis_d() +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  labs(y = "Mean reactivity (peak − T1, log-transformed)", x = NULL, color = "Profile") +
  theme_minimal()


## ----lpa-profile-ns-----------------------------------------------------------
lpa_assignments |>
  count(profile) |>
  kable(col.names = c("Profile", "n"), caption = "Profile membership counts") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----lpa-results-vals, echo=FALSE, include=FALSE------------------------------
prof_ns   <- lpa_assignments |> count(profile)
prof_list <- paste(prof_ns$profile, "(n =", prof_ns$n, ")", collapse = "; ")

# Describe each profile by direction of cortisol and mean immune reactivity
prof_char <- profile_means |>
  group_by(profile) |>
  summarise(
    cort_dir   = sign(mean_react[biomarker == "Cortisol"]),
    mean_immune = mean(mean_react[biomarker %in% c("CRP", "IL-6", "TNF-α", "IL-10")]),
    .groups = "drop"
  ) |>
  mutate(
    cort_label  = case_when(cort_dir > 0 ~ "cortisol-increasing", .default = "cortisol-blunted"),
    immune_label = case_when(
      mean_immune > 0.05  ~ "with elevated immune reactivity",
      mean_immune < -0.05 ~ "with suppressed immune reactivity",
      .default = "with minimal immune reactivity"
    ),
    desc = paste0(profile, ": ", cort_label, " ", immune_label)
  )
prof_desc <- paste(prof_char$desc, collapse = "; ")


## ----lpa-puberty, results='asis'----------------------------------------------
profile_puberty <- lpa_assignments |>
  left_join(sos_puberty, by = "SampleID") |>
  mutate(profile = relevel(profile, ref = "Profile 1"))

for (pv in puberty_vars) {
  cat("\n\n###", pv, "\n\n")
  fit <- multinom(
    as.formula(paste("profile ~", pv)),
    data  = profile_puberty,
    trace = FALSE
  )
  tbl <- broom::tidy(fit, exponentiate = TRUE) |>
    mutate(across(where(is.numeric), \(x) round(x, 3)))

  tbl |>
    mutate(p.value = cell_spec(p.value, bold = p.value < 0.05,
      color = if_else(p.value < 0.05, "#2166ac", "black"))) |>
    kable(
      escape    = FALSE,
      col.names = c("Profile (vs. Profile 1)", "Predictor", "OR", "SE", "Statistic", "p")
    ) |>
    kable_styling(bootstrap_options = "hover", full_width = FALSE) |>
    print()
}


## ----lpa-hr-subj-data, echo=FALSE---------------------------------------------
profile_hr_subj <- lpa_assignments |>
  left_join(
    all_difference |> select(SampleID, task_rs_hr_diff, conn_dis_hr_diff,
                              conn_other_hr_diff, conn_rest_hr_diff,
                              subj_scsd_difference, subj_scother_difference),
    by = "SampleID"
  ) |>
  pivot_longer(
    c(task_rs_hr_diff, conn_dis_hr_diff, conn_other_hr_diff, conn_rest_hr_diff,
      subj_scsd_difference, subj_scother_difference),
    names_to  = "measure",
    values_to = "value"
  ) |>
  mutate(measure = case_match(
    measure,
    "task_rs_hr_diff"       ~ "ΔHR: Task vs. Rest",
    "conn_dis_hr_diff"      ~ "ΔHR: SC vs. SD",
    "conn_other_hr_diff"    ~ "ΔHR: SC vs. Other",
    "conn_rest_hr_diff"     ~ "ΔHR: SC vs. Rest",
    "subj_scsd_difference"  ~ "ΔSubj Stress: SC vs. SD",
    "subj_scother_difference" ~ "ΔSubj Stress: SC vs. Other"
  ))


## ----lpa-hr-subj-plot, fig.width=11, fig.height=5-----------------------------
ggplot(profile_hr_subj, aes(x = profile, y = value, fill = profile)) +
  stat_halfeye(adjust = 0.5, width = 0.5, .width = 0, justification = -0.2,
               point_colour = NA, alpha = 0.8) +
  geom_boxplot(width = 0.12, outlier.shape = NA, color = "gray30", linewidth = 0.5) +
  geom_point(aes(color = profile), position = position_jitter(seed = 1, width = 0.08),
             size = 1, alpha = 0.3) +
  scale_fill_viridis_d() +
  scale_color_viridis_d(guide = "none") +
  facet_wrap(~ measure, scales = "free_y", nrow = 2) +
  labs(x = NULL, y = "Difference score", fill = "Profile") +
  theme_minimal() +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())


## ----lpa-hr-subj-anova, results='asis'----------------------------------------
hr_subj_vars <- c(
  "task_rs_hr_diff", "conn_dis_hr_diff", "conn_other_hr_diff", "conn_rest_hr_diff",
  "subj_scsd_difference", "subj_scother_difference"
)
hr_subj_labels <- c(
  "ΔHR: Task vs. Rest", "ΔHR: SC vs. SD", "ΔHR: SC vs. Other", "ΔHR: SC vs. Rest",
  "ΔSubj Stress: SC vs. SD", "ΔSubj Stress: SC vs. Other"
)

profile_wide <- lpa_assignments |>
  left_join(all_difference, by = "SampleID")

cat("\n\n### ANOVA / Kruskal-Wallis tests\n\n")
map2_dfr(hr_subj_vars, hr_subj_labels, function(v, lab) {
  dat <- profile_wide |> select(profile, all_of(v)) |> na.omit()
  kw  <- kruskal.test(as.formula(paste(v, "~ profile")), data = dat)
  tibble(
    Measure   = lab,
    statistic = round(kw$statistic, 3),
    df        = kw$parameter,
    p.value   = round(kw$p.value, 3)
  )
}) |>
  mutate(p.value = cell_spec(p.value, bold = p.value < 0.05,
    color = if_else(p.value < 0.05, "#2166ac", "black"))) |>
  kable(escape = FALSE, col.names = c("Measure", "H", "df", "p")) |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE) |>
  print()


## ----lpa-dep-bfnes-data, echo=FALSE-------------------------------------------
profile_dep_bfnes <- lpa_assignments |>
  left_join(dep,   by = "SampleID") |>
  left_join(bfnes, by = "SampleID") |>
  pivot_longer(
    c(CESD_total, BFNES_total),
    names_to  = "measure",
    values_to = "value"
  ) |>
  mutate(measure = case_match(
    measure,
    "CESD_total"  ~ "CES-DC (depression)",
    "BFNES_total" ~ "BFNES (fear of negative evaluation)"
  ))


## ----lpa-dep-bfnes-plot, fig.width=9, fig.height=5----------------------------
ggplot(profile_dep_bfnes, aes(x = profile, y = value, fill = profile)) +
  stat_halfeye(adjust = 0.5, width = 0.5, .width = 0, justification = -0.2,
               point_colour = NA, alpha = 0.8) +
  geom_boxplot(width = 0.12, outlier.shape = NA, color = "gray30", linewidth = 0.5) +
  geom_point(aes(color = profile),
             position = position_jitter(seed = 1, width = 0.08),
             size = 1.5, alpha = 0.4) +
  scale_fill_viridis_d() +
  scale_color_viridis_d(guide = "none") +
  facet_wrap(~ measure, scales = "free_y") +
  labs(x = NULL, y = "Score", fill = "Profile") +
  theme_minimal() +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())


## ----lpa-dep-bfnes-tests------------------------------------------------------
profile_dep_bfnes_wide <- lpa_assignments |>
  left_join(dep,   by = "SampleID") |>
  left_join(bfnes, by = "SampleID")

dep_bfnes_vars   <- c("CESD_total", "BFNES_total")
dep_bfnes_labels <- c("CES-DC (depression)", "BFNES (fear of negative evaluation)")

map2_dfr(dep_bfnes_vars, dep_bfnes_labels, function(v, lab) {
  dat <- profile_dep_bfnes_wide |> select(profile, all_of(v)) |> na.omit()
  kw  <- kruskal.test(as.formula(paste(v, "~ profile")), data = dat)

  grp_stats <- dat |>
    group_by(profile) |>
    summarise(M = round(mean(.data[[v]], na.rm = TRUE), 2),
              SD = round(sd(.data[[v]], na.rm = TRUE), 2),
              .groups = "drop") |>
    mutate(label = paste0(profile, ": M = ", M, ", SD = ", SD)) |>
    pull(label) |>
    paste(collapse = "; ")

  tibble(
    Measure   = lab,
    Groups    = grp_stats,
    H         = round(kw$statistic, 3),
    df        = kw$parameter,
    p.value   = round(kw$p.value, 3)
  )
}) |>
  mutate(p.value = cell_spec(p.value, bold = p.value < 0.05,
    color = if_else(p.value < 0.05, "#2166ac", "black"))) |>
  kable(escape = FALSE, col.names = c("Measure", "Group descriptives", "H", "df", "p"),
        caption = "Kruskal-Wallis tests: CES-DC and BFNES by LPA profile") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----lpa-dep-bfnes-results-vals, echo=FALSE, include=FALSE--------------------
dep_bfnes_kw <- map2_dfr(dep_bfnes_vars, dep_bfnes_labels, function(v, lab) {
  dat <- profile_dep_bfnes_wide |> select(profile, all_of(v)) |> na.omit()
  kw  <- kruskal.test(as.formula(paste(v, "~ profile")), data = dat)
  tibble(Measure = lab, H = round(kw$statistic, 3), df = kw$parameter,
         p = round(kw$p.value, 3), sig = kw$p.value < 0.05)
})

fmt_kw <- function(row) {
  paste0("*H*(", row$df, ") = ", row$H, ", *p* = ", row$p)
}


## ----dhea-cort-ratio, echo=FALSE----------------------------------------------
dhea_cort <- sos_hormones_wide |>
  mutate(
    dhea_cort_ratio_t1   = DHEA_log_1 / abs(Cortisol_log_1),
    dhea_cort_ratio_peak = dhea_peak  / abs(cort_peak),
    dhea_cort_ratio_diff = dhea_cort_ratio_peak - dhea_cort_ratio_t1
  ) |>
  select(SampleID, dhea_cort_ratio_t1, dhea_cort_ratio_peak, dhea_cort_ratio_diff)


## ----dhea-cort-puberty, fig.width=9, fig.height=4-----------------------------
dhea_cort_puberty <- dhea_cort |>
  left_join(sos_puberty, by = "SampleID")

ratio_plots <- map(puberty_vars, function(pv) {
  ggplot(dhea_cort_puberty, aes(x = .data[[pv]], y = dhea_cort_ratio_peak)) +
    geom_point(alpha = 0.5, size = 1.5) +
    geom_smooth(
      method = "loess",
      formula = y ~ x,
      color = "#29AF7FFF",
      se = TRUE
    ) +
    labs(x = pv, y = "DHEA:Cortisol ratio (peak)") +
    theme_minimal()
})

do.call(ggarrange, c(ratio_plots, list(ncol = length(puberty_vars))))


## ----dhea-cort-corrs----------------------------------------------------------
dhea_cort_puberty |>
  select(all_of(c(puberty_vars,
                  "dhea_cort_ratio_t1", "dhea_cort_ratio_peak", "dhea_cort_ratio_diff"))) |>
  na.omit() |>
  as.matrix() |>
  rcorr() |>
  (\(r) r$r[puberty_vars,
             c("dhea_cort_ratio_t1", "dhea_cort_ratio_peak", "dhea_cort_ratio_diff"),
             drop = FALSE])() |>
  as.data.frame() |>
  mutate(across(everything(), \(x) round(x, 3))) |>
  kable(col.names = c("DHEA:Cort T1", "DHEA:Cort Peak", "DHEA:Cort Δ"),
        caption   = "Correlations between puberty and DHEA:Cortisol ratio") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----dhea-cort-profiles, fig.width=7, fig.height=4----------------------------
lpa_assignments |>
  left_join(dhea_cort, by = "SampleID") |>
  pivot_longer(
    c(dhea_cort_ratio_t1, dhea_cort_ratio_peak, dhea_cort_ratio_diff),
    names_to  = "timepoint",
    values_to = "ratio"
  ) |>
  mutate(timepoint = case_match(
    timepoint,
    "dhea_cort_ratio_t1"   ~ "T1 (baseline)",
    "dhea_cort_ratio_peak" ~ "Peak",
    "dhea_cort_ratio_diff" ~ "Δ (peak − T1)"
  )) |>
  ggplot(aes(x = profile, y = ratio, fill = profile)) +
  stat_halfeye(adjust = 0.5, width = 0.5, .width = 0, justification = -0.2,
               point_colour = NA, alpha = 0.8) +
  geom_boxplot(width = 0.12, outlier.shape = NA, color = "gray30", linewidth = 0.5) +
  scale_fill_viridis_d() +
  facet_wrap(~ timepoint, scales = "free_y") +
  labs(x = NULL, y = "DHEA:Cortisol ratio", fill = "Profile") +
  theme_minimal() +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())


## ----covariate-load, echo=FALSE-----------------------------------------------
# Medications: one row per medication reported; collapse to one row per person
meds_wide <- read.csv(file.path(
  data_path,
  "TAG/data/Medications/all-meds/cleaned-data/all_meds_compiled.csv"
)) |>
  filter(wave == "sos") |>
  rename(SampleID = tagid) |>
  select(SampleID, starts_with("flag_")) |>
  group_by(SampleID) |>
  summarise(
    across(starts_with("flag_"), \(x) any(x, na.rm = TRUE)),
    .groups = "drop"
  )

str(meds_wide$SampleID)

illness <- read.csv(file.path(
  data_path,
  "SOS/SOS-study-monash/SOS_medsNillness.csv"
)) |>
  mutate(ill_yn = nzchar(sicklast24hrs)) %>%
  rename(SampleID = sid)

str(illness$SampleID)

# BMI: ID column → SampleID; recode SOS068/SOS076 → TAG068/TAG076
bmi <- read.csv(file.path(
  data_path,
  "SOS/SOS-study-monash/sos-bmi.csv"
)) |>
  rename(SampleID = 1) |>
  mutate(SampleID = case_when(
    SampleID == "SOS068" ~ "TAG068",
    SampleID == "SOS076" ~ "TAG076",
    .default = SampleID
  ))

str(bmi$SampleID) 

# Oral health: Qualtrics export — row 1 = question text, row 2 = import IDs
# saliva_1 = subject ID; saliva_7 = gum soreness (1-10); saliva_8 = bleeding gums
oral_health <- read.csv(
  file.path(
    data_path,
    "SOS/SOS-study-monash/questionnaires/sos-session-runner-qual-data.csv"
  ),
  header = TRUE
) |>
  select(saliva_1, saliva_5, saliva_6, saliva_7, saliva_8) |>
  setNames(c(
    "SampleID",
    "last_ate",
    "last_brushed",
    "gum_soreness",
    "bleeding_gums"
  )) |>
  filter(grepl("^(TAG|SOS)\\d{3}", SampleID)) |>
  mutate(
    SampleID      = sub("^SOS", "TAG", SampleID),
    gum_soreness  = suppressWarnings(as.numeric(gum_soreness)),
    bleeding_gums = as.integer(bleeding_gums == "1")
  )

# dep and bfnes loaded in load-data chunk above

# Smoking: saliva_11 == "3" → smoker; SOS-prefix → TAG-prefix
smoking <- sos_session_runner |>
  select(saliva_1, saliva_11) |>
  setNames(c("SampleID", "smokes")) |>
  filter(grepl("^(TAG|SOS)\\d{3}", SampleID)) |>
  mutate(
    SampleID = sub("^SOS", "TAG", SampleID),
    smokes   = (smokes == "3")
  )

# Sample timing: parse HH:MM → minutes since midnight; compute elapsed from T1
parse_hhmm <- function(x) {
  x     <- trimws(x)
  parts <- strsplit(x, ":")
  hrs   <- suppressWarnings(as.numeric(sapply(parts, `[`, 1)))
  mins  <- suppressWarnings(as.numeric(sapply(parts, function(p) if (length(p) >= 2) p[2] else "0")))
  mins[is.na(mins)] <- 0
  ifelse(nzchar(x) & !is.na(hrs), hrs * 60 + mins, NA_real_)
}

saliva_timing <- sos_saliva_times |>
  rename(SampleID = TAG.ID) |>
  mutate(
    SampleID = case_when(
      SampleID == "SOS068" ~ "TAG068",
      SampleID == "SOS076" ~ "TAG076",
      .default = SampleID
    ),
    t1_min = parse_hhmm(X1i_start),
    t2_min = parse_hhmm(X2i_start),
    t3_min = parse_hhmm(X3i_start),
    t4_min = parse_hhmm(X4i_start),
    elapsed_T2 = t2_min - t1_min,
    elapsed_T3 = t3_min - t1_min,
    elapsed_T4 = t4_min - t1_min
  ) |>
  select(SampleID, t1_min, elapsed_T2, elapsed_T3, elapsed_T4)

# Wake time × hormones: parse free-text wake time; join to T1 start time
parse_wake <- function(x) {
  x <- trimws(tolower(x))
  x <- gsub("\\s+", " ", x)
  pm <- grepl("pm", x)
  x  <- gsub("[^0-9:]", "", x)
  parts <- strsplit(x, ":")
  hrs   <- suppressWarnings(as.numeric(sapply(parts, `[`, 1)))
  mins  <- suppressWarnings(as.numeric(sapply(parts, function(p) if (length(p) >= 2) p[2] else "0")))
  mins[is.na(mins)] <- 0
  hrs[pm & hrs < 12] <- hrs[pm & hrs < 12] + 12
  ifelse(is.na(hrs), NA_real_, hrs * 60 + mins)
}

wake_time <- sos_session_runner |>
  select(saliva_1, saliva_2) |>
  setNames(c("SampleID", "wake_raw")) |>
  filter(grepl("^(TAG|SOS)\\d{3}", SampleID)) |>
  mutate(
    SampleID = sub("^SOS", "TAG", SampleID),
    wake_min = parse_wake(wake_raw),
    wake_min = ifelse(wake_min > 840, NA_real_, wake_min)  # exclude implausible (>2pm)
  ) |>
  select(SampleID, wake_min) |>
  left_join(saliva_timing |> select(SampleID, t1_min), by = "SampleID") |>
  mutate(
    hours_since_wake = (t1_min - wake_min) / 60
  )


## ----cov-illness-n------------------------------------------------------------
illness |>
  count(ill_yn) |>
  mutate(ill_yn = if_else(ill_yn, "Yes", "No")) |>
  kable(col.names = c("Ill in last 24 hrs", "n"),
        caption   = "Illness at time of session") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)

ill_ids <- illness |> filter(ill_yn) |> pull(SampleID)
cat("N excluded for illness:", length(ill_ids), "\n")
cat("SampleIDs:", paste(ill_ids, collapse = ", "), "\n")


## ----cov-meds-desc------------------------------------------------------------
meds_wide |>
  select(-SampleID) |>
  summarise(across(everything(), \(x) sum(x, na.rm = TRUE))) |>
  pivot_longer(everything(), names_to = "medication", values_to = "n_using") |>
  filter(n_using > 0) |>
  mutate(medication = str_remove(medication, "^flag_")) |>
  arrange(desc(n_using)) |>
  kable(col.names = c("Medication category", "n using"),
        caption = "Medication use at SOS visit") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----cov-bmi-desc-------------------------------------------------------------
bmi |>
  summarise(
    n    = sum(!is.na(BMI)),
    Mean = round(mean(BMI, na.rm = TRUE), 2),
    SD   = round(sd(BMI,   na.rm = TRUE), 2),
    Min  = round(min(BMI,  na.rm = TRUE), 2),
    Max  = round(max(BMI,  na.rm = TRUE), 2)
  ) |>
  kable(caption = "BMI descriptives") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----cov-oral-health-desc-----------------------------------------------------
oral_health |>
  summarise(
    `N participants`          = as.character(n()),
    `Gum soreness: mean (SD)` = paste0(
      round(mean(gum_soreness, na.rm = TRUE), 1), " (",
      round(sd(gum_soreness,   na.rm = TRUE), 1), ")"
    ),
    `Bleeding gums: n (%)`    = paste0(
      sum(bleeding_gums, na.rm = TRUE), " (",
      round(mean(bleeding_gums, na.rm = TRUE) * 100, 1), "%)"
    )
  ) |>
  pivot_longer(everything(), names_to = "Item", values_to = "Value") |>
  kable(caption = "Oral health descriptives") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----cov-smoking-desc---------------------------------------------------------
smoking |>
  count(smokes) |>
  mutate(smokes = if_else(smokes, "Yes", "No")) |>
  kable(col.names = c("Smokes", "n"),
        caption   = "Smoking status at time of session") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----sens-illness-exclusion, echo=FALSE---------------------------------------
crp_wide_well      <- sos_crp_wide      |> filter(!SampleID %in% ill_ids)
cytokines_wide_well <- sos_cytokines_wide |> filter(!SampleID %in% ill_ids)
hormones_wide_well  <- sos_hormones_wide  |> filter(!SampleID %in% ill_ids)
hr_all_wide_well    <- hr_all_wide        |>
  mutate(SampleID = str_sub(id, 1, 6)) |>
  filter(!SampleID %in% ill_ids)
hr_conditions_well  <- hr_conditions_avg  |>
  mutate(SampleID = case_when(
    str_sub(id, 1, 6) == "SOS068" ~ "TAG068",
    str_sub(id, 1, 6) == "SOS076" ~ "TAG076",
    .default = str_sub(id, 1, 6)
  )) |>
  filter(!SampleID %in% ill_ids)
pull_hr_well <- function(cond) filter(hr_conditions_well, task_condition == cond)$mean_hr


## ----sens-illness-biomarker-ttests--------------------------------------------
sens_peak_tests <- list(
  crp  = run_peak_test("crp_peak",  "CRP_log_1",          crp_wide_well),
  il10 = run_peak_test("il10_peak", "IL10_log_1",         cytokines_wide_well),
  il6  = run_peak_test("il6_peak",  "IL6_log_1",          cytokines_wide_well),
  tnfa = run_peak_test("tnfa_peak", "TNFalpha_log_1",     cytokines_wide_well),
  dhea = run_peak_test("dhea_peak", "DHEA_log_1",         hormones_wide_well),
  test = run_peak_test("test_peak", "Testosterone_log_1", hormones_wide_well),
  cort = run_peak_test("cort_peak", "Cortisol_log_1",     hormones_wide_well)
)

sens_pfdr <- setNames(
  c(p.adjust(map_dbl(sens_peak_tests[1:4], \(t) t$p.value), method = "fdr"),
    p.adjust(map_dbl(sens_peak_tests[5:7], \(t) t$p.value), method = "fdr")),
  names(sens_peak_tests)
)

sens_peak_tests |>
  map(broom::tidy) |>
  list_rbind(names_to = "analyte") |>
  mutate(
    analyte = case_match(analyte,
      "crp" ~ "CRP", "il10" ~ "IL-10", "il6" ~ "IL-6", "tnfa" ~ "TNF-α",
      "dhea" ~ "DHEA", "test" ~ "Testosterone", "cort" ~ "Cortisol"
    ),
    p_fdr = round(unname(sens_pfdr), 4)
  ) |>
  select(analyte, estimate, statistic, parameter, p.value, p_fdr) |>
  mutate(across(where(is.numeric), \(x) round(x, 3))) |>
  mutate(p_fdr = cell_spec(p_fdr, bold = p_fdr < 0.05,
    color = if_else(p_fdr < 0.05, "#2166ac", "black"))) |>
  kable(col.names = c("Analyte", "Mean diff", "t", "df", "p (raw)", "p (FDR)"),
        escape = FALSE,
        caption = "Peak vs. T1 t-tests excluding ill participants") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----sens-illness-hr-ttests---------------------------------------------------
list(
  "Task vs. Resting"                     = t.test(hr_all_wide_well$Task, hr_all_wide_well$resting_avg, alternative = "greater", paired = TRUE),
  "Self-Connected vs. Rest"              = t.test(pull_hr_well("Self-Connected"), pull_hr_well("Rest"),             alternative = "greater", paired = TRUE),
  "Self-Connected vs. Self-Disconnected" = t.test(pull_hr_well("Self-Connected"), pull_hr_well("Self-Disconnected"), alternative = "greater", paired = TRUE),
  "Self-Connected vs. Other"             = t.test(pull_hr_well("Self-Connected"), pull_hr_well("Other"),            alternative = "greater", paired = TRUE)
) |>
  map(broom::tidy) |>
  list_rbind(names_to = "comparison") |>
  select(comparison, estimate, statistic, parameter, p.value) |>
  mutate(across(where(is.numeric), \(x) round(x, 3))) |>
  mutate(p.value = cell_spec(p.value, bold = p.value < 0.05,
    color = if_else(p.value < 0.05, "#2166ac", "black"))) |>
  kable(col.names = c("Comparison", "Mean diff", "t", "df", "p"),
        escape = FALSE,
        caption = "HR paired t-tests excluding ill participants") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----sens-cov-processing, echo=FALSE------------------------------------------
# Immune: BMI, bleeding gums, allergy meds, systemic steroids, NSAIDs, excluding ill
cov_immune <- biomarkers_difference |>
  left_join(bmi         |> select(SampleID, BMI),                                          by = "SampleID") |>
  left_join(oral_health |> select(SampleID, bleeding_gums, gum_soreness),                  by = "SampleID") |>
  left_join(meds_wide   |> select(SampleID, flag_allergy, flag_systemic_steroid, flag_nsaid), by = "SampleID") |>
  left_join(illness     |> select(SampleID, ill_yn),                                       by = "SampleID") |>
  filter(!ill_yn | is.na(ill_yn))

# Hormones: BMI, birth control, other hormones, SSRIs, excluding ill
cov_hormones <- hormones_difference |>
  left_join(bmi       |> select(SampleID, BMI),                         by = "SampleID") |>
  left_join(meds_wide |> select(SampleID, flag_bc, flag_hormone, flag_ssri), by = "SampleID") |>
  left_join(illness   |> select(SampleID, ill_yn),                      by = "SampleID") |>
  filter(!ill_yn | is.na(ill_yn))


## ----sens-cov-immune-models, results='asis'-----------------------------------
fmt_p <- function(p) {
  if (is.na(p)) return("—")
  cell_spec(round(p, 3), bold = p < 0.05,
            color = if (p < 0.05) "#2166ac" else "black")
}

immune_outcomes    <- c("crp_difference", "il10_difference", "il6_difference", "tnfa_difference")
immune_labels      <- c("ΔCRP", "ΔIL-10", "ΔIL-6", "ΔTNF-α")
immune_cov_formula <- "~ BMI + bleeding_gums + flag_allergy + flag_systemic_steroid + flag_nsaid"

cat("### Immune markers\n\n")
map2(immune_outcomes, immune_labels, function(outcome, label) {
  f   <- as.formula(paste(outcome, immune_cov_formula))
  fit <- lm(f, data = cov_immune, na.action = na.omit)
  cat("\n####", label, "\n\n")
  broom::tidy(fit) |>
    mutate(across(where(is.numeric), \(x) round(x, 3))) |>
    mutate(p.value = map_chr(p.value, fmt_p)) |>
    kable(escape = FALSE,
          caption = paste(label, "— intercept = mean reactivity adjusted for covariates")) |>
    kable_styling(bootstrap_options = "hover", full_width = FALSE) |>
    print()
}) |> invisible()


## ----sens-cov-hormone-models, results='asis'----------------------------------
hormone_outcomes    <- c("dhea_difference", "test_difference", "cort_difference")
hormone_labels      <- c("ΔDHEA", "ΔTestosterone", "ΔCortisol")
hormone_cov_formula <- "~ BMI + flag_bc + flag_hormone + flag_ssri"

cat("### Hormones\n\n")
map2(hormone_outcomes, hormone_labels, function(outcome, label) {
  f   <- as.formula(paste(outcome, hormone_cov_formula))
  fit <- lm(f, data = cov_hormones, na.action = na.omit)
  cat("\n####", label, "\n\n")
  broom::tidy(fit) |>
    mutate(across(where(is.numeric), \(x) round(x, 3))) |>
    mutate(p.value = map_chr(p.value, fmt_p)) |>
    kable(escape = FALSE,
          caption = paste(label, "— intercept = mean reactivity adjusted for covariates")) |>
    kable_styling(bootstrap_options = "hover", full_width = FALSE) |>
    print()
}) |> invisible()


## ----sens-bleed-smoke-exclusion, echo=FALSE-----------------------------------
excl_clean_ids <- illness    |> filter(ill_yn) |> pull(SampleID) |>
  union(oral_health |> filter(bleeding_gums == 1) |> pull(SampleID)) |>
  union(smoking     |> filter(smokes)             |> pull(SampleID))

cat("N excluded (ill + bleeding + smoking):", length(excl_clean_ids), "\n")
cat("IDs:", paste(sort(excl_clean_ids), collapse = ", "), "\n")

crp_wide_clean       <- sos_crp_wide       |> filter(!SampleID %in% excl_clean_ids)
cytokines_wide_clean <- sos_cytokines_wide |> filter(!SampleID %in% excl_clean_ids)
hormones_wide_clean  <- sos_hormones_wide  |> filter(!SampleID %in% excl_clean_ids)


## ----sens-bleed-smoke-ttests--------------------------------------------------
clean_peak_tests <- list(
  crp  = run_peak_test("crp_peak",  "CRP_log_1",          crp_wide_clean),
  il10 = run_peak_test("il10_peak", "IL10_log_1",         cytokines_wide_clean),
  il6  = run_peak_test("il6_peak",  "IL6_log_1",          cytokines_wide_clean),
  tnfa = run_peak_test("tnfa_peak", "TNFalpha_log_1",     cytokines_wide_clean),
  dhea = run_peak_test("dhea_peak", "DHEA_log_1",         hormones_wide_clean),
  test = run_peak_test("test_peak", "Testosterone_log_1", hormones_wide_clean),
  cort = run_peak_test("cort_peak", "Cortisol_log_1",     hormones_wide_clean)
)

clean_pfdr <- setNames(
  c(p.adjust(map_dbl(clean_peak_tests[1:4], \(t) t$p.value), method = "fdr"),
    p.adjust(map_dbl(clean_peak_tests[5:7], \(t) t$p.value), method = "fdr")),
  names(clean_peak_tests)
)

clean_peak_tests |>
  map(broom::tidy) |>
  list_rbind(names_to = "analyte") |>
  mutate(
    analyte = case_match(analyte,
      "crp"  ~ "CRP",    "il10" ~ "IL-10", "il6"  ~ "IL-6", "tnfa" ~ "TNF-α",
      "dhea" ~ "DHEA",   "test" ~ "Testosterone",            "cort" ~ "Cortisol"
    ),
    p_fdr = round(unname(clean_pfdr), 4)
  ) |>
  select(analyte, estimate, statistic, parameter, p.value, p_fdr) |>
  mutate(across(where(is.numeric), \(x) round(x, 3))) |>
  mutate(p_fdr = cell_spec(p_fdr, bold = p_fdr < 0.05,
    color = if_else(p_fdr < 0.05, "#2166ac", "black"))) |>
  kable(col.names = c("Analyte", "Mean diff", "t", "df", "p (raw)", "p (FDR)"),
        escape = FALSE,
        caption = "Peak vs. T1 t-tests: excluding ill, bleeding gums, and smokers") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----sens-crosscheck, echo=FALSE----------------------------------------------
# ── analyte reference table ───────────────────────────────────────────────────
analyte_ref <- tibble(
  key     = c("crp",  "il10",  "il6",  "tnfa",  "dhea",  "test",          "cort"),
  analyte = c("CRP",  "IL-10", "IL-6", "TNF-α", "DHEA",  "Testosterone",  "Cortisol"),
  group   = c(rep("Immune", 4), rep("Hormones", 3)),
  outcome_immune  = c("crp_difference", "il10_difference", "il6_difference",
                       "tnfa_difference", NA, NA, NA),
  outcome_hormone = c(NA, NA, NA, NA, "dhea_difference", "test_difference",
                       "cort_difference")
)

# ── primary FDR p-values ──────────────────────────────────────────────────────
primary_p <- tibble(
  key = names(peak_pfdr),
  p_primary = unname(peak_pfdr)
)

# ── illness-exclusion FDR p-values ───────────────────────────────────────────
ill_p <- tibble(
  key   = names(sens_pfdr),
  p_ill = unname(sens_pfdr)
)

# ── bleed + smoke exclusion FDR p-values ─────────────────────────────────────
clean_p <- tibble(
  key     = names(clean_pfdr),
  p_clean = unname(clean_pfdr)
)

# ── covariate-adjusted intercept p-values ────────────────────────────────────
cov_immune_ps <- map2_dfr(
  c("crp_difference", "il10_difference", "il6_difference", "tnfa_difference"),
  c("crp", "il10", "il6", "tnfa"),
  function(outcome, key) {
    f   <- as.formula(paste(outcome, immune_cov_formula))
    fit <- lm(f, data = cov_immune, na.action = na.omit)
    broom::tidy(fit) |>
      filter(term == "(Intercept)") |>
      transmute(key = key, p_cov = p.value)
  }
)

cov_hormone_ps <- map2_dfr(
  c("dhea_difference", "test_difference", "cort_difference"),
  c("dhea", "test", "cort"),
  function(outcome, key) {
    f   <- as.formula(paste(outcome, hormone_cov_formula))
    fit <- lm(f, data = cov_hormones, na.action = na.omit)
    broom::tidy(fit) |>
      filter(term == "(Intercept)") |>
      transmute(key = key, p_cov = p.value)
  }
)

cov_p <- bind_rows(cov_immune_ps, cov_hormone_ps)

# ── join everything ───────────────────────────────────────────────────────────
fmt_p_check <- function(p, threshold = 0.05) {
  if (is.na(p)) return("—")
  lbl <- if (p < threshold) paste0(round(p, 3), "*") else as.character(round(p, 3))
  cell_spec(lbl, bold = p < threshold,
            color = if (p < threshold) "#2166ac" else "black")
}

bio_cross <- analyte_ref |>
  left_join(primary_p, by = "key") |>
  left_join(ill_p,     by = "key") |>
  left_join(clean_p,   by = "key") |>
  left_join(cov_p,     by = "key") |>
  mutate(
    sig_primary = !is.na(p_primary) & p_primary < .05,
    sig_ill     = !is.na(p_ill)     & p_ill     < .05,
    sig_clean   = !is.na(p_clean)   & p_clean   < .05,
    sig_cov     = !is.na(p_cov)     & p_cov     < .05,
    n_sig   = as.integer(sig_primary) + as.integer(sig_ill) +
              as.integer(sig_clean)   + as.integer(sig_cov),
    n_tests = 4L,
    consistent = case_when(
      n_sig == n_tests ~ "All sig",
      n_sig == 0L      ~ "All ns",
      TRUE             ~ paste0("Mixed (", n_sig, "/", n_tests, ")")
    )
  ) |>
  select(Group = group, Analyte = analyte,
         p_primary, p_ill, p_clean, p_cov, Consistency = consistent) |>
  mutate(across(c(p_primary, p_ill, p_clean, p_cov),
                \(x) map_chr(x, fmt_p_check))) |>
  rename(`Primary (FDR)` = p_primary, `Ill excl (FDR)` = p_ill,
         `Bleed+smoke excl (FDR)` = p_clean, `Cov-adj intercept` = p_cov) |>
  mutate(Consistency = cell_spec(
    Consistency,
    bold  = Consistency == "All sig",
    color = case_when(
      Consistency == "All sig" ~ "#2166ac",
      Consistency == "All ns"  ~ "gray40",
      TRUE                     ~ "#d95f02"
    )
  ))

bio_cross |>
  kable(escape = FALSE,
        caption = "Biomarker reactivity: significance across all sensitivity analyses (* = p < .05)") |>
  kable_styling(bootstrap_options = c("hover", "striped"), full_width = FALSE)


## ----sens-crosscheck-hr, echo=FALSE-------------------------------------------
# ── HR cross-check: primary vs. illness-excluded ─────────────────────────────
hr_ill_tbl <- list(
  "Task vs. Resting"                     = t.test(hr_all_wide_well$Task, hr_all_wide_well$resting_avg,
                                                   alternative = "greater", paired = TRUE),
  "Self-Connected vs. Rest"              = t.test(pull_hr_well("Self-Connected"), pull_hr_well("Rest"),
                                                   alternative = "greater", paired = TRUE),
  "Self-Connected vs. Self-Disconnected" = t.test(pull_hr_well("Self-Connected"),
                                                   pull_hr_well("Self-Disconnected"),
                                                   alternative = "greater", paired = TRUE),
  "Self-Connected vs. Other"             = t.test(pull_hr_well("Self-Connected"), pull_hr_well("Other"),
                                                   alternative = "greater", paired = TRUE)
) |>
  map(broom::tidy) |>
  list_rbind(names_to = "Comparison") |>
  select(Comparison, p_ill = p.value)

hr_cross <- hr_ttest_tbl |>
  select(Comparison = comparison, p_primary = p.value) |>
  left_join(hr_ill_tbl, by = "Comparison") |>
  mutate(
    consistent = case_when(
      (p_primary < .05) & (p_ill < .05)   ~ "Both sig",
      (p_primary >= .05) & (p_ill >= .05) ~ "Both ns",
      TRUE                                 ~ "Mixed"
    )
  ) |>
  mutate(
    across(c(p_primary, p_ill), \(x) map_chr(x, fmt_p_check)),
    Consistency = cell_spec(
      consistent,
      bold  = consistent == "Both sig",
      color = case_when(
        consistent == "Both sig" ~ "#2166ac",
        consistent == "Both ns"  ~ "gray40",
        TRUE                     ~ "#d95f02"
      )
    )
  ) |>
  select(Comparison, `Primary` = p_primary, `Ill excl` = p_ill, Consistency)

hr_cross |>
  kable(escape = FALSE,
        caption = "HR reactivity: significance across sensitivity analyses (✓ = p < .05)") |>
  kable_styling(bootstrap_options = c("hover", "striped"), full_width = FALSE)


## ----sens-crosscheck-text, echo=FALSE, include=FALSE--------------------------
bio_cross_raw <- analyte_ref |>
  left_join(primary_p, by = "key") |>
  left_join(ill_p,     by = "key") |>
  left_join(clean_p,   by = "key") |>
  left_join(cov_p,     by = "key") |>
  mutate(
    n_sig = (p_primary < .05) + (p_ill < .05) + (p_clean < .05) +
              (!is.na(p_cov) & p_cov < .05)
  )
n_all_sig <- sum(bio_cross_raw$n_sig == 4)
n_all_ns  <- sum(bio_cross_raw$n_sig == 0)
n_mixed   <- nrow(bio_cross_raw) - n_all_sig - n_all_ns
all_sig_analytes <- bio_cross_raw |> filter(n_sig == 4) |> pull(analyte) |> paste(collapse = ", ")
mixed_analytes   <- bio_cross_raw |> filter(n_sig > 0 & n_sig < 4) |> pull(analyte) |> paste(collapse = ", ")


## ----timing-intervals---------------------------------------------------------
saliva_timing |>
  select(elapsed_T2, elapsed_T3, elapsed_T4) |>
  summarise(across(
    everything(),
    list(
      n    = \(x) sum(!is.na(x)),
      Mean = \(x) round(mean(x, na.rm = TRUE), 1),
      SD   = \(x) round(sd(x, na.rm = TRUE), 1),
      Min  = \(x) round(min(x, na.rm = TRUE), 1),
      Max  = \(x) round(max(x, na.rm = TRUE), 1)
    ),
    .names = "{.col}_{.fn}"
  )) |>
  pivot_longer(everything(),
               names_to  = c("Sample", ".value"),
               names_sep = "_(?=[^_]+$)") |>
  mutate(Sample = case_match(Sample,
    "elapsed_T2" ~ "T1 → T2",
    "elapsed_T3" ~ "T1 → T3",
    "elapsed_T4" ~ "T1 → T4"
  )) |>
  kable(caption = "Minutes elapsed from T1 to each subsequent sample") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----timing-hormone-corr, results='asis'--------------------------------------
hormone_timing <- sos_hormones_panel |>
  left_join(saliva_timing, by = "SampleID") |>
  mutate(elapsed = case_when(
    Time == 2 ~ elapsed_T2,
    Time == 3 ~ elapsed_T3,
    Time == 4 ~ elapsed_T4,
    .default  = NA_real_
  ))

hormone_vars <- c("DHEA_log", "Testosterone_log", "Cortisol_log")

cat("### Correlation: elapsed time × hormone level at T2–T4\n\n")
map_dfr(hormone_vars, function(hv) {
  map_dfr(2:4, function(tp) {
    dat <- hormone_timing |> filter(Time == tp) |>
      select(all_of(hv), elapsed) |> na.omit()
    if (nrow(dat) < 5) return(NULL)
    ct <- cor.test(dat[[hv]], dat$elapsed)
    tibble(Hormone = hv, Timepoint = paste0("T", tp),
           r = round(ct$estimate, 3), p = round(ct$p.value, 3))
  })
}) |>
  pivot_wider(names_from = Timepoint, values_from = c(r, p),
              names_glue = "{Timepoint}_{.value}") |>
  select(Hormone, T2_r, T2_p, T3_r, T3_p, T4_r, T4_p) |>
  mutate(across(ends_with("_p"), \(x) cell_spec(
    round(x, 3), bold = x < 0.05,
    color = if_else(x < 0.05, "#2166ac", "black")
  ))) |>
  kable(escape = FALSE,
        col.names = c("Hormone", "r", "p", "r", "p", "r", "p"),
        caption = "Elapsed minutes from T1 × hormone level") |>
  add_header_above(c(" " = 1, "T2" = 2, "T3" = 2, "T4" = 2)) |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE) |>
  print()


## ----wake-desc----------------------------------------------------------------
wake_time |>
  filter(!is.na(hours_since_wake)) |>
  summarise(
    n    = n(),
    Mean = round(mean(hours_since_wake), 1),
    SD   = round(sd(hours_since_wake), 1),
    Min  = round(min(hours_since_wake), 1),
    Max  = round(max(hours_since_wake), 1)
  ) |>
  kable(caption = "Hours elapsed from waking to T1 sample collection") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----wake-hormone-corr--------------------------------------------------------
wake_hormones <- sos_hormones_panel |>
  filter(Time == 1) |>
  left_join(wake_time |> select(SampleID, hours_since_wake), by = "SampleID") |>
  left_join(
    hormones_difference |> select(SampleID, dhea_difference, test_difference, cort_difference),
    by = "SampleID"
  )

hormone_wake_outcomes <- c(
  "DHEA_log"        = "DHEA (T1 level)",
  "Testosterone_log" = "Testosterone (T1 level)",
  "Cortisol_log"    = "Cortisol (T1 level)",
  "dhea_difference" = "ΔDHEA (reactivity)",
  "test_difference" = "ΔTestosterone (reactivity)",
  "cort_difference" = "ΔCortisol (reactivity)"
)

map_dfr(names(hormone_wake_outcomes), function(hv) {
  dat <- wake_hormones |> select(all_of(hv), hours_since_wake) |> na.omit()
  if (nrow(dat) < 5) return(NULL)
  ct <- cor.test(dat[[hv]], dat$hours_since_wake)
  tibble(
    Outcome = hormone_wake_outcomes[[hv]],
    n       = nrow(dat),
    r       = round(ct$estimate, 3),
    p       = round(ct$p.value, 3)
  )
}) |>
  mutate(p = cell_spec(p, bold = p < 0.05,
    color = if_else(p < 0.05, "#2166ac", "black"))) |>
  kable(escape = FALSE,
        col.names = c("Outcome", "n", "r", "p"),
        caption = "Correlations: hours since waking × sex steroid hormone levels and reactivity") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----puberty-raw-levels, echo=FALSE-------------------------------------------
biomarker_levels <- sos_crp_panel |>
  full_join(sos_cytokines_panel, by = c("SampleID", "Time")) |>
  full_join(sos_hormones_panel,  by = c("SampleID", "Time")) |>
  left_join(sos_puberty,         by = "SampleID")


## ----puberty-levels-corr, results='asis'--------------------------------------
for (pv in puberty_vars) {
  cat("\n\n##", pv, "\n\n")
  bio_vars <- c("CRP_log", "IL10_log", "IL6_log", "TNFalpha_log",
                "DHEA_log", "Testosterone_log", "Cortisol_log")

  corr_tbl <- map_dfr(bio_vars, function(bv) {
    map_dfr(1:4, function(tp) {
      dat <- biomarker_levels |>
        filter(Time == tp) |>
        select(all_of(c(bv, pv))) |>
        na.omit()
      if (nrow(dat) < 5) return(NULL)
      ct <- cor.test(dat[[bv]], dat[[pv]])
      tibble(
        Biomarker = bv,
        Timepoint = paste0("T", tp),
        r         = round(ct$estimate, 3),
        p         = round(ct$p.value,  3)
      )
    })
  }) |>
    pivot_wider(names_from = Timepoint, values_from = c(r, p),
                names_glue = "{Timepoint}_{.value}") |>
    select(Biomarker, T1_r, T1_p, T2_r, T2_p, T3_r, T3_p, T4_r, T4_p)

  corr_tbl |>
    mutate(across(ends_with("_p"), \(x) cell_spec(
      round(x, 3), bold = x < 0.05,
      color = if_else(x < 0.05, "#2166ac", "black")
    ))) |>
    kable(escape = FALSE,
          col.names = c("Biomarker", "r", "p", "r", "p", "r", "p", "r", "p"),
          caption   = paste("Correlations:", pv, "× biomarker at each timepoint")) |>
    add_header_above(c(" " = 1, "T1" = 2, "T2" = 2, "T3" = 2, "T4" = 2)) |>
    kable_styling(bootstrap_options = "hover", full_width = FALSE) |>
    print()
}


## ----dep-desc-----------------------------------------------------------------
dep |>
  summarise(
    n    = sum(!is.na(CESD_total)),
    Mean = round(mean(CESD_total, na.rm = TRUE), 2),
    SD   = round(sd(CESD_total,   na.rm = TRUE), 2),
    Min  = round(min(CESD_total,  na.rm = TRUE), 2),
    Max  = round(max(CESD_total,  na.rm = TRUE), 2)
  ) |>
  kable(caption = "CES-DC descriptives") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----dep-levels-corr----------------------------------------------------------
dep_levels <- biomarker_levels |>
  left_join(dep, by = "SampleID")

bio_vars <- c("CRP_log", "IL10_log", "IL6_log", "TNFalpha_log",
              "DHEA_log", "Testosterone_log", "Cortisol_log")

dep_corr_long <- map_dfr(bio_vars, function(bv) {
  map_dfr(1:4, function(tp) {
    dat <- dep_levels |> filter(Time == tp) |>
      select(all_of(c(bv, "CESD_total"))) |> na.omit()
    if (nrow(dat) < 5) return(NULL)
    ct <- cor.test(dat[[bv]], dat$CESD_total)
    tibble(Biomarker = bv, Timepoint = paste0("T", tp),
           r = round(ct$estimate, 3), p_raw = ct$p.value)
  })
}) |>
  mutate(group = if_else(
    Biomarker %in% c("CRP_log", "IL10_log", "IL6_log", "TNFalpha_log"),
    "Immune", "Hormones"
  )) |>
  group_by(group) |>
  mutate(p_fdr = round(p.adjust(p_raw, method = "fdr"), 4)) |>
  ungroup()

dep_corr_tbl <- dep_corr_long |>
  pivot_wider(id_cols = Biomarker, names_from = Timepoint,
              values_from = c(r, p_fdr),
              names_glue = "{Timepoint}_{.value}") |>
  select(Biomarker, T1_r, T1_p_fdr, T2_r, T2_p_fdr, T3_r, T3_p_fdr, T4_r, T4_p_fdr)

dep_corr_tbl |>
  mutate(across(ends_with("_p_fdr"), \(x) cell_spec(
    round(x, 4), bold = !is.na(x) & x < 0.05,
    color = if_else(!is.na(x) & x < 0.05, "#2166ac", "black")
  ))) |>
  kable(escape = FALSE,
        col.names = c("Biomarker", "r", "p (FDR)", "r", "p (FDR)", "r", "p (FDR)", "r", "p (FDR)"),
        caption   = "Correlations: CES-DC × biomarker levels (FDR-adjusted p-values; bold = p_FDR < .05)") |>
  add_header_above(c(" " = 1, "T1" = 2, "T2" = 2, "T3" = 2, "T4" = 2)) |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----dep-levels-results-vals, echo=FALSE, include=FALSE-----------------------
sig_dep_levels <- dep_corr_long |> filter(p_fdr < 0.05)
n_sig_dep_levels <- nrow(sig_dep_levels)
dep_levels_sig_text <- if (n_sig_dep_levels == 0) {
  "No significant associations were observed after FDR correction"
} else {
  paste(
    paste0(sig_dep_levels$Biomarker, " at ", sig_dep_levels$Timepoint,
           " (r = ", sig_dep_levels$r, ", p~FDR~ = ", sig_dep_levels$p_fdr, ")"),
    collapse = "; "
  )
}


## ----dep-reactivity-corr------------------------------------------------------
dep_reactivity <- all_difference |>
  left_join(dep, by = "SampleID") |>
  select(-SampleID) |>
  na.omit()

dep_react_corrs <- map_dfr(setNames(reactivity_vars, reactivity_labels), function(rv) {
  ct <- cor.test(dep_reactivity[[rv]], dep_reactivity$CESD_total)
  tibble(r = round(ct$estimate, 3), p_raw = ct$p.value)
}, .id = "Reactivity") |>
  mutate(domain = case_when(
    str_detect(Reactivity, "^ΔHR")                                        ~ "HR",
    Reactivity %in% c("ΔCRP", "ΔIL-10", "ΔIL-6", "ΔTNF-α")             ~ "Immune",
    Reactivity %in% c("ΔDHEA", "ΔTestosterone", "ΔCortisol")             ~ "Hormones",
    TRUE                                                                   ~ "Subjective"
  )) |>
  group_by(domain) |>
  mutate(p_fdr = round(p.adjust(p_raw, method = "fdr"), 4)) |>
  ungroup()

dep_react_corrs |>
  select(Reactivity, r, p_fdr) |>
  mutate(p_fdr = cell_spec(p_fdr, bold = !is.na(p_fdr) & p_fdr < 0.05,
    color = if_else(!is.na(p_fdr) & p_fdr < 0.05, "#2166ac", "black"))) |>
  kable(escape = FALSE, col.names = c("Reactivity outcome", "r", "p (FDR)"),
        caption = "Correlations: CES-DC × reactivity (FDR-adjusted; bold = p_FDR < .05)") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----dep-reactivity-results-vals, echo=FALSE, include=FALSE-------------------
sig_dep_react <- dep_react_corrs |> filter(p_fdr < 0.05)
n_sig_dep_react <- nrow(sig_dep_react)
dep_react_sig_text <- if (n_sig_dep_react == 0) {
  "No significant associations were observed after FDR correction"
} else {
  paste(
    paste0(sig_dep_react$Reactivity, " (r = ", sig_dep_react$r,
           ", p~FDR~ = ", sig_dep_react$p_fdr, ")"),
    collapse = "; "
  )
}


## ----bfnes-desc---------------------------------------------------------------
bfnes |>
  filter(!is.na(BFNES_total)) |>
  summarise(
    n    = n(),
    Mean = round(mean(BFNES_total), 2),
    SD   = round(sd(BFNES_total),   2),
    Min  = round(min(BFNES_total),  2),
    Max  = round(max(BFNES_total),  2)
  ) |>
  kable(caption = "BFNES descriptives") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----bfnes-levels-corr--------------------------------------------------------
bfnes_levels <- biomarker_levels |>
  left_join(bfnes, by = "SampleID")

bfnes_corr_long <- map_dfr(bio_vars, function(bv) {
  map_dfr(1:4, function(tp) {
    dat <- bfnes_levels |> filter(Time == tp) |>
      select(all_of(c(bv, "BFNES_total"))) |> na.omit()
    if (nrow(dat) < 5) return(NULL)
    ct <- cor.test(dat[[bv]], dat$BFNES_total)
    tibble(Biomarker = bv, Timepoint = paste0("T", tp),
           r = round(ct$estimate, 3), p_raw = ct$p.value)
  })
}) |>
  mutate(group = if_else(
    Biomarker %in% c("CRP_log", "IL10_log", "IL6_log", "TNFalpha_log"),
    "Immune", "Hormones"
  )) |>
  group_by(group) |>
  mutate(p_fdr = round(p.adjust(p_raw, method = "fdr"), 4)) |>
  ungroup()

bfnes_corr_tbl <- bfnes_corr_long |>
  pivot_wider(id_cols = Biomarker, names_from = Timepoint,
              values_from = c(r, p_fdr),
              names_glue = "{Timepoint}_{.value}") |>
  select(Biomarker, T1_r, T1_p_fdr, T2_r, T2_p_fdr, T3_r, T3_p_fdr, T4_r, T4_p_fdr)

bfnes_corr_tbl |>
  mutate(across(ends_with("_p_fdr"), \(x) cell_spec(
    round(x, 4), bold = !is.na(x) & x < 0.05,
    color = if_else(!is.na(x) & x < 0.05, "#2166ac", "black")
  ))) |>
  kable(escape = FALSE,
        col.names = c("Biomarker", "r", "p (FDR)", "r", "p (FDR)", "r", "p (FDR)", "r", "p (FDR)"),
        caption   = "Correlations: BFNES × biomarker levels (FDR-adjusted; bold = p_FDR < .05)") |>
  add_header_above(c(" " = 1, "T1" = 2, "T2" = 2, "T3" = 2, "T4" = 2)) |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----bfnes-levels-results-vals, echo=FALSE, include=FALSE---------------------
sig_bfnes_levels <- bfnes_corr_long |> filter(p_fdr < 0.05)
n_sig_bfnes_levels <- nrow(sig_bfnes_levels)
bfnes_levels_sig_text <- if (n_sig_bfnes_levels == 0) {
  "No significant associations were observed after FDR correction"
} else {
  paste(
    paste0(sig_bfnes_levels$Biomarker, " at ", sig_bfnes_levels$Timepoint,
           " (r = ", sig_bfnes_levels$r, ", p~FDR~ = ", sig_bfnes_levels$p_fdr, ")"),
    collapse = "; "
  )
}


## ----bfnes-reactivity-corr----------------------------------------------------
bfnes_reactivity <- all_difference |>
  left_join(bfnes, by = "SampleID") |>
  select(-SampleID) |>
  na.omit()

bfnes_react_corrs <- map_dfr(setNames(reactivity_vars, reactivity_labels), function(rv) {
  ct <- cor.test(bfnes_reactivity[[rv]], bfnes_reactivity$BFNES_total)
  tibble(r = round(ct$estimate, 3), p_raw = ct$p.value)
}, .id = "Reactivity") |>
  mutate(domain = case_when(
    str_detect(Reactivity, "^ΔHR")                                        ~ "HR",
    Reactivity %in% c("ΔCRP", "ΔIL-10", "ΔIL-6", "ΔTNF-α")             ~ "Immune",
    Reactivity %in% c("ΔDHEA", "ΔTestosterone", "ΔCortisol")             ~ "Hormones",
    TRUE                                                                   ~ "Subjective"
  )) |>
  group_by(domain) |>
  mutate(p_fdr = round(p.adjust(p_raw, method = "fdr"), 4)) |>
  ungroup()

bfnes_react_corrs |>
  select(Reactivity, r, p_fdr) |>
  mutate(p_fdr = cell_spec(p_fdr, bold = !is.na(p_fdr) & p_fdr < 0.05,
    color = if_else(!is.na(p_fdr) & p_fdr < 0.05, "#2166ac", "black"))) |>
  kable(escape = FALSE, col.names = c("Reactivity outcome", "r", "p (FDR)"),
        caption = "Correlations: BFNES × reactivity (FDR-adjusted; bold = p_FDR < .05)") |>
  kable_styling(bootstrap_options = "hover", full_width = FALSE)


## ----bfnes-reactivity-results-vals, echo=FALSE, include=FALSE-----------------
sig_bfnes_react <- bfnes_react_corrs |> filter(p_fdr < 0.05)
n_sig_bfnes_react <- nrow(sig_bfnes_react)
bfnes_react_sig_text <- if (n_sig_bfnes_react == 0) {
  "No significant associations were observed after FDR correction"
} else {
  paste(
    paste0(sig_bfnes_react$Reactivity, " (r = ", sig_bfnes_react$r,
           ", p~FDR~ = ", sig_bfnes_react$p_fdr, ")"),
    collapse = "; "
  )
}


## ----corr-bioreact, fig.width=10, fig.height=9--------------------------------
bio_react_cols <- c(
  "task_rs_hr_diff", "conn_dis_hr_diff", "conn_other_hr_diff", "conn_rest_hr_diff",
  "crp_difference", "il10_difference", "il6_difference", "tnfa_difference",
  "dhea_difference", "test_difference", "cort_difference"
)
bio_react_col_labels <- c(
  "ΔHR: Task vs. Rest", "ΔHR: SC vs. SD", "ΔHR: SC vs. Other", "ΔHR: SC vs. Rest",
  "ΔCRP", "ΔIL-10", "ΔIL-6", "ΔTNF-α", "ΔDHEA", "ΔTestosterone", "ΔCortisol"
)

bio_mat2 <- all_difference |>
  select(all_of(bio_react_cols)) |>
  setNames(bio_react_col_labels) |>
  as.matrix()

bio_rc2 <- rcorr(bio_mat2)
plot_sig_corrplot(bio_rc2$r, bio_rc2$P, "Bioreactivity Measures")


## ----corr-outcomes, fig.width=6, fig.height=5---------------------------------
outcome_mat <- all_difference |>
  select(SampleID, subj_scsd_difference, subj_scother_difference) |>
  left_join(dep   |> select(SampleID, CESD_total),  by = "SampleID") |>
  left_join(bfnes |> select(SampleID, BFNES_total), by = "SampleID") |>
  select(-SampleID) |>
  setNames(c("ΔSubj Stress: SC vs. SD", "ΔSubj Stress: SC vs. Other",
             "CES-DC", "BFNES")) |>
  as.matrix()

outcome_rc <- rcorr(outcome_mat)
plot_sig_corrplot(outcome_rc$r, outcome_rc$P, "Outcome Measures")


## ----corr-all, fig.width=12, fig.height=11------------------------------------
all_measures_mat <- all_difference |>
  left_join(dep   |> select(SampleID, CESD_total),  by = "SampleID") |>
  left_join(bfnes |> select(SampleID, BFNES_total), by = "SampleID") |>
  select(all_of(bio_react_cols), subj_scsd_difference, subj_scother_difference,
         CESD_total, BFNES_total) |>
  setNames(c(bio_react_col_labels,
             "ΔSubj Stress: SC vs. SD", "ΔSubj Stress: SC vs. Other",
             "CES-DC", "BFNES")) |>
  as.matrix()

all_rc <- rcorr(all_measures_mat)
plot_sig_corrplot(all_rc$r, all_rc$P, "All Measures")

