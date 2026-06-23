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
# then: sz_explorer → quick_look → search robert smith
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
| [**CHEATSHEET.md**](CHEATSHEET.md) | Quick reference — commands, errors, workflows |
| [**EDA-TUTORIAL.md**](EDA-TUTORIAL.md) | Official [Senzing EDA](https://senzing.zendesk.com/hc/en-us/sections/360009388534-Exploratory-Data-Analysis-EDA) series |
| [**EXERCISES.md**](EXERCISES.md) | Hands-on exercises 0–14 with checklists |
| [**DATA-MAPPING-TUTORIAL.md**](DATA-MAPPING-TUTORIAL.md) | [Data mapping](https://senzing.zendesk.com/hc/en-us/sections/360000385913-Data-Mapping) + pipeline ops |

**Suggested path**

1. EDA-TUTORIAL (Parts 0–6) — explore, snapshot, audit  
2. EXERCISES 0–8 — truth set, MinIO pipeline, vendors  
3. DATA-MAPPING-TUTORIAL (Phase B & C) — map `my_team.csv`, operate pipeline  
4. CHEATSHEET — bookmark for daily use  

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

```bash
docker run --rm -it -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools
```

Inside explorer: `get CUSTOMERS 1070`, `search robert smith`, `load truthset_snapshot.json`, `cross_source_summary`.

---

## Project layout

```text
senzing-demo/
├── README.md                    ← you are here
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
├── learning/                    ← my_team.csv mapping exercises
├── pipeline/                    ← run_pipeline.sh, MinIO scripts
├── parquet/                     ← sample Parquet files
├── incoming/                    ← Parquet downloaded from MinIO
└── staging/                     ← mapped JSONL + .processed_files.log
```

---

## Data sources in this lab

| Source | Description |
|--------|-------------|
| `CUSTOMERS`, `REFERENCE`, `WATCHLIST` | Original truth-set JSONL |
| `CUSTOMERS_PQ`, `WATCHLIST_PQ` | Same data via Parquet/MinIO pipeline |
| `VENDORS_PQ` | Vendor merge + watchlist screening exercise |
| `MY_TEAM`, `MY_TEAM_PQ` | Your mapped employee CSV exercise |

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
