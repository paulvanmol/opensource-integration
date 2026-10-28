/* ============================================================
   PROC PYTHON & PROC R -- Clinical Data Demo Script
   Workshop: Open-Source Integration in SAS Viya
   Audience: Novo Nordisk / Servier -- experienced SAS programmers
   Requires: SAS Viya 2026.03+ (for PROC R)
             PROC PYTHON available since SAS Viya 2021.1
   Packages: ggplot2, dplyr, survival, survminer, tidyverse
   ============================================================ */


/* ============================================================
   SECTION 0 -- Check your environment
   ============================================================ */

/* -- 0a. Python: list installed packages and Python version -- */
proc python;
submit;
import sys

print("=" * 50)
print(f"Python version: {sys.version}")
print("=" * 50)

# Use importlib.metadata (standard library, available in Python 3.8+)
try:
    from importlib.metadata import distributions
    pkgs = sorted([f"  {d.name:<30} {d.version}" for d in distributions()])
except ImportError:
    # Fallback for older Python or if importlib.metadata unavailable
    import subprocess
    result = subprocess.run([sys.executable, "-m", "pip", "list"],
                          capture_output=True, text=True)
    pkgs = result.stdout.strip().split('\n')

print(f"Installed packages ({len(pkgs)} total):")
for p in pkgs:
    print(p)
endsubmit;
run;


/* -- 0b. R: list installed packages -- */
proc r;
submit;
cat("R version:", paste(R.version$major, R.version$minor, sep="."), "\n")
cat(rep("=", 50), "\n", sep="")

ip <- as.data.frame(installed.packages()[, c("Package","Version")])
ip <- ip[order(ip$Package), ]

# Print full list to SAS log (no row limit)
cat(sprintf("Installed R packages (%d total):\n", nrow(ip)))
for (i in seq_len(nrow(ip))) {
    cat(sprintf("  %-30s %s\n", ip$Package[i], ip$Version[i]))
}

# Pass full list to SAS as a dataset so PROC PRINT can show it in results
df2sd(ip, "r_packages")
endsubmit;
run;

/* Show full package list in results window via SAS */
proc print data=work.r_packages noobs;
  title "Installed R Packages (full list)";
run;
title;


/* ============================================================
   SECTION 1 -- Create synthetic ADaM datasets
   (Replace with your actual ADaM libref in production)
   ============================================================ */

/* -- ADSL: Subject-Level Analysis Dataset -- */
data work.adsl;
  length USUBJID $10 TRT01P $20 SEX $1 RACE $30;
  input USUBJID $ TRT01P $ AGE SEX $ RACE $ WEIGHTBL HEIGHTBL;
  /* Derive BMI */
  BMI = WEIGHTBL / (HEIGHTBL/100)**2;
  label USUBJID  = "Unique Subject Identifier"
        TRT01P   = "Planned Treatment for Period 01"
        AGE      = "Age (years)"
        SEX      = "Sex"
        RACE     = "Race"
        WEIGHTBL = "Baseline Weight (kg)"
        HEIGHTBL = "Baseline Height (cm)"
        BMI      = "Baseline BMI (kg/m2)";
  datalines;
01-001 DrugA  52 F White              72.3 165
01-002 Placebo 61 M White             88.5 178
01-003 DrugA  47 M Asian              68.0 172
01-004 Placebo 55 F White             65.2 160
01-005 DrugA  63 F Black              80.1 163
01-006 Placebo 49 M White             92.3 182
01-007 DrugA  58 F Asian              58.7 155
01-008 Placebo 44 M White             95.0 185
01-009 DrugA  70 M White              77.4 175
01-010 Placebo 66 F Black             69.8 162
01-011 DrugA  51 F White              74.5 167
01-012 Placebo 53 M Asian             84.2 176
01-013 DrugA  48 F White              61.3 158
01-014 Placebo 60 M White             90.8 180
01-015 DrugA  55 F White              70.1 164
01-016 Placebo 57 M Black             87.6 179
01-017 DrugA  42 M White              79.2 174
01-018 Placebo 65 F White             66.4 161
01-019 DrugA  59 F Asian              63.0 157
01-020 Placebo 50 M White             93.1 183
;
run;

/* -- ADTTE: Time-to-Event Analysis Dataset -- */
/* AVAL = time in days, CNSR = 1 censored / 0 = event */
data work.adtte;
  length USUBJID $10 TRT01P $20 PARAM $40;
  input USUBJID $ TRT01P $ AVAL CNSR;
  PARAM = "Overall Survival";
  label USUBJID = "Unique Subject Identifier"
        TRT01P  = "Planned Treatment"
        AVAL    = "Time to Event (Days)"
        CNSR    = "Censoring Indicator (1=Censored)"
        PARAM   = "Parameter";
  datalines;
01-001 DrugA   365 0
01-002 Placebo 180 0
01-003 DrugA   420 1
01-004 Placebo 210 0
01-005 DrugA   510 1
01-006 Placebo 155 0
01-007 DrugA   390 0
01-008 Placebo 270 1
01-009 DrugA   480 1
01-010 Placebo 195 0
01-011 DrugA   350 0
01-012 Placebo 240 1
01-013 DrugA   430 1
01-014 Placebo 165 0
01-015 DrugA   400 0
01-016 Placebo 220 0
01-017 DrugA   460 1
01-018 Placebo 185 0
01-019 DrugA   395 1
01-020 Placebo 260 1
;
run;

/* -- ADLB: Laboratory Analysis Dataset (longitudinal) -- */
data work.adlb;
  length USUBJID $10 TRT01P $20 PARAM $40 VISIT $10;
  input USUBJID $ TRT01P $ VISIT $ AVAL BASE;
  PARAM = "HbA1c (%)";
  CHG   = AVAL - BASE;
  label USUBJID = "Unique Subject Identifier"
        TRT01P  = "Planned Treatment"
        VISIT   = "Analysis Visit"
        AVAL    = "Analysis Value"
        BASE    = "Baseline Value"
        CHG     = "Change from Baseline"
        PARAM   = "Parameter";
  datalines;
01-001 DrugA   WEEK12 7.2 8.1
01-001 DrugA   WEEK24 6.8 8.1
01-002 Placebo WEEK12 8.0 8.0
01-002 Placebo WEEK24 7.9 8.0
01-003 DrugA   WEEK12 7.0 8.3
01-003 DrugA   WEEK24 6.5 8.3
01-004 Placebo WEEK12 7.8 7.9
01-004 Placebo WEEK24 7.7 7.9
01-005 DrugA   WEEK12 6.9 8.2
01-005 DrugA   WEEK24 6.4 8.2
01-006 Placebo WEEK12 8.1 8.1
01-006 Placebo WEEK24 8.0 8.1
01-007 DrugA   WEEK12 7.1 8.0
01-007 DrugA   WEEK24 6.7 8.0
01-008 Placebo WEEK12 7.9 8.2
01-008 Placebo WEEK24 7.8 8.2
01-009 DrugA   WEEK12 7.3 8.4
01-009 DrugA   WEEK24 6.9 8.4
01-010 Placebo WEEK12 8.2 8.3
01-010 Placebo WEEK24 8.1 8.3
;
run;

proc print data=work.adsl    label; title "ADSL -- Subject-Level";  run;
proc print data=work.adtte   label; title "ADTTE -- Time to Event"; run;
proc print data=work.adlb    label; title "ADLB -- Laboratory";     run;
title;


/* ============================================================
   SECTION 2 -- Callback methods: data round-trip
   Demonstrates: sd2df, df2sd, symget, symput, show
   ============================================================ */

/* -- 2a. Python round-trip -- */
%let trt_filter = DrugA;

proc python;
submit;
import pandas as pd

# Read macro variable passed from SAS
trt = SAS.symget("trt_filter")
print(f"Filtering for treatment: {trt}")

# Import ADSL from SAS
adsl = SAS.sd2df("work.adsl")

# Filter and summarise
sub  = adsl[adsl["TRT01P"] == trt]
stats = (sub.groupby("TRT01P")
           .agg(N=("USUBJID","count"),
                MeanAge=("AGE","mean"),
                SDAge=("AGE","std"),
                MeanBMI=("BMI","mean"))
           .round(1)
           .reset_index())

# Send summary back to SAS
SAS.df2sd(stats, "work.py_demo_stats")

# Send scalar back to SAS as macro variable
SAS.symput("py_n_subjects", str(len(sub)))

# Display in Results window
SAS.show(stats)
endsubmit;
run;

%put NOTE: Python found &py_n_subjects subjects in treatment &trt_filter;
proc print data=work.py_demo_stats label; title "Python Summary -- &trt_filter"; run;


/* -- 2b. R round-trip (same logic, note no SAS. prefix) -- */
proc r;
submit;
library(dplyr)

# Read macro variable from SAS -- no SAS. prefix
trt <- symget("trt_filter")
cat("Filtering for treatment:", trt, "\n")

# Import ADSL -- no SAS. prefix
adsl <- sd2df("work.adsl")

# Summarise
stats <- adsl %>%
  filter(TRT01P == trt) %>%
  summarise(
    TRT01P  = first(TRT01P),
    N       = n(),
    MeanAge = round(mean(AGE, na.rm=TRUE), 1),
    SDAge   = round(sd(AGE, na.rm=TRUE), 1),
    MeanBMI = round(mean(BMI, na.rm=TRUE), 1)
  )

# Return to SAS
df2sd(stats, "work.r_demo_stats")
symput("r_n_subjects", as.character(stats$N))

# Display in Results window
show(stats, title=paste("R Summary --", trt))
endsubmit;
run;

%put NOTE: R found &r_n_subjects subjects in treatment &trt_filter;
proc print data=work.r_demo_stats label; title "R Summary -- &trt_filter"; run;
title;

/* -- 2c. Verify both procedures returned the same result -- */
proc compare data=work.py_demo_stats
             compare=work.r_demo_stats
             out=work.compare_diff
             outnoequal;
  title "Comparing Python vs R summary output";
run;
title;


/* ============================================================
   SECTION 3 -- Visualisation
   3a. Python: matplotlib histogram
   3b. R: ggplot2 demographic panel (3 plots)
   ============================================================ */

/* -- 3a. Python: Age distribution using matplotlib -- */
proc python;
submit;
import matplotlib
matplotlib.use('Agg')   # required for server-side rendering
import matplotlib.pyplot as plt
import pandas as pd

adsl = SAS.sd2df("work.adsl")

fig, axes = plt.subplots(1, 2, figsize=(10, 4))
fig.suptitle("Baseline Demographics", fontsize=13, fontweight='bold')

# Left: Age histogram by treatment
for trt, grp in adsl.groupby("TRT01P"):
    axes[0].hist(grp["AGE"], bins=7, alpha=0.6, label=trt)
axes[0].set_xlabel("Age (years)")
axes[0].set_ylabel("Count")
axes[0].set_title("Age Distribution")
axes[0].legend()

# Right: BMI boxplot by treatment
groups    = [grp["BMI"].values for _, grp in adsl.groupby("TRT01P")]
box_labels = list(adsl.groupby("TRT01P").groups.keys())
bp = axes[1].boxplot(groups, patch_artist=True,
                     boxprops=dict(facecolor='#AEC6E8', color='#0072B2'),
                     medianprops=dict(color='navy', linewidth=2))
axes[1].set_xticks(range(1, len(box_labels)+1))
axes[1].set_xticklabels(box_labels)
axes[1].set_xlabel("Treatment")
axes[1].set_ylabel("BMI (kg/m2)")
axes[1].set_title("Baseline BMI")

plt.tight_layout()
SAS.show(fig)
endsubmit;
run;


/* -- 3b. R: ggplot2 demographic panel -- */
proc r;
submit;
library(ggplot2)
library(dplyr)

adsl <- sd2df("work.adsl")

# Plot 1: Age histogram
p1 <- ggplot(adsl, aes(x=AGE, fill=TRT01P)) +
  geom_histogram(binwidth=5, alpha=0.7, position="identity", color="white") +
  scale_fill_manual(values=c("#0072B2","#E69F00")) +
  theme_minimal(base_size=12) +
  labs(title="Age Distribution by Treatment",
       x="Age (years)", y="Count", fill="Treatment")
rplot(p1)

# Plot 2: Sex proportion bar chart
p2 <- ggplot(adsl, aes(x=TRT01P, fill=SEX)) +
  geom_bar(position="fill") +
  scale_y_continuous(labels=scales::percent_format()) +
  scale_fill_manual(values=c("#CC79A7","#56B4E9"),
                    labels=c("Female","Male")) +
  theme_minimal(base_size=12) +
  labs(title="Sex Distribution by Treatment",
       x="Treatment", y="Proportion", fill="Sex")
rplot(p2)

# Plot 3: BMI boxplot
p3 <- ggplot(adsl, aes(x=TRT01P, y=BMI, fill=TRT01P)) +
  geom_boxplot(alpha=0.7, outlier.shape=21, outlier.size=2) +
  scale_fill_manual(values=c("#0072B2","#E69F00")) +
  theme_minimal(base_size=12) +
  theme(legend.position="none") +
  labs(title="Baseline BMI by Treatment",
       x="Treatment", y=expression(BMI~(kg/m^2)))
rplot(p3)
endsubmit;
run;


/* ============================================================
   SECTION 4 -- PROC R: Kaplan-Meier Survival Curve (ADTTE)
   Clinical graph -- primary use case for pharma
   ============================================================ */

proc r;
submit;
library(survival)
library(ggplot2)
library(dplyr)

adtte <- sd2df("work.adtte")

# Fit KM model
km_fit <- survfit(Surv(AVAL, CNSR==0) ~ TRT01P, data=adtte)

# Extract tidy summary for ggplot2
km_df <- data.frame(
  time   = km_fit$time,
  surv   = km_fit$surv,
  upper  = km_fit$upper,
  lower  = km_fit$lower,
  strata = rep(names(km_fit$strata), km_fit$strata)
)
km_df$Treatment <- gsub("TRT01P=", "", km_df$strata)

# Log-rank test
lr_test <- survdiff(Surv(AVAL, CNSR == 0) ~ TRT01P, data=adtte)
lr_df   <- length(lr_test$n) - 1
pval    <- pchisq(lr_test$chisq, df=lr_df, lower.tail=FALSE)
pval_lbl <- paste0("Log-rank p = ", format.pval(pval, digits=3))

# Median survival and confidence intervals
km_stats <- summary(km_fit)$table

km_sum <- data.frame(
  Treatment = gsub("TRT01P=", "", rownames(km_stats)),
  MedianOS  = as.numeric(km_stats[, "median"]),
  Lower95CI = as.numeric(km_stats[, "0.95LCL"]),
  Upper95CI = as.numeric(km_stats[, "0.95UCL"]),
  stringsAsFactors = FALSE,
  row.names = NULL
)

km_sum$MedianDisplay <- ifelse(
  is.na(km_sum$MedianOS),
  "NE",
  format(km_sum$MedianOS, trim=TRUE)
)

df2sd(km_sum, "work.km_median")
show(km_sum, title="Median Overall Survival by Treatment (days)")
endsubmit;
run;
/* Show median survival and at-risk table in SAS output */
proc print data=work.km_median noobs;
  title "Median Overall Survival by Treatment";
run;
proc print data=work.km_atrisk noobs;
  title "Number at Risk by Treatment";
run;
title;

/*
 TRAINER NOTE:
 Compare with SAS PROC LIFETEST for the same data:

proc lifetest data=work.adtte plots=survival(atrisk=0 to 600 by 100);
  time AVAL * CNSR(1);
  strata TRT01P;
  title "SAS PROC LIFETEST -- Overall Survival";
run;

 Discussion points:
 - Both produce the same KM estimate
 - This demo uses base survival + ggplot2 (no survminer needed)
 - If survminer IS installed: ggsurvplot() gives risk table + CI + p-value
   in a single call -- show the commented-out version as the "full" example
 - SAS: validated, submission-ready output with ODS customisation
 - Exploratory work → R; regulatory submission output → SAS (or validated R)
*/

/* ============================================================
   SECTION 5 -- PROC R: Mixed Model + comparison with PROC MIXED
   Uses ADLB (HbA1c over time)
   ============================================================ */

%let endpoint = HbA1c (%);

proc r;
submit;
library(nlme)
library(dplyr)
library(ggplot2)

endpoint <- symget("endpoint")
adlb     <- sd2df("work.adlb")

# Filter to endpoint
df <- adlb %>%
  filter(PARAM == endpoint) %>%
  mutate(
    CHG    = AVAL - BASE,
    VISIT  = factor(VISIT, levels=c("WEEK12","WEEK24")),
    TRT01P = factor(TRT01P, levels=c("Placebo","DrugA"))
  )

# Mixed model for repeated measures (MMRM)
model <- lme(
  fixed     = CHG ~ TRT01P * VISIT + BASE,
  random    = ~1 | USUBJID,
  data      = df,
  na.action = na.omit
)

# Extract fixed effects table
coef_tbl <- as.data.frame(summary(model)$tTable)
coef_tbl$Parameter <- rownames(coef_tbl)
coef_tbl <- coef_tbl[, c("Parameter","Value","Std.Error","t-value","p-value")]
names(coef_tbl) <- c("Parameter","Estimate","StdErr","tValue","pValue")

show(coef_tbl, title=paste("MMRM Fixed Effects --", endpoint))
df2sd(coef_tbl, "work.r_mmrm")

# Send model convergence status to SAS
symput("r_converged", "YES")

# Mean change by visit plot
means <- df %>%
  group_by(TRT01P, VISIT) %>%
  summarise(MeanCHG = mean(CHG, na.rm=TRUE), .groups='drop')

p <- ggplot(means, aes(x=VISIT, y=MeanCHG, group=TRT01P, color=TRT01P)) +
  geom_line(linewidth=1.2) +
  geom_point(size=3) +
  geom_hline(yintercept=0, linetype="dashed", color="grey50") +
  scale_color_manual(values=c("#0072B2","#E69F00")) +
  theme_minimal(base_size=12) +
  labs(title=paste("Mean Change from Baseline --", endpoint),
       x="Visit", y="Mean Change from Baseline", color="Treatment")
rplot(p)
endsubmit;
run;

%put NOTE: R MMRM convergence: &r_converged;
proc print data=work.r_mmrm noobs label;
  title "R Mixed Model Results -- &endpoint";
run;
title;

/* SAS PROC MIXED for comparison */
proc mixed data=work.adlb;
  where PARAM="&endpoint";
  class USUBJID TRT01P VISIT;
  model CHG = TRT01P VISIT TRT01P*VISIT BASE / ddfm=KR s;
  repeated VISIT / subject=USUBJID type=UN;
  lsmeans TRT01P*VISIT / diff cl;
  ods output LSMeans=work.sas_lsmeans;
  title "SAS PROC MIXED -- &endpoint";
run;
title;

/*
 TRAINER NOTE:
 Comparison discussion:
 - Estimates should be very similar (small dataset, simple structure)
 - Denominator df: Kenward-Roger (SAS ddfm=KR) vs. default in nlme
 - In a regulatory submission: PROC MIXED is the validated reference
 - R MMRM is valuable for exploratory analysis and cross-validation
 - Key message: you can run both in the same SAS program and compare
*/


/* ============================================================
   SECTION 6 -- PROC R: External R script
   Shows how to call a .R file from SAS using infile=
   ============================================================ */

/*
 Step 1: In SAS Studio, create a new R Program file (New > R Program)
         and save it as: /path/to/adsl_km_analysis.R
         Paste the content from the companion file:
         demo_adsl_km_analysis.R (created below as a reference)

 Step 2: Call it from SAS:
*/

/*
 UNCOMMENT AND ADJUST THE PATH when running in your environment:

%let make = DrugA;

filename kmScript "/home/user/scripts/adsl_km_analysis.R";
proc r infile=kmScript;
run;

%put NOTE: Median OS from external R script: &r_median_os days;
proc print data=work.km_from_script label noobs;
  title "KM Results from External R Script";
run;
title;
*/

/*
 Content of adsl_km_analysis.R (save separately):
 -------------------------------------------------------
 library(survival)
 library(survminer)

 trt_arm <- symget("make")        # receive from SAS macro var

 adtte   <- sd2df("work.adtte")
 sub     <- adtte[adtte$TRT01P == trt_arm, ]

 km_fit  <- survfit(Surv(AVAL, CNSR==0) ~ 1, data=sub)
 med_os  <- surv_median(km_fit)$median

 symput("r_median_os", as.character(med_os))   # return to SAS

 df2sd(data.frame(TRT01P=trt_arm, MedianOS=med_os),
       "work.km_from_script")
 -------------------------------------------------------
*/


/* ============================================================
   SECTION 7 -- PROC PYTHON: REST API demo
   Pulls clinical trial data from ClinicalTrials.gov API
   Change sponsor below to switch between customers:
     Novo Nordisk  -->  %let sponsor = Novo Nordisk;
     Servier       -->  %let sponsor = Servier;
   ============================================================ */

%let sponsor    = Novo Nordisk;   /* <-- change here: "Novo Nordisk" or "Servier" */
%let search_term = GLP-1;         /* <-- change search term if needed              */

proc python;
submit;
import requests
import pandas as pd

# Read parameters from SAS macro variables
sponsor     = SAS.symget("sponsor")
search_term = SAS.symget("search_term")

print(f"Querying ClinicalTrials.gov for sponsor: {sponsor}, term: {search_term}")

# ClinicalTrials.gov v2 REST API
url    = "https://clinicaltrials.gov/api/v2/studies"
params = {
    "query.spons":          sponsor,
    "query.term":           search_term,
    "filter.overallStatus": "COMPLETED",
    "pageSize": 10,
    "fields": "NCTId,BriefTitle,StartDate,CompletionDate,EnrollmentCount"
}

try:
    resp = requests.get(url, params=params, timeout=15)
    resp.raise_for_status()
    studies = resp.json().get("studies", [])

    rows = []
    for s in studies:
        pm   = s.get("protocolSection", {})
        idm  = pm.get("identificationModule", {})
        stm  = pm.get("statusModule", {})
        dsm  = pm.get("designModule", {})
        rows.append({
            "NCTId":      idm.get("nctId", ""),
            "Title":      idm.get("briefTitle", ""),
            "StartDate":  stm.get("startDateStruct",     {}).get("date", ""),
            "EndDate":    stm.get("completionDateStruct", {}).get("date", ""),
            "Enrollment": dsm.get("enrollmentInfo", {}).get("count", None)
        })

    df = pd.DataFrame(rows)
    SAS.symput("api_n_trials", str(len(df)))
    SAS.df2sd(df, "work.ct_trials")
    SAS.show(df)

except requests.exceptions.ConnectionError:
    print("NOTE: No internet access -- skipping REST API demo.")
    print("      In a live environment this would return trial records.")
    SAS.symput("api_n_trials", "0")
endsubmit;
run;

%put NOTE: Retrieved &api_n_trials completed trials for &sponsor (term: &search_term);

%if &api_n_trials > 0 %then %do;
  proc print data=work.ct_trials noobs;
    title "ClinicalTrials.gov -- &sponsor Completed Trials (term: &search_term)";
  run;
  title;
%end;

/* ============================================================
   END OF DEMO SCRIPT
   ============================================================
   Summary of what was demonstrated:
   1. Environment check       -- installed packages in Python and R
   2. Callback round-trip     -- sd2df / df2sd / symget / symput / show
                                (PROC PYTHON with SAS. prefix vs PROC R without)
   3. Visualisation           -- matplotlib (Python) and ggplot2 (R)
   4. Kaplan-Meier curve      -- survival + survminer from ADTTE
   5. MMRM / PROC MIXED       -- mixed model in R vs SAS, side-by-side
   6. External R script       -- proc r infile= / fileref pattern
   7. REST API                -- requests package pulling ClinicalTrials.gov
   ============================================================ */
