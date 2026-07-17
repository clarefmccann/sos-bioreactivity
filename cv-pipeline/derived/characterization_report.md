# CV pipeline -- characterization report
_Generated 2026-07-17 16:20:49_

## Plates per batch
|batch                            | n_plates|
|:--------------------------------|--------:|
|7-30-20 HU CRP box 3             |        1|
|7-30-20 HU CRP box 4             |        1|
|7-30-20 HU cytokine 3-plex Bx 3  |        1|
|7-30-20 HU cytokine 3-plex box 4 |        1|
|8-4-20 HU CRP box 5              |        1|
|8-4-20 HU CRP box 6              |        1|
|8-4-20 Hu cytokine box 5         |        1|
|8-5-20 HU CRP box 8              |        1|
|8-5-20 Hu cytokine box 8         |        1|
|CRP box2 replay                  |        1|
|Hu Cyto 3plex plt 6 8-4-20       |        1|
|Hu Cytokine saliva box1 7-28-20  |        1|
|Hu Cytokine saliva box2 7-29-20  |        1|

# Characterization: Hu Cytokine saliva plt1

## Run metadata
- Batch: Hu Cytokine saliva box1 7-28-20
- Run date: 2020-07-28 11:26:00
- Instrument SN: LX10014290402
- Protocol: Millipore Human Cytokine saliva 3plex
- Kit: Cytokine saliva (lot 3497399, expires 2021-05-31, Millipore)

### Analytes
|analyte   |bead_id |units |curve_model          | r_squared|
|:---------|:-------|:-----|:--------------------|---------:|
|IL-10     |27      |pg/ml |Logistic 5P Weighted |     0.994|
|IL-6      |57      |pg/ml |Logistic 5P Weighted |     0.990|
|TNF-alpha |75      |pg/ml |Logistic 5P Weighted |     0.994|

## Layout inventory
- Total wells: 90
|sample_type | n_wells|
|:-----------|-------:|
|background  |       2|
|control     |       4|
|standard    |      12|
|unknown     |      72|
- Replicate depth: confirmed 2 for all samples

## Standard curve health
_R² is the instrument-reported value, computed on the post-exclusion curve (xPONENT refits after invalidation)._
|analyte   | nominal_range_low| nominal_range_high| effective_range_low| effective_range_high| n_levels_excluded|curve_model          | r_squared| n_standards_invalidated|
|:---------|-----------------:|------------------:|-------------------:|--------------------:|-----------------:|:--------------------|---------:|-----------------------:|
|IL-10     |               3.2|              10000|                 3.2|                10000|                 0|Logistic 5P Weighted |     0.994|                       0|
|IL-6      |               3.2|              10000|                 3.2|                 2000|                 1|Logistic 5P Weighted |     0.990|                       1|
|TNF-alpha |               3.2|              10000|                 3.2|                10000|                 0|Logistic 5P Weighted |     0.994|                       0|

### Standard %Recovery (mean across replicates)
|analyte   |standard_level | mean_recovery_pct|
|:---------|:--------------|-----------------:|
|IL-10     |Standard1      |            99.815|
|IL-10     |Standard2      |           100.845|
|IL-10     |Standard3      |            99.160|
|IL-10     |Standard4      |           101.550|
|IL-10     |Standard5      |           104.090|
|IL-10     |Standard6      |           100.190|
|IL-6      |Standard1      |               NaN|
|IL-6      |Standard2      |           100.020|
|IL-6      |Standard3      |           100.265|
|IL-6      |Standard4      |           100.855|
|IL-6      |Standard5      |           104.855|
|IL-6      |Standard6      |           101.740|
|TNF-alpha |Standard1      |            99.950|
|TNF-alpha |Standard2      |           100.460|
|TNF-alpha |Standard3      |           100.000|
|TNF-alpha |Standard4      |           100.615|
|TNF-alpha |Standard5      |           104.580|
|TNF-alpha |Standard6      |           100.195|

### Standard %CV Replicates (as reported by xPONENT)
|analyte   |standard_level | cv_reported|
|:---------|:--------------|-----------:|
|IL-10     |Standard1      |       2.653|
|IL-6      |Standard1      |       0.000|
|TNF-alpha |Standard1      |       3.014|
|IL-10     |Standard2      |       0.848|
|IL-6      |Standard2      |       1.759|
|TNF-alpha |Standard2      |       6.066|
|IL-10     |Standard3      |       8.302|
|IL-6      |Standard3      |       5.452|
|TNF-alpha |Standard3      |       6.391|
|IL-10     |Standard4      |       0.278|
|IL-6      |Standard4      |       9.092|
|TNF-alpha |Standard4      |       0.482|
|IL-10     |Standard5      |      22.721|
|IL-6      |Standard5      |      21.855|
|TNF-alpha |Standard5      |      22.095|
|IL-10     |Standard6      |       2.118|
|IL-6      |Standard6      |      16.851|
|TNF-alpha |Standard6      |       3.845|

## Control performance
|analyte   |control_level | observed_avg| expected_conc| range_low| range_high| cv_reported|pass |
|:---------|:-------------|------------:|-------------:|---------:|----------:|-----------:|:----|
|IL-10     |Control1      |       85.895|            75|        44|        105|       8.799|TRUE |
|IL-6      |Control1      |      165.446|           150|       101|        209|       0.196|TRUE |
|TNF-alpha |Control1      |      139.633|           125|        84|        175|       3.453|TRUE |
|IL-10     |Control2      |      534.083|           500|       385|        800|      12.815|TRUE |
|IL-6      |Control2      |      599.665|           700|       485|       1008|       8.750|TRUE |
|TNF-alpha |Control2      |      576.223|           700|       447|        929|       1.698|TRUE |

## Quantifiability (unknowns only)
_This is the single most important number in the report -- an analyte where most samples are below the LLOQ cannot be reported as continuous regardless of CV quality._
|analyte   |censor_flag |  n|  pct|
|:---------|:-----------|--:|----:|
|IL-10     |below_lloq  | 15| 20.8|
|IL-10     |ok          | 57| 79.2|
|IL-6      |below_lloq  | 43| 59.7|
|IL-6      |ok          | 29| 40.3|
|TNF-alpha |below_lloq  |  2|  2.8|
|TNF-alpha |ok          | 70| 97.2|

### Invalidated unknown wells
|analyte   | n_invalidated|
|:---------|-------------:|
|IL-10     |             0|
|IL-6      |             0|
|TNF-alpha |             0|

## Bead counts
|analyte   | min_count| median_count| max_count| n_below_threshold| threshold|
|:---------|---------:|------------:|---------:|-----------------:|---------:|
|IL-10     |        50|         58.5|        92|                 0|        50|
|IL-6      |        50|         59.0|        86|                 0|        50|
|TNF-alpha |        50|         50.0|        72|                 0|        50|

---

# Characterization: Hu Cytokine saliva plt2

## Run metadata
- Batch: Hu Cytokine saliva box2 7-29-20
- Run date: 2020-07-29 12:14:00
- Instrument SN: LX10014290402
- Protocol: 7-28-20 Human cytokine saliva
- Kit: Cytokine (lot 3497399, expires 2021-05-31, Millipore)

### Analytes
|analyte   |bead_id |units |curve_model          | r_squared|
|:---------|:-------|:-----|:--------------------|---------:|
|IL-10     |27      |pg/ml |Logistic 5P Weighted |     0.998|
|IL-6      |57      |pg/ml |Logistic 5P Weighted |     0.999|
|TNF-alpha |75      |pg/ml |Logistic 5P Weighted |     0.999|

## Layout inventory
- Total wells: 94
|sample_type | n_wells|
|:-----------|-------:|
|background  |       2|
|standard    |      12|
|unknown     |      80|
- Replicate depth: confirmed 2 for all samples

## Standard curve health
_R² is the instrument-reported value, computed on the post-exclusion curve (xPONENT refits after invalidation)._
|analyte   | nominal_range_low| nominal_range_high| effective_range_low| effective_range_high| n_levels_excluded|curve_model          | r_squared| n_standards_invalidated|
|:---------|-----------------:|------------------:|-------------------:|--------------------:|-----------------:|:--------------------|---------:|-----------------------:|
|IL-10     |               3.2|              10000|                 3.2|                10000|                 0|Logistic 5P Weighted |     0.998|                       0|
|IL-6      |               3.2|              10000|                 3.2|                 2000|                 1|Logistic 5P Weighted |     0.999|                       1|
|TNF-alpha |               3.2|              10000|                 3.2|                10000|                 0|Logistic 5P Weighted |     0.999|                       0|

### Standard %Recovery (mean across replicates)
|analyte   |standard_level | mean_recovery_pct|
|:---------|:--------------|-----------------:|
|IL-10     |Standard1      |            99.930|
|IL-10     |Standard2      |           100.555|
|IL-10     |Standard3      |            96.870|
|IL-10     |Standard4      |           106.955|
|IL-10     |Standard5      |            97.630|
|IL-10     |Standard6      |           100.235|
|IL-6      |Standard1      |               NaN|
|IL-6      |Standard2      |           100.145|
|IL-6      |Standard3      |           100.110|
|IL-6      |Standard4      |           100.910|
|IL-6      |Standard5      |            99.930|
|IL-6      |Standard6      |           100.050|
|TNF-alpha |Standard1      |            99.605|
|TNF-alpha |Standard2      |           100.780|
|TNF-alpha |Standard3      |            98.285|
|TNF-alpha |Standard4      |           102.805|
|TNF-alpha |Standard5      |            98.800|
|TNF-alpha |Standard6      |           100.155|

### Standard %CV Replicates (as reported by xPONENT)
|analyte   |standard_level | cv_reported|
|:---------|:--------------|-----------:|
|IL-10     |Standard1      |       0.497|
|IL-6      |Standard1      |       0.000|
|TNF-alpha |Standard1      |       0.465|
|IL-10     |Standard2      |       0.236|
|IL-6      |Standard2      |       1.106|
|TNF-alpha |Standard2      |       2.150|
|IL-10     |Standard3      |       5.284|
|IL-6      |Standard3      |       6.889|
|TNF-alpha |Standard3      |       2.768|
|IL-10     |Standard4      |       0.219|
|IL-6      |Standard4      |       8.297|
|TNF-alpha |Standard4      |       4.000|
|IL-10     |Standard5      |       7.100|
|IL-6      |Standard5      |       0.803|
|TNF-alpha |Standard5      |       2.358|
|IL-10     |Standard6      |       2.115|
|IL-6      |Standard6      |       2.063|
|TNF-alpha |Standard6      |       1.234|

## Control performance
_(no rows)_

## Quantifiability (unknowns only)
_This is the single most important number in the report -- an analyte where most samples are below the LLOQ cannot be reported as continuous regardless of CV quality._
|analyte   |censor_flag |  n|   pct|
|:---------|:-----------|--:|-----:|
|IL-10     |ok          | 80| 100.0|
|IL-6      |below_lloq  | 13|  16.2|
|IL-6      |ok          | 67|  83.8|
|TNF-alpha |ok          | 80| 100.0|

### Invalidated unknown wells
|analyte   | n_invalidated|
|:---------|-------------:|
|IL-10     |             0|
|IL-6      |             0|
|TNF-alpha |             0|

## Bead counts
|analyte   | min_count| median_count| max_count| n_below_threshold| threshold|
|:---------|---------:|------------:|---------:|-----------------:|---------:|
|IL-10     |        50|         64.0|       102|                 0|        50|
|IL-6      |        50|         58.5|        91|                 0|        50|
|TNF-alpha |        50|         50.0|        84|                 0|        50|

---

# Characterization: HU cytokine saliva plt 3

## Run metadata
- Batch: 7-30-20 HU cytokine 3-plex Bx 3
- Run date: 2020-07-30 10:56:00
- Instrument SN: LX10014290402
- Protocol: 7-28-20 Human cytokine saliva
- Kit: Cytokine (lot 3497399, expires 2021-05-31, Millipore)

### Analytes
|analyte   |bead_id |units |curve_model          | r_squared|
|:---------|:-------|:-----|:--------------------|---------:|
|IL-10     |27      |pg/ml |Logistic 5P Weighted |     0.998|
|IL-6      |57      |pg/ml |Logistic 5P Weighted |     0.997|
|TNF-alpha |75      |pg/ml |Logistic 5P Weighted |     0.994|

## Layout inventory
- Total wells: 92
|sample_type | n_wells|
|:-----------|-------:|
|background  |       2|
|standard    |      12|
|unknown     |      78|
- Replicate depth: confirmed 2 for all samples

## Standard curve health
_R² is the instrument-reported value, computed on the post-exclusion curve (xPONENT refits after invalidation)._
|analyte   | nominal_range_low| nominal_range_high| effective_range_low| effective_range_high| n_levels_excluded|curve_model          | r_squared| n_standards_invalidated|
|:---------|-----------------:|------------------:|-------------------:|--------------------:|-----------------:|:--------------------|---------:|-----------------------:|
|IL-10     |               3.2|              10000|                16.0|                10000|                 1|Logistic 5P Weighted |     0.998|                       1|
|IL-6      |               3.2|              10000|                 3.2|                 2000|                 1|Logistic 5P Weighted |     0.997|                       1|
|TNF-alpha |               3.2|              10000|                 3.2|                10000|                 0|Logistic 5P Weighted |     0.994|                       0|

### Standard %Recovery (mean across replicates)
|analyte   |standard_level | mean_recovery_pct|
|:---------|:--------------|-----------------:|
|IL-10     |Standard1      |           101.245|
|IL-10     |Standard2      |            98.030|
|IL-10     |Standard3      |           104.315|
|IL-10     |Standard4      |            97.230|
|IL-10     |Standard5      |           101.380|
|IL-10     |Standard6      |            99.550|
|IL-6      |Standard1      |               NaN|
|IL-6      |Standard2      |            95.840|
|IL-6      |Standard3      |           103.250|
|IL-6      |Standard4      |            96.545|
|IL-6      |Standard5      |           103.125|
|IL-6      |Standard6      |           100.125|
|TNF-alpha |Standard1      |            99.380|
|TNF-alpha |Standard2      |           103.620|
|TNF-alpha |Standard3      |            97.975|
|TNF-alpha |Standard4      |           102.220|
|TNF-alpha |Standard5      |            98.950|
|TNF-alpha |Standard6      |           105.680|

### Standard %CV Replicates (as reported by xPONENT)
|analyte   |standard_level | cv_reported|
|:---------|:--------------|-----------:|
|IL-10     |Standard1      |       7.575|
|IL-6      |Standard1      |       0.000|
|TNF-alpha |Standard1      |       3.315|
|IL-10     |Standard2      |       6.930|
|IL-6      |Standard2      |       7.603|
|TNF-alpha |Standard2      |      15.843|
|IL-10     |Standard3      |       5.587|
|IL-6      |Standard3      |       2.440|
|TNF-alpha |Standard3      |       2.522|
|IL-10     |Standard4      |       3.445|
|IL-6      |Standard4      |       9.766|
|TNF-alpha |Standard4      |       1.606|
|IL-10     |Standard5      |       2.313|
|IL-6      |Standard5      |       4.928|
|TNF-alpha |Standard5      |       0.286|
|IL-10     |Standard6      |       0.000|
|IL-6      |Standard6      |       6.360|
|TNF-alpha |Standard6      |      27.603|

## Control performance
_(no rows)_

## Quantifiability (unknowns only)
_This is the single most important number in the report -- an analyte where most samples are below the LLOQ cannot be reported as continuous regardless of CV quality._
|analyte   |censor_flag |  n|   pct|
|:---------|:-----------|--:|-----:|
|IL-10     |below_lloq  |  9|  11.5|
|IL-10     |ok          | 69|  88.5|
|IL-6      |ok          | 78| 100.0|
|TNF-alpha |below_lloq  |  1|   1.3|
|TNF-alpha |ok          | 77|  98.7|

### Invalidated unknown wells
|analyte   | n_invalidated|
|:---------|-------------:|
|IL-10     |             0|
|IL-6      |             0|
|TNF-alpha |             0|

## Bead counts
|analyte   | min_count| median_count| max_count| n_below_threshold| threshold|
|:---------|---------:|------------:|---------:|-----------------:|---------:|
|IL-10     |        50|           64|       100|                 0|        50|
|IL-6      |        50|           56|       106|                 0|        50|
|TNF-alpha |        50|           50|        80|                 0|        50|

---

# Characterization: HU cytokine saliva plt 4

## Run metadata
- Batch: 7-30-20 HU cytokine 3-plex box 4
- Run date: 2020-07-30 12:15:00
- Instrument SN: LX10014290402
- Protocol: 7-28-20 Human cytokine saliva
- Kit: Cytokine (lot 3497399, expires 2021-05-31, Millipore)

### Analytes
|analyte   |bead_id |units |curve_model          | r_squared|
|:---------|:-------|:-----|:--------------------|---------:|
|IL-10     |27      |pg/ml |Logistic 5P Weighted |     0.993|
|IL-6      |57      |pg/ml |Logistic 5P Weighted |     0.994|
|TNF-alpha |75      |pg/ml |Logistic 5P Weighted |     0.998|

## Layout inventory
- Total wells: 94
|sample_type | n_wells|
|:-----------|-------:|
|background  |       2|
|standard    |      12|
|unknown     |      80|
- Replicate depth: confirmed 2 for all samples

## Standard curve health
_R² is the instrument-reported value, computed on the post-exclusion curve (xPONENT refits after invalidation)._
|analyte   | nominal_range_low| nominal_range_high| effective_range_low| effective_range_high| n_levels_excluded|curve_model          | r_squared| n_standards_invalidated|
|:---------|-----------------:|------------------:|-------------------:|--------------------:|-----------------:|:--------------------|---------:|-----------------------:|
|IL-10     |               3.2|              10000|                 3.2|                 2000|                 1|Logistic 5P Weighted |     0.993|                       1|
|IL-6      |               3.2|              10000|                 3.2|                 2000|                 1|Logistic 5P Weighted |     0.994|                       1|
|TNF-alpha |               3.2|              10000|                16.0|                 2000|                 2|Logistic 5P Weighted |     0.998|                       2|

### Standard %Recovery (mean across replicates)
|analyte   |standard_level | mean_recovery_pct|
|:---------|:--------------|-----------------:|
|IL-10     |Standard1      |           100.830|
|IL-10     |Standard2      |            99.595|
|IL-10     |Standard3      |           102.010|
|IL-10     |Standard4      |            99.475|
|IL-10     |Standard5      |           100.780|
|IL-10     |Standard6      |           103.655|
|IL-6      |Standard1      |               NaN|
|IL-6      |Standard2      |           100.060|
|IL-6      |Standard3      |           103.725|
|IL-6      |Standard4      |           100.750|
|IL-6      |Standard5      |           100.150|
|IL-6      |Standard6      |           100.515|
|TNF-alpha |Standard1      |            99.570|
|TNF-alpha |Standard2      |           101.865|
|TNF-alpha |Standard3      |            99.425|
|TNF-alpha |Standard4      |           101.395|
|TNF-alpha |Standard5      |            99.395|
|TNF-alpha |Standard6      |           100.170|

### Standard %CV Replicates (as reported by xPONENT)
|analyte   |standard_level | cv_reported|
|:---------|:--------------|-----------:|
|IL-10     |Standard1      |       0.000|
|IL-6      |Standard1      |       0.000|
|TNF-alpha |Standard1      |       0.000|
|IL-10     |Standard2      |       6.477|
|IL-6      |Standard2      |       2.767|
|TNF-alpha |Standard2      |      13.498|
|IL-10     |Standard3      |       7.737|
|IL-6      |Standard3      |      19.914|
|TNF-alpha |Standard3      |       1.784|
|IL-10     |Standard4      |       9.788|
|IL-6      |Standard4      |       8.425|
|TNF-alpha |Standard4      |       4.773|
|IL-10     |Standard5      |       1.249|
|IL-6      |Standard5      |       3.732|
|TNF-alpha |Standard5      |       2.267|
|IL-10     |Standard6      |      19.351|
|IL-6      |Standard6      |       8.266|
|TNF-alpha |Standard6      |       0.000|

## Control performance
_(no rows)_

## Quantifiability (unknowns only)
_This is the single most important number in the report -- an analyte where most samples are below the LLOQ cannot be reported as continuous regardless of CV quality._
|analyte   |censor_flag |  n| pct|
|:---------|:-----------|--:|---:|
|IL-10     |ok          | 80| 100|
|IL-6      |below_lloq  | 16|  20|
|IL-6      |ok          | 64|  80|
|TNF-alpha |ok          | 80| 100|

### Invalidated unknown wells
|analyte   | n_invalidated|
|:---------|-------------:|
|IL-10     |             0|
|IL-6      |             0|
|TNF-alpha |             0|

## Bead counts
|analyte   | min_count| median_count| max_count| n_below_threshold| threshold|
|:---------|---------:|------------:|---------:|-----------------:|---------:|
|IL-10     |        50|         62.0|       110|                 0|        50|
|IL-6      |        50|         57.5|        96|                 0|        50|
|TNF-alpha |        50|         50.0|        67|                 0|        50|

---

# Characterization: Hu cytokine saliva plt 5

## Run metadata
- Batch: 8-4-20 Hu cytokine box 5
- Run date: 2020-08-04 14:32:59
- Instrument SN: LX10014290402
- Protocol: 7-28-20 Human cytokine saliva
- Kit: Cytokine (lot 3497399, expires 2021-05-31, Millipore)

### Analytes
|analyte   |bead_id |units |curve_model          | r_squared|
|:---------|:-------|:-----|:--------------------|---------:|
|IL-10     |27      |pg/ml |Logistic 5P Weighted |     0.993|
|IL-6      |57      |pg/ml |Logistic 5P Weighted |     0.995|
|TNF-alpha |75      |pg/ml |Logistic 5P Weighted |     0.994|

## Layout inventory
- Total wells: 94
|sample_type | n_wells|
|:-----------|-------:|
|background  |       2|
|standard    |      12|
|unknown     |      80|
- Replicate depth: confirmed 2 for all samples

## Standard curve health
_R² is the instrument-reported value, computed on the post-exclusion curve (xPONENT refits after invalidation)._
|analyte   | nominal_range_low| nominal_range_high| effective_range_low| effective_range_high| n_levels_excluded|curve_model          | r_squared| n_standards_invalidated|
|:---------|-----------------:|------------------:|-------------------:|--------------------:|-----------------:|:--------------------|---------:|-----------------------:|
|IL-10     |               3.2|              10000|                 3.2|                10000|                 0|Logistic 5P Weighted |     0.993|                       0|
|IL-6      |               3.2|              10000|                 3.2|                 2000|                 1|Logistic 5P Weighted |     0.995|                       1|
|TNF-alpha |               3.2|              10000|                 3.2|                10000|                 0|Logistic 5P Weighted |     0.994|                       0|

### Standard %Recovery (mean across replicates)
|analyte   |standard_level | mean_recovery_pct|
|:---------|:--------------|-----------------:|
|IL-10     |Standard1      |           100.020|
|IL-10     |Standard2      |           100.155|
|IL-10     |Standard3      |           100.760|
|IL-10     |Standard4      |           100.075|
|IL-10     |Standard5      |           101.450|
|IL-10     |Standard6      |           103.495|
|IL-6      |Standard1      |               NaN|
|IL-6      |Standard2      |           100.075|
|IL-6      |Standard3      |           100.000|
|IL-6      |Standard4      |           101.110|
|IL-6      |Standard5      |           100.895|
|IL-6      |Standard6      |           101.085|
|TNF-alpha |Standard1      |           101.565|
|TNF-alpha |Standard2      |            98.370|
|TNF-alpha |Standard3      |           106.850|
|TNF-alpha |Standard4      |            93.120|
|TNF-alpha |Standard5      |           106.635|
|TNF-alpha |Standard6      |            99.490|

### Standard %CV Replicates (as reported by xPONENT)
|analyte   |standard_level | cv_reported|
|:---------|:--------------|-----------:|
|IL-10     |Standard1      |       2.013|
|IL-6      |Standard1      |       0.000|
|TNF-alpha |Standard1      |       6.438|
|IL-10     |Standard2      |       3.847|
|IL-6      |Standard2      |       3.117|
|TNF-alpha |Standard2      |       0.989|
|IL-10     |Standard3      |       9.231|
|IL-6      |Standard3      |       0.339|
|TNF-alpha |Standard3      |       6.670|
|IL-10     |Standard4      |       1.957|
|IL-6      |Standard4      |       9.679|
|TNF-alpha |Standard4      |       7.633|
|IL-10     |Standard5      |      11.763|
|IL-6      |Standard5      |       8.825|
|TNF-alpha |Standard5      |       9.871|
|IL-10     |Standard6      |      18.221|
|IL-6      |Standard6      |      12.485|
|TNF-alpha |Standard6      |       4.272|

## Control performance
_(no rows)_

## Quantifiability (unknowns only)
_This is the single most important number in the report -- an analyte where most samples are below the LLOQ cannot be reported as continuous regardless of CV quality._
|analyte   |censor_flag |  n|   pct|
|:---------|:-----------|--:|-----:|
|IL-10     |ok          | 80| 100.0|
|IL-6      |below_lloq  |  3|   3.8|
|IL-6      |ok          | 77|  96.2|
|TNF-alpha |below_lloq  |  1|   1.2|
|TNF-alpha |ok          | 79|  98.8|

### Invalidated unknown wells
|analyte   | n_invalidated|
|:---------|-------------:|
|IL-10     |             0|
|IL-6      |             0|
|TNF-alpha |             0|

## Bead counts
|analyte   | min_count| median_count| max_count| n_below_threshold| threshold|
|:---------|---------:|------------:|---------:|-----------------:|---------:|
|IL-10     |        50|         67.5|       117|                 0|        50|
|IL-6      |        50|         64.5|       114|                 0|        50|
|TNF-alpha |        50|         50.0|        76|                 0|        50|

---

# Characterization: Hu Cyto saliva plt 6

## Run metadata
- Batch: Hu Cyto 3plex plt 6 8-4-20
- Run date: 2020-08-04 15:17:00
- Instrument SN: LX10014290402
- Protocol: 7-28-20 Human cytokine saliva
- Kit: Cytokine (lot 3497399, expires 2021-05-31, Millipore)

### Analytes
|analyte   |bead_id |units |curve_model          | r_squared|
|:---------|:-------|:-----|:--------------------|---------:|
|IL-10     |27      |pg/ml |Logistic 5P Weighted |     0.997|
|IL-6      |57      |pg/ml |Logistic 5P Weighted |     0.999|
|TNF-alpha |75      |pg/ml |Logistic 5P Weighted |     0.998|

## Layout inventory
- Total wells: 94
|sample_type | n_wells|
|:-----------|-------:|
|background  |       2|
|standard    |      12|
|unknown     |      80|
- Replicate depth: confirmed 2 for all samples

## Standard curve health
_R² is the instrument-reported value, computed on the post-exclusion curve (xPONENT refits after invalidation)._
|analyte   | nominal_range_low| nominal_range_high| effective_range_low| effective_range_high| n_levels_excluded|curve_model          | r_squared| n_standards_invalidated|
|:---------|-----------------:|------------------:|-------------------:|--------------------:|-----------------:|:--------------------|---------:|-----------------------:|
|IL-10     |               3.2|              10000|                 3.2|                10000|                 0|Logistic 5P Weighted |     0.997|                       0|
|IL-6      |               3.2|              10000|                 3.2|                 2000|                 1|Logistic 5P Weighted |     0.999|                       1|
|TNF-alpha |               3.2|              10000|                 3.2|                10000|                 0|Logistic 5P Weighted |     0.998|                       0|

### Standard %Recovery (mean across replicates)
|analyte   |standard_level | mean_recovery_pct|
|:---------|:--------------|-----------------:|
|IL-10     |Standard1      |            99.880|
|IL-10     |Standard2      |           101.545|
|IL-10     |Standard3      |            98.975|
|IL-10     |Standard4      |           101.090|
|IL-10     |Standard5      |           100.435|
|IL-10     |Standard6      |           100.915|
|IL-6      |Standard1      |               NaN|
|IL-6      |Standard2      |           100.005|
|IL-6      |Standard3      |           100.095|
|IL-6      |Standard4      |           100.000|
|IL-6      |Standard5      |           100.025|
|IL-6      |Standard6      |           100.680|
|TNF-alpha |Standard1      |           101.480|
|TNF-alpha |Standard2      |            98.145|
|TNF-alpha |Standard3      |           104.805|
|TNF-alpha |Standard4      |            95.760|
|TNF-alpha |Standard5      |           102.770|
|TNF-alpha |Standard6      |            99.470|

### Standard %CV Replicates (as reported by xPONENT)
|analyte   |standard_level | cv_reported|
|:---------|:--------------|-----------:|
|IL-10     |Standard1      |       3.803|
|IL-6      |Standard1      |       0.000|
|TNF-alpha |Standard1      |       2.330|
|IL-10     |Standard2      |       8.693|
|IL-6      |Standard2      |       0.958|
|TNF-alpha |Standard2      |       4.450|
|IL-10     |Standard3      |       5.964|
|IL-6      |Standard3      |       3.155|
|TNF-alpha |Standard3      |       7.432|
|IL-10     |Standard4      |       2.044|
|IL-6      |Standard4      |       0.267|
|TNF-alpha |Standard4      |       1.556|
|IL-10     |Standard5      |       9.315|
|IL-6      |Standard5      |       1.510|
|TNF-alpha |Standard5      |       1.498|
|IL-10     |Standard6      |      10.960|
|IL-6      |Standard6      |       8.958|
|TNF-alpha |Standard6      |       0.000|

## Control performance
_(no rows)_

## Quantifiability (unknowns only)
_This is the single most important number in the report -- an analyte where most samples are below the LLOQ cannot be reported as continuous regardless of CV quality._
|analyte   |censor_flag |  n|  pct|
|:---------|:-----------|--:|----:|
|IL-10     |below_lloq  | 39| 48.8|
|IL-10     |ok          | 41| 51.2|
|IL-6      |below_lloq  | 31| 38.8|
|IL-6      |ok          | 49| 61.2|
|TNF-alpha |below_lloq  | 11| 13.8|
|TNF-alpha |ok          | 69| 86.2|

### Invalidated unknown wells
|analyte   | n_invalidated|
|:---------|-------------:|
|IL-10     |             0|
|IL-6      |             0|
|TNF-alpha |             0|

## Bead counts
|analyte   | min_count| median_count| max_count| n_below_threshold| threshold|
|:---------|---------:|------------:|---------:|-----------------:|---------:|
|IL-10     |        50|         64.5|       179|                 0|        50|
|IL-6      |        50|         58.0|       140|                 0|        50|
|TNF-alpha |        50|         50.0|        70|                 0|        50|

---

# Characterization: Hu cytokine saliva plt 8

## Run metadata
- Batch: 8-5-20 Hu cytokine box 8
- Run date: 2020-08-05 12:17:59
- Instrument SN: LX10014290402
- Protocol: 7-28-20 Human cytokine saliva
- Kit: Cytokine (lot 3497399, expires 2021-05-31, Millipore)

### Analytes
|analyte   |bead_id |units |curve_model          | r_squared|
|:---------|:-------|:-----|:--------------------|---------:|
|IL-10     |27      |pg/ml |Logistic 5P Weighted |     0.996|
|IL-6      |57      |pg/ml |Logistic 5P Weighted |     0.999|
|TNF-alpha |75      |pg/ml |Logistic 5P Weighted |     0.989|

## Layout inventory
- Total wells: 54
|sample_type | n_wells|
|:-----------|-------:|
|background  |       2|
|standard    |      12|
|unknown     |      40|
- Replicate depth: confirmed 2 for all samples

## Standard curve health
_R² is the instrument-reported value, computed on the post-exclusion curve (xPONENT refits after invalidation)._
|analyte   | nominal_range_low| nominal_range_high| effective_range_low| effective_range_high| n_levels_excluded|curve_model          | r_squared| n_standards_invalidated|
|:---------|-----------------:|------------------:|-------------------:|--------------------:|-----------------:|:--------------------|---------:|-----------------------:|
|IL-10     |               3.2|              10000|                 3.2|                10000|                 0|Logistic 5P Weighted |     0.996|                       0|
|IL-6      |               3.2|              10000|                 3.2|                10000|                 0|Logistic 5P Weighted |     0.999|                       0|
|TNF-alpha |               3.2|              10000|                 3.2|                10000|                 0|Logistic 5P Weighted |     0.989|                       0|

### Standard %Recovery (mean across replicates)
|analyte   |standard_level | mean_recovery_pct|
|:---------|:--------------|-----------------:|
|IL-10     |Standard1      |           100.675|
|IL-10     |Standard2      |            99.685|
|IL-10     |Standard3      |           104.815|
|IL-10     |Standard4      |            95.200|
|IL-10     |Standard5      |           102.880|
|IL-10     |Standard6      |           100.420|
|IL-6      |Standard1      |           102.245|
|IL-6      |Standard2      |            99.995|
|IL-6      |Standard3      |           100.005|
|IL-6      |Standard4      |           101.105|
|IL-6      |Standard5      |           100.120|
|IL-6      |Standard6      |           100.030|
|TNF-alpha |Standard1      |           100.675|
|TNF-alpha |Standard2      |            99.700|
|TNF-alpha |Standard3      |           101.520|
|TNF-alpha |Standard4      |            99.700|
|TNF-alpha |Standard5      |           101.575|
|TNF-alpha |Standard6      |           106.035|

### Standard %CV Replicates (as reported by xPONENT)
|analyte   |standard_level | cv_reported|
|:---------|:--------------|-----------:|
|IL-10     |Standard1      |       6.844|
|IL-6      |Standard1      |      16.353|
|TNF-alpha |Standard1      |       3.040|
|IL-10     |Standard2      |      10.135|
|IL-6      |Standard2      |       1.600|
|TNF-alpha |Standard2      |       5.390|
|IL-10     |Standard3      |       3.608|
|IL-6      |Standard3      |       0.418|
|TNF-alpha |Standard3      |       0.184|
|IL-10     |Standard4      |       8.115|
|IL-6      |Standard4      |      10.217|
|TNF-alpha |Standard4      |      13.249|
|IL-10     |Standard5      |       1.467|
|IL-6      |Standard5      |       3.311|
|TNF-alpha |Standard5      |       6.197|
|IL-10     |Standard6      |       4.563|
|IL-6      |Standard6      |       1.670|
|TNF-alpha |Standard6      |      21.413|

## Control performance
_(no rows)_

## Quantifiability (unknowns only)
_This is the single most important number in the report -- an analyte where most samples are below the LLOQ cannot be reported as continuous regardless of CV quality._
|analyte   |censor_flag |  n| pct|
|:---------|:-----------|--:|---:|
|IL-10     |ok          | 40| 100|
|IL-6      |ok          | 40| 100|
|TNF-alpha |ok          | 40| 100|

### Invalidated unknown wells
|analyte   | n_invalidated|
|:---------|-------------:|
|IL-10     |             0|
|IL-6      |             0|
|TNF-alpha |             0|

## Bead counts
|analyte   | min_count| median_count| max_count| n_below_threshold| threshold|
|:---------|---------:|------------:|---------:|-----------------:|---------:|
|IL-10     |        50|           67|       103|                 0|        50|
|IL-6      |        50|           56|        80|                 0|        50|
|TNF-alpha |        50|           50|        68|                 0|        50|

---

# Characterization: Hu CRP saliva plt 2

## Run metadata
- Batch: CRP box2 replay
- Run date: 2020-07-31 13:24:00
- Instrument SN: LX10014290402
- Protocol: 12-18-19 Human CRP saliva
- Kit: Human CRP (lot 3385047, expires 2020-09-30, Millipore)

### Analytes
|analyte |bead_id |units |curve_model          | r_squared|
|:-------|:-------|:-----|:--------------------|---------:|
|CRP     |19      |ng/ml |Logistic 5P Weighted |     0.988|

## Layout inventory
- Total wells: 94
|sample_type | n_wells|
|:-----------|-------:|
|background  |       1|
|standard    |      13|
|unknown     |      80|
- **WARNING**: 2 sample(s) do not have replicate depth 2 (see warnings)

## Standard curve health
_R² is the instrument-reported value, computed on the post-exclusion curve (xPONENT refits after invalidation)._
|analyte | nominal_range_low| nominal_range_high| effective_range_low| effective_range_high| n_levels_excluded|curve_model          | r_squared| n_standards_invalidated|
|:-------|-----------------:|------------------:|-------------------:|--------------------:|-----------------:|:--------------------|---------:|-----------------------:|
|CRP     |             0.012|                 50|               0.012|                 12.5|                 2|Logistic 5P Weighted |     0.988|                       2|

### Standard %Recovery (mean across replicates)
|analyte |standard_level | mean_recovery_pct|
|:-------|:--------------|-----------------:|
|CRP     |Standard1      |            93.860|
|CRP     |Standard2      |           104.745|
|CRP     |Standard3      |            94.030|
|CRP     |Standard4      |           110.415|
|CRP     |Standard5      |               NaN|
|CRP     |Standard6      |           103.050|
|CRP     |Standard7      |           101.090|

### Standard %CV Replicates (as reported by xPONENT)
|analyte |standard_level | cv_reported|
|:-------|:--------------|-----------:|
|CRP     |Standard1      |       0.000|
|CRP     |Standard2      |       6.406|
|CRP     |Standard3      |       0.601|
|CRP     |Standard4      |      18.258|
|CRP     |Standard5      |       0.000|
|CRP     |Standard6      |      13.315|
|CRP     |Standard7      |          NA|

## Control performance
_(no rows)_

## Quantifiability (unknowns only)
_This is the single most important number in the report -- an analyte where most samples are below the LLOQ cannot be reported as continuous regardless of CV quality._
|analyte |censor_flag |  n|  pct|
|:-------|:-----------|--:|----:|
|CRP     |below_lloq  |  6|  7.5|
|CRP     |nan         |  1|  1.2|
|CRP     |ok          | 73| 91.2|

### Invalidated unknown wells
|analyte | n_invalidated|
|:-------|-------------:|
|CRP     |             0|

## Bead counts
|analyte | min_count| median_count| max_count| n_below_threshold| threshold|
|:-------|---------:|------------:|---------:|-----------------:|---------:|
|CRP     |         0|           50|        50|                 1|        50|

---

# Characterization: Hu CRP saliva plt 3

## Run metadata
- Batch: 7-30-20 HU CRP box 3
- Run date: 2020-07-30 13:02:00
- Instrument SN: LX10014290402
- Protocol: 12-18-19 Human CRP saliva
- Kit: Human CRP (lot 3385047, expires 2020-09-30, Millipore)

### Analytes
|analyte |bead_id |units |curve_model          | r_squared|
|:-------|:-------|:-----|:--------------------|---------:|
|CRP     |19      |ng/ml |Logistic 5P Weighted |     0.859|

## Layout inventory
- Total wells: 94
|sample_type | n_wells|
|:-----------|-------:|
|background  |       2|
|standard    |      14|
|unknown     |      78|
- Replicate depth: confirmed 2 for all samples

## Standard curve health
_R² is the instrument-reported value, computed on the post-exclusion curve (xPONENT refits after invalidation)._
|analyte | nominal_range_low| nominal_range_high| effective_range_low| effective_range_high| n_levels_excluded|curve_model          | r_squared| n_standards_invalidated|
|:-------|-----------------:|------------------:|-------------------:|--------------------:|-----------------:|:--------------------|---------:|-----------------------:|
|CRP     |             0.012|                 50|               0.012|                   50|                 0|Logistic 5P Weighted |     0.859|                       0|

### Standard %Recovery (mean across replicates)
|analyte |standard_level | mean_recovery_pct|
|:-------|:--------------|-----------------:|
|CRP     |Standard1      |           102.375|
|CRP     |Standard2      |           100.600|
|CRP     |Standard3      |           101.470|
|CRP     |Standard4      |           101.225|
|CRP     |Standard5      |           101.090|
|CRP     |Standard6      |           100.175|
|CRP     |Standard7      |           109.495|

### Standard %CV Replicates (as reported by xPONENT)
|analyte |standard_level | cv_reported|
|:-------|:--------------|-----------:|
|CRP     |Standard1      |      18.133|
|CRP     |Standard2      |       4.901|
|CRP     |Standard3      |      17.036|
|CRP     |Standard4      |       4.594|
|CRP     |Standard5      |       2.686|
|CRP     |Standard6      |       8.260|
|CRP     |Standard7      |      31.429|

## Control performance
_(no rows)_

## Quantifiability (unknowns only)
_This is the single most important number in the report -- an analyte where most samples are below the LLOQ cannot be reported as continuous regardless of CV quality._
|analyte |censor_flag |  n| pct|
|:-------|:-----------|--:|---:|
|CRP     |ok          | 78| 100|

### Invalidated unknown wells
|analyte | n_invalidated|
|:-------|-------------:|
|CRP     |             0|

## Bead counts
|analyte | min_count| median_count| max_count| n_below_threshold| threshold|
|:-------|---------:|------------:|---------:|-----------------:|---------:|
|CRP     |        13|           50|        50|                 2|        50|

---

# Characterization: Hu CRP saliva plt 4

## Run metadata
- Batch: 7-30-20 HU CRP box 4
- Run date: 2020-07-30 13:47:00
- Instrument SN: LX10014290402
- Protocol: 12-18-19 Human CRP saliva
- Kit: Human CRP (lot 3385047, expires 2020-09-30, Millipore)

### Analytes
|analyte |bead_id |units |curve_model          | r_squared|
|:-------|:-------|:-----|:--------------------|---------:|
|CRP     |19      |ng/ml |Logistic 5P Weighted |      0.99|

## Layout inventory
- Total wells: 96
|sample_type | n_wells|
|:-----------|-------:|
|background  |       2|
|standard    |      14|
|unknown     |      80|
- Replicate depth: confirmed 2 for all samples

## Standard curve health
_R² is the instrument-reported value, computed on the post-exclusion curve (xPONENT refits after invalidation)._
|analyte | nominal_range_low| nominal_range_high| effective_range_low| effective_range_high| n_levels_excluded|curve_model          | r_squared| n_standards_invalidated|
|:-------|-----------------:|------------------:|-------------------:|--------------------:|-----------------:|:--------------------|---------:|-----------------------:|
|CRP     |             0.012|                 50|               0.012|                   50|                 0|Logistic 5P Weighted |      0.99|                       0|

### Standard %Recovery (mean across replicates)
|analyte |standard_level | mean_recovery_pct|
|:-------|:--------------|-----------------:|
|CRP     |Standard1      |            99.555|
|CRP     |Standard2      |           101.930|
|CRP     |Standard3      |            99.010|
|CRP     |Standard4      |            99.760|
|CRP     |Standard5      |           104.975|
|CRP     |Standard6      |           103.470|
|CRP     |Standard7      |           101.400|

### Standard %CV Replicates (as reported by xPONENT)
|analyte |standard_level | cv_reported|
|:-------|:--------------|-----------:|
|CRP     |Standard1      |       6.681|
|CRP     |Standard2      |       7.879|
|CRP     |Standard3      |       6.604|
|CRP     |Standard4      |       4.211|
|CRP     |Standard5      |      14.756|
|CRP     |Standard6      |      20.628|
|CRP     |Standard7      |       8.372|

## Control performance
_(no rows)_

## Quantifiability (unknowns only)
_This is the single most important number in the report -- an analyte where most samples are below the LLOQ cannot be reported as continuous regardless of CV quality._
|analyte |censor_flag |  n|  pct|
|:-------|:-----------|--:|----:|
|CRP     |below_lloq  |  6|  7.5|
|CRP     |ok          | 74| 92.5|

### Invalidated unknown wells
|analyte | n_invalidated|
|:-------|-------------:|
|CRP     |             0|

## Bead counts
|analyte | min_count| median_count| max_count| n_below_threshold| threshold|
|:-------|---------:|------------:|---------:|-----------------:|---------:|
|CRP     |        50|           50|        50|                 0|        50|

---

# Characterization: Hu CRP saliva plt 5

## Run metadata
- Batch: 8-4-20 HU CRP box 5
- Run date: 2020-08-04 11:02:00
- Instrument SN: LX10014290402
- Protocol: 12-18-19 Human CRP saliva
- Kit: Human CRP (lot 3385047, expires 2020-09-30, Millipore)

### Analytes
|analyte |bead_id |units |curve_model          | r_squared|
|:-------|:-------|:-----|:--------------------|---------:|
|CRP     |19      |ng/ml |Logistic 5P Weighted |     0.993|

## Layout inventory
- Total wells: 96
|sample_type | n_wells|
|:-----------|-------:|
|background  |       2|
|standard    |      14|
|unknown     |      80|
- Replicate depth: confirmed 2 for all samples

## Standard curve health
_R² is the instrument-reported value, computed on the post-exclusion curve (xPONENT refits after invalidation)._
|analyte | nominal_range_low| nominal_range_high| effective_range_low| effective_range_high| n_levels_excluded|curve_model          | r_squared| n_standards_invalidated|
|:-------|-----------------:|------------------:|-------------------:|--------------------:|-----------------:|:--------------------|---------:|-----------------------:|
|CRP     |             0.012|                 50|               0.049|                   50|                 1|Logistic 5P Weighted |     0.993|                       1|

### Standard %Recovery (mean across replicates)
|analyte |standard_level | mean_recovery_pct|
|:-------|:--------------|-----------------:|
|CRP     |Standard1      |           102.055|
|CRP     |Standard2      |           101.645|
|CRP     |Standard3      |            98.775|
|CRP     |Standard4      |           101.245|
|CRP     |Standard5      |           100.920|
|CRP     |Standard6      |           104.500|
|CRP     |Standard7      |           100.000|

### Standard %CV Replicates (as reported by xPONENT)
|analyte |standard_level | cv_reported|
|:-------|:--------------|-----------:|
|CRP     |Standard1      |      20.677|
|CRP     |Standard2      |       2.631|
|CRP     |Standard3      |       6.849|
|CRP     |Standard4      |       4.407|
|CRP     |Standard5      |      10.624|
|CRP     |Standard6      |      19.194|
|CRP     |Standard7      |       0.000|

## Control performance
_(no rows)_

## Quantifiability (unknowns only)
_This is the single most important number in the report -- an analyte where most samples are below the LLOQ cannot be reported as continuous regardless of CV quality._
|analyte |censor_flag |  n|  pct|
|:-------|:-----------|--:|----:|
|CRP     |below_lloq  | 37| 46.2|
|CRP     |ok          | 43| 53.8|

### Invalidated unknown wells
|analyte | n_invalidated|
|:-------|-------------:|
|CRP     |             0|

## Bead counts
|analyte | min_count| median_count| max_count| n_below_threshold| threshold|
|:-------|---------:|------------:|---------:|-----------------:|---------:|
|CRP     |        20|           50|        50|                17|        50|

---

# Characterization: Hu CRP saliva plt 6

## Run metadata
- Batch: 8-4-20 HU CRP box 6
- Run date: 2020-08-04 12:58:00
- Instrument SN: LX10014290402
- Protocol: 12-18-19 Human CRP saliva
- Kit: Human CRP (lot 3385047, expires 2020-09-30, Millipore)

### Analytes
|analyte |bead_id |units |curve_model          | r_squared|
|:-------|:-------|:-----|:--------------------|---------:|
|CRP     |19      |ng/ml |Logistic 5P Weighted |     0.998|

## Layout inventory
- Total wells: 96
|sample_type | n_wells|
|:-----------|-------:|
|background  |       2|
|standard    |      14|
|unknown     |      80|
- Replicate depth: confirmed 2 for all samples

## Standard curve health
_R² is the instrument-reported value, computed on the post-exclusion curve (xPONENT refits after invalidation)._
|analyte | nominal_range_low| nominal_range_high| effective_range_low| effective_range_high| n_levels_excluded|curve_model          | r_squared| n_standards_invalidated|
|:-------|-----------------:|------------------:|-------------------:|--------------------:|-----------------:|:--------------------|---------:|-----------------------:|
|CRP     |             0.012|                 50|               0.049|                   50|                 1|Logistic 5P Weighted |     0.998|                       1|

### Standard %Recovery (mean across replicates)
|analyte |standard_level | mean_recovery_pct|
|:-------|:--------------|-----------------:|
|CRP     |Standard1      |           103.600|
|CRP     |Standard2      |            98.630|
|CRP     |Standard3      |           104.160|
|CRP     |Standard4      |            96.645|
|CRP     |Standard5      |           102.310|
|CRP     |Standard6      |            99.875|
|CRP     |Standard7      |           100.000|

### Standard %CV Replicates (as reported by xPONENT)
|analyte |standard_level | cv_reported|
|:-------|:--------------|-----------:|
|CRP     |Standard1      |      19.633|
|CRP     |Standard2      |       3.919|
|CRP     |Standard3      |      10.616|
|CRP     |Standard4      |       2.331|
|CRP     |Standard5      |       0.221|
|CRP     |Standard6      |       4.526|
|CRP     |Standard7      |       0.000|

## Control performance
_(no rows)_

## Quantifiability (unknowns only)
_This is the single most important number in the report -- an analyte where most samples are below the LLOQ cannot be reported as continuous regardless of CV quality._
|analyte |censor_flag |  n| pct|
|:-------|:-----------|--:|---:|
|CRP     |below_lloq  |  8|  10|
|CRP     |ok          | 72|  90|

### Invalidated unknown wells
|analyte | n_invalidated|
|:-------|-------------:|
|CRP     |             0|

## Bead counts
|analyte | min_count| median_count| max_count| n_below_threshold| threshold|
|:-------|---------:|------------:|---------:|-----------------:|---------:|
|CRP     |        12|           50|        50|                33|        50|

---

# Characterization: Hu CRP saliva plt 8

## Run metadata
- Batch: 8-5-20 HU CRP box 8
- Run date: 2020-08-05 14:03:59
- Instrument SN: LX10014290402
- Protocol: 12-18-19 Human CRP saliva
- Kit: Human CRP (lot 3385047, expires 2020-09-30, Millipore)

### Analytes
|analyte |bead_id |units |curve_model          | r_squared|
|:-------|:-------|:-----|:--------------------|---------:|
|CRP     |19      |ng/ml |Logistic 5P Weighted |     0.889|

## Layout inventory
- Total wells: 56
|sample_type | n_wells|
|:-----------|-------:|
|background  |       2|
|standard    |      14|
|unknown     |      40|
- Replicate depth: confirmed 2 for all samples

## Standard curve health
_R² is the instrument-reported value, computed on the post-exclusion curve (xPONENT refits after invalidation)._
|analyte | nominal_range_low| nominal_range_high| effective_range_low| effective_range_high| n_levels_excluded|curve_model          | r_squared| n_standards_invalidated|
|:-------|-----------------:|------------------:|-------------------:|--------------------:|-----------------:|:--------------------|---------:|-----------------------:|
|CRP     |             0.012|                 50|               0.012|                3.125|                 2|Logistic 5P Weighted |     0.889|                       2|

### Standard %Recovery (mean across replicates)
|analyte |standard_level | mean_recovery_pct|
|:-------|:--------------|-----------------:|
|CRP     |Standard1      |            94.920|
|CRP     |Standard2      |           107.960|
|CRP     |Standard3      |           100.805|
|CRP     |Standard4      |            95.830|
|CRP     |Standard5      |           104.345|
|CRP     |Standard6      |            98.960|
|CRP     |Standard7      |           101.510|

### Standard %CV Replicates (as reported by xPONENT)
|analyte |standard_level | cv_reported|
|:-------|:--------------|-----------:|
|CRP     |Standard1      |       0.000|
|CRP     |Standard2      |       0.000|
|CRP     |Standard3      |       4.076|
|CRP     |Standard4      |       0.128|
|CRP     |Standard5      |       0.723|
|CRP     |Standard6      |       1.375|
|CRP     |Standard7      |          NA|

## Control performance
_(no rows)_

## Quantifiability (unknowns only)
_This is the single most important number in the report -- an analyte where most samples are below the LLOQ cannot be reported as continuous regardless of CV quality._
|analyte |censor_flag |  n| pct|
|:-------|:-----------|--:|---:|
|CRP     |below_lloq  |  4|  10|
|CRP     |ok          | 36|  90|

### Invalidated unknown wells
|analyte | n_invalidated|
|:-------|-------------:|
|CRP     |             0|

## Bead counts
|analyte | min_count| median_count| max_count| n_below_threshold| threshold|
|:-------|---------:|------------:|---------:|-----------------:|---------:|
|CRP     |        43|           50|        50|                 1|        50|

---

## Sheets not characterized

- **Human_cytokine_rawdata.xlsx :: HU cytokine saliva plt 7**: Unknown ID map is incomplete: missing Unknown40 (map has 39 entries, Result references 40 distinct UnknownN). This usually means Median has the SAME sample label typed at two different wells, which breaks positional inference when no Deducing IDs block exists -- check Median for a duplicated label and resolve against the plate loading manifest.
- **human_cvd_panel_crp_raw_data.xlsx :: Hu CRP saliva plt 7**: Unknown ID map is incomplete: missing Unknown40 (map has 39 entries, Result references 40 distinct UnknownN). This usually means Median has the SAME sample label typed at two different wells, which breaks positional inference when no Deducing IDs block exists -- check Median for a duplicated label and resolve against the plate loading manifest.
