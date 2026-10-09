# PROC PYTHON & PROC R -- Clinical Demo Walkthrough

**Workshop:** Open-Source Integration in SAS Viya
**Audience:** Experienced SAS programmers (Novo Nordisk / Servier)
**Script file:** `demo_procR_clinical.sas`
**Environment:** SAS Viya 2026.03+, Python 3.12, R 4.4

---

## Before you start

Open `demo_procR_clinical.sas` in SAS Studio. Run sections one at a time using **F3** (run selected code) so you can discuss the output after each block.

Two macro variables at the top of each section control what runs:

| Variable | Default | Purpose |
|---|---|---|
| `&trt_filter` | `DrugA` | Treatment arm used in callback demos |
| `&sponsor` | `Novo Nordisk` | Sponsor name for ClinicalTrials.gov query |
| `&search_term` | `GLP-1` | Search term for ClinicalTrials.gov query |
| `&endpoint` | `HbA1c (%)` | Lab parameter used in mixed model |

---

## Section 0 -- Check your environment

**Purpose:** Confirm what is available before coding. Good opening exercise for participants.

### 0a. Python packages

```python
proc python;
submit;
import sys
from importlib.metadata import distributions

print(f"Python version: {sys.version}")
pkgs = sorted([f"  {d.name:<30} {d.version}" for d in distributions()])
print(f"Installed packages ({len(pkgs)} total):")
for p in pkgs:
    print(p)
endsubmit;
run;
```

**What to point out:**
- `importlib.metadata` is standard library -- no pip install needed
- Output goes to the SAS **log** (378 packages on this image)
- Key packages to highlight: `pandas`, `requests`, `matplotlib`, `scikit-learn`, `swat`, `saspy`

### 0b. R packages

```r
proc r;
submit;
ip <- as.data.frame(installed.packages()[, c("Package","Version")])
ip <- ip[order(ip$Package), ]
cat(sprintf("Installed R packages (%d total):\n", nrow(ip)))
for (i in seq_len(nrow(ip))) {
    cat(sprintf("  %-30s %s\n", ip$Package[i], ip$Version[i]))
}
df2sd(ip, "work.r_packages")
endsubmit;
run;
proc print data=work.r_packages noobs;
run;
```

**What to point out:**
- Full list prints to the **log** via `cat()`; the Results window shows it via `PROC PRINT` after `df2sd()`
- Key packages: `ggplot2`, `dplyr`, `survival`, `nlme`, `tidyverse`, `forecast`
- `survminer` is **not** installed on this image -- the KM demo (Section 4) uses base `survival` + `ggplot2` instead

> **Trainer tip:** Ask participants: "What R package would you want that isn't here?" -- leads naturally into the package installation discussion.

---

## Section 1 -- Synthetic ADaM datasets

**Purpose:** Create three small ADaM-structured datasets that all subsequent demos use. In production, replace `work.adsl` etc. with your actual ADaM libref.

| Dataset | Variables | N obs | Description |
|---|---|---|---|
| `work.adsl` | USUBJID, TRT01P, AGE, SEX, RACE, WEIGHTBL, HEIGHTBL, BMI | 20 | Subject-level: 10 DrugA, 10 Placebo |
| `work.adtte` | USUBJID, TRT01P, AVAL, CNSR, PARAM | 20 | Time to event (Overall Survival) |
| `work.adlb` | USUBJID, TRT01P, VISIT, AVAL, BASE, CHG, PARAM | 20 | HbA1c at WEEK12 and WEEK24 |

**CDISC naming conventions used:**
- `AVAL` = Analysis Value, `BASE` = Baseline, `CHG` = Change from Baseline
- `CNSR` = Censoring indicator (1 = censored, 0 = event)
- `TRT01P` = Planned treatment for Period 01

> **Trainer tip:** Run `PROC PRINT` on each dataset and briefly walk through the structure. Participants should recognise the ADaM standard.

---

## Section 2 -- Callback methods: the core of both procedures

**Purpose:** This is the most important section. Show side-by-side how PROC PYTHON and PROC R exchange data and macro variables with SAS.

### The key difference to emphasise

| Action | PROC PYTHON | PROC R |
|---|---|---|
| Import SAS dataset | `SAS.sd2df("work.adsl")` | `sd2df("work.adsl")` |
| Export to SAS | `SAS.df2sd(df, "work.result")` | `df2sd(df, "work.result")` |
| Read macro variable | `SAS.symget("name")` | `symget("name")` |
| Write macro variable | `SAS.symput("name", val)` | `symput("name", val)` |
| Results window output | `SAS.show(obj)` | `show(obj)` |

**Python always uses the `SAS.` prefix. R injects the functions directly -- no prefix.**

### 2a. Python round-trip

```sas
%let trt_filter = DrugA;

proc python;
submit;
import pandas as pd

trt  = SAS.symget("trt_filter")          # read macro var from SAS
adsl = SAS.sd2df("work.adsl")            # import SAS dataset
sub  = adsl[adsl["TRT01P"] == trt]

stats = (sub.groupby("TRT01P")
           .agg(N=("USUBJID","count"),
                MeanAge=("AGE","mean"),
                SDAge=("AGE","std"),
                MeanBMI=("BMI","mean"))
           .round(1).reset_index())

SAS.df2sd(stats, "work.py_demo_stats")   # send back to SAS
SAS.symput("py_n_subjects", str(len(sub)))  # write macro var
SAS.show(stats)                          # display in Results
endsubmit;
run;
```

### 2b. R round-trip

```r
proc r;
submit;
library(dplyr)

trt  <- symget("trt_filter")             # read macro var -- no SAS. prefix
adsl <- sd2df("work.adsl")              # import SAS dataset -- no SAS. prefix

stats <- adsl %>%
  filter(TRT01P == trt) %>%
  summarise(TRT01P=first(TRT01P), N=n(),
            MeanAge=round(mean(AGE),1),
            SDAge=round(sd(AGE),1),
            MeanBMI=round(mean(BMI),1))

df2sd(stats, "work.r_demo_stats")       # send back to SAS
symput("r_n_subjects", as.character(stats$N))
show(stats, title=paste("R Summary --", trt))
endsubmit;
run;
```

### 2c. Verification

```sas
proc compare data=work.py_demo_stats compare=work.r_demo_stats
             out=work.compare_diff outnoequal;
run;
```

`work.compare_diff` has 0 observations -- both procedures returned identical results.

> **Discussion point:** Both languages produced the same numbers. The choice of language comes down to what you do *next* -- not the data exchange itself.

---

## Section 3 -- Visualisation

### 3a. Python: matplotlib

```python
import matplotlib
matplotlib.use('Agg')       # required: SAS compute server has no display
import matplotlib.pyplot as plt

fig, axes = plt.subplots(1, 2, figsize=(10, 4))
# ... histogram and boxplot code ...
SAS.show(fig)               # renders the figure in the SAS Results window
```

**Key points:**
- `matplotlib.use('Agg')` must be called **before** importing `pyplot` -- the server has no display device
- `SAS.show(fig)` accepts a matplotlib Figure object directly
- You can also save to a file with `fig.savefig('/path/file.png')` and render with `SAS.show('/path/file.png')`

### 3b. R: ggplot2 -- three plots in one PROC R step

```r
proc r;
submit;
library(ggplot2)
adsl <- sd2df("work.adsl")

p1 <- ggplot(adsl, aes(x=AGE, fill=TRT01P)) + geom_histogram(...);  rplot(p1)
p2 <- ggplot(adsl, aes(x=TRT01P, fill=SEX)) + geom_bar(...);        rplot(p2)
p3 <- ggplot(adsl, aes(x=TRT01P, y=BMI))    + geom_boxplot(...);    rplot(p3)
endsubmit;
run;
```

**Key points:**
- `rplot(plot_object)` sends any ggplot2 or base R graphic to the SAS Results window
- Multiple `rplot()` calls in **one** PROC R step produce multiple outputs in sequence
- To save to file: `rplot(p, filename="myplot.png")` -- file lands in `sas$workpath`
- To render a saved image: `renderImage('/path/to/file.png')`

> **Discussion point:** ggplot2's grammar of graphics maps cleanly to clinical figure specifications: you declare the data, the aesthetic mapping (what goes on which axis), and the geometry (histogram, boxplot, step). This is why R is the natural choice for TLF development.

---

## Section 4 -- Kaplan-Meier survival curve (ADTTE)

**Purpose:** The primary clinical graph use case for R in pharma. Uses base `survival` + `ggplot2` (no `survminer` required).

```r
proc r;
submit;
library(survival); library(ggplot2); library(dplyr)

adtte  <- sd2df("work.adtte")
km_fit <- survfit(Surv(AVAL, CNSR==0) ~ TRT01P, data=adtte)

# Tidy the fit into a data frame for ggplot2
km_df <- data.frame(time=km_fit$time, surv=km_fit$surv,
                    upper=km_fit$upper, lower=km_fit$lower,
                    strata=rep(names(km_fit$strata), km_fit$strata))
km_df$Treatment <- gsub("TRT01P=", "", km_df$strata)

# Log-rank p-value
lr <- survdiff(Surv(AVAL, CNSR==0) ~ TRT01P, data=adtte)
pval <- round(1 - pchisq(lr$chisq, df=1), 3)

p <- ggplot(km_df, aes(x=time, y=surv, color=Treatment, fill=Treatment)) +
  geom_step(linewidth=1.1) +
  geom_ribbon(aes(ymin=lower, ymax=upper), alpha=0.15, color=NA) +
  annotate("text", x=max(km_df$time)*0.6, y=0.95,
           label=paste0("Log-rank p = ", pval), size=4, hjust=0) +
  scale_y_continuous(limits=c(0,1), labels=scales::percent_format()) +
  theme_minimal(base_size=12) +
  labs(title="Kaplan-Meier: Overall Survival by Treatment",
       x="Time (Days)", y="Survival Probability")
rplot(p)

# Median survival -- returned to SAS dataset
km_q   <- quantile(km_fit, probs=0.5)$quantile
km_sum <- data.frame(Treatment=gsub("TRT01P=","",names(km_q)),
                     MedianOS=as.numeric(km_q))
df2sd(km_sum, "work.km_median")
endsubmit;
run;
```

**Outputs:**
- KM step curve with 95% CI ribbon and log-rank p-value in the Results window
- `work.km_median` -- median survival days per treatment arm
- `work.km_atrisk` -- number at risk at t=0, 100, 200, 300, 400, 500 days

**SAS equivalent for comparison (run separately):**

```sas
proc lifetest data=work.adtte plots=survival(atrisk=0 to 600 by 100);
  time AVAL * CNSR(1);
  strata TRT01P;
run;
```

> **Discussion points:**
> - Both produce identical KM estimates
> - `survminer::ggsurvplot()` (if installed) gives the full clinical layout -- risk table, CI, p-value -- in one call. Show as the "production upgrade."
> - For regulatory submission: use SAS `PROC LIFETEST` with validated ODS templates
> - For exploratory analysis or publications: R gives more visual flexibility

---

## Section 5 -- Mixed model (MMRM) vs PROC MIXED

**Purpose:** Show that R and SAS can run the same statistical model on the same data, and compare outputs.

### R model (nlme)

```r
library(nlme)
endpoint <- symget("endpoint")         # "HbA1c (%)"
adlb     <- sd2df("work.adlb")

df <- adlb %>% filter(PARAM == endpoint) %>%
      mutate(CHG=AVAL-BASE, VISIT=factor(VISIT), TRT01P=factor(TRT01P))

model <- lme(fixed     = CHG ~ TRT01P * VISIT + BASE,
             random    = ~1 | USUBJID,
             data      = df,
             na.action = na.omit)

coef_tbl <- as.data.frame(summary(model)$tTable)
df2sd(coef_tbl, "work.r_mmrm")
symput("r_converged", "YES")
```

### SAS equivalent

```sas
proc mixed data=work.adlb;
  where PARAM="&endpoint";
  class USUBJID TRT01P VISIT;
  model CHG = TRT01P VISIT TRT01P*VISIT BASE / ddfm=KR s;
  repeated VISIT / subject=USUBJID type=UN;
  lsmeans TRT01P*VISIT / diff cl;
  ods output LSMeans=work.sas_lsmeans;
run;
```

**Key discussion points:**
- Estimates will be very close on this small dataset
- Main difference: **denominator degrees of freedom** -- SAS uses Kenward-Roger (`ddfm=KR`), which is the regulatory standard; `nlme` uses a simpler approximation
- `symput("r_converged", "YES")` demonstrates passing model metadata back to SAS
- In a submission context: `PROC MIXED` is the validated reference; R MMRM is useful for cross-validation and exploratory work

---

## Section 6 -- External scripts: PROC PYTHON and PROC R

**Purpose:** Both procedures support `infile=` to load a script file instead of embedding all code inline. Scripts can live on the server filesystem or in SAS Content. This is better for version control, reuse, and team collaboration.

### Two storage locations

| Location | filename statement | Works with |
|---|---|---|
| Server filesystem | `filename myScript '/path/file.py';` | PROC PYTHON + PROC R |
| SAS Content | `filename myScript filesrvc folderPath='/My Folder' filename='file.py';` | PROC PYTHON + PROC R |

### PROC PYTHON infile=

**Option 1: Server filesystem path**
```sas
proc python infile='/tmp/my_script.py';
submit;
my_function()          /* call a function defined in the script */
print("y = " + str(y))
endsubmit;
run;
```

**Option 2: Fileref — server path**
```sas
filename pyScript '/path/analysis.py';
proc python infile=pyScript;
run;
```

**Option 3: Fileref — SAS Content (filesrvc engine)**
```sas
filename pyScript filesrvc
  folderPath='/My Folder'
  filename='analysis.py';
proc python infile=pyScript;
run;
```

> **How infile= works with PROC PYTHON:** The script file is loaded first (functions and variables it defines become available). The optional `submit; ... endsubmit;` block that follows can then call those functions or reference those variables.

### PROC R infile=

**Option 1: Server filesystem path**
```sas
proc r infile="/home/user/scripts/adsl_km.R";
run;
```

**Option 2: Fileref — server path (max 8 chars)**
```sas
filename clinR "/home/user/scripts/adsl_km.R";
proc r infile=clinR;
run;
```

**Option 3: Fileref — SAS Content (filesrvc engine)**
```sas
filename clinR filesrvc
  folderPath='/My Folder'
  filename='adsl_km.R';
proc r infile=clinR;
run;
```

**Option 4: From SAS Studio, create a native R Program file**
New > R Program creates a `.R` file where you code pure R -- no `submit/endsubmit` syntax. The file can be called from a PROC R step or run standalone.

### Passing parameters via macro variables

Both procedures receive parameters via `symget()` and return values via `symput()` -- works identically whether code is inline or in an external file:

```r
# adsl_km_analysis.R
trt_arm <- symget("make")           # receive SAS macro variable
adtte   <- sd2df("work.adtte")      # read SAS dataset
# ... analysis ...
symput("r_median_os", med_os)       # write back to SAS
df2sd(results, "work.km_result")    # export to SAS dataset
```

Called from SAS:
```sas
%let make = DrugA;
filename kmR "/path/adsl_km_analysis.R";
proc r infile=kmR;
run;
%put Median OS: &r_median_os days;
```

> **Trainer tip:** SAS Content (`filesrvc`) is the best option for teams -- scripts are stored centrally in SAS Viya, accessible from SAS Studio, Flows, and scheduled jobs without needing filesystem access.

---

## Section 7 -- REST API (PROC PYTHON)

**Purpose:** The headline PROC PYTHON use case -- pulling external data into SAS without leaving the program.

**Parameters (change at the top of the section):**
```sas
%let sponsor    = Novo Nordisk;   /* or: Servier */
%let search_term = GLP-1;         /* any term */
```

```python
proc python;
submit;
import requests, pandas as pd

sponsor     = SAS.symget("sponsor")
search_term = SAS.symget("search_term")

url    = "https://clinicaltrials.gov/api/v2/studies"
params = {"query.spons": sponsor, "query.term": search_term,
          "filter.overallStatus": "COMPLETED", "pageSize": 10,
          "fields": "NCTId,BriefTitle,StartDate,CompletionDate,EnrollmentCount"}

try:
    resp = requests.get(url, params=params, timeout=15)
    resp.raise_for_status()
    # ... parse JSON, build DataFrame ...
    SAS.df2sd(df, "work.ct_trials")
    SAS.symput("api_n_trials", str(len(df)))
    SAS.show(df)
except requests.exceptions.ConnectionError:
    print("NOTE: No internet access.")
    SAS.symput("api_n_trials", "0")
endsubmit;
run;
```

**What to demonstrate:**
1. Run with `Novo Nordisk` -- show 10 completed trials in Results
2. Change `%let sponsor = Servier;` -- re-run same code, different data
3. Point out `SAS.symget()` -- parameters injected from SAS, not hardcoded in Python

**Real-world extensions of this pattern:**
- Internal CTMS or pharmacovigilance APIs (same `requests` pattern, add auth headers)
- Azure Blob Storage (`azure-storage-blob` -- installed)
- AWS S3 (`boto3`)
- SharePoint / OneDrive (`office365-rest-python-client`)

---

## Callback reference card

| | PROC PYTHON | PROC R |
|---|---|---|
| **Available since** | SAS Viya 2021.1 | SAS Viya 2026.03 |
| **Submit block** | `submit;` ... `endsubmit;` | `submit;` ... `endsubmit;` |
| **SAS dataset -> language** | `SAS.sd2df("lib.ds")` | `sd2df("lib.ds")` |
| **DataFrame -> SAS** | `SAS.df2sd(df, "lib.ds")` | `df2sd(df, "lib.ds")` |
| **Read macro var** | `SAS.symget("name")` | `symget("name")` |
| **Write macro var** | `SAS.symput("name", val)` | `symput("name", val)` |
| **Call SAS function** | `SAS.sasfnc("func", arg)` | `sasfnc("func", arg)` |
| **Log output** | `print()` | `cat()` / `message()` |
| **Results window** | `SAS.show(fig_or_df)` | `show(obj)` |
| **Render ggplot/plot** | `SAS.show(matplotlib_fig)` | `rplot(ggplot_obj)` |
| **Render saved image** | `SAS.show("/path/file.png")` | `renderImage("/path/file.png")` |
| **External script** | `proc python infile="f.py";` | `proc r infile="f.R";` |
| **Pharma sweet spot** | APIs, cloud ingestion, Office365, data formats | Clinical stats, survival, mixed models, TLFs |

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `SyntaxError: invalid binary literal` | SAS `/* */` comment inside a Python submit block | Use `#` comments in Python |
| `ModuleNotFoundError` | Package not installed in active Python environment | Check `PROC_PYPATH`; install with `pip install` |
| R only shows 5 rows | `show()` has a default row limit | Use `cat()` + `for` loop to print to log; use `df2sd()` + `PROC PRINT` for results |
| `submit` split across lines in log | Non-ASCII characters in the file (em dashes, smart quotes) | Save file as UTF-8 without BOM; replace special characters |
| `replacement has N rows, data has 1` | Wrong data structure assumption from R `quantile()` | Use `names()` and `as.numeric()` to extract from named vector |
| `labels=` error in matplotlib boxplot | `labels` argument removed in matplotlib 3.9+ | Use `set_xticks()` + `set_xticklabels()` instead |
