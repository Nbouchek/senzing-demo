# Senzing Local Learning Lab

Hands-on **entity resolution** lab for Mac (Apple Silicon or Intel) using **Docker**, **PostgreSQL**, and **MinIO** as a local S3 stand-in. **No AWS account required.**

Load Senzing truth-set data, explore matches with EDA tools, map your own CSV, and run a **Parquet → MinIO → Senzing** pipeline — the same pattern used in production, without cloud costs.

---

## What you will learn

- Entity resolution basics (records vs entities, merged vs related)
- **EDA tools:** `sz_explorer`, `sz_snapshot`, `sz_audit`
- Data mapping (CSV/Parquet → Senzing JSONL)
- Watchlist screening and duplicate detection
- Local pipeline operations (idempotent loads, simulated S3 drops)

---

## Prerequisites

| Tool | Purpose |
|------|---------|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | PostgreSQL, MinIO, Senzing SDK containers |
| [AWS CLI](https://aws.amazon.com/cli/) | Talk to **MinIO** only (`brew install awscli`) |
| Senzing Docker images | Pulled automatically on first run |

**Senzing license:** Uses official Senzing SDK container images. Ensure your environment meets [Senzing's licensing requirements](https://senzing.com/) for your use case.

---

## Quick start

```bash
git clone https://github.com/Nbouchek/senzing-demo.git
cd senzing-demo

# 1. Start infrastructure
docker compose up -d
source ./setup-env.sh

# 2. Initialize Senzing (first time only)
docker run --rm \
  --env SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/init-database \
  --install-senzing-er-configuration

# 3. Register sources and load truth set
printf 'addDataSource CUSTOMERS\naddDataSource REFERENCE\naddDataSource WATCHLIST\nsave\ny\nquit\n' | \
  docker run --rm -i -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/senzingsdk-tools sz_configtool

for f in customers reference watchlist; do
  docker run --rm -u $(id -u) -v ${PWD}:/data \
    -e SENZING_ENGINE_CONFIGURATION_JSON \
    senzing/sz-file-loader -f /data/${f}.jsonl
done

# 4. Explore
docker run --rm -it -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools
# 4. Explore — see EXPLORER-SESSION.md: docker run ... → sz_explorer → quick_look → search robert smith
```

**Every session after that:**

```bash
cd senzing-demo
docker compose up -d
source ./setup-env.sh
source ./setup-minio-env.sh   # needed for MinIO pipeline exercises
```

> Always use `source ./setup-env.sh` — not `./setup-env.sh` alone.

---

## Architecture

```text
JSONL truth set ──► sz-file-loader ──► PostgreSQL (:5433) ──► sz_explorer
                                              ▲
MinIO (:9000) ──► Parquet ──► map ──► JSONL ──┘
     │
     └── S3-compatible bucket: senzing-incoming
```

| Service | URL | Credentials |
|---------|-----|-------------|
| PostgreSQL | `localhost:5433` | `senzing` / `senzing` / db `G2` |
| MinIO S3 API | http://localhost:9000 | via `setup-minio-env.sh` |
| MinIO Console | http://localhost:9001 | `minioadmin` / `minioadmin` |

Senzing does **not** load Parquet directly. The pipeline always: **Parquet → map → JSONL → load**.

---

## Learning guides (read in order)

| Guide | Topics |
|-------|--------|
| [**EXPLORER-SESSION.md**](EXPLORER-SESSION.md) | **Start here for sz_explorer** — open, use, exit |
| [**CHEATSHEET.md**](CHEATSHEET.md) | Quick reference — commands, errors, workflows |
| [**EDA-TUTORIAL.md**](EDA-TUTORIAL.md) | Official [Senzing EDA](https://senzing.zendesk.com/hc/en-us/sections/360009388534-Exploratory-Data-Analysis-EDA) series |
| [**EXERCISES.md**](EXERCISES.md) | Hands-on exercises 0–15 with checklists |
| [**DATA-MAPPING-TUTORIAL.md**](DATA-MAPPING-TUTORIAL.md) | [Data mapping](https://senzing.zendesk.com/hc/en-us/sections/360000385913-Data-Mapping) + pipeline ops + LOCAL_CLIENTS capstone |

**Suggested path**

1. EDA-TUTORIAL (Parts 0–6) — explore, snapshot, audit  
2. EXERCISES 0–8 — truth set, MinIO pipeline, vendors  
3. DATA-MAPPING-TUTORIAL (Phase B & C) — map `my_team.csv`, operate pipeline  
4. EXERCISE 15 / Phase D — map `local_clients.csv` (your-data capstone)  
5. CHEATSHEET — bookmark for daily use  

---

## Common commands

### MinIO pipeline (local S3)

```bash
source ./setup-env.sh && source ./setup-minio-env.sh
./pipeline/setup_minio.sh              # first time: create bucket + upload Parquet
./pipeline/run_all_from_minio.sh       # load CUSTOMERS_PQ + WATCHLIST_PQ
./pipeline/learn_local_exercise.sh     # vendors exercise
./pipeline/load_my_team.sh             # Phase B: CSV → Senzing
./pipeline/run_my_team_from_minio.sh   # Phase C: CSV → MinIO → Senzing
./pipeline/load_local_clients.sh       # Phase B: capstone fake client CSV
./pipeline/run_local_clients_from_minio.sh  # Phase C: local_clients via MinIO
```

### Snapshot & audit

```bash
source ./setup-env.sh

docker run --rm -u $(id -u) -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools \
  sz_snapshot -QAo truthset_snapshot

docker run --rm -u $(id -u) -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools \
  sz_audit -n truthset_snapshot.csv -p alternate_truthset_key.csv -o truthset_audit
```

### Enter `sz_explorer`

See **[EXPLORER-SESSION.md](./EXPLORER-SESSION.md)** for the full step-by-step (Mac → container → `(szeda)` → exit).

```bash
source ./setup-env.sh
docker run --rm -it -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools
# at root@...:/data#  →  sz_explorer
# at (szeda)  →  get CUSTOMERS 1070, search robert smith, load truthset_snapshot.json, ...
# quit  →  exit
```

---

## Project layout

```text
senzing-demo/
├── README.md                    ← you are here
├── EXPLORER-SESSION.md          ← how to open sz_explorer (read this first)
├── CHEATSHEET.md                ← command reference
├── EDA-TUTORIAL.md              ← EDA workbook
├── EXERCISES.md                 ← step-by-step exercises
├── DATA-MAPPING-TUTORIAL.md     ← mapping + pipeline workbook
├── docker-compose.yml           ← PostgreSQL + MinIO
├── setup-env.sh                 ← Senzing DB connection
├── setup-minio-env.sh           ← MinIO / local S3 env
├── customers.jsonl              ┐
├── reference.jsonl              ├─ Senzing truth set
├── watchlist.jsonl              ┘
├── learning/                    ← my_team.csv + local_clients.csv exercises
├── pipeline/                    ← run_pipeline.sh, MinIO scripts
├── parquet/                     ← Parquet build scripts (*.parquet is generated)
├── incoming/                    ← Parquet downloaded from MinIO (gitignored)
└── staging/                     ← mapped JSONL + logs (gitignored)
```

---

## Generated files (not in git)

Pipeline and EDA commands write local artifacts. These are **gitignored** so runs do not dirty the repo:

| Path | Created by |
|------|------------|
| `staging/mapped_*.jsonl` | `run_pipeline.sh`, load scripts |
| `staging/.processed_files.log` | Pipeline idempotency tracker |
| `staging/cron*.log` | Scheduled or manual pipeline runs |
| `incoming/**/*.parquet` | MinIO sync or local Parquet build |
| `parquet/*.parquet` | `setup_minio.sh`, `csv_to_parquet.py` |
| `truthset_snapshot.*` | `sz_snapshot` |
| `truthset_audit.*`, `actual_audit.*` | `sz_audit` |
| `*_export.jsonl`, `snapshots.json` | `sz_explorer` exports |

Fresh clone: run the [Quick start](#quick-start) (or `./pipeline/setup_minio.sh` for MinIO exercises). Directories exist via `.gitkeep`; files appear on first run.

To force a reload after a pipeline run: remove the matching line from `staging/.processed_files.log`, or delete the file entirely.

---

## Data sources in this lab

| Source | Description |
|--------|-------------|
| `CUSTOMERS`, `REFERENCE`, `WATCHLIST` | Original truth-set JSONL |
| `CUSTOMERS_PQ`, `WATCHLIST_PQ` | Same data via Parquet/MinIO pipeline |
| `VENDORS_PQ` | Vendor merge + watchlist screening exercise |
| `MY_TEAM`, `MY_TEAM_PQ` | Mapped employee CSV exercise (Phase B/C tutorial) |
| `LOCAL_CLIENTS`, `LOCAL_CLIENTS_PQ` | Fake client contacts — your-data capstone (Exercise 15) |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Env var errors | `source ./setup-env.sh` |
| `cross_source_summary` fails | Run `load truthset_snapshot.json` first in explorer |
| `Already processed` | Remove line from `staging/.processed_files.log` |
| `init-database` fails on re-run | Normal if DB exists — do **not** re-run on loaded DB |
| Re-run `--install-senzing-er-configuration` | Only on **empty** DB; use `docker compose down -v` for fresh start |

See [CHEATSHEET.md § Common errors](CHEATSHEET.md#10-common-errors-fixes) for more.

---

## Fresh start (wipe all data)

```bash
docker compose down -v
docker compose up -d
source ./setup-env.sh
# Re-run Quick start steps 2–3
```

---

## Official Senzing docs

- [Entity Specification](https://senzing.com/docs/entity_specification/)
- [Exploratory Data Analysis (EDA)](https://senzing.zendesk.com/hc/en-us/sections/360009388534-Exploratory-Data-Analysis-EDA)
- [Data Mapping](https://senzing.zendesk.com/hc/en-us/sections/360000385913-Data-Mapping)

---

## License & data

Demo truth-set data and tutorials are for **learning purposes**. Senzing SDK usage is subject to [Senzing licensing terms](https://senzing.com/). Do not commit secrets (`.env` files are gitignored).
