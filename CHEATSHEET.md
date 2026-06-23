# Senzing Local Lab — Learning Cheat Sheet

Your **learning & familiarization guide** for the `senzing-demo` project.  
Stack: **M1 Mac + Docker + PostgreSQL + MinIO** (local S3). **No AWS account needed.**

Use this doc in order the first time, then as a quick reference later.

---

## Table of contents

**Workbooks:** [EXERCISES.md](./EXERCISES.md) · [EDA-TUTORIAL.md](./EDA-TUTORIAL.md) · [DATA-MAPPING-TUTORIAL.md](./DATA-MAPPING-TUTORIAL.md) · **[EXPLORER-SESSION.md](./EXPLORER-SESSION.md)** ← open sz_explorer

- [1. Core concepts (read first)](#1-core-concepts-read-first)
  - [What Senzing does](#what-senzing-does)
  - [Record vs entity](#record-vs-entity)
  - [Merged vs related (critical for learning)](#merged-vs-related-critical-for-learning)
  - [Data flow (what you built locally)](#data-flow-what-you-built-locally)
  - [Three EDA tools](#three-eda-tools)
- [2. Learning curriculum (8 phases)](#2-learning-curriculum-8-phases)
- [3. Every session — start here](#3-every-session-start-here)
- [4. Where to run commands](#4-where-to-run-commands)
- [5. Initial setup (first time only)](#5-initial-setup-first-time-only)
  - [5a. Start infrastructure](#5a-start-infrastructure)
  - [5b. Initialize Senzing database (once)](#5b-initialize-senzing-database-once)
  - [5c. Connection string (do not change unless you know why)](#5c-connection-string-do-not-change-unless-you-know-why)
  - [5d. Load truth set (original JSONL)](#5d-load-truth-set-original-jsonl)
  - [5e. Setup MinIO + upload Parquet](#5e-setup-minio-upload-parquet)
- [6. Pipeline & MinIO commands](#6-pipeline-minio-commands)
  - [Pipeline scripts](#pipeline-scripts)
  - [Full pipeline from MinIO](#full-pipeline-from-minio)
  - [One dataset (environment variables)](#one-dataset-environment-variables)
  - [Force re-process](#force-re-process)
  - [MinIO / aws CLI (after `source ./setup-minio-env.sh`)](#minio-aws-cli-after-source-setup-minio-envsh)
  - [MinIO bucket layout](#minio-bucket-layout)
  - [Snapshot (Mac — refreshes reports)](#snapshot-mac-refreshes-reports)
  - [Audit (Mac)](#audit-mac)
  - [Load JSONL directly (Mac)](#load-jsonl-directly-mac)
- [7. sz_explorer — all commands](#7-sz_explorer-all-commands)
  - [Navigation keys (reports & compare)](#navigation-keys-reports-compare)
  - [Live database commands (no `load` needed)](#live-database-commands-no-load-needed)
  - [Syntax rules (memorize)](#syntax-rules-memorize)
  - [Snapshot report commands (**must `load` first**)](#snapshot-report-commands-must-load-first)
  - [why color legend](#why-color-legend)
- [8. How to read results](#8-how-to-read-results)
  - [Did two records merge? (duplicate detection)](#did-two-records-merge-duplicate-detection)
  - [Did a record match the watchlist?](#did-a-record-match-the-watchlist)
  - [Audit metrics (from `sz_audit` output)](#audit-metrics-from-sz_audit-output)
  - [cross_source_summary (after `load`)](#cross_source_summary-after-load)
- [9. Learning exercises with answers](#9-learning-exercises-with-answers)
  - [Exercise A — Truth set basics](#exercise-a-truth-set-basics)
  - [Exercise B — Audit interpretation](#exercise-b-audit-interpretation)
  - [Exercise C — Full MinIO pipeline](#exercise-c-full-minio-pipeline)
  - [Exercise D — Vendors exercise](#exercise-d-vendors-exercise)
  - [Exercise E — Snapshot screening report](#exercise-e-snapshot-screening-report)
  - [Exercise F — MinIO visual](#exercise-f-minio-visual)
- [10. Common errors & fixes](#10-common-errors-fixes)
- [Viewing files (Cursor / MinIO)](#viewing-files-cursor-minio)
  - [Inspect Parquet in terminal (Mac)](#inspect-parquet-in-terminal-mac)
  - [Inspect mapped JSONL (readable)](#inspect-mapped-jsonl-readable)
  - [MinIO console (http://localhost:9001)](#minio-console-httplocalhost9001)
- [11. Project file map](#11-project-file-map)
  - [Data sources in this lab](#data-sources-in-this-lab)
- [12. Quick workflows (copy-paste)](#12-quick-workflows-copy-paste)
  - [Workflow 1 — Explore live data (5 min)](#workflow-1-explore-live-data-5-min)
  - [Workflow 2 — Full MinIO pipeline + reports (10 min)](#workflow-2-full-minio-pipeline-reports-10-min)
  - [Workflow 3 — Vendors learning check (5 min)](#workflow-3-vendors-learning-check-5-min)
  - [Workflow 4 — Fresh start (wipe all data)](#workflow-4-fresh-start-wipe-all-data)
- [13. Official docs](#13-official-docs)
- [Local vs AWS (when you eventually migrate)](#local-vs-aws-when-you-eventually-migrate)

---

<a id="1-core-concepts-read-first"></a>
## 1. Core concepts (read first)

<a id="what-senzing-does"></a>
### What Senzing does

```text
Many messy records  →  Entity Resolution  →  Fewer "entities" (real people/orgs)
     (inputs)              (Senzing)              (outputs)
```

Example: three customer records for "Robert Smith" become **one entity** with three source records attached.

<a id="record-vs-entity"></a>
### Record vs entity

| Term | Example | Think of it as |
|------|---------|----------------|
| **RECORD_ID** | `CUSTOMERS 1070` | One row from one source file |
| **ENTITY_ID** | `54` (shown in `get` header) | The resolved real-world person/org |
| **DATA_SOURCE** | `CUSTOMERS`, `VENDORS_PQ` | Which dataset the record came from |

```text
get CUSTOMERS 1070     ← uses RECORD_ID + DATA_SOURCE
why 17 18              ← uses two ENTITY_IDs (numbers from get header)
compare 1 9            ← uses ENTITY_IDs (spaces, not commas)
```

<a id="merged-vs-related-critical-for-learning"></a>
### Merged vs related (critical for learning)

| Outcome | Meaning | How you see it |
|---------|---------|----------------|
| **Merged** | Same person/org — one entity | Same entity ID; multiple sources in one `get` block |
| **Related** | Similar but not same — flagged for review | Different entity IDs; link in tree or `why` shows green NAME, red DOB |
| **No match** | Unrelated | Different entities, low scores in `why` |

```text
Merged   = "These ARE the same organization"     (V001 + V002 → entity 600002)
Related  = "These MIGHT be connected — check"    (V003 Maria ↔ entity 24 watchlist)
```

<a id="data-flow-what-you-built-locally"></a>
### Data flow (what you built locally)

```text
JSONL truth set ──► sz_file_loader ──► PostgreSQL ──► sz_explorer
                                              ▲
MinIO (local S3) ──► Parquet ──► map ──► JSONL ──┘
```

Senzing **never loads Parquet directly**. Pipeline always: **Parquet → map → JSONL → load**.

<a id="three-eda-tools"></a>
### Three EDA tools

| Tool | Runs on | Purpose |
|------|---------|---------|
| `sz_explorer` | Mac (via Docker) | Interactive search, get, why, how |
| `sz_snapshot` | Mac | Batch reports → `.json` file |
| `sz_audit` | Mac | Accuracy vs truth key → `.json` file |

---

<a id="2-learning-curriculum-8-phases"></a>
## 2. Learning curriculum (8 phases)

Work through in order. Check off as you go.

| Phase | Topic | Key command / file |
|-------|-------|-------------------|
| **1** | Install stack | `docker compose up -d`, `init-database` |
| **2** | Load truth set | `customers.jsonl`, `sz_configtool`, `sz_file_loader` |
| **3** | Explore entities | `sz_explorer` → `get`, `search`, `how`, `why` |
| **4** | Snapshot reports | `sz_snapshot` → `load` → `cross_source_summary` |
| **5** | Audit accuracy | `sz_audit` → `load` → `audit_summary` |
| **6** | Parquet pipeline | `run_pipeline.sh` (local incoming/) |
| **7** | MinIO (local S3) | `setup_minio.sh`, `run_all_from_minio.sh` |
| **8** | Vendors exercise | `learn_local_exercise.sh` → verify merge & screening |
| **9** | Data mapping (CSV) | [DATA-MAPPING-TUTORIAL.md](./DATA-MAPPING-TUTORIAL.md) → `load_my_team.sh` |
| **10** | Pipeline ops (MinIO) | `run_my_team_from_minio.sh`, cron, processed log |

---

<a id="3-every-session-start-here"></a>
## 3. Every session — start here

**Mac terminal** — run this every time you sit down to practice:

```bash
cd ~/Dev/Tutorials/senzing-demo

docker compose up -d              # PostgreSQL :5433 + MinIO :9000/:9001
source ./setup-env.sh             # REQUIRED — Senzing DB connection
source ./setup-minio-env.sh       # REQUIRED for S3/MinIO pipeline
```

| Service | Address | Credentials |
|---------|---------|-------------|
| PostgreSQL | `localhost:5433` | `senzing` / `senzing` / db `G2` |
| MinIO S3 API | http://localhost:9000 | via `setup-minio-env.sh` |
| MinIO Console | http://localhost:9001 | `minioadmin` / `minioadmin` |

**Remember:** `source ./setup-env.sh` — never `./setup-env.sh` alone (subshell won't export vars).

---

<a id="4-where-to-run-commands"></a>
## 4. Where to run commands

| Where | Prompt | Examples |
|-------|--------|----------|
| **Mac** | `➜ senzing-demo` | `docker compose`, `source`, `aws`, `./pipeline/*.sh` |
| **Container shell** | `root@...:/data#` | `sz_explorer`, `sz_configtool` |
| **sz_explorer** | `(szeda)` | `get`, `search`, `load`, `cross_source_summary` |

**New to sz_explorer?** Read **[EXPLORER-SESSION.md](./EXPLORER-SESSION.md)** — full open/exit steps with prompts.

### Open sz_explorer (copy every time)

**Step 1 — Mac** (`➜ senzing-demo`):

```bash
cd ~/Dev/Tutorials/senzing-demo
source ./setup-env.sh

docker run --rm -it \
  -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/senzingsdk-tools
```

**Step 2 — Container** (`root@....:/data#`):

```
sz_explorer
```

**Step 3 — Explorer** (`(szeda)`): type `get`, `search`, `load`, etc.

**Step 4 — Exit:** `quit` then `exit` (see [EXPLORER-SESSION.md](./EXPLORER-SESSION.md)).

**Always mount** `-v ${PWD}:/data -w /data` so snapshot/audit JSON files are visible.

---

<a id="5-initial-setup-first-time-only"></a>
## 5. Initial setup (first time only)

<a id="5a-start-infrastructure"></a>
### 5a. Start infrastructure

```bash
cd ~/Dev/Tutorials/senzing-demo
docker compose up -d
source ./setup-env.sh
```

<a id="5b-initialize-senzing-database-once"></a>
### 5b. Initialize Senzing database (once)

```bash
docker run --rm \
  --env SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/init-database \
  --install-senzing-er-configuration
```

Expect: `Processed 45 lines with no failures` (or "already exists" if re-run — OK).

<a id="5c-connection-string-do-not-change-unless-you-know-why"></a>
### 5c. Connection string (do not change unless you know why)

```text
postgresql://senzing:senzing@host.docker.internal:5433:G2?sslmode=disable
                                              ^ colon before G2, not slash ^
```

<a id="5d-load-truth-set-original-jsonl"></a>
### 5d. Load truth set (original JSONL)

**Register data sources** (inside container or piped from Mac):

```bash
printf 'addDataSource CUSTOMERS\naddDataSource REFERENCE\naddDataSource WATCHLIST\nsave\ny\nquit\n' | \
  docker run --rm -i -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/senzingsdk-tools sz_configtool
```

**Load files:**

```bash
source ./setup-env.sh
for f in customers reference watchlist; do
  docker run --rm -u $(id -u) -v ${PWD}:/data \
    -e SENZING_ENGINE_CONFIGURATION_JSON \
    senzing/sz-file-loader -f /data/${f}.jsonl
done
```

<a id="5e-setup-minio-upload-parquet"></a>
### 5e. Setup MinIO + upload Parquet

```bash
./pipeline/setup_minio.sh
```

---

<a id="6-pipeline-minio-commands"></a>
## 6. Pipeline & MinIO commands

<a id="pipeline-scripts"></a>
### Pipeline scripts

| Script | Purpose |
|--------|---------|
| `pipeline/setup_minio.sh` | Start MinIO, build Parquet, upload to bucket |
| `pipeline/run_pipeline.sh` | One dataset: acquire → map → load → snapshot |
| `pipeline/run_all_from_minio.sh` | Customers + watchlist from MinIO, then snapshot |
| `pipeline/learn_local_exercise.sh` | Load VENDORS_PQ learning dataset |

<a id="full-pipeline-from-minio"></a>
### Full pipeline from MinIO

```bash
source ./setup-env.sh && source ./setup-minio-env.sh
./pipeline/run_all_from_minio.sh
```

<a id="one-dataset-environment-variables"></a>
### One dataset (environment variables)

| Variable | Example | Meaning |
|----------|---------|---------|
| `S3_URI` | `s3://senzing-incoming/customers/` | MinIO prefix to sync |
| `SENZING_DATA_SOURCE` | `CUSTOMERS_PQ` | Must exist in sz_configtool |
| `INCOMING_DIR` | `customers` | Local folder under `incoming/` |
| `PARQUET_FILE` | `customers.parquet` | Filename |
| `JSONL_FILE` | `mapped_customers_pq.jsonl` | Staging output |
| `SKIP_SNAPSHOT` | `1` | Skip snapshot (use in multi-load scripts) |

```bash
S3_URI=s3://senzing-incoming/vendors/ \
SENZING_DATA_SOURCE=VENDORS_PQ \
INCOMING_DIR=vendors PARQUET_FILE=vendors.parquet \
JSONL_FILE=mapped_vendors_pq.jsonl \
./pipeline/run_pipeline.sh
```

<a id="force-re-process"></a>
### Force re-process

```bash
rm staging/.processed_files.log
# Or remove one source only:
grep -v '^VENDORS_PQ-' staging/.processed_files.log > staging/.tmp && mv staging/.tmp staging/.processed_files.log
```

<a id="minio-aws-cli-after-source-setup-minio-envsh"></a>
### MinIO / aws CLI (after `source ./setup-minio-env.sh`)

```bash
aws --endpoint-url http://localhost:9000 s3 ls
aws --endpoint-url http://localhost:9000 s3 ls s3://senzing-incoming/ --recursive

aws --endpoint-url http://localhost:9000 s3 cp \
  parquet/vendors.parquet s3://senzing-incoming/vendors/vendors.parquet
```

<a id="minio-bucket-layout"></a>
### MinIO bucket layout

```text
s3://senzing-incoming/
├── customers/customers.parquet   → CUSTOMERS_PQ
├── watchlist/watchlist.parquet   → WATCHLIST_PQ
└── vendors/vendors.parquet       → VENDORS_PQ
```

<a id="snapshot-mac-refreshes-reports"></a>
### Snapshot (Mac — refreshes reports)

```bash
docker run --rm -u $(id -u) -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/senzingsdk-tools sz_snapshot -QAo truthset_snapshot
```

| Flag | Meaning |
|------|---------|
| `-Q` | Quiet (overwrite without prompt) |
| `-A` | Include audit data for sz_audit |
| `-o truthset_snapshot` | Creates `.json` + `.csv` |

<a id="audit-mac"></a>
### Audit (Mac)

```bash
# vs alternate algorithm (~97% F1 — intentional MERGE/SPLIT demo)
docker run --rm -u $(id -u) -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools \
  sz_audit -n truthset_snapshot.csv -p alternate_truthset_key.csv -o truthset_audit

# vs definitive truth (expect 100% F1)
docker run --rm -u $(id -u) -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools \
  sz_audit -n truthset_snapshot.csv -p actual_truthset_key.csv -o actual_audit
```

<a id="load-jsonl-directly-mac"></a>
### Load JSONL directly (Mac)

```bash
docker run --rm -u $(id -u) -v ${PWD}:/data \
  -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/sz-file-loader -f /data/customers.jsonl
```

---

<a id="7-sz_explorer-all-commands"></a>
## 7. sz_explorer — all commands

**Open explorer first:** [EXPLORER-SESSION.md](./EXPLORER-SESSION.md) (Mac → container → `(szeda)`).

Quick version: Mac `source ./setup-env.sh` → `docker run ... senzing/senzingsdk-tools` → `sz_explorer` → commands below → `quit` → `exit`.

<a id="navigation-keys-reports-compare"></a>
### Navigation keys (reports & compare)

| Key | Action |
|-----|--------|
| ↑ ↓ | Move between rows |
| Enter | Drill into row |
| Q | Go back / quit view |
| ← → | Scroll wide tables (compare) |

---

<a id="live-database-commands-no-load-needed"></a>
### Live database commands (no `load` needed)

| Command | Syntax | Example |
|---------|--------|---------|
| Help | `help` or `help search` | |
| Search | `search <text>` | `search robert smith` |
| Search field | `search NAME="Jie Wang"` | |
| Get by record | `get <SOURCE> <RECORD_ID>` | `get CUSTOMERS 1070` |
| Get by entity | `get <ENTITY_ID>` | `get 54` |
| Get detail | `get <id> detail` | `get 54 detail` |
| Compare entities | `compare <id1> <id2>` | `compare 1 9` |
| Compare search | `compare search` | after `search ...` |
| Why entities | `why <id1> <id2>` | `why 17 18` |
| Why records | `why <src1> <rec1> <src2> <rec2>` | `why CUSTOMERS 1069 CUSTOMERS 1070` |
| Why search | `why search` / `why search 9` | after search |
| How merged | `how <ENTITY_ID>` | `how 600002` |
| Tree | `tree <ENTITY_ID> degree 2` | |
| Export | `export <id> to /data/file.jsonl` | |
| Record counts | `quick_look` | per DATA_SOURCE |
| SDK debug | `show_last_call` | after any command |
| Quit explorer | `quit` | |
| Exit container | `exit` | |

<a id="syntax-rules-memorize"></a>
### Syntax rules (memorize)

```text
why 1 9                    ✅  entity IDs, spaces
why 1, 9                   ❌  commas fail
compare 1 9                  ✅  spaces
get CUSTOMERS 1070           ✅  DATA_SOURCE + RECORD_ID
why CUSTOMERS 1070           ❌  need entity ID or 4-arg record form
```

<a id="snapshot-report-commands-must-load-first"></a>
### Snapshot report commands (**must `load` first**)

```text
load truthset_snapshot.json       ← ALWAYS run this first
cross_source_summary              ← screening across sources
data_source_summary               ← duplicates within one source
entity_source_summary
entity_size_breakdown             ← spot over-matching
principles_used                   ← which match rules fired

load truthset_audit.json
audit_summary                     ← precision/recall, MERGE/SPLIT drill-down
```

**Common mistake:**

```text
(szeda) cross_source_summary
ERROR: Please load a json file created with sz_snapshot
```

**Fix:** run `load truthset_snapshot.json` first.

<a id="why-color-legend"></a>
### why color legend

| Color | Meaning |
|-------|---------|
| **Green** | Matched — helped the score |
| **Red** | Did not match — hurt the score |
| **Yellow** | Did not match — did not hurt |
| **Cyan** | Only helped get on candidate list |

---

<a id="8-how-to-read-results"></a>
## 8. How to read results

<a id="did-two-records-merge-duplicate-detection"></a>
### Did two records merge? (duplicate detection)

```
get VENDORS_PQ V001
get VENDORS_PQ V002
```

| Signal | Meaning |
|--------|---------|
| **Same** `Entity summary for entity XXXXX` | ✅ Merged |
| Both V001 and V002 in Sources column | ✅ Same entity |
| Different entity IDs | ❌ Not merged |

Then: `how XXXXX` to see merge steps.

**Lab answer:** V001 + V002 → entity **600002** (ACME Supply Limited) — **merged**.

---

<a id="did-a-record-match-the-watchlist"></a>
### Did a record match the watchlist?

**Step 1 — get the record**

```
get VENDORS_PQ V003
```

**Step 2 — interpret**

| What you see | Meaning |
|--------------|---------|
| `WATCHLIST` in **Sources** column | ✅ Merged with watchlist (same entity) |
| `WATCHLIST` only in **tree** at bottom | ⚠️ Related, not merged — investigate |
| No watchlist mention | ❌ No connection found |

**Step 3 — search**

```
search maria sentosa
compare search
```

Multiple entity rows = separate entities (may still be related).

**Step 4 — why (if related)**

```
why 600001 24
```

Green ADDRESS + red DOB = same address, different person → **related, not merged**.

**Lab answer:** V003 (entity **600001**) is **related** to entity **24** (has WATCHLIST records), not merged. Same address (`638 Downey St`), different DOB.

---

<a id="audit-metrics-from-sz_audit-output"></a>
### Audit metrics (from `sz_audit` output)

| Metric | Meaning |
|--------|---------|
| **Precision** | Of Senzing's merges, how many matched the key |
| **Recall** | Of the key's merges, how many Senzing found |
| **F1** | Overall balance |
| **MERGE** | Senzing combined groups the key kept separate |
| **SPLIT** | Senzing split groups the key merged |

| Comparison file | Expected F1 in lab |
|-----------------|-------------------|
| `alternate_truthset_key.csv` | ~97% (intentional differences) |
| `actual_truthset_key.csv` | 100% (definitive truth) |

---

<a id="cross_source_summary-after-load"></a>
### cross_source_summary (after `load`)

Look for rows like:

```text
CUSTOMERS ↔ WATCHLIST          ← watchlist screening
CUSTOMERS ↔ CUSTOMERS_PQ       ← Parquet pipeline dedup worked
VENDORS_PQ ↔ WATCHLIST         ← vendor exercise screening
```

Use **Enter** to drill into entity IDs, then `get <id>` for details.

---

<a id="9-learning-exercises-with-answers"></a>
## 9. Learning exercises with answers

Run these in order. Answers reflect a fully loaded lab (truth set + MinIO pipelines + vendors exercise).

<a id="exercise-a-truth-set-basics"></a>
### Exercise A — Truth set basics

```bash
# Container:
sz_explorer
quick_look
get CUSTOMERS 1070
how 54                    # use YOUR entity id from get header
search robert smith
compare search
why 1 9                   # use entity ids from search
quit
```

**Learn:** entity resolution, cross-source matches, why entities didn't merge.

---

<a id="exercise-b-audit-interpretation"></a>
### Exercise B — Audit interpretation

```bash
# Mac:
source ./setup-env.sh
docker run --rm -u $UID -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools \
  sz_audit -n truthset_snapshot.csv -p alternate_truthset_key.csv -o truthset_audit
```

```text
# Container:
load truthset_audit.json
audit_summary
```

Drill into **SPLIT** → Darla/Darlene (entities 17 & 18).  
Drill into **MERGE** → Margaret Charney (`how 100009`, employer match).

---

<a id="exercise-c-full-minio-pipeline"></a>
### Exercise C — Full MinIO pipeline

```bash
source ./setup-env.sh && source ./setup-minio-env.sh
./pipeline/run_all_from_minio.sh
```

**Verify in terminal (not by opening Parquet in Cursor):**

```bash
# Pipeline succeeded if you see: "Successfully loaded ... records" and "Process completed"
ls -la incoming/customers/customers.parquet staging/mapped_customers_pq.jsonl
head -1 staging/mapped_customers_pq.jsonl | python3 -m json.tool
```

**Verify in Senzing (the real test):**

```bash
docker run --rm -it -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools
```

```text
sz_explorer
get CUSTOMERS_PQ 1001     # should show CUSTOMERS + CUSTOMERS_PQ on same entity
quick_look                # should list CUSTOMERS_PQ and WATCHLIST_PQ counts
quit
exit
```

> **Cursor "Preview unavailable" on `.parquet`?** Normal — Parquet is binary. Cursor/MinIO cannot preview it. Use terminal commands above or MinIO **Download**, not Preview.

---

<a id="exercise-d-vendors-exercise"></a>
### Exercise D — Vendors exercise

```bash
./pipeline/learn_local_exercise.sh
```

```text
get VENDORS_PQ V001
get VENDORS_PQ V002       # same entity 600002? → duplicate vendor merge
get VENDORS_PQ V003
search maria sentosa
why 600001 24             # related vs watchlist, not merged
how 600002
```

| Question | Expected in lab |
|----------|-----------------|
| V001 + V002 merged? | **Yes** → entity **600002** |
| V003 matched watchlist? | **Related** to entity **24**, not merged |

---

<a id="exercise-e-snapshot-screening-report"></a>
### Exercise E — Snapshot screening report

```text
load truthset_snapshot.json
cross_source_summary
data_source_summary
```

**Learn:** batch view of dedup + screening (production reporting pattern).

---

<a id="exercise-f-minio-visual"></a>
### Exercise F — MinIO visual

1. Open http://localhost:9001
2. Browse `senzing-incoming` bucket
3. Correlate folders with `DATA_SOURCE` codes

---

<a id="10-common-errors-fixes"></a>
## 10. Common errors & fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `unknown database schema: in` | Env not sourced | `source ./setup-env.sh` |
| `SSL is not enabled on the server` | Missing sslmode | Use `setup-env.sh` (`?sslmode=disable`) |
| `invalid integer value "senzing@host..."` | `/G2` instead of `:G2` | Use `:G2?sslmode=disable` |
| `truthset_snapshot.json not found` | No volume mount | `-v ${PWD}:/data -w /data` |
| `Please load a json file...` | Skipped `load` | `load truthset_snapshot.json` first |
| `Unknown entity '1070'` | Record ID in `why`/`compare` | Use entity ID from `get` header |
| `Unknown entity '88'` | Guessed entity ID | Use IDs from your `search`/`get` |
| `invalid parameters` on `why 1, 9` | Used comma | Use spaces: `why 1 9` |
| `Already processed` | Idempotency log | `rm staging/.processed_files.log` |
| `the input device is not a TTY` | `-it` in script | Remove `-it` for automation |
| MinIO connection refused | MinIO down | `docker compose up -d minio` |
| `relation already exists` on init | DB already init | OK — skip or `docker compose down -v` to reset |
| Cursor **Preview unavailable** on file | Opened `.parquet` or binary in IDE | Use terminal/`sz_explorer` — see [Viewing files](#viewing-files-cursor--minio) |

---

<a id="viewing-files-cursor-minio"></a>
## Viewing files (Cursor / MinIO)

Cursor cannot preview some file types. **This is normal — not a pipeline error.**

| File type | Open in Cursor? | How to view instead |
|-----------|-----------------|---------------------|
| `.parquet` | ❌ Preview unavailable | Terminal (below) or MinIO **Download** |
| `.jsonl` | ⚠️ Often plain text OK | `head -3 file.jsonl` or `python3 -m json.tool` |
| `truthset_snapshot.json` | ⚠️ Large (170KB+) | Use `sz_explorer` → `load truthset_snapshot.json` |
| `.sh` scripts | ✅ Usually OK | Run in terminal, don't need to preview |

<a id="inspect-parquet-in-terminal-mac"></a>
### Inspect Parquet in terminal (Mac)

```bash
docker run --rm -v ${PWD}:/data -w /data python:3.12-slim bash -c \
  'pip -q install pandas pyarrow && python -c "
import pandas as pd
df = pd.read_parquet(\"/data/parquet/customers.parquet\")
print(df.columns.tolist())
print(df.head(3))
"'
```

<a id="inspect-mapped-jsonl-readable"></a>
### Inspect mapped JSONL (readable)

```bash
head -1 staging/mapped_customers_pq.jsonl | python3 -m json.tool
```

<a id="minio-console-httplocalhost9001"></a>
### MinIO console (http://localhost:9001)

- **Browse** bucket → see files ✅  
- **Download** parquet ✅  
- **Preview** parquet ❌ (same "preview unavailable" — use Download or terminal)

---

<a id="11-project-file-map"></a>
## 11. Project file map

```text
senzing-demo/
├── CHEATSHEET.md                ← this file
├── setup-env.sh                 ← source every session (Senzing)
├── setup-minio-env.sh           ← source for MinIO/S3 pipeline
├── docker-compose.yml           ← postgres :5433 + minio :9000/:9001
│
├── customers.jsonl              ┐
├── reference.jsonl              ├─ truth set (original)
├── watchlist.jsonl              ┘
├── vendors.jsonl                ← learning exercise (3 records)
│
├── truthset_snapshot.json         ← load in sz_explorer for reports
├── truthset_snapshot.csv          ← input to sz_audit
├── truthset_audit.json            ← load for audit_summary
├── actual_audit.json              ← 100% truth comparison
├── actual_truthset_key.csv        ← definitive truth key
├── alternate_truthset_key.csv     ← legacy-style comparison key
│
├── incoming/                    ← synced from MinIO
│   ├── customers/
│   ├── watchlist/
│   └── vendors/
├── staging/
│   ├── mapped_*_pq.jsonl        ← mapped before load
│   └── .processed_files.log     ← idempotency tracker
├── parquet/
│   ├── jsonl_to_parquet.py
│   └── *.parquet
└── pipeline/
    ├── setup_minio.sh
    ├── run_pipeline.sh
    ├── run_all_from_minio.sh
    ├── learn_local_exercise.sh
    ├── map_parquet_to_jsonl.py
    └── schedule.example.cron
```

<a id="data-sources-in-this-lab"></a>
### Data sources in this lab

| DATA_SOURCE | Origin | Records (approx) |
|-------------|--------|------------------|
| `CUSTOMERS` | Truth set JSONL | 120 |
| `REFERENCE` | Truth set JSONL | 22 |
| `WATCHLIST` | Truth set JSONL | 17 |
| `CUSTOMERS_PQ` | MinIO Parquet pipeline | 120 |
| `WATCHLIST_PQ` | MinIO Parquet pipeline | 17 |
| `VENDORS_PQ` | Learning exercise | 3 |

---

<a id="12-quick-workflows-copy-paste"></a>
## 12. Quick workflows (copy-paste)

<a id="workflow-1-explore-live-data-5-min"></a>
### Workflow 1 — Explore live data (5 min)

```bash
source ./setup-env.sh
docker run --rm -it -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools
```

```
sz_explorer
quick_look
search robert smith
compare search
get CUSTOMERS 1070
quit
exit
```

---

<a id="workflow-2-full-minio-pipeline-reports-10-min"></a>
### Workflow 2 — Full MinIO pipeline + reports (10 min)

```bash
source ./setup-env.sh && source ./setup-minio-env.sh
./pipeline/run_all_from_minio.sh

docker run --rm -it -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools
```

```
sz_explorer
load truthset_snapshot.json
cross_source_summary
data_source_summary
quit
exit
```

---

<a id="workflow-3-vendors-learning-check-5-min"></a>
### Workflow 3 — Vendors learning check (5 min)

```bash
./pipeline/learn_local_exercise.sh
# then enter container and run Exercise D commands above
```

---

<a id="workflow-4-fresh-start-wipe-all-data"></a>
### Workflow 4 — Fresh start (wipe all data)

```bash
docker compose down -v
docker compose up -d
source ./setup-env.sh
docker run --rm --env SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/init-database --install-senzing-er-configuration
# Re-run truth set load + pipeline/setup_minio.sh + run_all_from_minio.sh
```

---

<a id="13-official-docs"></a>
## 13. Official docs

- [Docker Quickstart](https://senzing.com/docs/quickstart/quickstart_docker/)
- [EDA Tools overview](https://senzing.com/docs/tutorials/eda/)
- [Entity Exploration (`get`, `why`, `how`)](https://senzing.com/docs/tutorials/eda/eda_basic_exploration/)
- [Truth Set Setup (load, snapshot, audit)](https://senzing.com/docs/tutorials/eda/eda_loading/)
- [Snapshot Analysis](https://senzing.com/docs/tutorials/eda/eda_snapshot/)
- [Auditing](https://senzing.com/docs/tutorials/eda/eda_audit/)
- [Entity Specification (mapping fields)](https://senzing.com/docs/entity_specification/)

---

<a id="local-vs-aws-when-you-eventually-migrate"></a>
## Local vs AWS (when you eventually migrate)

| Today (local lab) | Production (AWS) |
|-------------------|------------------|
| `source ./setup-minio-env.sh` | IAM role or access keys |
| `AWS_ENDPOINT_URL=http://localhost:9000` | omit (uses AWS default) |
| `s3://senzing-incoming/...` | `s3://your-company-bucket/...` |
| Same `run_pipeline.sh` | Same scripts |

---

*Last updated for senzing-demo local lab — Docker, PostgreSQL, MinIO, Senzing v4.3.x.*
