<a id="senzing-eda-tutorial-step-by-step-workbook"></a>
# Senzing EDA Tutorial — Step-by-Step Workbook

Follow this workbook to complete every article in the official Senzing **Exploratory Data Analysis (EDA)** series on your **M1 Mac + Docker** lab.

**Official series:** [Exploratory Data Analysis (EDA)](https://senzing.zendesk.com/hc/en-us/sections/360009388534-Exploratory-Data-Analysis-EDA)

**Your project:** `~/Dev/Tutorials/senzing-demo`  
**Companion docs:** [CORE-CONCEPTS.md](./CORE-CONCEPTS.md) · [CHEATSHEET.md](./CHEATSHEET.md) · [EXERCISES.md](./EXERCISES.md) · [DATA-MAPPING-TUTORIAL.md](./DATA-MAPPING-TUTORIAL.md)

**New?** Read [CORE-CONCEPTS.md](./CORE-CONCEPTS.md) before Part 1.

---

## Table of contents

**Workbooks:** [CORE-CONCEPTS.md](./CORE-CONCEPTS.md) · [CHEATSHEET.md](./CHEATSHEET.md) · [EXERCISES.md](./EXERCISES.md) · [DATA-MAPPING-TUTORIAL.md](./DATA-MAPPING-TUTORIAL.md)

- [How this maps to the official tutorials](#how-this-maps-to-the-official-tutorials)
- [Before every session](#before-every-session)
- [Progress checklist](#progress-checklist)
- [Part 0 — EDA Overview](#part-0-eda-overview)
  - [What you'll learn](#what-youll-learn)
  - [The three EDA tools](#the-three-eda-tools)
  - [Reports from sz_snapshot (viewed in sz_explorer after `load`)](#reports-from-sz_snapshot-viewed-in-sz_explorer-after-load)
- [Part 1 — Loading the truth set demo](#part-1-loading-the-truth-set-demo)
  - [Step 1.1 — Start PostgreSQL (Mac)](#step-11-start-postgresql-mac)
  - [Step 1.2 — Initialize Senzing database (first time only)](#step-12-initialize-senzing-database-first-time-only)
  - [Step 1.3 — Register data sources (Mac)](#step-13-register-data-sources-mac)
  - [Step 1.4 — Load truth set files (Mac)](#step-14-load-truth-set-files-mac)
  - [Step 1.5 — Verify load (container)](#step-15-verify-load-container)
  - [Optional: fresh database (truth set only)](#optional-fresh-database-truth-set-only)
- [Part 2 — Basic exploration](#part-2-basic-exploration)
  - [Step 2.1 — Start explorer (container)](#step-21-start-explorer-container)
  - [Step 2.2 — Search by name](#step-22-search-by-name)
  - [Step 2.3 — Compare entities side-by-side](#step-23-compare-entities-side-by-side)
  - [Step 2.4 — Get entity detail](#step-24-get-entity-detail)
  - [Step 2.5 — Why records are IN an entity (`how`)](#step-25-why-records-are-in-an-entity-how)
  - [Step 2.6 — Why two entities did NOT merge](#step-26-why-two-entities-did-not-merge)
  - [Step 2.7 — JSON search (name + address + DOB)](#step-27-json-search-name-address-dob)
  - [Step 2.8 — Interesting truth-set searches](#step-28-interesting-truth-set-searches)
  - [Step 2.9 — Exit](#step-29-exit)
- [Part 3 — Taking a snapshot](#part-3-taking-a-snapshot)
  - [Step 3.1 — Take snapshot with audit CSV (Mac)](#step-31-take-snapshot-with-audit-csv-mac)
  - [Step 3.2 — Load snapshot in explorer (container)](#step-32-load-snapshot-in-explorer-container)
  - [Step 3.3 — Data source summary](#step-33-data-source-summary)
  - [Step 3.4 — Cross source summary (watchlist screening)](#step-34-cross-source-summary-watchlist-screening)
  - [Step 3.5 — Entity size breakdown](#step-35-entity-size-breakdown)
  - [Step 3.6 — Exit](#step-36-exit)
- [Part 4 — Comparing ER results (audit)](#part-4-comparing-er-results-audit)
  - [Step 4.1 — Audit vs definitive truth (Mac)](#step-41-audit-vs-definitive-truth-mac)
  - [Step 4.2 — Audit vs alternate key (Mac)](#step-42-audit-vs-alternate-key-mac)
  - [Step 4.3 — Explore audit in sz_explorer (container)](#step-43-explore-audit-in-sz_explorer-container)
  - [Step 4.4 — Drill into MERGE cases](#step-44-drill-into-merge-cases)
  - [Step 4.5 — Drill into SPLIT cases](#step-45-drill-into-split-cases)
  - [Step 4.6 — Help and export](#step-46-help-and-export)
- [Part 5 — Understanding snapshot statistics (reference)](#part-5-understanding-snapshot-statistics-reference)
  - [Match levels](#match-levels)
  - [Database-level stats (top of `truthset_snapshot.json`)](#database-level-stats-top-of-truthset_snapshotjson)
  - [Cross-source note](#cross-source-note)
- [Part 6 — Understanding audit statistics (reference)](#part-6-understanding-audit-statistics-reference)
  - [Formulas](#formulas)
  - [Entity-level stats](#entity-level-stats)
  - [Pairwise vs entity review](#pairwise-vs-entity-review)
- [Quick command reference (EDA sessions)](#quick-command-reference-eda-sessions)
  - [Mac — snapshot & audit](#mac-snapshot-audit)
  - [Container — explorer workflow](#container-explorer-workflow)
- [Troubleshooting](#troubleshooting)
- [After the EDA series](#after-the-eda-series)

---

<a id="how-this-maps-to-the-official-tutorials"></a>
## How this maps to the official tutorials

The Senzing docs were written for Linux installs using Python scripts in `/g2/python`. Your lab uses the same tools under modern names inside Docker:

| Official (docs) | Your lab (Mac) | What it does |
|-----------------|----------------|--------------|
| `G2Loader.py` | `sz-file-loader` + `sz_configtool` | Load data |
| `G2Explorer.py` | `sz_explorer` | Interactive exploration |
| `G2Snapshot.py` | `sz_snapshot` | Batch statistics → `.json` |
| `G2Audit.py` | `sz_audit` | Compare results vs truth key |
| Prompt `(g2)` | Prompt `(szeda)` | Explorer command line |
| `dataSourceSummary` | `data_source_summary` | snake_case in sz_explorer |
| `crossSourceSummary` | `cross_source_summary` | |
| `entitySizeBreakdown` | `entity_size_breakdown` | |
| `auditSummary` | `audit_summary` | |
| `compare 1, 1003, 5` | `compare 1 1003 5` | **spaces**, not commas |
| `./G2Explorer.py -s snap.json` | `load truthset_snapshot.json` | Load snapshot inside explorer |

---

<a id="before-every-session"></a>
## Before every session

**Mac terminal:**

```bash
cd ~/Dev/Tutorials/senzing-demo
docker compose up -d
source ./setup-env.sh
```

**Open sz_explorer** — see **[EXPLORER-SESSION.md](./EXPLORER-SESSION.md)** for the full 4-step recipe (Mac → container → `(szeda)` → exit).

Quick version:

**Step 1 — Mac:** `source ./setup-env.sh` then:

```bash
docker run --rm -it -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools
```

**Step 2 — Container:** `sz_explorer` → prompt `(szeda)`

**Step 3 — Explorer:** run the commands in each part below

**Step 4 — Exit:** `quit` then `exit`

---

<a id="progress-checklist"></a>
## Progress checklist

| # | Official article | This workbook | Done |
|---|------------------|---------------|------|
| 0 | — | Setup & tool overview | ☐ |
| 1 | [EDA 1 — Loading truth set](https://senzing.zendesk.com/hc/en-us/articles/360051385634) | Load truth set demo | ☐ |
| 2 | [EDA 2 — Basic exploration](https://senzing.zendesk.com/hc/en-us/articles/360051768234) | search, compare, get, why | ☐ |
| 3 | [EDA 3 — Taking a snapshot](https://senzing.zendesk.com/hc/en-us/articles/360051874294) | sz_snapshot + reports | ☐ |
| 4 | [EDA 4 — Comparing ER results](https://senzing.zendesk.com/hc/en-us/articles/360050643034) | sz_audit + audit_summary | ☐ |
| 5 | [G2Snapshot statistics](https://senzing.zendesk.com/hc/en-us/articles/360035699253) | Read & interpret reports | ☐ |
| 6 | [G2Audit statistics](https://senzing.zendesk.com/hc/en-us/articles/360045624093) | Precision, recall, F1 | ☐ |

---

<a id="part-0-eda-overview"></a>
# Part 0 — EDA Overview

**Official:** [Exploratory Data Analysis Overview (EDA Tools)](https://senzing.zendesk.com/hc/en-us/articles/360052040553-Exploratory-Data-Analysis-Overview-EDA-Tools)

<a id="what-youll-learn"></a>
### What you'll learn

After loading data, you need answers to questions like:

- How many **duplicate customers** do I have?
- Were any customers on a **watch list**?
- What is that **ambiguous match**?
- How does Senzing compare to a **truth set**?

<a id="the-three-eda-tools"></a>
### The three EDA tools

| Tool | Purpose |
|------|---------|
| **sz_explorer** | Search, compare, get records, ask why/how |
| **sz_snapshot** | Pre-compute reports: data source summary, cross-source summary, entity size breakdown |
| **sz_audit** | Compare Senzing's groupings to a truth key (precision / recall / F1) |

<a id="reports-from-sz_snapshot-viewed-in-sz_explorer-after-load"></a>
### Reports from sz_snapshot (viewed in sz_explorer after `load`)

1. **data_source_summary** — duplicates *within* each source (e.g. duplicate CUSTOMERS)
2. **cross_source_summary** — matches *across* sources (e.g. CUSTOMERS ↔ WATCHLIST)
3. **entity_size_breakdown** — largest entities; flags possible **over-matching**

**✅ Part 0 done when:** You can name all three tools and three report types.

---

<a id="part-1-loading-the-truth-set-demo"></a>
# Part 1 — Loading the truth set demo

**Official:** [EDA 1 — Loading the truth set demo](https://senzing.zendesk.com/hc/en-us/articles/360051385634-Exploratory-Data-Analysis-1-Loading-the-truth-set-demo)

Official command:

```text
./G2Loader.py --FORCEPURGE -p demo/truth/truthset-project3.json
```

Your lab equivalent loads the same **truth set project 3** from three JSONL files.

<a id="step-11-start-postgresql-mac"></a>
### Step 1.1 — Start PostgreSQL (Mac)

```bash
cd ~/Dev/Tutorials/senzing-demo
docker compose up -d
source ./setup-env.sh
```

<a id="step-12-initialize-senzing-database-first-time-only"></a>
### Step 1.2 — Initialize Senzing database (first time only)

```bash
docker run --rm \
  --env SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/init-database \
  --install-senzing-er-configuration
```

**Expect:** `Processed 45 lines with no failures` (or "already exists" on re-run).

<a id="step-13-register-data-sources-mac"></a>
### Step 1.3 — Register data sources (Mac)

```bash
printf 'addDataSource CUSTOMERS\naddDataSource REFERENCE\naddDataSource WATCHLIST\nsave\ny\nquit\n' | \
  docker run --rm -i -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/senzingsdk-tools sz_configtool
```

**Expect:** Three sources added (or "already exists").

<a id="step-14-load-truth-set-files-mac"></a>
### Step 1.4 — Load truth set files (Mac)

This is the equivalent of `--FORCEPURGE -p truthset-project3.json` for a **clean truth-set-only** run.

> **Note:** If you previously loaded Parquet pipeline data (`CUSTOMERS_PQ`, `VENDORS_PQ`), your counts will include those extra sources. For a **pure EDA tutorial** matching the docs, either skip pipeline exercises until Part 4 is done, or reset the database (see **Optional: fresh database** at end of Part 1).

```bash
source ./setup-env.sh

for f in customers reference watchlist; do
  echo "=== Loading ${f}.jsonl ==="
  docker run --rm -u $(id -u) -v ${PWD}:/data \
    -e SENZING_ENGINE_CONFIGURATION_JSON \
    senzing/sz-file-loader -f /data/${f}.jsonl
done
```

**Expect:** Each file → `Successfully loaded ... 0 error(s)`.

Approximate counts:

| File | Records |
|------|---------|
| customers.jsonl | ~120 |
| reference.jsonl | ~22 |
| watchlist.jsonl | ~17 |

<a id="step-15-verify-load-container"></a>
### Step 1.5 — Verify load (container)

```bash
docker run --rm -it -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools
```

```
sz_explorer
quick_look
quit
exit
```

**Expect:** CUSTOMERS, REFERENCE, WATCHLIST with record counts.

**✅ Part 1 done when:** `quick_look` shows all three truth-set sources with no load errors.

<a id="optional-fresh-database-truth-set-only"></a>
### Optional: fresh database (truth set only)

If you want numbers to match the official tutorial screenshots (no `CUSTOMERS_PQ`, no `VENDORS_PQ`):

```bash
docker compose down -v
docker compose up -d
source ./setup-env.sh
# Re-run Steps 1.2–1.4 only (do not run pipeline scripts yet)
```

---

<a id="part-2-basic-exploration"></a>
# Part 2 — Basic exploration

**Official:** [EDA 2 — Basic exploration](https://senzing.zendesk.com/hc/en-us/articles/360051768234-Exploratory-Data-Analysis-2-Basic-exploration)

<a id="step-21-start-explorer-container"></a>
### Step 2.1 — Start explorer (container)

```bash
docker run --rm -it -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools
```

```
sz_explorer
help
```

**Expect:** List of available commands (similar to official `help` at `(g2)` prompt).

---

<a id="step-22-search-by-name"></a>
### Step 2.2 — Search by name

Official:

```text
search robert smith
```

Your command (same):

```
search robert smith
```

**What to look for** (from the tutorial):

| Entity | Who | Notes |
|--------|-----|-------|
| **#1** (typical) | Robert Smith | ~4 CUSTOMERS records merged |
| **#1003** (typical) | Robert Smith | Watchlist only |
| **#5** (typical) | Rob Smith Sr | Customer **and** watchlist |

**Learn:**
- **Match key** column — which attributes matched (e.g. `+NAME`)
- **Match score** — best matches ranked on top

Write your entity IDs here:

| Entity | ID you got |
|--------|------------|
| Robert Smith (multi-customer) | ______ |
| Robert Smith (watchlist) | ______ |
| Rob Smith Sr | ______ |

---

<a id="step-23-compare-entities-side-by-side"></a>
### Step 2.3 — Compare entities side-by-side

Official:

```text
compare 1, 1003, 5
```

Your command (**spaces, not commas**):

```
compare 1 1003 5
```

(Replace with **your** entity IDs from search if different.)

**Use arrow keys** ← → to scroll wide tables. Press **Q** to exit compare view.

**Learn from the tutorial:**
1. Two customer Roberts may share an address; DOBs 24 years apart → likely **father and son**
2. Middle watchlist Robert is **not** the same as the customer Roberts

---

<a id="step-24-get-entity-detail"></a>
### Step 2.4 — Get entity detail

Official:

```text
get detail 1
```

Your command:

```
get 1 detail
```

(Use your Robert Smith customer entity ID.)

**Three columns:**

| Column | Content |
|--------|---------|
| Sources | DATA_SOURCE, RECORD_ID, match key, rule |
| Features | Name, DOB, address, identifiers used for resolution |
| Additional | Status, amounts, dates — helps analyst decisions |

Press **Q** when done.

**Also try by record:**

```
get CUSTOMERS 1001 detail
```

---

<a id="step-25-why-records-are-in-an-entity-how"></a>
### Step 2.5 — Why records are IN an entity (`how`)

Official:

```text
why 1
```

In modern `sz_explorer`, use **`how`** for the merge decision tree inside one entity:

```
how 1
```

(Replace `1` with your Robert Smith entity ID.)

**Press Enter** to step through the tree. **Q** to quit.

**What the tutorial teaches (read the why/how screen):**

| Color | Meaning |
|-------|---------|
| **Green** | Matched — helped the score |
| **Red** | Did not match — hurt the score |
| **Yellow** | Different but did not hurt (e.g. moved address) |
| **Cyan** | Only helped find candidates |

Example insight: Customer 1004 may share only a **weak name** with 1001, but still merged via stronger links to other records in the entity.

Type `help why` in explorer for the full color legend.

---

<a id="step-26-why-two-entities-did-not-merge"></a>
### Step 2.6 — Why two entities did NOT merge

Official:

```text
why 1, 5
```

Your command:

```
why 1 5
```

(Use your customer Robert entity ID and Rob Smith Sr entity ID.)

**Learn:**
- Often **related** by name + address (green)
- **Red DOB** — different birth dates kept them apart
- Cyan keys — how Senzing found them as candidates

---

<a id="step-27-json-search-name-address-dob"></a>
### Step 2.7 — JSON search (name + address + DOB)

Official:

```text
search {"NAME_FULL": "robert smith", "ADDR_FULL": "123 Main Street, Las Vegas NV", "DATE_OF_BIRTH": "3/31/54"}
```

Try in your explorer:

```
search {"NAME_FULL": "robert smith", "ADDR_FULL": "123 Main Street, Las Vegas NV", "DATE_OF_BIRTH": "3/31/54"}
```

**Learn:**
- Rob Smith Sr should rank higher (name + DOB + address match)
- Pure watchlist Robert drops to bottom (name only)
- Max score ≈ 300 when searching 3 attributes (100 each)

If JSON search fails, try field search:

```
search NAME="robert smith"
```

---

<a id="step-28-interesting-truth-set-searches"></a>
### Step 2.8 — Interesting truth-set searches

**Email search** (official tutorial):

```
search {"email_address": "Kusha123@hmail.com"}
```

**Expect:** Family sharing one email; some members flagged on watchlist.

**Unicode name search:**

```
search 张秀英
why 61
```

(Use entity ID from your search if not 61.)

**Learn:** Senzing supports non-Latin scripts; `why` shows name scoring.

---

<a id="step-29-exit"></a>
### Step 2.9 — Exit

```
quit
exit
```

**✅ Part 2 done when:** You completed search → compare → get detail → how/why for Robert Smith cases.

---

<a id="part-3-taking-a-snapshot"></a>
# Part 3 — Taking a snapshot

**Official:** [EDA 3 — Taking a snapshot](https://senzing.zendesk.com/hc/en-us/articles/360051874294-Exploratory-Data-Analysis-3-Taking-a-snapshot)

Entities change every time you load data. A **snapshot** freezes statistics for review.

<a id="step-31-take-snapshot-with-audit-csv-mac"></a>
### Step 3.1 — Take snapshot with audit CSV (Mac)

Official:

```text
./G2Snapshot.py -o demo/truth/demo-snap-v1 -a
```

Your command (`-A` = for audit, writes `.csv` for `sz_audit`):

```bash
source ./setup-env.sh

docker run --rm -u $(id -u) -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/senzingsdk-tools sz_snapshot -QAo truthset_snapshot
```

**Flags:**
- `-Q` — quiet progress
- `-A` — also write `.csv` for audit
- `-o truthset_snapshot` — creates `truthset_snapshot.json` + `truthset_snapshot.csv`

**Verify (Mac):**

```bash
ls -la truthset_snapshot.json truthset_snapshot.csv
```

**Expect:** `Process completed successfully`

---

<a id="step-32-load-snapshot-in-explorer-container"></a>
### Step 3.2 — Load snapshot in explorer (container)

Official starts explorer with `-s file.json`. You load inside explorer:

```bash
docker run --rm -it -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools
```

```
sz_explorer
load truthset_snapshot.json
help
```

**Expect:** `Successfully loaded truthset_snapshot.json`

> **Common mistake:** Running reports before `load` → ERROR. Always `load` first.

---

<a id="step-33-data-source-summary"></a>
### Step 3.3 — Data source summary

Official:

```text
dataSourceSummary
```

Your command:

```
data_source_summary
```

**Column guide** (from tutorial):

| Column | Meaning |
|--------|---------|
| Records | Input records in this source |
| Entities | Distinct entities after resolution |
| Compression | % duplicate records found |
| Singletons | Entities with only 1 record |
| Duplicates | Entities with 2+ records |
| Ambiguous | Could match more than one entity |
| Possibles | High-strength attrs agree **and** disagree |
| Relationships | Weaker links (address, phone only) |

**Drill into CUSTOMERS duplicates:**

Official:

```text
dataSourceSummary CUSTOMERS duplicates
```

Try:

```
data_source_summary
```

Then use **↓** and **Enter** on the CUSTOMERS row → drill into **duplicates**.

In sz_explorer use **arrow keys + Enter** to drill. **Q** to go back.

When viewing examples, try:
- **Enter** on an entity → `get` detail
- From entity view, run `why` or `how` as needed

Official keys when browsing: **P** prior, **N** next, **D** detail, **W** why, **E** export, **Q** quit — some may map to arrow keys in sz_explorer.

**Practice:** Step through 3 duplicate customer examples. On one, run:

```
get <ENTITY_ID> detail
how <ENTITY_ID>
```

---

<a id="step-34-cross-source-summary-watchlist-screening"></a>
### Step 3.4 — Cross source summary (watchlist screening)

Official:

```text
crossSourceSummary
crossSourceSummary CUSTOMERS WATCHLIST duplicates
```

Your commands:

```
cross_source_summary
```

**Expect:** Row `CUSTOMERS ↔ WATCHLIST` — customers who matched watchlist entities.

Drill down with **Enter** on that row → browse entity examples.

**Learn:** This is **watchlist screening** — how many customers appear connected to watchlist records.

---

<a id="step-35-entity-size-breakdown"></a>
### Step 3.5 — Entity size breakdown

Official:

```text
entitySizeBreakdown
entitySizeBreakdown = 6
entitySizeBreakdown review
```

Your commands:

```
entity_size_breakdown
```

**Learn:**
- Size 1 = singletons
- Size 2+ = duplicates
- **Review** flag = more names/DOBs/SSNs than expected → check for over-matching or fraud

Drill into a size-6 entity if present (**Enter** on row).

Try entities flagged for review:

```
entity_size_breakdown
```

Navigate to **review** section if shown, or pick a large entity and run:

```
why <id1> <id2>
```

**Three review categories** (from tutorial):

1. **Explainable** — typos, bad data
2. **Intentional obfuscation** — fraud patterns
3. **Overmatched** — should be split manually

---

<a id="step-36-exit"></a>
### Step 3.6 — Exit

```
quit
exit
```

**✅ Part 3 done when:** You ran all three reports after `load` and drilled into at least one CUSTOMERS↔WATCHLIST match.

---

<a id="part-4-comparing-er-results-audit"></a>
# Part 4 — Comparing ER results (audit)

**Official:** [EDA 4 — Comparing ER results](https://senzing.zendesk.com/hc/en-us/articles/360050643034-Exploratory-Data-Analysis-4-Comparing-ER-results)

The audit compares **Senzing's snapshot** (what the engine did) vs a **truth key** (what you expected).

Your lab already has:
- `truthset_snapshot.csv` — from Part 3
- `actual_truthset_key.csv` — definitive truth (expect **100% F1**)
- `alternate_truthset_key.csv` — deliberately different rules (expect **~97% F1**, splits & merges to explore)

Official uses a separate person dataset; **you use the same truth set** — the learning goals are identical.

---

<a id="step-41-audit-vs-definitive-truth-mac"></a>
### Step 4.1 — Audit vs definitive truth (Mac)

Official:

```text
./G2Audit.py --newer_csv_file ...-snapshot.csv --prior_csv_file ...-key.csv --output_file_root ...-audit
```

Your command:

```bash
source ./setup-env.sh

docker run --rm -u $(id -u) -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools \
  sz_audit -n truthset_snapshot.csv -p actual_truthset_key.csv -o actual_audit
```

**Expect (approximate):**

```text
1.0 precision
1.0 recall
1.0 f1-score
0 merged entities
0 split entities
process completed successfully
```

**Learn:** Senzing matches the **definitive** truth key perfectly on this dataset.

---

<a id="step-42-audit-vs-alternate-key-mac"></a>
### Step 4.2 — Audit vs alternate key (Mac)

The alternate key uses different clustering assumptions (no employer matching, aggressive name matching). This creates **MERGE** and **SPLIT** cases to investigate — like editing the key in the official tutorial.

```bash
docker run --rm -u $(id -u) -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools \
  sz_audit -n truthset_snapshot.csv -p alternate_truthset_key.csv -o truthset_audit
```

**Expect (approximate):**

```text
~0.98 precision
~0.96 recall
~0.97 f1-score
2 merged entities
2 split entities
```

---

<a id="step-43-explore-audit-in-sz_explorer-container"></a>
### Step 4.3 — Explore audit in sz_explorer (container)

Official:

```text
./G2Explorer.py --snapshot_json_file ... --audit_json_file ...-edited-audit.json
auditSummary
```

Your commands:

```bash
docker run --rm -it -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools
```

```
sz_explorer
load truthset_audit.json
audit_summary
```

**Learn from the tutorial:**

| Term | Meaning |
|------|---------|
| **SPLIT** | You expected merge; Senzing kept apart |
| **MERGE** | Senzing merged; you expected separate |
| **New positives** | Unexpected matches (lower precision) |
| **New negatives** | Missed matches (lower recall) |

Review at **entity level**, not just F1 numbers.

---

<a id="step-44-drill-into-merge-cases"></a>
### Step 4.4 — Drill into MERGE cases

Official:

```text
auditSummary merge
auditSummary merge 1
```

Try in sz_explorer:

```
audit_summary
```

Use **Enter** to drill into **MERGE** category → browse entities.

On a merged entity, run:

```
why <id1> <id2>
```

**Classic lab case — Margaret Charney / employer:**

```
get REFERENCE 2091
how 100009
```

**Learn:** Senzing merged on **NAME+EMPLOYER**; alternate key kept groups separate → shows as MERGE in audit.

Press **Q** / navigate back when done.

---

<a id="step-45-drill-into-split-cases"></a>
### Step 4.5 — Drill into SPLIT cases

Official:

```text
auditSummary split
auditSummary split 1
```

At **`(szeda)`** (see [EXPLORER-SESSION.md](./EXPLORER-SESSION.md) if not open yet):

```
audit_summary
```

Use **Enter** to drill into **SPLIT**.

**Classic lab case — Darla / Darlene:**

```
get CUSTOMERS 1025
get CUSTOMERS 1026
why 17 18
```

(Use **your** entity IDs if different.)

**Learn:** Names similar (green), **DOB different** (red) → Senzing split; alternate key merged them → SPLIT in audit.

Official insight: Sometimes records look "all green" in `why` but only share a **close name + DOB** — Senzing classifies as **relationship**, not merge.

---

<a id="step-46-help-and-export"></a>
### Step 4.6 — Help and export

```
help why
quit
exit
```

**Bracket legend** (from tutorial — when entities don't match):

| Symbol | Meaning |
|--------|---------|
| `~` | Too many entities share this value (generic) |
| `!` | Likely garbage ("test customer", "unknown") |
| `#` | Suppressed — more complete value exists |

**✅ Part 4 done when:** You viewed `audit_summary`, explored at least one MERGE and one SPLIT, and ran `why` on each.

---

<a id="part-5-understanding-snapshot-statistics-reference"></a>
# Part 5 — Understanding snapshot statistics (reference)

**Official:** [Understanding the G2Snapshot statistics](https://senzing.zendesk.com/hc/en-us/articles/360035699253-Understanding-the-G2Snapshot-statistics)

Read this section after Part 3. No new commands — deeper meaning.

<a id="match-levels"></a>
### Match levels

| Level | Example |
|-------|---------|
| **Resolved / duplicate / match** | Same entity — records merged |
| **Ambiguous match** | Pat Smith at address — could be Patrick OR Patricia |
| **Possible match** | Share strong ID but conflicting attrs |
| **Possibly related** | Share address/phone only |
| **Disclosed relationship** | Known link (marriage, joint account) |

<a id="database-level-stats-top-of-truthset_snapshotjson"></a>
### Database-level stats (top of `truthset_snapshot.json`)

The official docs describe the legacy **G2Snapshot** JSON keys (`TOTAL_RECORD_COUNT`, etc.).  
Modern **`sz_snapshot`** uses a nested `TOTALS` object instead:

| Official (G2Snapshot) | Your lab (`sz_snapshot`) | Meaning |
|-----------------------|--------------------------|---------|
| `TOTAL_RECORD_COUNT` | `TOTALS.RECORD_COUNT` | All records loaded |
| `TOTAL_ENTITY_COUNT` | `TOTALS.ENTITY_COUNT` | Distinct entities |
| `TOTAL_COMPRESSION` | *(computed)* | `1 - ENTITY_COUNT / RECORD_COUNT` |
| `TOTAL_AMBIGUOUS_MATCHES` | `TOTALS.AMBIGUOUS_MATCH.RELATION_COUNT` | Ambiguous relationships |
| `TOTAL_POSSIBLE_MATCHES` | `TOTALS.POSSIBLE_MATCH.RELATION_COUNT` | Possible matches |
| `TOTAL_POSSIBLY_RELATEDS` | `TOTALS.POSSIBLE_RELATION.RELATION_COUNT` | Weak relationships |

Per-source stats live under `DATA_SOURCES.<NAME>`. Entity sizes under `ENTITY_SIZES`.

**Peek at JSON (Mac):**

```bash
python3 -c "
import json
d = json.load(open('truthset_snapshot.json'))
t = d['TOTALS']
records = t['RECORD_COUNT']
entities = t['ENTITY_COUNT']
compression = round(100 * (1 - entities / records), 1)
print('RECORD_COUNT', records)
print('ENTITY_COUNT', entities)
print('COMPRESSION_%', compression)
print('AMBIGUOUS_MATCH', t['AMBIGUOUS_MATCH']['RELATION_COUNT'])
print('POSSIBLE_MATCH', t['POSSIBLE_MATCH']['RELATION_COUNT'])
print('POSSIBLE_RELATION', t['POSSIBLE_RELATION']['RELATION_COUNT'])
"
```

**Your lab (with pipeline data loaded) — typical output:**

```text
RECORD_COUNT 299
ENTITY_COUNT 103
COMPRESSION_% 65.6
AMBIGUOUS_MATCH 7
POSSIBLE_MATCH ...
POSSIBLE_RELATION 50
```

<a id="cross-source-note"></a>
### Cross-source note

`MATCH_ENTITY_COUNT` for CUSTOMERS→WATCHLIST equals WATCHLIST→CUSTOMERS (entity count).  
`MATCH_RECORD_COUNT` differs by **parent source perspective**.

**✅ Part 5 done when:** You can explain compression vs possible match vs relationship.

---

<a id="part-6-understanding-audit-statistics-reference"></a>
# Part 6 — Understanding audit statistics (reference)

**Official:** [Understanding the G2Audit statistics](https://senzing.zendesk.com/hc/en-us/articles/360045624093-Understanding-the-G2Audit-statistics)

Read after Part 4.

<a id="formulas"></a>
### Formulas

| Metric | Formula | If score drops… |
|--------|---------|-----------------|
| **Precision** | prior_positives / (prior_positives + new_positives) | Too many unexpected merges |
| **Recall** | prior_positives / (prior_positives + new_negatives) | Too many missed merges |
| **F1** | 2 × (P × R) / (P + R) | Overall balance |

<a id="entity-level-stats"></a>
### Entity-level stats

| Stat | Meaning |
|------|---------|
| Prior count | Entities in truth key |
| Newer count | Entities in Senzing snapshot |
| Common count | Same entity groupings |
| Split | Expected together; Senzing apart |
| Merged | Senzing together; expected apart |
| Overlapped | Both split and merge in same entity group |

<a id="pairwise-vs-entity-review"></a>
### Pairwise vs entity review

F1 uses **record pairs**, but you review **entities** in `audit_summary`.  
Example from tutorial: 7 new positives may affect only **1 entity** — many pair differences, one root cause.

**Target:** F1 in the **90s** is healthy on real data. This lab hits **100%** vs actual key and **~97%** vs alternate key by design.

**✅ Part 6 done when:** You can explain precision vs recall and why alternate key F1 is lower than actual key F1.

---

<a id="quick-command-reference-eda-sessions"></a>
# Quick command reference (EDA sessions)

<a id="mac-snapshot-audit"></a>
### Mac — snapshot & audit

```bash
cd ~/Dev/Tutorials/senzing-demo && source ./setup-env.sh

# Snapshot (repeat after loading new data)
docker run --rm -u $(id -u) -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools \
  sz_snapshot -QAo truthset_snapshot

# Audit
docker run --rm -u $(id -u) -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools \
  sz_audit -n truthset_snapshot.csv -p alternate_truthset_key.csv -o truthset_audit
```

<a id="container-explorer-workflow"></a>
### Container — explorer workflow

```
sz_explorer
quick_look                          # live DB counts
search robert smith
compare search
get 1 detail
how 1
why 1 5
load truthset_snapshot.json
data_source_summary
cross_source_summary
entity_size_breakdown
load truthset_audit.json
audit_summary
quit
```

---

<a id="troubleshooting"></a>
# Troubleshooting

| Problem | Fix |
|---------|-----|
| Env var not set | `source ./setup-env.sh` (not `./setup-env.sh`) |
| `cross_source_summary` ERROR | Run `load truthset_snapshot.json` first |
| `compare 1, 5` fails | Use spaces: `compare 1 5` |
| `why CUSTOMERS 1070` fails | Use entity ID: `why 17 18` or 4-arg record form |
| Counts differ from tutorial | Extra sources loaded (PQ/vendors) — reset DB or ignore extra rows |
| SSL / schema errors | Connection string must use `:G2?sslmode=disable` — see `setup-env.sh` |

More fixes: [CHEATSHEET.md § Common errors](./CHEATSHEET.md#10-common-errors-fixes)

---

<a id="after-the-eda-series"></a>
# After the EDA series

You completed the official [EDA curriculum](https://senzing.zendesk.com/hc/en-us/sections/360009388534-Exploratory-Data-Analysis-EDA). Continue with:

| Topic | Where |
|-------|-------|
| **Data Mapping (recommended next)** | [DATA-MAPPING-TUTORIAL.md](./DATA-MAPPING-TUTORIAL.md) — Phase B & C |
| Official mapping docs | [Data Mapping – Senzing®](https://senzing.zendesk.com/hc/en-us/sections/360000385913-Data-Mapping) |
| Parquet → Senzing pipeline | [EXERCISES.md § Exercise 6](./EXERCISES.md) |
| MinIO (local S3) | [EXERCISES.md § Exercises 6–7, 11–14](./EXERCISES.md) |
| All commands | [CHEATSHEET.md](./CHEATSHEET.md) |

---

*Workbook version: maps Senzing EDA articles to senzing-demo Docker lab (M1 Mac).*
