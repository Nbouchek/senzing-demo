<a id="senzing-core-concepts"></a>
# Senzing Core Concepts

Read this **before** hands-on exercises if you are new to entity resolution or Senzing.

**Stack:** Mac + Docker + PostgreSQL + **MinIO** (local S3). **No AWS account required.**

**Companion workbooks:** [EXPLORER-SESSION.md](./EXPLORER-SESSION.md) · [EXERCISES.md](./EXERCISES.md) · [CHEATSHEET.md](./CHEATSHEET.md) · [EDA-TUTORIAL.md](./EDA-TUTORIAL.md) · [DATA-MAPPING-TUTORIAL.md](./DATA-MAPPING-TUTORIAL.md)

---

## Table of contents

- [1. What problem Senzing solves](#1-what-problem-senzing-solves)
- [2. Record vs entity vs data source](#2-record-vs-entity-vs-data-source)
- [3. Merged vs related vs no match](#3-merged-vs-related-vs-no-match)
- [4. Disclosed relationships (REFERENCE)](#4-disclosed-relationships-reference)
- [5. Resolution attributes vs payload](#5-resolution-attributes-vs-payload)
- [6. Mapping: your CSV to Senzing JSONL](#6-mapping-your-csv-to-senzing-jsonl)
- [7. Data flow in this lab (MinIO = S3)](#7-data-flow-in-this-lab-minio-s3)
- [8. The three EDA tools](#8-the-three-eda-tools)
- [9. Deduplication vs screening](#9-deduplication-vs-screening)
- [10. Explainability: get, how, why, compare](#10-explainability-get-how-why-compare)
- [11. Where you run commands](#11-where-you-run-commands)
- [12. Concept → exercise map](#12-concept-exercise-map)
- [13. Mastery checklist](#13-mastery-checklist)

---

<a id="1-what-problem-senzing-solves"></a>
## 1. What problem Senzing solves

**Entity resolution (ER)** answers: *“Which of these many records refer to the same real-world person or organization?”*

```text
  Input                         Senzing                    Output
┌─────────────────┐         ┌──────────┐         ┌──────────────────┐
│ CUSTOMERS 1070  │         │          │         │ Entity 54        │
│ CUSTOMERS 1069  │  ──────►  │ Resolve  │  ──────►  │  ├─ record 1070  │
│ CUSTOMERS_PQ …  │         │  + match │         │  ├─ record 1069  │
│ WATCHLIST …     │         │          │         │  └─ …            │
└─────────────────┘         └──────────┘         └──────────────────┘
   Many records               One engine              Fewer entities
```

Typical use cases in this lab:

| Use case | Example in lab |
|----------|----------------|
| **Duplicate detection** | Jane Doe appears as `E001` and `E002` in MY_TEAM |
| **Watchlist screening** | CUSTOMERS record relates to WATCHLIST entry |
| **Cross-source matching** | Same customer loaded via JSONL and via MinIO pipeline |
| **Data quality** | Audit finds records that should merge but did not (SPLIT) |

---

<a id="2-record-vs-entity-vs-data-source"></a>
## 2. Record vs entity vs data source

Three terms you will use constantly:

| Term | What it is | Example |
|------|------------|---------|
| **DATA_SOURCE** | Which dataset / system a row came from | `CUSTOMERS`, `LOCAL_CLIENTS_PQ` |
| **RECORD_ID** | One row’s ID inside that source | `1070`, `CL001` |
| **ENTITY_ID** | Senzing’s resolved “real person/org” | `54` (shown when you `get` a record) |

```text
get CUSTOMERS 1070          ← DATA_SOURCE + RECORD_ID
why 17 18                   ← two ENTITY_IDs (numbers from get header)
compare 1 9                   ← ENTITY_IDs (spaces, not commas)
search robert smith           ← free-text search
```

**Important:** One entity can hold **many records** from **many data sources**. That is normal after resolution.

**Lab example:** After loading truth set + pipeline sources, `quick_look` may show both `CUSTOMERS` and `CUSTOMERS_PQ` — same people can appear under two sources until you understand cross-source behavior.

---

<a id="3-merged-vs-related-vs-no-match"></a>
## 3. Merged vs related vs no match

This distinction is **the** core skill for analysts.

| Outcome | Meaning | How you see it in sz_explorer |
|---------|---------|-------------------------------|
| **Merged** | Same real-world person/org | Same entity ID; multiple records in one `get` block |
| **Related** | Possibly connected — review needed | Different entity IDs; link in tree or `why` shows strong NAME, weak/conflicting DOB |
| **No match** | Unrelated | Different entities; low scores in `why` |

```text
Merged   →  CL001 + CL002 (Sarah/Sara Chen)     →  one entity
Related  →  CL007 + CL008 (David & Lisa Kim)    →  same address, different people
Related  →  V003 vendor ↔ watchlist entity      →  screening hit, not merged
No match →  Emily Davis ↔ unrelated customer    →  no meaningful link
```

**Rule of thumb:** Merged = “these **are** the same.” Related = “these **might** matter together — look.”

**Try in lab:**

```
get LOCAL_CLIENTS CL001
get LOCAL_CLIENTS CL002          # same entity ID?
get LOCAL_CLIENTS CL007 detail
get LOCAL_CLIENTS CL008 detail   # related, not merged?
why <id1> <id2>
```

See [EXERCISES.md § Exercise 3](./EXERCISES.md#exercise-3-why-and-how-explainability) and [Exercise 15](./EXERCISES.md#exercise-15-local_clients-map-your-own-fake-data-phase-b-c).

---

<a id="4-disclosed-relationships-reference"></a>
## 4. Disclosed relationships (REFERENCE)

Some relationships are **declared in the data**, not inferred by Senzing.

The truth-set **REFERENCE** source encodes facts like “person A is spouse of person B” or “person C works for org D.” Senzing uses these as **disclosed relationships** — they do not always mean the two records merge into one entity.

```text
Disclosed  →  "We already know these are linked"     (REFERENCE records)
Resolved   →  "Senzing figured out they're the same" (merge into one entity)
Related    →  "Senzing suspects a connection"        (similarity score)
```

**Lab example:** `get REFERENCE 2012`, `2013`, `2014` — note `2011` is a relationship anchor key, **not** a loadable RECORD_ID.

See [EXERCISES.md § Exercise 10](./EXERCISES.md#exercise-10-disclosed-relationships).

---

<a id="5-resolution-attributes-vs-payload"></a>
## 5. Resolution attributes vs payload

When mapping CSV columns to Senzing JSONL:

| Type | Used for matching? | Examples |
|------|-------------------|----------|
| **Resolution attributes** | Yes — drive merge/related decisions | `PRIMARY_NAME_*`, `DATE_OF_BIRTH`, `ADDR_*`, `PHONE_*`, `EMAIL_ADDRESS`, `EMPLOYER` |
| **Payload** | No — stored for review only | `DEPARTMENT`, `HIRE_DATE`, `ACCOUNT_TYPE`, `STATUS` |

**Common mapping mistake:** Putting an employer or org name in `NAME_ORG` on a **person** record causes **overmatching** — unrelated people at the same company merge.

```text
Correct   →  EMPLOYER: "Acme Corp"     on a PERSON record
Wrong     →  NAME_ORG: "Acme Corp"     on a PERSON record (usually)
```

Official reference: [Generic Entity Specification](https://senzing.com/docs/entity_specification/)

See [DATA-MAPPING-TUTORIAL.md § B1–B6](./DATA-MAPPING-TUTORIAL.md#phase-b-map-and-load-your-own-data).

---

<a id="6-mapping-your-csv-to-senzing-jsonl"></a>
## 6. Mapping: your CSV to Senzing JSONL

Senzing loads **JSONL** (one JSON object per line). Your spreadsheet must be **mapped** first.

```text
my_team.csv  ──►  map_my_team_csv.py  ──►  mapped_my_team.jsonl  ──►  sz-file-loader
```

Every mapped record needs at minimum:

| Field | Purpose |
|-------|---------|
| `DATA_SOURCE` | Registered name (e.g. `MY_TEAM`) |
| `RECORD_ID` | Unique ID within that source |
| `RECORD_TYPE` | Usually `PERSON` or `ORGANIZATION` |
| Name / DOB / address / phone / email | Resolution attributes |

**Two paths in this lab:**

| Path | Name | When to use |
|------|------|-------------|
| **Phase B** | Direct CSV → JSONL → load | Learning mapping; quick tests |
| **Phase C** | CSV → Parquet → MinIO → map → load | Simulates production S3 drops |

Same mapper logic — different input format (CSV vs Parquet).

---

<a id="7-data-flow-in-this-lab-minio-s3"></a>
## 7. Data flow in this lab (MinIO = S3)

```text
┌─────────────┐     ┌──────────────┐     ┌────────────┐     ┌─────────────┐
│ JSONL files │────►│ sz-file-     │────►│ PostgreSQL │────►│ sz_explorer │
│ (truth set) │     │ loader       │     │  :5433     │     │  (EDA UI)   │
└─────────────┘     └──────────────┘     └────────────┘     └─────────────┘
                                               ▲
┌─────────────┐     ┌──────────┐     ┌─────────┴──┐
│ MinIO :9000 │────►│ Parquet  │────►│ map → JSONL│
│ (local S3)  │     │ incoming/│     │ staging/   │
└─────────────┘     └──────────┘     └────────────┘
```

| Component | Role | You need AWS? |
|-----------|------|---------------|
| **PostgreSQL** | Senzing’s entity store | No |
| **MinIO** | S3-compatible file drop (`senzing-incoming` bucket) | **No — this replaces S3** |
| **Docker** | Runs Senzing tools consistently | No |
| **AWS CLI** | Talks to MinIO with `--endpoint-url http://localhost:9000` | CLI yes; AWS account **no** |

Senzing **never loads Parquet directly**. Pipeline is always: **Parquet → map → JSONL → load**.

When you eventually use real S3: same scripts, drop `setup-minio-env.sh`, unset `AWS_ENDPOINT_URL`.

---

<a id="8-the-three-eda-tools"></a>
## 8. The three EDA tools

| Tool | Where it runs | Purpose |
|------|---------------|---------|
| **`sz_explorer`** | Interactive (in Docker) | Search, `get`, `how`, `why`, load snapshot/audit reports |
| **`sz_snapshot`** | Mac (batch) | Export entity state → `truthset_snapshot.json` + `.csv` |
| **`sz_audit`** | Mac (batch) | Compare snapshot to truth key → `truthset_audit.json` |

**Workflow pattern:**

```text
1. Load data        →  sz-file-loader or pipeline
2. Explore live     →  sz_explorer (get, search, how, why)
3. Batch reports    →  sz_snapshot on Mac
4. Load reports     →  sz_explorer: load truthset_snapshot.json
5. Screening        →  cross_source_summary, data_source_summary
6. Accuracy check   →  sz_audit, then load truthset_audit.json
```

See [EDA-TUTORIAL.md](./EDA-TUTORIAL.md) for the full official series mapped to this lab.

---

<a id="9-deduplication-vs-screening"></a>
## 9. Deduplication vs screening

| Question | Report / command | Sources involved |
|----------|------------------|------------------|
| “Who are duplicates **within** one file?” | `data_source_summary` (after `load` snapshot) | One DATA_SOURCE |
| “Who in list A matches list B?” | `cross_source_summary` | Two+ DATA_SOURCEs (e.g. CUSTOMERS ↔ WATCHLIST) |
| “How big are merged entities?” | `entity_size_breakdown` | All loaded data |

**Lab examples:**

- **Dedup:** `E001` + `E002` in MY_TEAM → same entity
- **Screening:** CUSTOMERS person relates to WATCHLIST name (Exercise 7 vendors)
- **Cross-source:** `LOCAL_CLIENTS` CL006 may relate to CUSTOMERS Robert Smith (same address)

Always run `load truthset_snapshot.json` **before** report commands in explorer.

See [EXERCISES.md § Exercise 4](./EXERCISES.md#exercise-4-snapshot-and-cross-source-screening).

---

<a id="10-explainability-get-how-why-compare"></a>
## 10. Explainability: get, how, why, compare

| Command | Question it answers |
|---------|---------------------|
| **`get DS RECID`** | What does Senzing know about this record? What entity is it in? |
| **`get DS RECID detail`** | Full feature tree — names, addresses, related entities |
| **`how ENTITY_ID`** | How did records **merge into** this entity? (decision tree) |
| **`why ID1 ID2`** | Why did these two entities **not merge** (or how strong is the link)? |
| **`compare ID1 ID2`** | Side-by-side attribute comparison |
| **`search name`** | Find candidate entities |

**`how` example (entity 54 — Jie Wang):** Shows step-by-step virtual entities built on NAME+DOB+ADDRESS, including cross-script names (Latin vs CJK) and REFERENCE disclosed links.

**Color hints in `why`:** Green = strong agreement; red = conflict (often DOB or address) → likely **related**, not merged.

See [EXERCISES.md § Exercise 3](./EXERCISES.md#exercise-3-why-and-how-explainability).

---

<a id="11-where-you-run-commands"></a>
## 11. Where you run commands

| Place | Prompt | Examples |
|-------|--------|----------|
| **Mac terminal** | `➜ senzing-demo` | `docker compose`, `source ./setup-env.sh`, `./pipeline/*.sh`, `aws --endpoint-url …` |
| **Container shell** | `root@…:/data#` | Start `sz_explorer`, `sz_configtool` |
| **sz_explorer** | `(szeda)` | `get`, `search`, `load`, `cross_source_summary` |

**Every session (Mac):**

```bash
cd ~/Dev/Tutorials/senzing-demo
docker compose up -d
source ./setup-env.sh
source ./setup-minio-env.sh   # pipeline / MinIO days only
```

**Open explorer:** [EXPLORER-SESSION.md](./EXPLORER-SESSION.md)

**Common mistake:** Typing `get` or `quit` at the Mac prompt → `bash: get: command not found`. You must be at `(szeda)`.

---

<a id="12-concept-exercise-map"></a>
## 12. Concept → exercise map

| Concept | Read here | Practice |
|---------|-----------|----------|
| Setup & load truth set | § 7 | [EXERCISES § 0–1](./EXERCISES.md#exercise-0-first-time-setup-once-only) |
| Record vs entity | § 2 | [EXERCISES § 1](./EXERCISES.md#exercise-1-meet-your-data-quick_look-get) |
| Search & compare | § 10 | [EXERCISES § 2](./EXERCISES.md#exercise-2-search-and-compare) |
| how / why | § 10 | [EXERCISES § 3](./EXERCISES.md#exercise-3-why-and-how-explainability) |
| Snapshot & screening | § 8–9 | [EXERCISES § 4](./EXERCISES.md#exercise-4-snapshot-and-cross-source-screening) |
| Audit MERGE/SPLIT | § 3 | [EXERCISES § 5](./EXERCISES.md#exercise-5-audit-accuracy) |
| MinIO pipeline | § 7 | [EXERCISES § 6–8](./EXERCISES.md#exercise-6-full-minio-pipeline-local-s3) |
| Mapping CSV | § 5–6 | [DATA-MAPPING Phase B](./DATA-MAPPING-TUTORIAL.md#phase-b-map-and-load-your-own-data) |
| Pipeline ops | § 7 | [DATA-MAPPING Phase C](./DATA-MAPPING-TUTORIAL.md#phase-c-operate-the-pipeline-locally-minio-s3) |
| Your own data | § 3, 6 | [EXERCISES § 15](./EXERCISES.md#exercise-15-local_clients-map-your-own-fake-data-phase-b-c) |
| Disclosed relationships | § 4 | [EXERCISES § 10](./EXERCISES.md#exercise-10-disclosed-relationships) |

**Suggested order:** CORE-CONCEPTS (this file) → EXERCISES 0–8 → EDA-TUTORIAL → DATA-MAPPING → EXERCISES 9–15.

---

<a id="13-mastery-checklist"></a>
## 13. Mastery checklist

Check off when you can explain each **without looking at notes**:

| # | I can… | Lab proof |
|---|--------|-----------|
| 1 | Define record, entity, data source | `get CUSTOMERS 1070` — point to RECORD_ID vs entity header |
| 2 | Explain merged vs related with examples | LOCAL_CLIENTS CL001/CL002 vs CL007/CL008 |
| 3 | Open and exit sz_explorer correctly | [EXPLORER-SESSION.md](./EXPLORER-SESSION.md) — no `bash: get` errors |
| 4 | Run snapshot and screening reports | `load truthset_snapshot.json` → `cross_source_summary` |
| 5 | Read a `how` tree in plain English | Entity 54 (Jie Wang) or MY_TEAM duplicate |
| 6 | Map a CSV and load it | `./pipeline/load_local_clients.sh` |
| 7 | Run MinIO pipeline end-to-end | `./pipeline/run_local_clients_from_minio.sh` |
| 8 | Clear processed log and reload one source | Edit `staging/.processed_files.log` |
| 9 | Explain why MinIO replaces S3 in this lab | Same `run_*_pipeline.sh`; only env vars change |
| 10 | Name resolution vs payload fields | EMPLOYER vs DEPARTMENT on MY_TEAM mapper |

When all ten are checked, move to building **your own** CSV + mapper (copy `learning/map_local_clients_csv.py`).

---

*MinIO on `:9000` is your S3. No AWS account required for mastery in this lab.*
