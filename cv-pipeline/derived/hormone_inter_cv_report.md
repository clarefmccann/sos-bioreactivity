# Hormone inter-assay CV
_Generated 2026-08-03 15:38:33_

Computed directly from the `<hormone> inter-assay CV` sheets in the Masterfile: each sheet is
already organized as one control-well block per plate, so this is SD/mean x 100 of the per-plate
control means across plates -- the same method used for cytokines/CRP.

`shared_or_redo` plates are trays shared with a different study (`Mixedplate_...`) or reruns
(`Redoplate_...`). Both an all-plates and an excluding-shared/redo summary are reported below;
which to use in a methods section is a judgment call, not decided here.

## Summary
|hormone      |control_level |plate_set                       | n_plates|     cv| mean_conc|
|:------------|:-------------|:-------------------------------|--------:|------:|---------:|
|Cortisol     |CtrlH         |all_plates                      |        8| 11.441|     1.059|
|Cortisol     |CtrlL         |all_plates                      |        8| 17.313|     0.112|
|DHEA         |CtrlH         |all_plates                      |        8|  7.906|   486.957|
|DHEA         |CtrlL         |all_plates                      |        8| 25.117|    18.696|
|Estradiol    |CtrlH         |all_plates                      |        3|  4.940|    17.056|
|Estradiol    |CtrlL         |all_plates                      |        3|  6.414|     6.705|
|Testosterone |CtrlH         |all_plates                      |        8|  3.198|   186.080|
|Testosterone |CtrlL         |all_plates                      |        8| 18.669|    17.319|
|Cortisol     |CtrlH         |excluding_shared_or_redo_plates |        7| 11.693|     1.071|
|Cortisol     |CtrlL         |excluding_shared_or_redo_plates |        7| 18.541|     0.113|
|DHEA         |CtrlH         |excluding_shared_or_redo_plates |        7|  8.063|   491.113|
|DHEA         |CtrlL         |excluding_shared_or_redo_plates |        7| 21.343|    17.579|
|Testosterone |CtrlH         |excluding_shared_or_redo_plates |        7|  2.866|   184.889|
|Testosterone |CtrlL         |excluding_shared_or_redo_plates |        7| 14.826|    16.504|

## Per-plate control detail
|hormone      |plate                                                           |control_level | mean_conc| cv_reported_intra|shared_or_redo |
|:------------|:---------------------------------------------------------------|:-------------|---------:|-----------------:|:--------------|
|DHEA         |SOS_09.01.2020_DHEA_tray1_Allissa                               |CtrlH         |   483.059|             1.086|FALSE          |
|DHEA         |SOS_09.01.2020_DHEA_tray1_Allissa                               |CtrlL         |    16.016|            34.229|FALSE          |
|DHEA         |SOS_09.15.2020_DHEA_tray1_Allissa                               |CtrlH         |   459.839|             3.688|FALSE          |
|DHEA         |SOS_09.15.2020_DHEA_tray1_Allissa                               |CtrlL         |    16.654|             3.225|FALSE          |
|DHEA         |SOS_09.22.2020_DHEA_tray1_Allissa                               |CtrlH         |   450.995|             2.583|FALSE          |
|DHEA         |SOS_09.22.2020_DHEA_tray1_Allissa                               |CtrlL         |    14.010|            40.313|FALSE          |
|DHEA         |SOS_10.03.2020_DHEA_tray1_Allissa                               |CtrlH         |   486.912|             0.601|FALSE          |
|DHEA         |SOS_10.03.2020_DHEA_tray1_Allissa                               |CtrlL         |    24.350|             2.419|FALSE          |
|DHEA         |SOS_10.13.2020_DHEA_tray1_Allissa                               |CtrlH         |   573.184|             1.543|FALSE          |
|DHEA         |SOS_10.13.2020_DHEA_tray1_Allissa                               |CtrlL         |    20.625|             6.067|FALSE          |
|DHEA         |SOS_10.27.2020_DHEA_tray1_Allissa                               |CtrlH         |   491.496|             2.872|FALSE          |
|DHEA         |SOS_10.27.2020_DHEA_tray1_Allissa                               |CtrlL         |    13.934|             4.226|FALSE          |
|DHEA         |SOS_11.3.2020_DHEA_Tray1_Maddie                                 |CtrlH         |   492.307|             4.338|FALSE          |
|DHEA         |SOS_11.3.2020_DHEA_Tray1_Maddie                                 |CtrlL         |    17.464|             3.426|FALSE          |
|DHEA         |Mixedplate_SOS_GBT2Hair_11.21.2020_DHEA_Lotte                   |CtrlH         |   457.867|             2.922|TRUE           |
|DHEA         |Mixedplate_SOS_GBT2Hair_11.21.2020_DHEA_Lotte                   |CtrlL         |    26.517|            18.398|TRUE           |
|Testosterone |SOS_09.01.2020_testo_tray1_Allissa                              |CtrlH         |   186.341|             6.632|FALSE          |
|Testosterone |SOS_09.01.2020_testo_tray1_Allissa                              |CtrlL         |    17.787|             0.233|FALSE          |
|Testosterone |SOS_09.15.2020_testo_tray1_Allissa                              |CtrlH         |   186.051|             0.664|FALSE          |
|Testosterone |SOS_09.15.2020_testo_tray1_Allissa                              |CtrlL         |    21.043|             7.773|FALSE          |
|Testosterone |SOS_09.22.2020_testo_tray1_Maddie                               |CtrlH         |   181.282|             2.244|FALSE          |
|Testosterone |SOS_09.22.2020_testo_tray1_Maddie                               |CtrlL         |    15.912|            11.355|FALSE          |
|Testosterone |SOS_10.03.2020_testo_tray1_Allissa                              |CtrlH         |   195.406|             6.373|FALSE          |
|Testosterone |SOS_10.03.2020_testo_tray1_Allissa                              |CtrlL         |    17.057|             6.382|FALSE          |
|Testosterone |SOS_10.13.2020_testo_tray1_Allissa                              |CtrlH         |   180.024|             5.126|FALSE          |
|Testosterone |SOS_10.13.2020_testo_tray1_Allissa                              |CtrlL         |    13.762|             9.829|FALSE          |
|Testosterone |SOS_10.27.2020_Testo_tray1_Maddie                               |CtrlH         |   180.699|             1.245|FALSE          |
|Testosterone |SOS_10.27.2020_Testo_tray1_Maddie                               |CtrlL         |    14.323|            15.547|FALSE          |
|Testosterone |SOS_11.03.2020_Testo_Tray1_Alexis                               |CtrlH         |   184.419|             9.336|FALSE          |
|Testosterone |SOS_11.03.2020_Testo_Tray1_Alexis                               |CtrlL         |    15.642|             2.883|FALSE          |
|Testosterone |Mixedplate_SOS_Stu_GBT2Hair_11.21.2020_Testo_Lotte              |CtrlH         |   194.416|             9.152|TRUE           |
|Testosterone |Mixedplate_SOS_Stu_GBT2Hair_11.21.2020_Testo_Lotte              |CtrlL         |    23.029|             7.059|TRUE           |
|Cortisol     |SOS_09.01.2020_Cortisol_Tray1_Scott                             |CtrlH         |     1.282|             6.389|FALSE          |
|Cortisol     |SOS_09.01.2020_Cortisol_Tray1_Scott                             |CtrlL         |     0.105|             6.114|FALSE          |
|Cortisol     |SOS_09.15.2020_Cortisol_Tray1_Scott                             |CtrlH         |     1.003|             0.747|FALSE          |
|Cortisol     |SOS_09.15.2020_Cortisol_Tray1_Scott                             |CtrlL         |     0.094|             5.144|FALSE          |
|Cortisol     |SOS_09.24.2020_Cortisol_Tray1_Scott                             |CtrlH         |     1.197|             2.469|FALSE          |
|Cortisol     |SOS_09.24.2020_Cortisol_Tray1_Scott                             |CtrlL         |     0.138|             4.937|FALSE          |
|Cortisol     |SOS_10.03.2020_Cortisol_Lotte                                   |CtrlH         |     1.009|             1.972|FALSE          |
|Cortisol     |SOS_10.03.2020_Cortisol_Lotte                                   |CtrlL         |     0.117|             4.366|FALSE          |
|Cortisol     |SOS_10.13.2020_Cortisol_Tray1_Scott                             |CtrlH         |     1.075|             3.042|FALSE          |
|Cortisol     |SOS_10.13.2020_Cortisol_Tray1_Scott                             |CtrlL         |     0.086|            11.934|FALSE          |
|Cortisol     |SOS_10.27.2020_Cortisol_Tray1_Scott                             |CtrlH         |     1.004|             3.091|FALSE          |
|Cortisol     |SOS_10.27.2020_Cortisol_Tray1_Scott                             |CtrlL         |     0.107|             3.359|FALSE          |
|Cortisol     |SOS_11.03.2020_Cortisol_Tray1_Scott                             |CtrlH         |     0.927|             4.917|FALSE          |
|Cortisol     |SOS_11.03.2020_Cortisol_Tray1_Scott                             |CtrlL         |     0.141|             6.401|FALSE          |
|Cortisol     |Mixedplate_SOS_Stu_11.21.2020_Cortisol_Lotte                    |CtrlH         |     0.972|             4.368|TRUE           |
|Cortisol     |Mixedplate_SOS_Stu_11.21.2020_Cortisol_Lotte                    |CtrlL         |     0.108|             4.487|TRUE           |
|Estradiol    |Mixedplate_TAGSalivaW3_SOS_GBT2_EGDS_09.08.2020_Estradiol_Lotte |CtrlH         |    17.046|            11.614|TRUE           |
|Estradiol    |Mixedplate_TAGSalivaW3_SOS_GBT2_EGDS_09.08.2020_Estradiol_Lotte |CtrlL         |     6.702|             0.042|TRUE           |
|Estradiol    |Mixedplate_GBT2Hair_SOS_11.23.2020_Estradiol_Lotte              |CtrlH         |    17.904|             7.897|TRUE           |
|Estradiol    |Mixedplate_GBT2Hair_SOS_11.23.2020_Estradiol_Lotte              |CtrlL         |     7.136|             3.033|TRUE           |
|Estradiol    |Redoplate_SOS_11.28.2020_Estradiol_Lotte                        |CtrlH         |    16.219|             3.492|TRUE           |
|Estradiol    |Redoplate_SOS_11.28.2020_Estradiol_Lotte                        |CtrlL         |     6.276|             8.961|TRUE           |
