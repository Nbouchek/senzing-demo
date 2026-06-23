# Senzing Local Lab — Hands-On Exercises

Follow this workbook **in order**. Each exercise builds on the previous one.  
Companion reference: [CHEATSHEET.md](./CHEATSHEET.md)

**Stack:** Mac + Docker + PostgreSQL + MinIO (local S3). **No AWS account required.**

**Related workbooks:** [EDA-TUTORIAL.md](./EDA-TUTORIAL.md) · [DATA-MAPPING-TUTORIAL.md](./DATA-MAPPING-TUTORIAL.md) · **[EXPLORER-SESSION.md](./EXPLORER-SESSION.md)**

---

## Table of contents

**Workbooks:** [CHEATSHEET.md](./CHEATSHEET.md) · [EDA-TUTORIAL.md](./EDA-TUTORIAL.md) · [DATA-MAPPING-TUTORIAL.md](./DATA-MAPPING-TUTORIAL.md)

- [Before you start](#before-you-start)
  - [Prerequisites](#prerequisites)
  - [Three places you run commands](#three-places-you-run-commands)
  - [Every session — run first (Mac)](#every-session-run-first-mac)
  - [Enter Senzing tools container (repeat whenever needed)](#enter-senzing-tools-container-repeat-whenever-needed)
  - [sz_explorer navigation keys](#sz_explorer-navigation-keys)
- [Exercise 0 — First-time setup (once only)](#exercise-0-first-time-setup-once-only)
  - [Step 0.1 — Start infrastructure](#step-01-start-infrastructure)
  - [Step 0.2 — Set Senzing environment](#step-02-set-senzing-environment)
  - [Step 0.3 — Initialize Senzing database](#step-03-initialize-senzing-database)
  - [Step 0.4 — Register truth set data sources](#step-04-register-truth-set-data-sources)
  - [Step 0.5 — Load truth set JSONL files](#step-05-load-truth-set-jsonl-files)
  - [Step 0.6 — Setup MinIO and upload sample Parquet](#step-06-setup-minio-and-upload-sample-parquet)
  - [✅ Exercise 0 complete when](#exercise-0-complete-when)
- [Exercise 1 — Meet your data (`quick_look` + `get`)](#exercise-1-meet-your-data-quick_look-get)
  - [Step 1.1 — Enter container](#step-11-enter-container)
  - [Step 1.2 — Record counts by source](#step-12-record-counts-by-source)
  - [Step 1.3 — Get one record](#step-13-get-one-record)
  - [Step 1.4 — Get detail view](#step-14-get-detail-view)
  - [Step 1.5 — Exit](#step-15-exit)
  - [📝 Write down](#write-down)
  - [✅ Exercise 1 complete when](#exercise-1-complete-when)
- [Exercise 2 — Search and compare](#exercise-2-search-and-compare)
  - [Step 2.1 — Enter sz_explorer](#step-21-enter-sz_explorer)
  - [Step 2.2 — Compare search results](#step-22-compare-search-results)
  - [Step 2.3 — Compare two specific entities by ID](#step-23-compare-two-specific-entities-by-id)
  - [Step 2.4 — Exit](#step-24-exit)
  - [✅ Exercise 2 complete when](#exercise-2-complete-when)
- [Exercise 3 — Why and how (explainability)](#exercise-3-why-and-how-explainability)
  - [Step 3.1 — Why two entities did NOT merge (SPLIT case)](#step-31-why-two-entities-did-not-merge-split-case)
  - [Step 3.2 — How records merged into one entity](#step-32-how-records-merged-into-one-entity)
  - [Step 3.3 — How employer caused a merge (MERGE case)](#step-33-how-employer-caused-a-merge-merge-case)
  - [Step 3.4 — Record-level why (4 arguments)](#step-34-record-level-why-4-arguments)
  - [Step 3.5 — Exit](#step-35-exit)
  - [✅ Exercise 3 complete when](#exercise-3-complete-when)
- [Exercise 4 — Snapshot and cross-source screening](#exercise-4-snapshot-and-cross-source-screening)
  - [Step 4.1 — Create snapshot (Mac)](#step-41-create-snapshot-mac)
  - [Step 4.2 — Load snapshot in explorer (container)](#step-42-load-snapshot-in-explorer-container)
  - [Step 4.3 — Cross-source summary](#step-43-cross-source-summary)
  - [Step 4.4 — Within-source deduplication](#step-44-within-source-deduplication)
  - [Step 4.5 — Exit](#step-45-exit)
  - [✅ Exercise 4 complete when](#exercise-4-complete-when)
- [Exercise 5 — Audit accuracy](#exercise-5-audit-accuracy)
  - [Step 5.1 — Run audit vs alternate key (Mac)](#step-51-run-audit-vs-alternate-key-mac)
  - [Step 5.2 — Run audit vs definitive truth (Mac)](#step-52-run-audit-vs-definitive-truth-mac)
  - [Step 5.3 — Explore audit in sz_explorer](#step-53-explore-audit-in-sz_explorer)
  - [✅ Exercise 5 complete when](#exercise-5-complete-when)
- [Exercise 6 — Full MinIO pipeline (local S3)](#exercise-6-full-minio-pipeline-local-s3)
  - [Step 6.1 — Run full pipeline (Mac)](#step-61-run-full-pipeline-mac)
  - [Step 6.2 — Verify mapped JSONL (Mac)](#step-62-verify-mapped-jsonl-mac)
  - [Step 6.3 — Verify entity resolution (container)](#step-63-verify-entity-resolution-container)
  - [Step 6.4 — Screening report after pipeline](#step-64-screening-report-after-pipeline)
  - [✅ Exercise 6 complete when](#exercise-6-complete-when)
- [Exercise 7 — Vendors exercise (duplicate org + watchlist screening)](#exercise-7-vendors-exercise-duplicate-org-watchlist-screening)
  - [Background — the 3 vendor records (`vendors.jsonl`)](#background-the-3-vendor-records-vendorsjsonl)
  - [Step 7.1 — Run vendor pipeline (Mac)](#step-71-run-vendor-pipeline-mac)
  - [Step 7.2 — Question 1: Did V001 and V002 merge?](#step-72-question-1-did-v001-and-v002-merge)
  - [Step 7.3 — Question 2: Did V003 match the watchlist?](#step-73-question-2-did-v003-match-the-watchlist)
  - [Step 7.4 — Export for your records (optional)](#step-74-export-for-your-records-optional)
  - [✅ Exercise 7 complete when](#exercise-7-complete-when)
- [Exercise 8 — Export and simulate new S3 file drop](#exercise-8-export-and-simulate-new-s3-file-drop)
  - [Step 8.1 — Export an interesting entity](#step-81-export-an-interesting-entity)
  - [Step 8.2 — Simulate new file in MinIO](#step-82-simulate-new-file-in-minio)
  - [Step 8.3 — Force re-process and reload](#step-83-force-re-process-and-reload)
  - [✅ Exercise 8 complete when](#exercise-8-complete-when)
- [Exercise checklist (track your progress)](#exercise-checklist-track-your-progress)
- [Troubleshooting quick reference](#troubleshooting-quick-reference)
- [What you learned (summary)](#what-you-learned-summary)
- [Exercises 9–14 — Data Mapping (Phase B & C)](#exercises-9-14-data-mapping-phase-b-c)
  - [Exercise 9 — Map CSV to JSONL (Phase B)](#exercise-9-map-csv-to-jsonl-phase-b)
  - [Exercise 10 — Disclosed relationships](#exercise-10-disclosed-relationships)
  - [Exercise 11 — MinIO pipeline for MY_TEAM (Phase C)](#exercise-11-minio-pipeline-for-my_team-phase-c)
  - [Exercise 12 — Idempotent reload](#exercise-12-idempotent-reload)
  - [Exercise 13 — Simulate file update](#exercise-13-simulate-file-update)
  - [Exercise 14 — Scheduled batch](#exercise-14-scheduled-batch)
- [Extended checklist](#extended-checklist)
- [Next steps (when ready)](#next-steps-when-ready)


---

<a id="before-you-start"></a>
## Before you start

<a id="prerequisites"></a>
### Prerequisites

- Docker Desktop installed and running (`docker ps` works)
- AWS CLI installed (`brew install awscli`) — used only to talk to **MinIO**, not AWS
- Project folder: `~/Dev/Tutorials/senzing-demo`

<a id="three-places-you-run-commands"></a>
### Three places you run commands

| Place | How you know you're there | Used for |
|-------|---------------------------|----------|
| **Mac terminal** | Prompt: `➜ senzing-demo` | `docker`, `source`, `./pipeline/*.sh`, `aws` |
| **Container shell** | Prompt: `root@...:/data#` | Starting `sz_explorer`, `sz_configtool` |
| **sz_explorer** | Prompt: `(szeda)` | `get`, `search`, `load`, reports |

<a id="every-session-run-first-mac"></a>
### Every session — run first (Mac)

```bash
cd ~/Dev/Tutorials/senzing-demo
docker compose up -d
source ./setup-env.sh
source ./setup-minio-env.sh
```

<a id="enter-senzing-tools-container-repeat-whenever-needed"></a>
### Open sz_explorer (repeat whenever a step says "explore" or "verify")

See **[EXPLORER-SESSION.md](./EXPLORER-SESSION.md)** for details.

**Step 1 — Mac:**

```bash
cd ~/Dev/Tutorials/senzing-demo
source ./setup-env.sh

docker run --rm -it -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools
```

**Step 2 — Container** (`root@....:/data#`): type `sz_explorer`

**Step 3 — Explorer** (`(szeda)`): type commands from the exercise

**Step 4 — Exit:** `quit` then `exit`

<a id="sz_explorer-navigation-keys"></a>
### sz_explorer navigation keys

| Key | Action |
|-----|--------|
| ↑ ↓ | Move between rows |
| Enter | Drill into a row |
| Q | Go back |
| ← → | Scroll wide tables |

---

<a id="exercise-0-first-time-setup-once-only"></a>
## Exercise 0 — First-time setup (once only)

**Goal:** Install PostgreSQL, MinIO, and initialize Senzing.  
**Time:** ~15 minutes  
**Where:** Mac terminal only

<a id="step-01-start-infrastructure"></a>
### Step 0.1 — Start infrastructure

```bash
cd ~/Dev/Tutorials/senzing-demo
docker compose up -d
docker compose ps
```

**Check:** Both `postgres` and `minio` show as running.

<a id="step-02-set-senzing-environment"></a>
### Step 0.2 — Set Senzing environment

```bash
source ./setup-env.sh
```

**Check:** Message says `SENZING_ENGINE_CONFIGURATION_JSON is set`.

> Use `source`, not `./setup-env.sh`

<a id="step-03-initialize-senzing-database"></a>
### Step 0.3 — Initialize Senzing database

```bash
docker run --rm \
  --env SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/init-database \
  --install-senzing-er-configuration
```

**Check:** `Processed 45 lines with no failures`  
(Re-running may show "already exists" warnings — that's OK.)

<a id="step-04-register-truth-set-data-sources"></a>
### Step 0.4 — Register truth set data sources

```bash
printf 'addDataSource CUSTOMERS\naddDataSource REFERENCE\naddDataSource WATCHLIST\nsave\ny\nquit\n' | \
  docker run --rm -i -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/senzingsdk-tools sz_configtool
```

**Check:** Three "successfully added" messages (or already exist).

<a id="step-05-load-truth-set-jsonl-files"></a>
### Step 0.5 — Load truth set JSONL files

```bash
source ./setup-env.sh

for f in customers reference watchlist; do
  echo "Loading ${f}.jsonl..."
  docker run --rm -u $(id -u) -v ${PWD}:/data \
    -e SENZING_ENGINE_CONFIGURATION_JSON \
    senzing/sz-file-loader -f /data/${f}.jsonl
done
```

**Check:** Each file shows `Successfully loaded` with `0 error(s)`.

<a id="step-06-setup-minio-and-upload-sample-parquet"></a>
### Step 0.6 — Setup MinIO and upload sample Parquet

```bash
source ./setup-minio-env.sh
./pipeline/setup_minio.sh
```

**Check:**
- `MinIO is ready`
- `upload: parquet/customers.parquet to s3://senzing-incoming/...`
- Open http://localhost:9001 (login: `minioadmin` / `minioadmin`) and see the bucket

<a id="exercise-0-complete-when"></a>
### ✅ Exercise 0 complete when

- `docker compose ps` shows postgres + minio up
- Truth set loaded (159 records total)
- MinIO bucket `senzing-incoming` has Parquet files

---

<a id="exercise-1-meet-your-data-quick_look-get"></a>
## Exercise 1 — Meet your data (`quick_look` + `get`)

**Goal:** See what's in Senzing and understand **record** vs **entity**.  
**Time:** ~10 minutes  
**Prerequisite:** Exercise 0

<a id="step-11-enter-container"></a>
### Step 1.1 — Enter container

```bash
source ./setup-env.sh
docker run --rm -it -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools
```

<a id="step-12-record-counts-by-source"></a>
### Step 1.2 — Record counts by source

```
sz_explorer
quick_look
```

**Check:** Rows for `CUSTOMERS` (~120), `REFERENCE` (~22), `WATCHLIST` (~17).

**Learn:** Each DATA_SOURCE is a separate dataset. Counts are **records**, not entities.

<a id="step-13-get-one-record"></a>
### Step 1.3 — Get one record

```
get CUSTOMERS 1070
```

**Check:** Header line like:

```text
Entity summary for entity 54: Jie Wang
```

Note the **entity number** (yours may differ from `54` — use yours in later steps).

**Check:** Sources column shows multiple records (e.g. 1069, 1070) under one entity.

**Learn:** Several **records** resolved into one **entity** (duplicate detection).

<a id="step-14-get-detail-view"></a>
### Step 1.4 — Get detail view

```
get CUSTOMERS 1070 detail
```

**Check:** Three columns — Sources | Features | Additional Data.  
Press **Q** when done reading.

<a id="step-15-exit"></a>
### Step 1.5 — Exit

```
quit
exit
```

<a id="write-down"></a>
### 📝 Write down

| Item | Your value |
|------|------------|
| Entity ID for CUSTOMERS 1070 | _________ |
| Name shown | _________ |
| How many CUSTOMERS records on that entity? | _________ |

<a id="exercise-1-complete-when"></a>
### ✅ Exercise 1 complete when

You can explain: "RECORD_ID is one input row; ENTITY_ID is the resolved person/org."

---

<a id="exercise-2-search-and-compare"></a>
## Exercise 2 — Search and compare

**Goal:** Find entities by name and compare them side-by-side.  
**Time:** ~10 minutes

<a id="step-21-enter-sz_explorer"></a>
### Step 2.1 — Enter sz_explorer

(Same docker command as Exercise 1.)

```
sz_explorer
search robert smith
```

**Check:** Multiple rows returned (different Entity IDs).

**Learn:** Same name ≠ same entity. Senzing may find several "Robert Smith" entities.

<a id="step-22-compare-search-results"></a>
### Step 2.2 — Compare search results

```
compare search
```

**Check:** Side-by-side columns for each entity from the search.  
Use **arrow keys** and **Q**.

<a id="step-23-compare-two-specific-entities-by-id"></a>
### Step 2.3 — Compare two specific entities by ID

From your search results, pick two Entity IDs (e.g. `1` and `9`):

```
compare 1 9
```

> Use **spaces**, not commas: `compare 1 9` not `compare 1, 9`

**Learn:** `compare` needs **entity IDs**, not `CUSTOMERS 1070` style record IDs.

<a id="step-24-exit"></a>
### Step 2.4 — Exit

```
quit
exit
```

<a id="exercise-2-complete-when"></a>
### ✅ Exercise 2 complete when

You can run `search` → `compare search` without help.

---

<a id="exercise-3-why-and-how-explainability"></a>
## Exercise 3 — Why and how (explainability)

**Goal:** Understand **why** entities didn't merge and **how** they did merge.  
**Time:** ~15 minutes

<a id="step-31-why-two-entities-did-not-merge-split-case"></a>
### Step 3.1 — Why two entities did NOT merge (SPLIT case)

```
sz_explorer
get CUSTOMERS 1025
get CUSTOMERS 1026
```

If they show **different entity IDs** (e.g. 17 and 18):

```
why 17 18
```

**Check:**
- **Green** on NAME = names similar
- **Red** on DOB = different birth dates → kept separate

Press **Q** to exit the report.

**Learn:** Green = matched feature; Red = conflicting feature. Similar names can be **related** but not **merged**.

<a id="step-32-how-records-merged-into-one-entity"></a>
### Step 3.2 — How records merged into one entity

Use entity ID from Exercise 1 (or `get CUSTOMERS 1070`):

```
how 54
```

(Replace `54` with **your** entity ID.)

**Check:** Step-by-step decision tree (read bottom to top).  
Press **Enter** to step through, **Q** to quit.

<a id="step-33-how-employer-caused-a-merge-merge-case"></a>
### Step 3.3 — How employer caused a merge (MERGE case)

```
get REFERENCE 2091
how 100009
```

(Entity ID `100009` may differ in your DB — use ID from `get REFERENCE 2091` header if different.)

**Check:** Match key includes **NAME+EMPLOYER**.

<a id="step-34-record-level-why-4-arguments"></a>
### Step 3.4 — Record-level why (4 arguments)

```
why CUSTOMERS 1069 CUSTOMERS 1070
```

**Check:** Explains relationship between two specific records (may be same entity if merged).

<a id="step-35-exit"></a>
### Step 3.5 — Exit

```
quit
exit
```

<a id="exercise-3-complete-when"></a>
### ✅ Exercise 3 complete when

You can answer: "What's the difference between `why 17 18` and `why CUSTOMERS 1069 CUSTOMERS 1070`?"

<details>
<summary>Answer</summary>
`why 17 18` compares two **entities** by ID.  
`why CUSTOMERS 1069 CUSTOMERS 1070` compares two **records** by DATA_SOURCE + RECORD_ID (4 tokens).
</details>

---

<a id="exercise-4-snapshot-and-cross-source-screening"></a>
## Exercise 4 — Snapshot and cross-source screening

**Goal:** Run batch reports and screen CUSTOMERS against WATCHLIST.  
**Time:** ~15 minutes

<a id="step-41-create-snapshot-mac"></a>
### Step 4.1 — Create snapshot (Mac)

```bash
source ./setup-env.sh

docker run --rm -u $(id -u) -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/senzingsdk-tools sz_snapshot -QAo truthset_snapshot
```

**Check:** `Process completed successfully` and files exist:

```bash
ls -la truthset_snapshot.json truthset_snapshot.csv
```

<a id="step-42-load-snapshot-in-explorer-container"></a>
### Step 4.2 — Load snapshot in explorer (container)

```
sz_explorer
load truthset_snapshot.json
```

**Check:** `Successfully loaded truthset_snapshot.json`

> **Common mistake:** Running `cross_source_summary` before `load` → ERROR. Always `load` first.

<a id="step-43-cross-source-summary"></a>
### Step 4.3 — Cross-source summary

```
cross_source_summary
```

**Check:** Rows like `CUSTOMERS ↔ WATCHLIST`.

**Learn:** This is **watchlist screening** — how many customer records matched watchlist entities.

Drill down: **Enter** on a row → see entity IDs → **Enter** again → **Q** to go back.

<a id="step-44-within-source-deduplication"></a>
### Step 4.4 — Within-source deduplication

```
data_source_summary
```

**Check:** CUSTOMERS row shows how many records matched other CUSTOMERS records.

<a id="step-45-exit"></a>
### Step 4.5 — Exit

```
quit
exit
```

<a id="exercise-4-complete-when"></a>
### ✅ Exercise 4 complete when

You can run `load truthset_snapshot.json` then `cross_source_summary` without errors.

---

<a id="exercise-5-audit-accuracy"></a>
## Exercise 5 — Audit accuracy

**Goal:** Measure how well Senzing matches known truth keys.  
**Time:** ~15 minutes

<a id="step-51-run-audit-vs-alternate-key-mac"></a>
### Step 5.1 — Run audit vs alternate key (Mac)

```bash
source ./setup-env.sh

docker run --rm -u $(id -u) -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools \
  sz_audit -n truthset_snapshot.csv -p alternate_truthset_key.csv -o truthset_audit
```

**Check:** Metrics printed, e.g.:

```text
0.98 precision
0.96 recall
0.97 f1-score
2 merged entities
2 split entities
```

**Learn:** ~97% F1 vs alternate is **expected** — the alternate key deliberately differs (no employer matching, aggressive name matching).

<a id="step-52-run-audit-vs-definitive-truth-mac"></a>
### Step 5.2 — Run audit vs definitive truth (Mac)

```bash
docker run --rm -u $(id -u) -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools \
  sz_audit -n truthset_snapshot.csv -p actual_truthset_key.csv -o actual_audit
```

**Check:** `1.0 precision`, `1.0 recall`, `1.0 f1-score`, `0 merged`, `0 split`.

**Learn:** Senzing matches the **definitive** truth perfectly in this lab.

<a id="step-53-explore-audit-in-sz_explorer"></a>
### Step 5.3 — Explore audit in sz_explorer

```
sz_explorer
load truthset_audit.json
audit_summary
```

Drill into **SPLIT** → Darla/Darlene case.  
Drill into **MERGE** → Margaret Charney / employer case.

```
why 17 18
how 100009
quit
exit
```

<a id="exercise-5-complete-when"></a>
### ✅ Exercise 5 complete when

You can explain precision, recall, and why alternate vs actual keys give different F1 scores.

---

<a id="exercise-6-full-minio-pipeline-local-s3"></a>
## Exercise 6 — Full MinIO pipeline (local S3)

**Goal:** Pull Parquet from MinIO, map, load, verify cross-source with `CUSTOMERS_PQ`.  
**Time:** ~15 minutes  
**Prerequisite:** Exercise 0 step 0.6 (MinIO setup)

<a id="step-61-run-full-pipeline-mac"></a>
### Step 6.1 — Run full pipeline (Mac)

```bash
source ./setup-env.sh
source ./setup-minio-env.sh

./pipeline/run_all_from_minio.sh
```

**Check terminal output:**

```text
download: s3://senzing-incoming/customers/customers.parquet ...
Successfully loaded 120 records ... 0 error(s)
Successfully loaded 17 records ... 0 error(s)
Process completed successfully
=== All sources loaded ===
```

> **Do not** try to preview `.parquet` in Cursor — you'll see "Preview unavailable". That's normal.

<a id="step-62-verify-mapped-jsonl-mac"></a>
### Step 6.2 — Verify mapped JSONL (Mac)

```bash
head -1 staging/mapped_customers_pq.jsonl | python3 -m json.tool
```

**Check:** JSON with `"DATA_SOURCE": "CUSTOMERS_PQ"`.

<a id="step-63-verify-entity-resolution-container"></a>
### Step 6.3 — Verify entity resolution (container)

```
sz_explorer
get CUSTOMERS_PQ 1001
```

**Check:** **Both** `CUSTOMERS` and `CUSTOMERS_PQ` appear on the **same entity** (Robert Smith).

```
quick_look
```

**Check:** Rows for `CUSTOMERS_PQ` and `WATCHLIST_PQ`.

<a id="step-64-screening-report-after-pipeline"></a>
### Step 6.4 — Screening report after pipeline

```
load truthset_snapshot.json
cross_source_summary
```

**Check:** Rows including `CUSTOMERS ↔ CUSTOMERS_PQ` and `CUSTOMERS_PQ ↔ WATCHLIST_PQ`.

```
quit
exit
```

<a id="exercise-6-complete-when"></a>
### ✅ Exercise 6 complete when

`get CUSTOMERS_PQ 1001` shows records from both CUSTOMERS and CUSTOMERS_PQ on one entity.

---

<a id="exercise-7-vendors-exercise-duplicate-org-watchlist-screening"></a>
## Exercise 7 — Vendors exercise (duplicate org + watchlist screening)

**Goal:** Load a new dataset end-to-end and answer two investigation questions.  
**Time:** ~20 minutes

<a id="background-the-3-vendor-records-vendorsjsonl"></a>
### Background — the 3 vendor records (`vendors.jsonl`)

| Record | Type | Name | Purpose in exercise |
|--------|------|------|---------------------|
| V001 | Organization | Acme Supplies Ltd | Duplicate of V002 |
| V002 | Organization | ACME Supply Limited | Same vendor, different spelling |
| V003 | Person | Maria Sentosa | May relate to watchlist (same address, different DOB) |

<a id="step-71-run-vendor-pipeline-mac"></a>
### Step 7.1 — Run vendor pipeline (Mac)

```bash
source ./setup-env.sh
source ./setup-minio-env.sh
./pipeline/learn_local_exercise.sh
```

**Check:** `=== Exercise complete ===`

<a id="step-72-question-1-did-v001-and-v002-merge"></a>
### Step 7.2 — Question 1: Did V001 and V002 merge?

```
sz_explorer
get VENDORS_PQ V001
```

Write down entity ID from header: _________

```
get VENDORS_PQ V002
```

**Check:**
- [ ] Same entity ID as V001?
- [ ] Both V001 and V002 listed in Sources column?

```
how 600002
```

(Use **your** entity ID if not 600002.)

**Expected answer:** **Yes — merged** into one organization (duplicate vendor detection).

<a id="step-73-question-2-did-v003-match-the-watchlist"></a>
### Step 7.3 — Question 2: Did V003 match the watchlist?

```
get VENDORS_PQ V003
```

**Look for:**

| Signal | Meaning |
|--------|---------|
| `WATCHLIST` in **Sources** column | Merged with watchlist |
| `WATCHLIST` only in **tree** at bottom | Related, not merged |

```
search maria sentosa
compare search
```

**Check:** Likely **two entities** — V003 alone and a larger Maria entity with WATCHLIST.

```
why 600001 24
```

(Use entity IDs from **your** `get` and `search` — 600001 and 24 are typical.)

**Check:**
- Green **ADDRESS** (same: 638 Downey St, Salem, OR)
- Red **DOB** (different dates)

**Expected answer:** **Related to watchlist, not merged** — same address, different person.

<a id="step-74-export-for-your-records-optional"></a>
### Step 7.4 — Export for your records (optional)

```
export 600002 to /data/vendor_merge_export.jsonl
quit
exit
```

File appears on Mac at `senzing-demo/vendor_merge_export.jsonl`.

<a id="exercise-7-complete-when"></a>
### ✅ Exercise 7 complete when

You can explain merge (V001/V002) vs relate (V003/watchlist) to someone else.

---

<a id="exercise-8-export-and-simulate-new-s3-file-drop"></a>
## Exercise 8 — Export and simulate new S3 file drop

**Goal:** Practice analyst workflow: export entity, re-upload to MinIO, re-run pipeline.  
**Time:** ~15 minutes

<a id="step-81-export-an-interesting-entity"></a>
### Step 8.1 — Export an interesting entity

```
sz_explorer
get CUSTOMERS 1070
export 54 to /data/my_export.jsonl
quit
exit
```

**Check on Mac:**

```bash
cat my_export.jsonl | python3 -m json.tool | head -30
```

<a id="step-82-simulate-new-file-in-minio"></a>
### Step 8.2 — Simulate new file in MinIO

```bash
source ./setup-minio-env.sh

aws --endpoint-url http://localhost:9000 s3 cp \
  parquet/customers.parquet \
  s3://senzing-incoming/customers/customers.parquet
```

<a id="step-83-force-re-process-and-reload"></a>
### Step 8.3 — Force re-process and reload

```bash
grep -v '^CUSTOMERS_PQ-' staging/.processed_files.log > staging/.tmp 2>/dev/null || true
mv staging/.tmp staging/.processed_files.log 2>/dev/null || rm -f staging/.processed_files.log

S3_URI=s3://senzing-incoming/customers/ \
SENZING_DATA_SOURCE=CUSTOMERS_PQ \
INCOMING_DIR=customers PARQUET_FILE=customers.parquet \
JSONL_FILE=mapped_customers_pq.jsonl \
./pipeline/run_pipeline.sh
```

**Learn:** Production pipelines track processed files (`staging/.processed_files.log`) to avoid duplicate loads.

<a id="exercise-8-complete-when"></a>
### ✅ Exercise 8 complete when

You understand export → investigate → re-ingest workflow.

---

<a id="exercise-checklist-track-your-progress"></a>
## Exercise checklist (track your progress)

| # | Exercise | Done? |
|---|----------|-------|
| 0 | First-time setup | ☐ |
| 1 | quick_look + get | ☐ |
| 2 | search + compare | ☐ |
| 3 | why + how | ☐ |
| 4 | snapshot + cross_source_summary | ☐ |
| 5 | audit | ☐ |
| 6 | MinIO full pipeline | ☐ |
| 7 | Vendors merge + screening | ☐ |
| 8 | Export + re-ingest | ☐ |

---

<a id="troubleshooting-quick-reference"></a>
## Troubleshooting quick reference

| Problem | Fix |
|---------|-----|
| `source ./setup-env.sh` forgotten | Env errors on every docker command |
| `cross_source_summary` fails | Run `load truthset_snapshot.json` first |
| `why 1, 9` fails | Use spaces: `why 1 9` |
| `Unknown entity 1070` | 1070 is RECORD_ID; use ENTITY_ID from `get` header |
| Preview unavailable in Cursor | Normal for `.parquet` — use terminal or `sz_explorer` |
| `Already processed` | `rm staging/.processed_files.log` or grep out one line |
| MinIO down | `docker compose up -d minio` |
| Fresh start | `docker compose down -v` then redo Exercise 0 |

Full list: [CHEATSHEET.md § Common errors](./CHEATSHEET.md#10-common-errors--fixes)

---

<a id="what-you-learned-summary"></a>
## What you learned (summary)

After all exercises you can:

1. Load JSONL and Parquet (via MinIO) into Senzing
2. Explore entities with `get`, `search`, `compare`
3. Explain matches with `why` and `how`
4. Run screening reports with `sz_snapshot` + `cross_source_summary`
5. Measure accuracy with `sz_audit`
6. Operate a local S3-compatible pipeline without AWS
7. Distinguish **merged** vs **related** entities
8. Investigate duplicate vendors and watchlist hits

---

<a id="exercises-9-14-data-mapping-phase-b-c"></a>
## Exercises 9–14 — Data Mapping (Phase B & C)

**Full workbook:** [DATA-MAPPING-TUTORIAL.md](./DATA-MAPPING-TUTORIAL.md)  
**Official curriculum:** [Data Mapping – Senzing®](https://senzing.zendesk.com/hc/en-us/sections/360000385913-Data-Mapping)

<a id="exercise-9-map-csv-to-jsonl-phase-b"></a>
### Exercise 9 — Map CSV to JSONL (Phase B)

```bash
source ./setup-env.sh
./pipeline/load_my_team.sh
```

Verify: `get MY_TEAM E001` and `get MY_TEAM E002` → same entity (Jane Doe duplicate).

<a id="exercise-10-disclosed-relationships"></a>
### Exercise 10 — Disclosed relationships

Open [EXPLORER-SESSION.md](./EXPLORER-SESSION.md), then at `(szeda)` run: `get REFERENCE 2012`, `get REFERENCE 2013`, `get REFERENCE 2014` (note: `2011` is a relationship anchor key, not a record ID).

<a id="exercise-11-minio-pipeline-for-my_team-phase-c"></a>
### Exercise 11 — MinIO pipeline for MY_TEAM (Phase C)

```bash
source ./setup-env.sh && source ./setup-minio-env.sh
./pipeline/run_my_team_from_minio.sh
```

Verify: `get MY_TEAM_PQ E001`, `load truthset_snapshot.json` → `cross_source_summary`.

<a id="exercise-12-idempotent-reload"></a>
### Exercise 12 — Idempotent reload

Run `./pipeline/run_my_team_from_minio.sh` twice; second run should say "Already processed".  
Clear `staging/.processed_files.log` line and re-run.

<a id="exercise-13-simulate-file-update"></a>
### Exercise 13 — Simulate file update

Simulates HR sending an **updated** employee file through MinIO (Phase C).

**Step 1 — Add E007 to the CSV**

Open `learning/my_team.csv` and append this line after E006:

```csv
E007,Alice,Johnson,1992-05-20,300 Maple Dr,Austin,TX,78702,512-555-0999,alice@acme.com,Acme Corp,Marketing,2024-06-01,Active
```

Or from the terminal:

```bash
cd ~/Dev/Tutorials/senzing-demo
echo 'E007,Alice,Johnson,1992-05-20,300 Maple Dr,Austin,TX,78702,512-555-0999,alice@acme.com,Acme Corp,Marketing,2024-06-01,Active' >> learning/my_team.csv
```

**Step 2 — Rebuild Parquet, upload to MinIO, clear processed log, re-run pipeline**

```bash
cd ~/Dev/Tutorials/senzing-demo
docker compose up -d
source ./setup-env.sh && source ./setup-minio-env.sh

# CSV → Parquet
docker run --rm \
  -e CSV_INPUT="/data/learning/my_team.csv" \
  -e PARQUET_OUTPUT="/data/parquet/my_team.parquet" \
  -v ${PWD}:/data -w /data python:3.12-slim bash -c \
  'pip -q install pandas pyarrow && python learning/csv_to_parquet.py'

# Upload to MinIO (local S3)
aws --endpoint-url http://localhost:9000 s3 cp \
  parquet/my_team.parquet \
  s3://senzing-incoming/my_team/my_team.parquet

# Clear MY_TEAM_PQ from processed log so pipeline runs again
grep -v '^MY_TEAM_PQ-' staging/.processed_files.log > staging/.tmp 2>/dev/null || true
mv staging/.tmp staging/.processed_files.log 2>/dev/null || true

# Run pipeline only for my_team (not the full run_all_from_minio.sh)
S3_URI=s3://senzing-incoming/my_team/ \
SENZING_DATA_SOURCE=MY_TEAM_PQ \
./pipeline/run_my_team_pipeline.sh
```

**Shortcut** (does steps 2–4 in one script, but still add E007 to CSV first):

```bash
# After editing learning/my_team.csv:
grep -v '^MY_TEAM_PQ-' staging/.processed_files.log > staging/.tmp 2>/dev/null || true
mv staging/.tmp staging/.processed_files.log 2>/dev/null || true
source ./setup-env.sh && source ./setup-minio-env.sh
./pipeline/run_my_team_from_minio.sh
```

**Step 3 — Verify in sz_explorer**

**Step 1 — Mac:** `source ./setup-env.sh` then start container (same as [EXPLORER-SESSION.md](./EXPLORER-SESSION.md))

**Step 2 — Container:** `sz_explorer`

**Step 3 — Explorer (`(szeda)`):**

```
get MY_TEAM_PQ E007
quick_look
```

**Step 4 — Exit:** `quit` then `exit`

**Expect:** E007 (Alice Johnson) loads; `MY_TEAM_PQ` count increases.

> **Note:** Re-loading the **full** file reloads E001–E006 as well, which can create duplicate records in Senzing. That is expected in this learning lab — real pipelines use incremental files or purge-by-source.

**✅ Done when:** `get MY_TEAM_PQ E007` shows Alice Johnson.

<a id="exercise-14-scheduled-batch"></a>
### Exercise 14 — Scheduled batch

```bash
./pipeline/run_all_from_minio.sh >> staging/cron.log 2>&1
tail staging/cron.log
```

See `pipeline/schedule.example.cron` for daily cron on Mac.

---

<a id="extended-checklist"></a>
## Extended checklist

| # | Exercise | Done |
|---|----------|------|
| 9 | MY_TEAM CSV mapping | ☐ |
| 10 | Disclosed relationships | ☐ |
| 11 | MY_TEAM_PQ via MinIO | ☐ |
| 12 | Processed-files log | ☐ |
| 13 | Updated file drop | ☐ |
| 14 | Batch + cron | ☐ |

---

<a id="next-steps-when-ready"></a>
## Next steps (when ready)

- [DATA-MAPPING-TUTORIAL.md](./DATA-MAPPING-TUTORIAL.md) — Phase B & C in detail
- [mapper-file](https://github.com/Senzing/mapper-file) — auto-generate mappers from Parquet
- Later with AWS: same scripts, drop `setup-minio-env.sh`, use real S3 bucket

---

*Workbooks: [CHEATSHEET.md](./CHEATSHEET.md) · [EDA-TUTORIAL.md](./EDA-TUTORIAL.md) · [DATA-MAPPING-TUTORIAL.md](./DATA-MAPPING-TUTORIAL.md)*
