# Rho by key repeating vs neither repeating

Raw = share of consecutive within-block trial pairs that repeat (key: A->A or B->B; neither: skip->skip).
Chance = expected from the participant's own frequencies (key: pA^2 + pB^2; neither: pNeither^2).
Quartiles are by excess = raw - chance, computed separately for key and neither, within session.

## Participants with fewer than 10 neither choices

|Session | Participants| Too few neither choices|
|:-------|------------:|-----------------------:|
|time1   |          185|                      71|
|time2   |          185|                      71|

## All participants

### time1: quartiles of excess repeating

| Quartile| Key n| Key raw| Key chance| Key mean rho| Neither n| Neither raw| Neither chance| Neither mean rho|
|--------:|-----:|-------:|----------:|------------:|---------:|-----------:|--------------:|----------------:|
|        1|    47|   0.338|      0.388|        0.089|        47|       0.149|          0.166|            0.174|
|        2|    46|   0.255|      0.267|        0.241|        46|       0.069|          0.070|            0.265|
|        3|    46|   0.237|      0.229|        0.271|        46|       0.214|          0.214|            0.162|
|        4|    46|   0.418|      0.368|        0.363|        46|       0.205|          0.182|            0.360|

### time2: quartiles of excess repeating

| Quartile| Key n| Key raw| Key chance| Key mean rho| Neither n| Neither raw| Neither chance| Neither mean rho|
|--------:|-----:|-------:|----------:|------------:|---------:|-----------:|--------------:|----------------:|
|        1|    47|   0.294|      0.346|        0.189|        47|       0.187|          0.206|            0.229|
|        2|    46|   0.234|      0.247|        0.236|        46|       0.075|          0.076|            0.260|
|        3|    46|   0.256|      0.244|        0.295|        46|       0.213|          0.212|            0.273|
|        4|    46|   0.448|      0.386|        0.356|        46|       0.185|          0.167|            0.314|

### Correlation and joint standardized regression: rho ~ key excess + neither excess

|time  |   n| r_key| p_r_key| r_neither| p_r_neither| beta_key| p_beta_key| beta_neither| p_beta_neither| r2_both|
|:-----|---:|-----:|-------:|---------:|-----------:|--------:|----------:|------------:|--------------:|-------:|
|time1 | 185| 0.558|       0|     0.352|           0|    0.499|          0|        0.217|          0.001|   0.355|
|time2 | 185| 0.559|       0|     0.256|           0|    0.529|          0|        0.150|          0.016|   0.333|

### Top key quartile vs top neither quartile (participants in both top groups left out)

|time  | n_top_key| n_top_neither| n_in_both| mean_rho_top_key| mean_rho_top_neither| difference| ci_low| ci_high|     t|     df| p_welch| p_wilcoxon|
|:-----|---------:|-------------:|---------:|----------------:|--------------------:|----------:|------:|-------:|-----:|------:|-------:|----------:|
|time1 |        33|            33|        13|            0.298|                0.293|      0.005| -0.086|   0.096| 0.108| 63.978|   0.914|      0.980|
|time2 |        30|            30|        16|            0.354|                0.289|      0.065| -0.017|   0.147| 1.605| 44.689|   0.116|      0.236|

### Average rho check: intercept = rho expected at chance-level repeating

|time  |   n| mean_rho| mean_key_excess| p_key_excess| mean_neither_excess| p_neither_excess| intercept_key_only| intercept_both| intercept_both_low| intercept_both_high|
|:-----|---:|--------:|---------------:|------------:|-------------------:|----------------:|------------------:|--------------:|------------------:|-------------------:|
|time1 | 185|    0.240|          -0.001|        0.659|               0.001|            0.512|              0.245|          0.242|              0.212|               0.271|
|time2 | 185|    0.269|           0.002|        0.584|              -0.001|            0.659|              0.265|          0.266|              0.249|               0.283|

## Only participants with >= 10 neither choices

### time1: quartiles of excess repeating

| Quartile| Key n| Key raw| Key chance| Key mean rho| Neither n| Neither raw| Neither chance| Neither mean rho|
|--------:|-----:|-------:|----------:|------------:|---------:|-----------:|--------------:|----------------:|
|        1|    29|   0.219|      0.255|        0.183|        29|       0.170|          0.195|            0.143|
|        2|    29|   0.130|      0.138|        0.234|        29|       0.248|          0.252|            0.299|
|        3|    28|   0.181|      0.175|        0.325|        28|       0.356|          0.351|            0.297|
|        4|    28|   0.317|      0.273|        0.384|        28|       0.259|          0.227|            0.385|

### time2: quartiles of excess repeating

| Quartile| Key n| Key raw| Key chance| Key mean rho| Neither n| Neither raw| Neither chance| Neither mean rho|
|--------:|-----:|-------:|----------:|------------:|---------:|-----------:|--------------:|----------------:|
|        1|    29|   0.218|      0.267|        0.200|        29|       0.188|          0.214|            0.218|
|        2|    29|   0.146|      0.161|        0.249|        29|       0.302|          0.308|            0.247|
|        3|    28|   0.108|      0.104|        0.290|        28|       0.329|          0.326|            0.297|
|        4|    28|   0.321|      0.268|        0.347|        28|       0.248|          0.223|            0.323|

### Correlation and joint standardized regression: rho ~ key excess + neither excess

|time  |   n| r_key| p_r_key| r_neither| p_r_neither| beta_key| p_beta_key| beta_neither| p_beta_neither| r2_both|
|:-----|---:|-----:|-------:|---------:|-----------:|--------:|----------:|------------:|--------------:|-------:|
|time1 | 114| 0.514|       0|     0.494|           0|    0.365|          0|        0.330|          0.000|   0.351|
|time2 | 114| 0.477|       0|     0.384|           0|    0.399|          0|        0.268|          0.002|   0.293|

### Top key quartile vs top neither quartile (participants in both top groups left out)

|time  | n_top_key| n_top_neither| n_in_both| mean_rho_top_key| mean_rho_top_neither| difference| ci_low| ci_high|      t|     df| p_welch| p_wilcoxon|
|:-----|---------:|-------------:|---------:|----------------:|--------------------:|----------:|------:|-------:|------:|------:|-------:|----------:|
|time1 |        18|            18|        10|            0.311|                0.313|     -0.003| -0.125|   0.120| -0.045| 33.999|   0.964|      0.767|
|time2 |        16|            16|        12|            0.321|                0.280|      0.041| -0.052|   0.135|  0.900| 27.542|   0.376|      0.515|

### Average rho check: intercept = rho expected at chance-level repeating

|time  |   n| mean_rho| mean_key_excess| p_key_excess| mean_neither_excess| p_neither_excess| intercept_key_only| intercept_both| intercept_both_low| intercept_both_high|
|:-----|---:|--------:|---------------:|------------:|-------------------:|----------------:|------------------:|--------------:|------------------:|-------------------:|
|time1 | 114|    0.280|           0.001|        0.816|               0.002|            0.456|              0.278|          0.273|              0.240|               0.306|
|time2 | 114|    0.271|          -0.002|        0.574|              -0.001|            0.534|              0.274|          0.275|              0.256|               0.294|

