# PROC PYTHON & PROC R — Hands-On Practice Exercises

**Workshop:** Open-Source Integration in SAS Viya
**Script to keep open:** `demo_procR_clinical.sas`
**Work library:** All outputs go to `WORK` unless stated otherwise.

Each exercise has a difficulty tag:
🟢 **Starter** — modify one or two values in existing code
🟡 **Intermediate** — write a new block based on the pattern shown
🔴 **Advanced** — extend or combine concepts independently

---

## Exercise 1 — Environment check
### Topic: Section 0 · PROC PYTHON · PROC R

**Context:** You ran the environment check in Section 0 and saw that Python has 378 packages and R has 150.

---

### 1a 🟢 Filter the Python package list

The current code prints all 378 packages. Change it so it only prints packages whose name **starts with `s`** (case-insensitive).

**Hint:** Add one line inside the `for p in pkgs:` loop using an `if` statement.

<details>
<summary>Solution</summary>

```python
proc python;
submit;
import sys
from importlib.metadata import distributions

pkgs = sorted([f"  {d.name:<30} {d.version}" for d in distributions()])
print("Packages starting with 's':")
for p in pkgs:
    if p.strip().lower().startswith('s'):
        print(p)
endsubmit;
run;
```

</details>

---

### 1b 🟢 Check for a specific R package

Write a PROC R step that checks whether `survminer` is installed and prints either `"survminer is available"` or `"survminer is NOT installed"` to the SAS log.

**Hint:** Use `"survminer" %in% rownames(installed.packages())`.

<details>
<summary>Solution</summary>

```sas
proc r;
submit;
if ("survminer" %in% rownames(installed.packages())) {
    cat("survminer is available\n")
} else {
    cat("survminer is NOT installed\n")
}
endsubmit;
run;
```

</details>

---

### 1c 🟡 Return the R version to a SAS macro variable

Write a PROC R step that reads the R major and minor version numbers and stores them in SAS macro variables `&r_major` and `&r_minor`. Then write a `%put` statement to display them.

**Hint:** Use `symput()` and `R.version$major` / `R.version$minor`.

<details>
<summary>Solution</summary>

```sas
proc r;
submit;
symput("r_major", R.version$major)
symput("r_minor", R.version$minor)
endsubmit;
run;

%put NOTE: R version is &r_major..&r_minor;
```

</details>

---

## Exercise 2 — Callback methods
### Topic: Section 2 · sd2df · df2sd · symget · symput · show

**Context:** Section 2 showed how to pass ADSL data to Python and R, compute a summary, and return it to SAS. `work.adsl`, `work.adtte`, and `work.adlb` are available from Section 1.

---

### 2a 🟢 Switch the treatment arm

The current demo filters for `DrugA`. Change `%let trt_filter = Placebo;` and re-run Section 2. Confirm that `&py_n_subjects` and `&r_n_subjects` both equal 10.

**No code change needed** — just update the macro variable and observe the output.

---

### 2b 🟡 Add a new summary statistic in Python

In Section 2a, the Python summary computes `N`, `MeanAge`, `SDAge`, and `MeanBMI`. Add a fifth column: `PctFemale` — the percentage of subjects who are female (SEX == 'F'), rounded to 1 decimal place.

**Hint:** Add a lambda function to the `.agg()` call:
```python
PctFemale=("SEX", lambda x: round(100 * sum(x == 'F') / len(x), 1))
```

<details>
<summary>Solution</summary>

```python
proc python;
submit;
import pandas as pd

trt  = SAS.symget("trt_filter")
adsl = SAS.sd2df("work.adsl")
sub  = adsl[adsl["TRT01P"] == trt]

stats = (sub.groupby("TRT01P")
           .agg(N         = ("USUBJID", "count"),
                MeanAge   = ("AGE",     "mean"),
                SDAge     = ("AGE",     "std"),
                MeanBMI   = ("BMI",     "mean"),
                PctFemale = ("SEX",     lambda x: round(100 * sum(x == 'F') / len(x), 1)))
           .round(1)
           .reset_index())

SAS.df2sd(stats, "work.py_demo_stats2")
SAS.show(stats)
endsubmit;
run;
```

</details>

---

### 2c 🟡 Replicate 2b in R

Write the equivalent PROC R step that produces the same five-column summary (`N`, `MeanAge`, `SDAge`, `MeanBMI`, `PctFemale`) for the treatment arm in `&trt_filter`. Store the result in `work.r_demo_stats2`.

<details>
<summary>Solution</summary>

```sas
proc r;
submit;
library(dplyr)

trt  <- symget("trt_filter")
adsl <- sd2df("work.adsl")

stats <- adsl %>%
  filter(TRT01P == trt) %>%
  summarise(
    TRT01P    = first(TRT01P),
    N         = n(),
    MeanAge   = round(mean(AGE,   na.rm=TRUE), 1),
    SDAge     = round(sd(AGE,     na.rm=TRUE), 1),
    MeanBMI   = round(mean(BMI,   na.rm=TRUE), 1),
    PctFemale = round(100 * sum(SEX == "F") / n(), 1)
  )

df2sd(stats, "work.r_demo_stats2")
show(stats, title=paste("Summary with % Female --", trt))
endsubmit;
run;
```

</details>

---

### 2d 🔴 Two-way macro variable flow

Write a SAS program that:
1. Sets `%let trt_filter = DrugA;`
2. Calls PROC R to compute the mean baseline weight (`WEIGHTBL`) for that treatment arm
3. Stores the result in a SAS macro variable called `&r_mean_weight`
4. Uses `&r_mean_weight` as the title in a `PROC PRINT` of `work.adsl`

Everything should work by changing only the `%let trt_filter` value.

<details>
<summary>Solution</summary>

```sas
%let trt_filter = DrugA;

proc r;
submit;
library(dplyr)
trt <- symget("trt_filter")
adsl <- sd2df("work.adsl")
mean_wt <- round(mean(adsl$WEIGHTBL[adsl$TRT01P == trt], na.rm=TRUE), 1)
symput("r_mean_weight", as.character(mean_wt))
endsubmit;
run;

%put NOTE: Mean baseline weight for &trt_filter = &r_mean_weight kg;

proc print data=work.adsl noobs label;
  where TRT01P = "&trt_filter";
  title "ADSL -- &trt_filter (Mean Baseline Weight: &r_mean_weight kg)";
run;
title;
```

</details>

---

## Exercise 3 — Visualisation
### Topic: Section 3 · matplotlib · ggplot2 · rplot()

---

### 3a 🟢 Change the ggplot2 color palette

In Section 3b, the age histogram uses `"#0072B2"` (blue) and `"#E69F00"` (orange). Change the colors to red (`"#CC0000"`) for DrugA and grey (`"#999999"`) for Placebo. Re-run the plot.

**One line change** in `scale_fill_manual(values=c(...))`.

---

### 3b 🟡 Add a race distribution plot in R

Write a fourth `rplot()` call in Section 3b that shows the racial distribution across the full ADSL dataset (both arms combined) as a horizontal bar chart, sorted from most to least common.

**Hint:** Use `geom_bar()` + `coord_flip()` + `fct_infreq()` from the `forcats` package (part of tidyverse).

<details>
<summary>Solution</summary>

```r
proc r;
submit;
library(ggplot2)
library(dplyr)
library(forcats)

adsl <- sd2df("work.adsl")

p4 <- ggplot(adsl, aes(y=fct_infreq(RACE))) +
  geom_bar(fill="#0072B2", alpha=0.8) +
  theme_minimal(base_size=12) +
  labs(title="Racial Distribution (All Subjects)",
       y="Race", x="Count")
rplot(p4)
endsubmit;
run;
```

</details>

---

### 3c 🟡 Python: scatter plot of BMI vs Age

Using PROC PYTHON and matplotlib, create a scatter plot of `BMI` (y-axis) versus `AGE` (x-axis) from `work.adsl`. Color the points by `TRT01P`. Display in the Results window with `SAS.show()`.

<details>
<summary>Solution</summary>

```python
proc python;
submit;
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import pandas as pd

adsl = SAS.sd2df("work.adsl")
colors = {"DrugA": "#0072B2", "Placebo": "#E69F00"}

fig, ax = plt.subplots(figsize=(7, 5))
for trt, grp in adsl.groupby("TRT01P"):
    ax.scatter(grp["AGE"], grp["BMI"],
               label=trt, color=colors.get(trt, "grey"),
               alpha=0.75, s=60, edgecolors='white', linewidths=0.5)

ax.set_xlabel("Age (years)")
ax.set_ylabel("BMI (kg/m²)")
ax.set_title("BMI vs Age by Treatment")
ax.legend(title="Treatment")
plt.tight_layout()
SAS.show(fig)
endsubmit;
run;
```

</details>

---

### 3d 🔴 Mean change from baseline line plot using ADLB

Write a PROC R step that:
1. Reads `work.adlb` and filters to `PARAM = "HbA1c (%)"`
2. Computes mean `CHG` (change from baseline) per `TRT01P` and `VISIT`
3. Produces a line plot with `VISIT` on the x-axis, mean `CHG` on y-axis, colored by `TRT01P`
4. Adds a horizontal dashed reference line at y = 0
5. Returns the mean CHG at WEEK24 for each arm as `work.chg_week24`

<details>
<summary>Solution</summary>

```sas
proc r;
submit;
library(ggplot2)
library(dplyr)

adlb <- sd2df("work.adlb")

df <- adlb %>%
  filter(PARAM == "HbA1c (%)") %>%
  mutate(VISIT = factor(VISIT, levels=c("WEEK12","WEEK24")))

means <- df %>%
  group_by(TRT01P, VISIT) %>%
  summarise(MeanCHG = round(mean(CHG, na.rm=TRUE), 2), .groups="drop")

p <- ggplot(means, aes(x=VISIT, y=MeanCHG,
                       group=TRT01P, color=TRT01P)) +
  geom_line(linewidth=1.2) +
  geom_point(size=3) +
  geom_hline(yintercept=0, linetype="dashed", color="grey50") +
  scale_color_manual(values=c("#0072B2","#E69F00")) +
  theme_minimal(base_size=12) +
  labs(title="Mean HbA1c Change from Baseline",
       x="Visit", y="Mean Change (%)", color="Treatment")
rplot(p)

# Return WEEK24 results to SAS
chg24 <- means %>% filter(VISIT == "WEEK24")
df2sd(chg24, "work.chg_week24")
show(chg24, title="Mean Change at WEEK24")
endsubmit;
run;

proc print data=work.chg_week24 noobs label;
  title "HbA1c Mean Change from Baseline at WEEK24";
run;
title;
```

</details>

---

## Exercise 4 — Kaplan-Meier (PROC R)
### Topic: Section 4 · survival · ggplot2

---

### 4a 🟢 Change the color palette

In Section 4, the KM curve uses `"#0072B2"` and `"#E69F00"`. Change both colors to the standard red/blue clinical palette: `"#E41A1C"` (red) and `"#377EB8"` (blue). Both `scale_color_manual` and `scale_fill_manual` need updating.

---

### 4b 🟡 KM curve for a single arm

Write a PROC R step that produces a KM curve for **DrugA only** (no stratification). Use `survfit(Surv(AVAL, CNSR==0) ~ 1, data=sub)`. Annotate the median survival on the plot using `annotate()`.

**Hint:** The median is `summary(km_fit)$table["median"]`.

<details>
<summary>Solution</summary>

```sas
proc r;
submit;
library(survival)
library(ggplot2)

adtte <- sd2df("work.adtte")
sub   <- adtte[adtte$TRT01P == "DrugA", ]

km_fit <- survfit(Surv(AVAL, CNSR==0) ~ 1, data=sub)

km_df <- data.frame(
  time  = km_fit$time,
  surv  = km_fit$surv,
  upper = km_fit$upper,
  lower = km_fit$lower
)

med_os <- summary(km_fit)$table["median"]

p <- ggplot(km_df, aes(x=time, y=surv)) +
  geom_step(color="#0072B2", linewidth=1.2) +
  geom_ribbon(aes(ymin=lower, ymax=upper),
              fill="#0072B2", alpha=0.15) +
  geom_vline(xintercept=med_os, linetype="dashed",
             color="grey40") +
  annotate("text", x=med_os + 15, y=0.55,
           label=paste0("Median OS = ", med_os, " days"),
           hjust=0, size=4) +
  scale_y_continuous(limits=c(0,1),
                     labels=scales::percent_format()) +
  theme_minimal(base_size=12) +
  labs(title="KM: Overall Survival -- Drug A",
       x="Time (Days)", y="Survival Probability")
rplot(p)
endsubmit;
run;
```

</details>

---

### 4c 🔴 Compare KM output with PROC LIFETEST

1. Run the KM analysis from Section 4 (both arms)
2. Run `PROC LIFETEST` on the same `work.adtte` dataset
3. Use `PROC COMPARE` to verify the median OS values match between `work.km_median` and the `PROC LIFETEST` output

**Hint:** `PROC LIFETEST` with `ods output Quartiles=work.sas_km_quartiles;` gives median survival.

<details>
<summary>Solution</summary>

```sas
/* Step 1: already in work.km_median from Section 4 */

/* Step 2: SAS PROC LIFETEST */
proc lifetest data=work.adtte
    plots=survival(atrisk=0 to 600 by 100);
  time AVAL * CNSR(1);
  strata TRT01P;
  ods output Quartiles=work.sas_km_quartiles;
  title "SAS PROC LIFETEST -- Overall Survival";
run;
title;

/* Step 3: inspect both */
proc print data=work.km_median noobs;
  title "R Median OS";
run;
proc print data=work.sas_km_quartiles noobs;
  where Percent = 50;
  title "SAS Median OS (Quartiles output, 50th percentile)";
run;
title;
/* Manual comparison -- values should match */
```

</details>

---

## Exercise 5 — Mixed model (PROC R + PROC MIXED)
### Topic: Section 5 · nlme · PROC MIXED

---

### 5a 🟢 Change the endpoint macro variable

In Section 5, `%let endpoint = HbA1c (%);` drives both the R model and `PROC MIXED`. The demo only has one lab parameter (`HbA1c (%)`), but the pattern is important: confirm you understand what would need to change if ADLB had a second parameter. No code change needed — just answer: **which single line controls what both procedures analyse?**

**Answer:** `%let endpoint = HbA1c (%);` — both the R `symget("endpoint")` call and the SAS `where PARAM="&endpoint"` clause read from this single macro variable.

---

### 5b 🟡 Extract and compare treatment estimates

After running Section 5:
- `work.r_mmrm` contains the R fixed effects table (Estimate, StdErr, tValue, pValue)
- `work.sas_lsmeans` contains the SAS least-squares means (Estimate, StdErr, df, tValue, Probt)

Write a DATA step that extracts the DrugA WEEK24 estimate from `work.sas_lsmeans` and stores it in a macro variable `&sas_est`. Then print both estimates side by side.

<details>
<summary>Solution</summary>

```sas
/* Extract DrugA WEEK24 estimate from SAS LSMeans */
proc sql noprint;
  select estimate into :sas_est trimmed
  from work.sas_lsmeans
  where TRT01P = "DrugA" and VISIT = "WEEK24";
quit;

%put NOTE: SAS PROC MIXED DrugA WEEK24 LSMean = &sas_est;

/* Print R results for comparison */
proc print data=work.r_mmrm noobs label;
  title "R nlme Fixed Effects (compare TRT01PDrugA:VISITWEEK24)";
run;
title;
```

</details>

---

### 5c 🔴 Add a mean change plot with error bars

Extend the PROC R step in Section 5 to add 95% confidence intervals as error bars to the mean change plot. Use `geom_errorbar()` with the standard error computed from the data.

<details>
<summary>Solution</summary>

```sas
proc r;
submit;
library(ggplot2)
library(dplyr)

adlb <- sd2df("work.adlb")

df <- adlb %>%
  filter(PARAM == "HbA1c (%)") %>%
  mutate(CHG    = AVAL - BASE,
         VISIT  = factor(VISIT, levels=c("WEEK12","WEEK24")),
         TRT01P = factor(TRT01P, levels=c("Placebo","DrugA")))

means <- df %>%
  group_by(TRT01P, VISIT) %>%
  summarise(
    MeanCHG = mean(CHG, na.rm=TRUE),
    SE      = sd(CHG, na.rm=TRUE) / sqrt(n()),
    .groups = "drop"
  ) %>%
  mutate(
    CI_lo = MeanCHG - 1.96 * SE,
    CI_hi = MeanCHG + 1.96 * SE
  )

p <- ggplot(means, aes(x=VISIT, y=MeanCHG,
                       group=TRT01P, color=TRT01P)) +
  geom_line(linewidth=1.1) +
  geom_point(size=3) +
  geom_errorbar(aes(ymin=CI_lo, ymax=CI_hi),
                width=0.08, linewidth=0.8) +
  geom_hline(yintercept=0, linetype="dashed", color="grey50") +
  scale_color_manual(values=c("#0072B2","#E69F00")) +
  theme_minimal(base_size=12) +
  labs(title="Mean HbA1c Change from Baseline (±95% CI)",
       x="Visit", y="Mean Change (%)", color="Treatment")
rplot(p)
endsubmit;
run;
```

</details>

---

## Exercise 6 — External R scripts
### Topic: Section 6 · proc r infile= · fileref

---

### 6a 🟡 Create and call your own R script

In SAS Studio:
1. Select **New > R Program**
2. Write R code that:
   - Reads `work.adsl`
   - Computes the min, median, and max of `AGE` grouped by `TRT01P`
   - Displays the result with `show()`
   - Returns the overall median age to SAS as `&r_median_age`
3. Save the file (note the path)
4. Call it from SAS using `proc r infile=...`

<details>
<summary>Solution — R script (save as adsl_age_summary.R)</summary>

```r
library(dplyr)

adsl <- sd2df("work.adsl")

age_summary <- adsl %>%
  group_by(TRT01P) %>%
  summarise(
    Min    = min(AGE),
    Median = median(AGE),
    Max    = max(AGE),
    .groups = "drop"
  )

show(age_summary, title="Age Summary by Treatment")
df2sd(age_summary, "work.age_summary")

overall_median <- median(adsl$AGE)
symput("r_median_age", as.character(overall_median))
```

</details>

<details>
<summary>Solution — SAS program</summary>

```sas
filename ageR "/home/user/scripts/adsl_age_summary.R";
proc r infile=ageR;
run;

%put NOTE: Overall median age = &r_median_age;

proc print data=work.age_summary noobs;
  title "Age Summary (from external R script)";
run;
title;
```

</details>

---

### 6b 🔴 Parameterised R script

Extend Exercise 6a so the R script accepts a `&trt_filter` macro variable and only processes subjects in that treatment arm. The script should:
- Return the filtered summary in `work.age_filtered`
- Return the N for that arm as `&r_arm_n`

The SAS program should set `%let trt_filter = Placebo;` and then call the script.

---

## Exercise 7 — REST API (PROC PYTHON)
### Topic: Section 7 · requests · SAS.symget · SAS.df2sd

---

### 7a 🟢 Switch sponsor

Change `%let sponsor = Servier;` and re-run Section 7. Note how many completed studies are returned. Then switch back to `Novo Nordisk`. No code change needed in the Python block — the sponsor name flows through `SAS.symget()`.

---

### 7b 🟢 Change the search term

Change `%let search_term = obesity;` and re-run with `Novo Nordisk` as the sponsor. Compare the results with the `GLP-1` query. Again, no Python code changes needed.

---

### 7c 🟡 Add a recruiting filter option

Currently the query filters for `"COMPLETED"` studies. Add a macro variable `%let status = RECRUITING;` and update the Python params dictionary to use `SAS.symget("status")` instead of the hardcoded string.

<details>
<summary>Solution</summary>

```sas
%let sponsor     = Novo Nordisk;
%let search_term = GLP-1;
%let status      = RECRUITING;   /* COMPLETED | RECRUITING | ALL */

proc python;
submit;
import requests, pandas as pd

sponsor     = SAS.symget("sponsor")
search_term = SAS.symget("search_term")
status      = SAS.symget("status")

url    = "https://clinicaltrials.gov/api/v2/studies"
params = {
    "query.spons":          sponsor,
    "query.term":           search_term,
    "filter.overallStatus": status,
    "pageSize": 10,
    "fields": "NCTId,BriefTitle,StartDate,CompletionDate,EnrollmentCount"
}

try:
    resp = requests.get(url, params=params, timeout=15)
    resp.raise_for_status()
    studies = resp.json().get("studies", [])
    rows = []
    for s in studies:
        pm  = s.get("protocolSection", {})
        idm = pm.get("identificationModule", {})
        stm = pm.get("statusModule", {})
        dsm = pm.get("designModule", {})
        rows.append({
            "NCTId":      idm.get("nctId", ""),
            "Title":      idm.get("briefTitle", ""),
            "StartDate":  stm.get("startDateStruct", {}).get("date", ""),
            "EndDate":    stm.get("completionDateStruct", {}).get("date", ""),
            "Enrollment": dsm.get("enrollmentInfo", {}).get("count", None)
        })
    df = pd.DataFrame(rows)
    SAS.symput("api_n_trials", str(len(df)))
    SAS.df2sd(df, "work.ct_trials")
    SAS.show(df)
except requests.exceptions.ConnectionError:
    print("NOTE: No internet access.")
    SAS.symput("api_n_trials", "0")
endsubmit;
run;

%put NOTE: &api_n_trials &status trials for &sponsor (term: &search_term);
```

</details>

---

### 7d 🔴 Parse JSON into multiple SAS datasets

The ClinicalTrials.gov API returns nested JSON. Extend the Python block to extract the **primary outcome measures** for each trial (found in `protocolSection.outcomesModule.primaryOutcomes`) and load them into a separate SAS dataset `work.ct_outcomes` with columns `NCTId` and `OutcomeMeasure`.

**Hint:** Some studies may have no primary outcomes — handle this with `.get("primaryOutcomes", [])`.

<details>
<summary>Solution</summary>

```python
proc python;
submit;
import requests, pandas as pd

sponsor     = SAS.symget("sponsor")
search_term = SAS.symget("search_term")

url    = "https://clinicaltrials.gov/api/v2/studies"
params = {"query.spons": sponsor, "query.term": search_term,
          "filter.overallStatus": "COMPLETED", "pageSize": 10,
          "fields": "NCTId,BriefTitle,PrimaryOutcomes"}

try:
    resp = requests.get(url, params=params, timeout=15)
    resp.raise_for_status()
    studies = resp.json().get("studies", [])

    trial_rows   = []
    outcome_rows = []

    for s in studies:
        pm  = s.get("protocolSection", {})
        nct = pm.get("identificationModule", {}).get("nctId", "")
        title = pm.get("identificationModule", {}).get("briefTitle", "")
        trial_rows.append({"NCTId": nct, "Title": title})

        outcomes = pm.get("outcomesModule", {}).get("primaryOutcomes", [])
        for o in outcomes:
            outcome_rows.append({
                "NCTId":           nct,
                "OutcomeMeasure":  o.get("measure", "")
            })

    SAS.df2sd(pd.DataFrame(trial_rows),   "work.ct_trials2")
    SAS.df2sd(pd.DataFrame(outcome_rows), "work.ct_outcomes")
    print(f"Loaded {len(trial_rows)} trials and {len(outcome_rows)} primary outcomes")

except requests.exceptions.ConnectionError:
    print("NOTE: No internet access.")
endsubmit;
run;

proc print data=work.ct_outcomes noobs;
  title "Primary Outcome Measures by Trial";
run;
title;
```

</details>

---

## Bonus Challenge — Combine PROC PYTHON and PROC R in one pipeline

🔴 **Full pipeline exercise**

Build a single SAS program that:

1. **Python (Section 7 pattern):** Query ClinicalTrials.gov for `%let sponsor = Novo Nordisk;` and `%let search_term = GLP-1;`. Store results in `work.ct_trials`.

2. **SAS DATA step:** Create a flag variable `LARGE_TRIAL` = 1 if `Enrollment > 500`, else 0. Store in `work.ct_flagged`.

3. **Python:** Compute the percentage of large trials and store it in `&pct_large` using `SAS.symput()`.

4. **R:** Read `work.ct_flagged` and produce a bar chart showing the count of large vs small trials using `ggplot2`. Display it with `rplot()`.

5. **PROC PRINT:** Print `work.ct_flagged` with a title that includes `&pct_large`.

This exercise uses all four callback methods (`symget`, `symput`, `sd2df`, `df2sd`) across both procedures and combines them with SAS steps.

---

## Quick reference — callbacks

| | PROC PYTHON | PROC R |
|---|---|---|
| SAS dataset → language | `SAS.sd2df("lib.ds")` | `sd2df("lib.ds")` |
| DataFrame → SAS | `SAS.df2sd(df, "lib.ds")` | `df2sd(df, "lib.ds")` |
| Read macro var | `SAS.symget("name")` | `symget("name")` |
| Write macro var | `SAS.symput("name", val)` | `symput("name", val)` |
| Log output | `print()` | `cat()` |
| Results window | `SAS.show(fig_or_df)` | `show(obj)` / `rplot(p)` |
| External script | `proc python infile="f.py";` | `proc r infile="f.R";` |
