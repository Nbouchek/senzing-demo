<a id="senzing-data-mapping-phase-b-c-workbook"></a>
# Senzing Data Mapping — Phase B & C Workbook

Step-by-step guide for **mapping your own data** and **operating the pipeline locally** (MinIO = S3, no AWS account).

**Official curriculum:** [Data Mapping – Senzing®](https://senzing.zendesk.com/hc/en-us/sections/360000385913-Data-Mapping)

**Prerequisites:** Completed [EDA-TUTORIAL.md](./EDA-TUTORIAL.md) (explore, snapshot, audit).

**Companion:** [CHEATSHEET.md](./CHEATSHEET.md) · [EXERCISES.md](./EXERCISES.md) · [EDA-TUTORIAL.md](./EDA-TUTORIAL.md) · **[EXPLORER-SESSION.md](./EXPLORER-SESSION.md)** (how to open `sz_explorer`)

---

## Table of contents

**Workbooks:** [CHEATSHEET.md](./CHEATSHEET.md) · [EXERCISES.md](./EXERCISES.md) · [EDA-TUTORIAL.md](./EDA-TUTORIAL.md)

- [Curriculum map (official → this lab)](#curriculum-map-official-this-lab)
- [Before every session](#before-every-session)
- [Progress checklist](#progress-checklist)
  - [Phase B — Map & load your own data](#phase-b-map-load-your-own-data)
  - [Phase C — Operate pipeline locally](#phase-c-operate-pipeline-locally)
- [Phase B — Map and load your own data](#phase-b-map-and-load-your-own-data)
  - [B1 — Generic Entity Specification (read first)](#b1-generic-entity-specification-read-first)
  - [B2 — Study the source data and mapping table](#b2-study-the-source-data-and-mapping-table)
  - [B3 — Run the mapper (inspect JSONL)](#b3-run-the-mapper-inspect-jsonl)
  - [B4 — Load MY_TEAM and verify entity resolution](#b4-load-my_team-and-verify-entity-resolution)
  - [B5 — Disclosed relationships (REFERENCE data)](#b5-disclosed-relationships-reference-data)
  - [B6 — Mapping mistake lab (overmatching)](#b6-mapping-mistake-lab-overmatching)
- [Phase C — Operate the pipeline locally (MinIO = S3)](#phase-c-operate-the-pipeline-locally-minio-s3)
  - [C1 — CSV → Parquet → MinIO](#c1-csv-parquet-minio)
  - [C2 — Full pipeline run](#c2-full-pipeline-run)
  - [C3 — Processed-files log (idempotent loads)](#c3-processed-files-log-idempotent-loads)
  - [C4 — Simulate an updated file drop](#c4-simulate-an-updated-file-drop)
  - [C5 — Schedule with cron (Mac)](#c5-schedule-with-cron-mac)
  - [C6 — Daily operations checklist](#c6-daily-operations-checklist)
- [Local vs AWS (when you eventually get S3)](#local-vs-aws-when-you-eventually-get-s3)
- [Project file map (Phase B & C)](#project-file-map-phase-b-c)
- [Troubleshooting](#troubleshooting)
- [What's next after Phase B & C](#whats-next-after-phase-b-c)
- [Learning tracks summary](#learning-tracks-summary)

---

<a id="curriculum-map-official-this-lab"></a>
## Curriculum map (official → this lab)

| Official article | Phase | This workbook |
|------------------|-------|---------------|
| [Generic Entity Specification](https://senzing.com/docs/entity_specification/) | B1 | Map CSV columns to Senzing attributes |
| [Advanced mapping concepts](https://senzing.zendesk.com/hc/en-us/articles/360054097153) | B2–B4 | Labels, payload, EMPLOYER vs NAME |
| [How to create disclosed relationships](https://senzing.zendesk.com/hc/en-us/articles/360051209553) | B5 | Explore REFERENCE data |
| [Mapping Tutorial & Assistance](https://senzing.zendesk.com/hc/en-us/articles/360002044173) | B1 | Column → term mapping table |
| Videos: Mapping and Loading 1 & 2 | B, C | CSV and Parquet paths |
| [Reprocessing / ER configuration](https://senzing.zendesk.com/hc/en-us/sections/360000385913-Data-Mapping) | C6 | Advanced — optional later |

---

<a id="before-every-session"></a>
## Before every session

```bash
cd ~/Dev/Tutorials/senzing-demo
docker compose up -d
source ./setup-env.sh
source ./setup-minio-env.sh   # Phase C only
```

---

<a id="progress-checklist"></a>
## Progress checklist

<a id="phase-b-map-load-your-own-data"></a>
### Phase B — Map & load your own data

| # | Exercise | Done |
|---|----------|------|
| B1 | Understand Generic Entity Specification | ☐ |
| B2 | Study the mapping table (`my_team.csv`) | ☐ |
| B3 | Run CSV → JSONL mapper | ☐ |
| B4 | Load MY_TEAM + verify duplicates | ☐ |
| B5 | Disclosed relationships (REFERENCE) | ☐ |
| B6 | Mapping mistake lab (EMPLOYER as NAME) | ☐ |

<a id="phase-c-operate-pipeline-locally"></a>
### Phase C — Operate pipeline locally

| # | Exercise | Done |
|---|----------|------|
| C1 | CSV → Parquet → MinIO drop | ☐ |
| C2 | Full MinIO pipeline (`run_my_team_from_minio.sh`) | ☐ |
| C3 | Processed-files log (idempotent reload) | ☐ |
| C4 | Simulate updated file re-drop | ☐ |
| C5 | Schedule with cron | ☐ |
| C6 | Daily run + snapshot + screening | ☐ |

---

<a id="phase-b-map-and-load-your-own-data"></a>
# Phase B — Map and load your own data

**Goal:** Go from a spreadsheet-style CSV to loaded Senzing records, using the same concepts as the [Advanced mapping concepts](https://senzing.zendesk.com/hc/en-us/articles/360054097153) article.

**Sample files in this repo:**

```text
learning/my_team.csv           ← source data (6 employees, 2 duplicate pairs)
learning/map_my_team_csv.py    ← mapper (CSV → JSONL)
pipeline/load_my_team.sh       ← one-command load
```

---

<a id="b1-generic-entity-specification-read-first"></a>
## B1 — Generic Entity Specification (read first)

**Official:** [Generic Entity Specification](https://senzing.com/docs/entity_specification/) (moved from [Zendesk article](https://senzing.zendesk.com/hc/en-us/articles/231925448))

Every record you load needs at minimum:

| Required | Example | Purpose |
|----------|---------|---------|
| `DATA_SOURCE` | `MY_TEAM` | Which dataset this row came from |
| `RECORD_ID` | `E001` | Unique ID within that source |
| Identity features | name, DOB, address… | What Senzing matches on |

Two JSON formats work with `sz-file-loader`:

1. **Flat** — `{"DATA_SOURCE":"...", "NAME_FIRST":"...", "ADDR_LINE1":"..."}`  
2. **FEATURES array** — like `customers.jsonl` in the truth set

This lab uses **flat JSON** (same as `map_parquet_to_jsonl.py`).

**Learn:** Mapping = telling Senzing which column means `NAME_LAST`, `ADDR_LINE1`, etc.

---

<a id="b2-study-the-source-data-and-mapping-table"></a>
## B2 — Study the source data and mapping table

Open `learning/my_team.csv`:

```bash
column -s, -t < learning/my_team.csv | head -8
```

**Deliberate duplicates built in:**

| Records | Expected ER outcome |
|---------|---------------------|
| E001 + E002 | **Merge** — Jane Doe / Jane Doee, same DOB, phone, address typo |
| E003 + E004 | **Merge** — John Smith, same DOB & phone, dept differs (payload) |
| E005 | Singleton |
| E006 | May **relate** to watchlist (638 Downey St — same as Maria Sentosa in truth set) |

**Mapping table** (from [Advanced mapping concepts](https://senzing.zendesk.com/hc/en-us/articles/360054097153)):

| CSV column | Senzing attribute | Label / notes |
|------------|-------------------|---------------|
| *(constant)* | `DATA_SOURCE` = `MY_TEAM` | No column in CSV — set in mapper |
| `employee_id` | `RECORD_ID` | Must be unique per source |
| — | `RECORD_TYPE` = `PERSON` | |
| `first_name` | `PRIMARY_NAME_FIRST` | PRIMARY only because we may add AKAs later |
| `last_name` | `PRIMARY_NAME_LAST` | |
| `dob` | `DATE_OF_BIRTH` | |
| address fields | `ADDR_LINE1`, `ADDR_CITY`, … | `ADDR_TYPE` = `HOME` |
| `phone` | `PHONE_NUMBER` | `PHONE_TYPE` = `MOBILE` |
| `email` | `EMAIL_ADDRESS` | |
| `employer` | `EMPLOYER` | **Not** `NAME_ORG` — employer ≠ person name |
| `department` | `DEPARTMENT` | **Payload** — display only |
| `hire_date` | `HIRE_DATE` | Payload |
| `status` | `STATUS` | Payload |

**Best practices** (from official docs):

- Use `MOBILE` for personal phones (less family sharing)
- Use `BUSINESS` address for organizations
- Use `PRIMARY` on names **only** when you have multiple names per record
- **Payload** fields help analysts decide — they don't affect matching

---

<a id="b3-run-the-mapper-inspect-jsonl"></a>
## B3 — Run the mapper (inspect JSONL)

**Mac:**

```bash
source ./setup-env.sh

docker run --rm \
  -e CSV_INPUT="/data/learning/my_team.csv" \
  -e JSONL_OUTPUT="/data/staging/mapped_my_team.jsonl" \
  -e SENZING_DATA_SOURCE="MY_TEAM" \
  -v ${PWD}:/data -w /data python:3.12-slim bash -c \
  'pip -q install pandas pyarrow && python learning/map_my_team_csv.py'
```

**Verify one record:**

```bash
head -1 staging/mapped_my_team.jsonl | python3 -m json.tool
```

**Check:**
- [ ] `DATA_SOURCE` is `MY_TEAM`
- [ ] `EMPLOYER` is present, not mapped as a name
- [ ] `DEPARTMENT` is payload at top level
- [ ] `ADDR_TYPE` is `HOME`, `PHONE_TYPE` is `MOBILE`

**Read the mapper source** — it's your template for future datasets:

```bash
cat learning/map_my_team_csv.py
```

---

<a id="b4-load-my_team-and-verify-entity-resolution"></a>
## B4 — Load MY_TEAM and verify entity resolution

**One command:**

```bash
source ./setup-env.sh
./pipeline/load_my_team.sh
```

Or step-by-step (what the script does):

```bash
# Register source
printf 'addDataSource MY_TEAM\nsave\ny\nquit\n' | \
  docker run --rm -i -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/senzingsdk-tools sz_configtool

# Load
docker run --rm -u $(id -u) -v ${PWD}:/data \
  -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/sz-file-loader -f /data/staging/mapped_my_team.jsonl
```

> Full open/exit guide: [EXPLORER-SESSION.md](./EXPLORER-SESSION.md)

**Step 1 — Mac terminal** (`➜ senzing-demo`):

```bash
cd ~/Dev/Tutorials/senzing-demo
source ./setup-env.sh

docker run --rm -it -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools
```

**Step 2 — Container** (`root@....:/data#`). Type:

```
sz_explorer
```

**Step 3 — Explorer** (`(szeda)`). Type:

```
quick_look                              # MY_TEAM should appear
get MY_TEAM E001
get MY_TEAM E002                        # Same entity ID as E001?
how <entity_id>                         # Why E001/E002 merged
search jane doe
compare search
get MY_TEAM E003 detail
get MY_TEAM E004 detail                 # John Smith pair
load truthset_snapshot.json
data_source_summary                     # MY_TEAM duplicates
cross_source_summary                    # MY_TEAM vs CUSTOMERS/WATCHLIST?
```

**Step 4 — Exit:**

```
quit          # leave explorer → container
exit          # leave container → Mac
```


**Expected answers:**

| Question | Expected |
|----------|----------|
| E001 + E002 merged? | **Yes** — same person, typo in last name |
| E003 + E004 merged? | **Yes** — same DOB, phone, address |
| E006 vs watchlist? | **Related** possible — same Salem address as Maria Sentosa |

**Write down your entity IDs:**

| Record | Entity ID |
|--------|-----------|
| E001 / E002 | _________ |
| E003 / E004 | _________ |
| E006 | _________ |

**✅ B4 done when:** You can explain why E001/E002 merged using `how` or `why`.

---

<a id="b5-disclosed-relationships-reference-data"></a>
## B5 — Disclosed relationships (REFERENCE data)

**Official:** [How to create disclosed relationships](https://senzing.zendesk.com/hc/en-us/articles/360051209553)

Disclosed relationships are **explicit links** you already know about (ownership, employment at org) — not discovered by ER.

Your truth set `reference.jsonl` already uses them. Example pattern:

```json
{"REL_POINTER_DOMAIN": "REFERENCE", "REL_POINTER_KEY": "2011", "REL_POINTER_ROLE": "Owns 60%"}
```

> Full open/exit guide: [EXPLORER-SESSION.md](./EXPLORER-SESSION.md)

**Step 1 — Mac terminal** (`➜ senzing-demo`):

```bash
cd ~/Dev/Tutorials/senzing-demo
source ./setup-env.sh

docker run --rm -it -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools
```

**Step 2 — Container** (`root@....:/data#`). Type:

```
sz_explorer
```

**Step 3 — Explorer** (`(szeda)`). Type:

```
get REFERENCE 2012
get REFERENCE 2013
get REFERENCE 2014
compare 2013 2014
```

| Record | What it is |
|--------|------------|
| **2012** | Organization "Hajah Maimunah" (`REL_ANCHOR_KEY`: 2011) |
| **2013** | Person Wang Jie — `REL_POINTER_KEY`: **2011**, role "Owns 60%" |
| **2014** | Person Wang Wei — `REL_POINTER_KEY`: **2011**, role "Owns 40%" |

> **`2011` is not a RECORD_ID** — there is no row `RECORD_ID: "2011"` in `reference.jsonl`.  
> `2011` is a **relationship anchor key** that owners point at. Use **2012** for the org record, or `get 2013` / `get 2014` by entity ID from the header after `get`.

**More examples (Universal Exports):**

```
get REFERENCE 2074
get REFERENCE 2091
how 100009
```

**Step 4 — Exit:** `quit` then `exit`

Look at `TOTALS.DISCLOSED_RELATION` in snapshot JSON (**Mac**):

```bash
python3 -c "
import json
d=json.load(open('truthset_snapshot.json'))
print('DISCLOSED_RELATION_COUNT', d['TOTALS']['DISCLOSED_RELATION']['RELATION_COUNT'])
"
```

**Learn:** ER merges records that **are** the same entity. Disclosed relationships link entities you **know** are related (owner ↔ company) without merging them into one person.

**✅ B5 done when:** You can contrast "merged duplicate" vs "disclosed owner relationship."

---

<a id="b6-mapping-mistake-lab-overmatching"></a>
## B6 — Mapping mistake lab (overmatching)

**Official warning:** [Advanced mapping concepts](https://senzing.zendesk.com/hc/en-us/articles/360054097153) — *"The single most common cause of overmatching is when attributes that don't belong to an entity get mapped to it."*

**Wrong mapping (do NOT load this):**

```python
# BAD: treats employer as the person's organization name for matching
record["NAME_ORG"] = row["employer"]
```

**Correct (what we did):**

```python
record["EMPLOYER"] = row["employer"]
```

**Think through:** If Acme Corp has 500 employees all mapped with `NAME_ORG = "Acme Corp"`, Senzing might merge unrelated people.

**Optional exercise:** Edit `learning/map_my_team_csv.py` temporarily to use `NAME_ORG` instead of `EMPLOYER`, reload on a **fresh test source** `MY_TEAM_BAD`, and compare entity counts.

**✅ Phase B complete when:** B1–B6 checked off and MY_TEAM loads with expected merges.

---

<a id="phase-c-operate-the-pipeline-locally-minio-s3"></a>
# Phase C — Operate the pipeline locally (MinIO = S3)

**Goal:** Treat your Mac lab like production — files land in object storage, pipeline picks them up, maps, loads, snapshots.

```text
CSV  →  Parquet  →  MinIO (senzing-incoming)  →  map  →  JSONL  →  sz-file-loader  →  PostgreSQL
                         ↑
                    local S3 (:9000) — same AWS CLI, no AWS account
```

---

<a id="c1-csv-parquet-minio"></a>
## C1 — CSV → Parquet → MinIO

**Why Parquet?** Data lakes export columnar files; your pipeline never loads Parquet directly — always **map first**.

```bash
source ./setup-env.sh && source ./setup-minio-env.sh

# Build Parquet
docker run --rm \
  -e CSV_INPUT="/data/learning/my_team.csv" \
  -e PARQUET_OUTPUT="/data/parquet/my_team.parquet" \
  -v ${PWD}:/data -w /data python:3.12-slim bash -c \
  'pip -q install pandas pyarrow && python learning/csv_to_parquet.py'

# Upload to MinIO (simulates S3 drop)
aws --endpoint-url http://localhost:9000 s3 cp \
  parquet/my_team.parquet \
  s3://senzing-incoming/my_team/my_team.parquet
```

**Verify:** MinIO console http://localhost:9001 → bucket `senzing-incoming` → `my_team/my_team.parquet`

---

<a id="c2-full-pipeline-run"></a>
## C2 — Full pipeline run

```bash
source ./setup-env.sh && source ./setup-minio-env.sh
./pipeline/run_my_team_from_minio.sh
```

**What happens:**

1. CSV → Parquet (if not already)
2. Upload to MinIO
3. Register `MY_TEAM_PQ` data source
4. `run_my_team_pipeline.sh`: sync from MinIO → map → load → snapshot

**Verify mapped file (Mac):**

```bash
head -1 staging/mapped_my_team_pq.jsonl | python3 -m json.tool
```

> Full open/exit guide: [EXPLORER-SESSION.md](./EXPLORER-SESSION.md)

**Step 1 — Mac terminal** (`➜ senzing-demo`):

```bash
cd ~/Dev/Tutorials/senzing-demo
source ./setup-env.sh

docker run --rm -it -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools
```

**Step 2 — Container** (`root@....:/data#`). Type:

```
sz_explorer
```

**Step 3 — Explorer** (`(szeda)`). Type:

```
get MY_TEAM_PQ E001
get MY_TEAM E001                 # Compare with Phase B direct load
quick_look
load truthset_snapshot.json
cross_source_summary             # MY_TEAM_PQ ↔ CUSTOMERS?
```

**Step 4 — Exit:**

```
quit          # leave explorer → container
exit          # leave container → Mac
```


**Learn:** `MY_TEAM` (Phase B) and `MY_TEAM_PQ` (Phase C) are **separate data sources** — same people may appear on two entities unless you designed them to cross-match. That's normal when simulating two ingestion paths.

---

<a id="c3-processed-files-log-idempotent-loads"></a>
## C3 — Processed-files log (idempotent loads)

File: `staging/.processed_files.log`

Each successful pipeline run appends a key like:

```text
MY_TEAM_PQ-my_team.parquet-1719151234
```

**Test idempotency:**

```bash
./pipeline/run_my_team_from_minio.sh
# Second run should print: "Already processed ..."
```

**Force reload** (remove one line):

```bash
grep -v '^MY_TEAM_PQ-' staging/.processed_files.log > staging/.tmp && mv staging/.tmp staging/.processed_files.log
./pipeline/run_my_team_from_minio.sh
```

**Learn:** Production pipelines skip unchanged files to avoid duplicate loads.

---

<a id="c4-simulate-an-updated-file-drop"></a>
## C4 — Simulate an updated file drop

Simulate HR sending a **revised** file (new employee E007):

**Step 1 — Edit CSV** (add row to `learning/my_team.csv`):

```csv
E007,Alice,Johnson,1992-05-20,300 Maple Dr,Austin,TX,78702,512-555-0999,alice@acme.com,Acme Corp,Marketing,2024-06-01,Active
```

**Step 2 — Re-build, re-upload, clear processed log:**

```bash
source ./setup-env.sh && source ./setup-minio-env.sh

docker run --rm \
  -e CSV_INPUT="/data/learning/my_team.csv" \
  -e PARQUET_OUTPUT="/data/parquet/my_team.parquet" \
  -v ${PWD}:/data -w /data python:3.12-slim bash -c \
  'pip -q install pandas pyarrow && python learning/csv_to_parquet.py'

aws --endpoint-url http://localhost:9000 s3 cp \
  parquet/my_team.parquet \
  s3://senzing-incoming/my_team/my_team.parquet

grep -v '^MY_TEAM_PQ-' staging/.processed_files.log > staging/.tmp 2>/dev/null || true
mv staging/.tmp staging/.processed_files.log 2>/dev/null || true

S3_URI=s3://senzing-incoming/my_team/ \
SENZING_DATA_SOURCE=MY_TEAM_PQ \
./pipeline/run_my_team_pipeline.sh
```

**Step 3 — Verify new record in sz_explorer**

See [EXPLORER-SESSION.md](./EXPLORER-SESSION.md) — Mac → `sz_explorer` → `(szeda)`:

```
get MY_TEAM_PQ E007
quick_look
```

Then `quit` and `exit`.

> **Note:** Re-loading the full file may add duplicate records if E001–E006 were already loaded. Real production uses **incremental** files or **purge-by-source** strategies. For learning, that's OK — explore duplicate entities in `entity_size_breakdown`.

---

<a id="c5-schedule-with-cron-mac"></a>
## C5 — Schedule with cron (Mac)

**File:** `pipeline/schedule.example.cron`

```bash
crontab -e
```

Add (edit path to your home directory):

```cron
0 2 * * * cd /Users/nacer/Dev/Tutorials/senzing-demo && source ./setup-env.sh && source ./setup-minio-env.sh && ./pipeline/run_all_from_minio.sh >> staging/cron.log 2>&1
```

**Test without waiting for 2am:**

```bash
cd ~/Dev/Tutorials/senzing-demo
source ./setup-env.sh && source ./setup-minio-env.sh
./pipeline/run_all_from_minio.sh >> staging/cron.log 2>&1
tail -20 staging/cron.log
```

---

<a id="c6-daily-operations-checklist"></a>
## C6 — Daily operations checklist

After any load batch, run this **analyst workflow**:

```bash
# 1. Snapshot (if pipeline didn't) — run on Mac
source ./setup-env.sh
docker run --rm -u $(id -u) -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools \
  sz_snapshot -QAo truthset_snapshot
```

**2. Explore in sz_explorer** — see [EXPLORER-SESSION.md](./EXPLORER-SESSION.md)

**Step 1 — Mac terminal** (`➜ senzing-demo`):

```bash
cd ~/Dev/Tutorials/senzing-demo
source ./setup-env.sh

docker run --rm -it -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools
```

**Step 2 — Container** (`root@....:/data#`). Type:

```
sz_explorer
```

**Step 3 — Explorer** (`(szeda)`). Type:

```
load truthset_snapshot.json
data_source_summary              # new duplicates?
cross_source_summary             # new watchlist hits?
entity_size_breakdown            # over-matching?
quick_look
```

**Step 4 — Exit:**

```
quit          # leave explorer → container
exit          # leave container → Mac
```


**Optional audit** — compare Senzing’s snapshot to a **truth key** (expected entity groupings).

The lab already includes truth keys for the **truth set** (not for `MY_TEAM`). Use these from [EDA-TUTORIAL Part 4](EDA-TUTORIAL.md):

```bash
source ./setup-env.sh

# vs definitive truth (expect ~100% F1)
docker run --rm -u $(id -u) -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools \
  sz_audit -n truthset_snapshot.csv -p actual_truthset_key.csv -o actual_audit

# vs alternate key (expect ~97% F1 — MERGE/SPLIT cases to explore)
docker run --rm -u $(id -u) -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools \
  sz_audit -n truthset_snapshot.csv -p alternate_truthset_key.csv -o truthset_audit
```

**Explore audit in sz_explorer:**

**Step 1 — Mac terminal** (`➜ senzing-demo`):

```bash
cd ~/Dev/Tutorials/senzing-demo
source ./setup-env.sh

docker run --rm -it -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools
```

**Step 2 — Container** (`root@....:/data#`). Type:

```
sz_explorer
```

**Step 3 — Explorer** (`(szeda)`). Type:

```
load truthset_audit.json
audit_summary
```

**Step 4 — Exit:**

```
quit          # leave explorer → container
exit          # leave container → Mac
```


**Truth key format** (`actual_truthset_key.csv`):

```text
CLUSTER_ID,RECORD_ID,DATA_SOURCE
2,1001,CUSTOMERS
2,1002,CUSTOMERS
...
```

Each `CLUSTER_ID` is the entity grouping you **expect**. Senzing’s snapshot is the **newer** result; the key is the **prior** expectation.

> **MY_TEAM / MY_TEAM_PQ:** This repo does not ship a truth key for your employee CSV. For mapping exercises, use `get`, `how`, and `data_source_summary` instead. To audit `MY_TEAM`, you would create e.g. `learning/my_team_truth_key.csv` listing which `RECORD_ID`s should merge (E001+E002 → cluster 1, E003+E004 → cluster 2, etc.).

---

<a id="local-vs-aws-when-you-eventually-get-s3"></a>
## Local vs AWS (when you eventually get S3)

| Today (local) | Production (AWS) |
|---------------|------------------|
| `source ./setup-minio-env.sh` | IAM role + default AWS endpoint |
| `AWS_ENDPOINT_URL=http://localhost:9000` | *(unset — real S3)* |
| `aws s3 cp ... --endpoint-url ...` | `aws s3 cp ...` |
| MinIO console `:9001` | S3 console / EventBridge trigger |
| Same `run_pipeline.sh` steps | Same map → load → snapshot |

**No code changes** to the pipeline logic — only environment variables.

---

<a id="project-file-map-phase-b-c"></a>
## Project file map (Phase B & C)

```text
learning/
├── my_team.csv                  ← your practice CSV
├── map_my_team_csv.py           ← Phase B mapper
├── csv_to_parquet.py            ← CSV → Parquet
└── map_my_team_parquet.py       ← Phase C mapper

pipeline/
├── load_my_team.sh              ← Phase B: direct load
├── run_my_team_from_minio.sh    ← Phase C: full MinIO path
├── run_my_team_pipeline.sh      ← map/load/snapshot for MY_TEAM_PQ
├── run_pipeline.sh              ← generic template
├── run_all_from_minio.sh        ← customers + watchlist batch
└── schedule.example.cron        ← cron template

staging/
├── mapped_my_team.jsonl         ← Phase B output
├── mapped_my_team_pq.jsonl      ← Phase C output
└── .processed_files.log         ← idempotency tracker
```

---

<a id="troubleshooting"></a>
## Troubleshooting

| Problem | Fix |
|---------|-----|
| `addDataSource` fails | `source ./setup-env.sh` |
| `Already processed` | Edit/remove line in `staging/.processed_files.log` |
| MinIO upload fails | `docker compose up -d minio` |
| No MY_TEAM in quick_look | Re-run `./pipeline/load_my_team.sh` |
| Overmatching after bad map | Use `EMPLOYER` not `NAME_ORG` for employer column |
| `cross_source_summary` ERROR | `load truthset_snapshot.json` first |

---

<a id="whats-next-after-phase-b-c"></a>
## What's next after Phase B & C

| Topic | Resource |
|-------|----------|
| Auto-map Parquet columns | [mapper-file](https://github.com/Senzing/mapper-file) |
| ER configuration tuning | Senzing docs: Managing ER configuration (advanced) |
| Reprocessing after config change | Advanced Zendesk articles |
| Your real company CSV | Copy `learning/map_my_team_csv.py` as template |

---

<a id="learning-tracks-summary"></a>
## Learning tracks summary

```text
Track 1 (Analyst)     → Phase B4 + B5 + C6 screening workflow
Track 2 (Pipeline)    → Phase C1–C5 + run_all_from_minio.sh
Track 3 (Your data)   → Replace my_team.csv with your sanitized export
```

---

*Workbook aligned with [Senzing Data Mapping](https://senzing.zendesk.com/hc/en-us/sections/360000385913-Data-Mapping). Local lab — MinIO replaces AWS S3.*
