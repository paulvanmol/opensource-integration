# PROC PYTHON & PROC R — Open-Source Integration

*SAS Viya Workshop*

Using Python and R inside SAS — without leaving your existing pipelines

Novo Nordisk / Servier · Half-day workshop · SAS Viya 2026.03+

## Contents

- Slide 2: Workshop Agenda
- Slide 3: Why open-source integration?
- Slide 4: PROC PYTHON vs PROC R — what's different?
- **Section 01 — Getting started**
- Slide 6: Section 0 — Check your environment
- Slide 7: Callback methods — moving data between SAS and open source
- **Section 02 — Visualisation**
- Slide 9: Visualisation — Python: matplotlib
- Slide 10: Visualisation — R: ggplot2 and rplot()
- **Section 03 — PROC PYTHON use cases**
- Slide 12: PROC PYTHON — REST API: ClinicalTrials.gov
- Slide 13: PROC PYTHON — other use cases
- **Section 04 — PROC R — Clinical data**
- Slide 15: PROC R — Kaplan-Meier survival curve (ADTTE)
- Slide 16: PROC R — Mixed model (MMRM) vs PROC MIXED
- **Section 05 — External scripts**
- Slide 18: External scripts — PROC PYTHON and PROC R
- Slide 19: Environment management & governance
- Slide 20: Quick reference — callback methods
- Slide 21: Resources & next steps

---

## Workshop Agenda

| Time | Topic | Content |
|---|---|---|
| 20 min | **Why open-source integration?** | Architecture, two integration modes, PROC PYTHON vs PROC R |
| 50 min | **Getting started — environment & callbacks** | Packages, virtual environments, sd2df / df2sd / symget / symput / show |
| 30 min | **Visualisation** | matplotlib (Python) · ggplot2 and rplot() (R) |
| 45 min | **PROC PYTHON use cases** | REST APIs · web scraping · Azure / AWS · SharePoint / OneDrive |
| 50 min | **PROC R use cases — clinical data** | ADaM exploration · KM curves · MMRM vs PROC MIXED |
| 25 min | **PROC R — scripts & flows** | External .R files · infile= · SAS Studio Flow R Program node |

---

## Why open-source integration?

### The challenge

- SAS is the **regulatory gold standard** for clinical submissions
- R and Python are where **new statistical methods** and data tooling live
- Teams were running two separate environments — no governance, no audit trail

> [!NOTE]
> **SAS Viya answer**  
> Run Python and R *inside* SAS. Your data, macro variables, and libraries stay in SAS. You add capability without rewriting.

### Two integration directions

| Direction | Tool | Use when |
|---|---|---|
| **Python/R inside SAS** | `PROC PYTHON`<br>`PROC R` | Extending SAS pipelines |
| **SAS inside Python/R** | `swat` package<br>`saspy` | Python/R-first workflows |

> [!TIP]
> **Today's focus**  
> PROC PYTHON and PROC R — the "inside SAS" path. Both run on the SAS compute server. Data never leaves SAS.

---

## PROC PYTHON vs PROC R — what's different?

|   | PROC PYTHON `Python` | PROC R `R`  **_New 2026.03_** |
|---|---|---|
| **Available since** | SAS Viya 2021.1 | SAS Viya 2026.03 |
| **Submit block** | `submit; ... endsubmit;` | `submit; ... endsubmit;` |
| **Import SAS dataset** | `SAS.sd2df("lib.ds")` | `sd2df("lib.ds")` |
| **Export to SAS** | `SAS.df2sd(df, "lib.ds")` | `df2sd(df, "lib.ds")` |
| **Read macro var** | `SAS.symget("name")` | `symget("name")` |
| **Results window** | `SAS.show(fig)` | `show(obj)` / `rplot(p)` |
| **External script** | `proc python infile="f.py";` | `proc r infile="f.R";` |
| **Pharma sweet spot** | APIs, cloud, ingestion, Office365 | Clinical stats, KM curves, MMRM, TLFs |

> [!NOTE]
> **The one thing to remember**  
> Python callbacks always use the `SAS.` prefix — it's an object. R injects them directly into the namespace — no prefix.

---

## 01 · Getting started

**Environment, anatomy of a PROC call, and callback methods**

Understanding your Python and R installation — and how data moves back and forth between SAS and the open-source session.

---

## Section 0 — Check your environment

#### Python

```python
proc python;
submit;
import sys
from importlib.metadata import distributions

print(f"Python: {sys.version}")
pkgs = sorted([f"  {d.name} {d.version}"
        for d in distributions()])
print(f"{len(pkgs)} packages installed")
endsubmit;
run;
```

- `importlib.metadata` — standard library, no pip install
- Output goes to the **SAS log**
- 378 packages on this image — highlight: pandas, requests, matplotlib, scikit-learn, swat

#### R

```r
proc r;
submit;
ip <- as.data.frame(
  installed.packages()[,
    c("Package","Version")])
# Full list to log
for (i in seq_len(nrow(ip)))
  cat(sprintf("%-28s %s\n",
      ip$Package[i], ip$Version[i]))
# Export to SAS for PROC PRINT
df2sd(ip, "work.r_packages")
endsubmit;
run;
```

- `show()` caps at 5 rows — use `cat()` + `df2sd()` for full list
- 150 packages: ggplot2, dplyr, survival, nlme, tidyverse, forecast
- `survminer` not installed — KM demo uses base survival + ggplot2

<sub>▶ Demo: Section 0 — `demo_procR_clinical.sas`</sub>

---

## Callback methods — moving data between SAS and open source

### Data transfer

```python
# Python — SAS. prefix always required
adsl = SAS.sd2df("work.adsl")    # SAS → pandas
SAS.df2sd(df, "work.result")   # pandas → SAS
```

```r
# R — no prefix, functions injected directly
adsl <- sd2df("work.adsl")       # SAS → data.frame
df2sd(df, "work.result")        # data.frame → SAS
```

### Macro variables

```python
# Python
trt = SAS.symget("trt_filter")  # read from SAS
SAS.symput("py_n", str(n))      # write to SAS
```

```r
# R
trt <- symget("trt_filter")     # read from SAS
symput("r_n", as.character(n)) # write to SAS
```

### Output

```python
# Python: show a DataFrame or figure
SAS.show(df)      # DataFrame → Results window
SAS.show(fig)     # matplotlib Figure → Results
```

```r
# R: show a data frame or plot
show(df, title="My Table")  # → Results window
rplot(p)                   # ggplot2 → Results
renderImage("/path/f.png") # saved file → Results
```

> [!NOTE]
> **Key insight**  
> `show()` in R has a default row limit of 5. To display all rows: use `df2sd()` and render with `PROC PRINT` from SAS.

> [!TIP]
> **Demo — Section 2**  
> Same ADSL summarisation in Python and R. `PROC COMPARE` confirms zero differences in the output datasets.

<sub>▶ Demo: Section 2 — `demo_procR_clinical.sas`</sub>

---

## 02 · Visualisation

**matplotlib in Python · ggplot2 and rplot() in R**

Rendering graphs directly in the SAS Results window — no file exports, no external viewers.

---

## Visualisation — Python: matplotlib

```python
import matplotlib
matplotlib.use('Agg')   # no display on server
import matplotlib.pyplot as plt

adsl = SAS.sd2df("work.adsl")

fig, axes = plt.subplots(1, 2, figsize=(10,4))

# Age histogram by treatment
for trt, grp in adsl.groupby("TRT01P"):
    axes[0].hist(grp["AGE"], bins=7,
                alpha=0.6, label=trt)
axes[0].legend()

# BMI boxplot
groups = [grp["BMI"].values
          for _, grp in adsl.groupby("TRT01P")]
axes[1].boxplot(groups, patch_artist=True)
axes[1].set_xticks([1,2])
axes[1].set_xticklabels(["DrugA","Placebo"])

plt.tight_layout()
SAS.show(fig)   # renders in Results window
```

### How it works

- `matplotlib.use('Agg')` must come **before** importing pyplot — SAS compute server has no display
- `SAS.show(fig)` accepts a matplotlib `Figure` object — rendered as SVG in the Results panel
- To save and reuse: `fig.savefig('/path/plot.png')` then `SAS.show('/path/plot.png')`

> [!TIP]
> **matplotlib 3.9+ note**  
> The `labels=` parameter was removed from `boxplot()`. Use `set_xticks()` + `set_xticklabels()` instead.

### Alternatives

- **seaborn** — statistical graphics built on matplotlib
- **plotly** — interactive charts (both installed)
- **altair** — declarative grammar similar to ggplot2

<sub>▶ Demo: Section 3a — `demo_procR_clinical.sas`</sub>

---

## Visualisation — R: ggplot2 and rplot()

```r
library(ggplot2); library(dplyr)
adsl <- sd2df("work.adsl")

# Plot 1: age histogram
p1 <- ggplot(adsl, aes(x=AGE, fill=TRT01P)) +
  geom_histogram(binwidth=5, alpha=0.7) +
  scale_fill_manual(
    values=c("#0072B2","#E69F00")) +
  theme_minimal()
rplot(p1)      # → Results window

# Plot 2: sex proportion bar
p2 <- ggplot(adsl, aes(x=TRT01P, fill=SEX)) +
  geom_bar(position="fill") +
  scale_y_continuous(
    labels=scales::percent_format())
rplot(p2)

# Plot 3: BMI boxplot
p3 <- ggplot(adsl,
        aes(x=TRT01P, y=BMI, fill=TRT01P)) +
  geom_boxplot(alpha=0.7)
rplot(p3)
```

### rplot() behaviour

- Sends any ggplot2 or base R graphic to the Results window
- Multiple `rplot()` calls in **one PROC R step** produce multiple outputs
- Save to file: `rplot(p, filename="plot.png")` — saved to `sas$workpath`
- Render saved file: `renderImage("/path/plot.png")`

### Why ggplot2 for pharma?

> [!NOTE]
> **Grammar of graphics**  
> Define *data*, *aesthetic mapping* (what goes on which axis), and *geometry* (histogram, step, boxplot). This maps directly to how clinical figures are specified in SAPs. Consistent across all TLF types.

<sub>▶ Demo: Section 3b — `demo_procR_clinical.sas`</sub>

---

## 03 · PROC PYTHON use cases

**REST APIs · Web scraping · Cloud · Office 365**

Where Python adds the most value: reaching external systems and pulling data into SAS that SAS cannot natively access.

---

## PROC PYTHON — REST API: ClinicalTrials.gov

```sas
/* Change sponsor to switch customer */
%let sponsor    = Novo Nordisk;
%let search_term = GLP-1;
```

```python
import requests, pandas as pd

sponsor     = SAS.symget("sponsor")
search_term = SAS.symget("search_term")

url    = "https://clinicaltrials.gov/api/v2/studies"
params = {
    "query.spons":          sponsor,
    "query.term":           search_term,
    "filter.overallStatus": "COMPLETED",
    "pageSize": 10
}

try:
    resp = requests.get(url, params=params,
                         timeout=15)
    resp.raise_for_status()
    # ... parse JSON, build DataFrame ...
    SAS.df2sd(df, "work.ct_trials")
    SAS.show(df)
except requests.exceptions.ConnectionError:
    print("No internet access.")
```

### What this demonstrates

- `SAS.symget()` injects SAS macro variables as Python strings — parameters never hardcoded
- `raise_for_status()` propagates HTTP errors to the SAS log
- `try/except` degrades gracefully when network is unavailable
- Result lands in `work.ct_trials` — ready for any SAS procedure

### Same pattern for

- **Azure Blob Storage** — `azure-storage-blob` (installed)
- **AWS S3** — `boto3`
- **SharePoint / OneDrive** — `office365-rest-python-client`
- **Internal APIs** — CTMS, pharmacovigilance, EHR

> [!TIP]
> **Live demo**  
> Change `%let sponsor = Servier;` — re-run same code, different data. Shows parameter-driven API calls in one line.

<sub>▶ Demo: Section 7 — `demo_procR_clinical.sas`</sub>

---

## PROC PYTHON — other use cases

### Web scraping

```python
import requests
from bs4 import BeautifulSoup

resp = requests.get("https://ema.europa.eu/...")
soup = BeautifulSoup(resp.text, "html.parser")
# Extract approved indications, dates ...
SAS.df2sd(df, "work.ema_labels")
```

- `beautifulsoup4` is installed (4.15)
- Use when no public API exists (EMA product pages, package inserts)

### Azure Blob / SharePoint

```python
# Read CSV from Azure Blob into SAS
from azure.storage.blob import BlobServiceClient
import pandas as pd, io

conn = SAS.symget("AZURE_CONN_STR")
client = BlobServiceClient.from_connection_string(conn)
data = client.get_blob_client(
    container="clinical", blob="adsl.csv"
).download_blob().readall()
df = pd.read_csv(io.BytesIO(data))
SAS.df2sd(df, "work.adsl_cloud")
```

### When to use PROC PYTHON vs PROC R

| Task | Use |
|---|---|
| Call a REST API | `Python` |
| Read Azure / S3 / GCS | `Python` |
| Parse XML, Avro, JSON | `Python` |
| SharePoint / OneDrive | `Python` |
| Kaplan-Meier curve | `R` |
| Mixed models (MMRM) | `R` |
| Forest / waterfall plots | `R` |
| ggplot2 TLF graphics | `R` |
| Data exploration / ADSL | `R` |

---

## 04 · PROC R — Clinical data

**ADaM datasets · Kaplan-Meier curves · Mixed models**

Where PROC R adds the most value in pharma: statistical analysis and clinical graphics on ADaM-structured data.

---

## PROC R — Kaplan-Meier survival curve (ADTTE)

```r
library(survival); library(ggplot2)

adtte  <- sd2df("work.adtte")
# ADTTE: AVAL=time(days), CNSR=1 censored
km_fit <- survfit(
  Surv(AVAL, CNSR==0) ~ TRT01P, data=adtte)

# Tidy fit into data frame
km_df <- data.frame(
  time=km_fit$time, surv=km_fit$surv,
  upper=km_fit$upper, lower=km_fit$lower,
  strata=rep(names(km_fit$strata),
                km_fit$strata))

# Log-rank p-value
lr   <- survdiff(Surv(AVAL,CNSR==0)~TRT01P,
                  data=adtte)
pval <- round(1 - pchisq(lr$chisq,df=1),3)

p <- ggplot(km_df,
        aes(x=time, y=surv,
            color=strata, fill=strata)) +
  geom_step(linewidth=1.1) +
  geom_ribbon(aes(ymin=lower,ymax=upper),
              alpha=0.15, color=NA) +
  annotate("text",x=300,y=0.95,
    label=paste0("p = ",pval))
rplot(p)
```

### Outputs from the demo

- KM step curve with 95% CI ribbon
- Log-rank p-value annotated on the plot
- `work.km_median` — median OS per arm returned to SAS
- `work.km_atrisk` — number at risk table at t=0,100,...,500

### PROC LIFETEST — the SAS equivalent

```sas
proc lifetest data=work.adtte
  plots=survival(atrisk=0 to 600 by 100);
  time AVAL * CNSR(1);
  strata TRT01P;
run;
```

> [!NOTE]
> **Discussion**  
> Both produce identical KM estimates. R gives more visual flexibility. SAS gives validated ODS output for regulatory submission. Both can live in the same program.

> [!TIP]
> **survminer upgrade**  
> If `survminer` is installed: `ggsurvplot()` gives risk table, CI, and p-value in a single call.

<sub>▶ Demo: Section 4 — `demo_procR_clinical.sas`</sub>

---

## PROC R — Mixed model (MMRM) vs PROC MIXED

#### R — nlme

```r
library(nlme)
endpoint <- symget("endpoint")  # "HbA1c (%)"
adlb     <- sd2df("work.adlb")

df <- adlb %>%
  filter(PARAM == endpoint) %>%
  mutate(CHG=AVAL-BASE,
         VISIT=factor(VISIT),
         TRT01P=factor(TRT01P))

model <- lme(
  fixed     = CHG ~ TRT01P * VISIT + BASE,
  random    = ~1 | USUBJID,
  data      = df,
  na.action = na.omit)

coef_tbl <- as.data.frame(
  summary(model)$tTable)
df2sd(coef_tbl, "work.r_mmrm")
symput("r_converged", "YES")
```

#### SAS — PROC MIXED

```sas
proc mixed data=work.adlb;
  where PARAM="&endpoint";
  class USUBJID TRT01P VISIT;
  model CHG = TRT01P VISIT
              TRT01P*VISIT BASE
              / ddfm=KR s;
  repeated VISIT
    / subject=USUBJID type=UN;
  lsmeans TRT01P*VISIT / diff cl;
  ods output LSMeans=work.sas_lsmeans;
run;
```

### Discussion points

- Estimates are very close — same model, same data
- Key difference: **denominator df** — SAS uses Kenward-Roger (`ddfm=KR`), the regulatory standard
- `symput("r_converged","YES")` — model metadata flows back to SAS

> [!NOTE]
> **Regulatory guidance**  
> For submissions: `PROC MIXED` is the validated reference. R MMRM is valuable for cross-validation and exploratory analysis during development.

<sub>▶ Demo: Section 5 — `demo_procR_clinical.sas`</sub>

---

## 05 · External scripts

**PROC PYTHON & PROC R — calling external script files**

Both procedures support an `infile=` option to load scripts from the server filesystem or SAS Content — no need to embed all code inline.

---

## External scripts — PROC PYTHON and PROC R

#### PROC PYTHON — infile=

```sas
/* Option 1: server filesystem path */
proc python infile='/tmp/my_script.py';
submit;
my_function()          # call function defined in script
print("y = " + y)
endsubmit;
run;

/* Option 2: fileref — server path */
filename pyScript '/path/analysis.py';
proc python infile=pyScript;
run;

/* Option 3: fileref — SAS Content (filesrvc) */
filename pyScript filesrvc
  folderPath='/My Folder'
  filename='analysis.py';
proc python infile=pyScript;
run;
```

#### PROC R — infile=

```sas
/* Option 1: server filesystem path */
proc r infile="/path/analysis.R";
run;

/* Option 2: fileref — server path */
filename clinR "/path/analysis.R";
proc r infile=clinR;
run;

/* Option 3: fileref — SAS Content */
filename clinR filesrvc
  folderPath='/My Folder'
  filename='analysis.R';
proc r infile=clinR;
run;
```

> [!NOTE]
> **infile= + submit block**  
> For PROC PYTHON, the script is loaded first (defines functions/variables), then the optional `submit; ... endsubmit;` block can call those functions. PROC R works the same way.

> [!TIP]
> **SAS Content (filesrvc)**  
> Stores scripts centrally in SAS Viya — no server filesystem access needed. Works with SAS Studio, Flows, and scheduled jobs.

### Passing parameters via macro variables

```sas
%let trt = DrugA;
filename kmR "/path/km.R";
proc r infile=kmR; run;
%put Median OS: &r_median_os days;
```

<sub>▶ Demo: Section 6 — `demo_procR_clinical.sas`</sub>

---

## Environment management & governance

### Python virtual environments

```sas
/* Switch Python environment */
options set=PROC_PYPATH=
  "/path/to/venv/bin/python";
options set=LD_LIBRARY_PATH=
  "/path/to/venv/lib";

proc python restart;
submit;
import subprocess
subprocess.run(["pip", "install", "-r",
  "/path/requirements.txt"])
endsubmit;
run;
```

- `requirements.txt` pins exact versions — reproducible across dev / test / prod
- SAS Studio custom step on GitHub: create virtual environments without SAS admin

### R package management with renv

```r
# Create a project-level lockfile
# (run once in R, outside PROC R)
renv::snapshot()  # save current state
renv::restore()   # reinstall from lockfile
```

- `renv.lock` = R equivalent of `requirements.txt`
- Commit the lockfile to Git — anyone can reproduce the environment

### Why this matters in pharma

| Concern | Solution |
|---|---|
| CSR reproducibility | Pin package versions in lockfile |
| 21 CFR Part 11 | Audit trail via SAS log + Git history |
| Validation | Validated SAS step for regulatory output; R for exploratory |
| Multi-project isolation | Separate virtual env per project |

---

## Quick reference — callback methods

| Action | PROC PYTHON | PROC R |
|---|---|---|
| Submit block | `submit; ... endsubmit;` | `submit; ... endsubmit;` |
| SAS dataset → language | `SAS.sd2df("lib.ds")` | `sd2df("lib.ds")` |
| DataFrame → SAS | `SAS.df2sd(df, "lib.ds")` | `df2sd(df, "lib.ds")` |
| Read macro var | `SAS.symget("name")` | `symget("name")` |
| Write macro var | `SAS.symput("name", val)` | `symput("name", val)` |
| Call SAS function | `SAS.sasfnc("func", arg)` | `sasfnc("func", arg)` |
| Log output | `print()` | `cat()` / `message()` |
| Results window | `SAS.show(fig_or_df)` | `show(obj)` |
| Render plot | `SAS.show(matplotlib_fig)` | `rplot(ggplot_obj)` |
| Render saved image | `SAS.show("/path/file.png")` | `renderImage("/path/file.png")` |
| External script | `proc python infile="f.py";` | `proc r infile="f.R";` |
| Pharma sweet spot | APIs · cloud · ingestion · Office365 | Clinical stats · KM · MMRM · TLFs |

---

## Resources & next steps

### PROC R blog series (SAS Communities)

- **Part 1** — Getting started: sd2df, df2sd, symget, symput, show
- **Part 2** — sasfnc(), rplot(), renderImage(), multiple plots
- **Part 3** — Creating and calling external .R scripts
- **Part 4** — R Program step in SAS Data and AI Studio Flows

### PROC PYTHON

- SAS Communities: *"Using PROC PYTHON to augment your SAS programs"*
- SAS Blog: *"Python à la carte"* — virtual environments
- PharmaSUG 2026 ET-207
- MWSUG 2024 BB-093

### Workshop files

| File | Purpose |
|---|---|
| `demo_procR_clinical.sas` | Full runnable demo script |
| `demo_procR_clinical.md` | Annotated walkthrough with discussion points |
| `slides.md` / `slides.pptx` | This presentation |

### SAS documentation

- PROC PYTHON reference — *SAS Viya: Procedures*
- PROC R reference — *SAS Viya: Procedures* (2026.03+)
- Virtual environments — GitHub: *sas-studio-custom-steps / Python Create Virtual Environment*

> [!TIP]
> **Questions?**  
> Run any section of `demo_procR_clinical.sas` — each section is independent. Change `%let sponsor`, `%let trt_filter`, or `%let endpoint` to explore different results.
