# PROC PYTHON & PROC R in SAS Viya
### Open-Source Integration Workshop — Novo Nordisk / Servier

A complete workshop package for experienced SAS programmers covering **PROC PYTHON** and **PROC R** in SAS Viya. Includes a slide deck, a runnable demo script, a trainer walkthrough, and hands-on exercises — all grounded in ADaM clinical datasets.

---

## Requirements

| Component | Version |
|---|---|
| SAS Viya | 2026.03+ (PROC R requires 2026.03; PROC PYTHON available from 2021.1) |
| Python | 3.8+ (3.12 on standard Viya images) |
| R | 4.0+ (4.4 on standard Viya images) |
| R packages | `ggplot2`, `dplyr`, `survival`, `nlme`, `tidyverse` |
| Python packages | `pandas`, `requests`, `matplotlib` (all included on standard Viya images) |

> No external dependencies are needed to open the slides or read the documentation — everything runs in a browser or SAS Studio.

---

## Repository structure

```
.
├── README.md                        ← this file
├── demo/
│   ├── demo_procR_clinical.sas      ← runnable SAS demo script (7 sections)
│   └── demo_procR_clinical.md       ← annotated walkthrough / trainer notes
├── practice/
│   └── practice.md                  ← 20 graded hands-on exercises
├── slides/
│   └── slides.html                  ← self-contained slide deck (21 slides)
└── doc/
    ├── Introducing_PROC_R_Part1.mhtml
    ├── Introducing_PROC_R_Part2.mhtml
    ├── Introducing_PROC_R_Part3.mhtml
    ├── Introducing_PROC_R_Part4.mhtml
    ├── PROC_PYTHON_SAS_Communities.mhtml
    ├── PharmaSUG-2026-ET-207.pdf
    ├── MWSUG-2024-BB-093.pdf
    └── rlafler_mbravo_proc_python.pdf
```

---

## Quick start

### 1. Open the slides
Open [`slides/slides.html`](slides/slides.html) in any browser.  
Navigate with **arrow keys**, **space bar**, or the on-screen buttons. No internet connection required.

### 2. Run the demo
Open [`demo/demo_procR_clinical.sas`](demo/demo_procR_clinical.sas) in SAS Studio.  
Run sections one at a time with **F3** (run selected). Each section is independent.

**Key parameters — change these to customise the demo:**

```sas
%let trt_filter  = DrugA;       /* Section 2 & 5 — treatment arm    */
%let endpoint    = HbA1c (%);   /* Section 5     — lab parameter     */
%let sponsor     = Novo Nordisk;/* Section 7     — "Novo Nordisk" or "Servier" */
%let search_term = GLP-1;       /* Section 7     — ClinicalTrials.gov term     */
```

### 3. Read the trainer walkthrough
[`demo/demo_procR_clinical.md`](demo/demo_procR_clinical.md) maps every code block to what to say, what to point out, and common discussion questions. Includes a troubleshooting section for known errors.

### 4. Run the exercises
[`practice/practice.md`](practice/practice.md) has 20 exercises graded from 🟢 Starter to 🔴 Advanced. Solutions are in collapsible blocks — participants try first, reveal if stuck.

---

## Demo script — section map

| Section | Topic | PROC | Key output |
|---|---|---|---|
| 0 | Check your environment | PYTHON + R | Package lists to log and Results |
| 1 | Synthetic ADaM datasets | SAS | `work.adsl`, `work.adtte`, `work.adlb` |
| 2 | Callback round-trip | PYTHON + R | `sd2df` / `df2sd` / `symget` / `symput` / `show` |
| 3 | Visualisation | PYTHON + R | matplotlib figures; ggplot2 demographic panel |
| 4 | Kaplan-Meier curve | R | KM plot from ADTTE; `work.km_median` |
| 5 | Mixed model vs PROC MIXED | R + SAS | MMRM fixed effects; LSMeans comparison |
| 6 | External R scripts | R | `proc r infile=`; fileref pattern |
| 7 | REST API | PYTHON | ClinicalTrials.gov → `work.ct_trials` |

---

## Callback reference

The single most important concept in the workshop:

| Action | PROC PYTHON | PROC R |
|---|---|---|
| SAS dataset → language | `SAS.sd2df("lib.ds")` | `sd2df("lib.ds")` |
| DataFrame → SAS | `SAS.df2sd(df, "lib.ds")` | `df2sd(df, "lib.ds")` |
| Read macro variable | `SAS.symget("name")` | `symget("name")` |
| Write macro variable | `SAS.symput("name", val)` | `symput("name", val)` |
| Log output | `print()` | `cat()` |
| Results window | `SAS.show(fig_or_df)` | `show(obj)` / `rplot(p)` |
| External script | — | `proc r infile="f.R";` |

> **Python always uses the `SAS.` prefix. R injects the callbacks directly — no prefix needed.**

---

## Pharma use-case split

**Use PROC PYTHON for:**
- REST API calls (`requests` — ClinicalTrials.gov, internal CTMS, PV databases)
- Cloud storage ingestion (Azure Blob, AWS S3, GCloud)
- SharePoint / OneDrive integration
- Parsing non-standard file formats (Avro, nested JSON, XML)
- Web scraping (EMA/FDA label pages, regulatory databases)

**Use PROC R for:**
- Clinical graphics on ADaM data (KM curves, forest plots, waterfall plots)
- Mixed models and survival analysis (`nlme`, `lme4`, `survival`)
- Data exploration with `ggplot2` and `tidyverse`
- Cross-validating SAS statistical results
- Comparing PROC MIXED and R MMRM outputs

---

## Reference material

All saved to [`doc/`](doc/):

| File | Description |
|---|---|
| [`Introducing_PROC_R_Part1.mhtml`](doc/Introducing_PROC_R_Part1.mhtml) | SAS Communities: PROC R basics — sd2df, df2sd, symget, symput, show |
| [`Introducing_PROC_R_Part2.mhtml`](doc/Introducing_PROC_R_Part2.mhtml) | SAS Communities: sasfnc(), rplot(), renderImage(), multiple plots |
| [`Introducing_PROC_R_Part3.mhtml`](doc/Introducing_PROC_R_Part3.mhtml) | SAS Communities: creating and calling external .R scripts |
| [`Introducing_PROC_R_Part4.mhtml`](doc/Introducing_PROC_R_Part4.mhtml) | SAS Communities: R Program step in SAS Data and AI Studio Flows |
| [`PROC_PYTHON_SAS_Communities.mhtml`](doc/PROC_PYTHON_SAS_Communities.mhtml) | SAS Communities: "Using PROC PYTHON to augment your SAS programs" |
| [`PharmaSUG-2026-ET-207.pdf`](doc/PharmaSUG-2026-ET-207.pdf) | PharmaSUG 2026 paper on PROC PYTHON in pharma |
| [`MWSUG-2024-BB-093.pdf`](doc/MWSUG-2024-BB-093.pdf) | MWSUG 2024 paper on open-source integration |
| [`rlafler_mbravo_proc_python.pdf`](doc/rlafler_mbravo_proc_python.pdf) | MISUG presentation: PROC PYTHON practical examples |

---

## Workshop formats

### Half-day (4 hours)
All 7 demo sections + exercises from [`practice/practice.md`](practice/practice.md). Participants run code alongside the trainer.

### Highlights session (1.5 hours)
Slides 1–4 (framing) → Section 2 demo (callback round-trip) → Section 7 demo (REST API, switch sponsor live) → Section 4 demo (KM curve) → Slide 20 (quick reference). No hands-on exercises.

---

## Notes for trainers

- The demo creates **synthetic ADaM data** in `WORK`. In a production session, point participants at a real ADaM libref by replacing `work.adsl`, `work.adtte`, and `work.adlb` at the top of Section 1.
- **`survminer` is not installed** on the standard Viya image — the KM demo in Section 4 uses base `survival` + `ggplot2`. If the course image has it installed, the `ggsurvplot()` commented block in `demo_procR_clinical.md` is the upgrade path.
- Section 6 (external R scripts) requires participants to save a `.R` file first. Adjust the file path in the commented code block to match the server home directory.
- Section 7 requires internet access from the compute server. If the training environment is air-gapped, the `try/except ConnectionError` block degrades gracefully with a printed note.

---

## License

Workshop materials. Not for redistribution without permission.  
SAS, SAS Viya, SAS Studio are trademarks of SAS Institute Inc.

---

*Built for Novo Nordisk and Servier — October 2026*
