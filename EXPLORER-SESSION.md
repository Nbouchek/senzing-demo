# How to open sz_explorer (copy every time)

Use this whenever a tutorial says **“explore in sz_explorer”**, **“verify in Senzing”**, or **“load audit results”**.

---

## The three prompts (know where you are)

| Step | Prompt looks like | You type |
|------|-------------------|----------|
| **1. Mac** | `➜ senzing-demo` | `docker run ...` (below) |
| **2. Container** | `root@abc123:/data#` | `sz_explorer` |
| **3. Explorer** | `(szeda)` | `get`, `search`, `load`, … |

> Commands like `get CUSTOMERS 1070` go at **`(szeda)`**, not in the Mac terminal.  
> If you see `bash: get: command not found`, you forgot step B or C.

---

## Step 1 — Mac terminal

```bash
cd ~/Dev/Tutorials/senzing-demo
source ./setup-env.sh

docker run --rm -it \
  -v ${PWD}:/data -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/senzingsdk-tools
```

Wait until the prompt is `root@....:/data#`.

---

## Step 2 — Start explorer (inside container)

```
sz_explorer
```

Wait until the prompt is `(szeda)`.

Type `help` anytime for command list.

---

## Step 3 — Example explorer commands

**Live data (no file load needed):**

```
quick_look
get CUSTOMERS 1070
search robert smith
compare search
how 54
why 17 18
```

**After `sz_snapshot` or `sz_audit` on Mac — reports from JSON files:**

```
load truthset_snapshot.json
cross_source_summary
data_source_summary
entity_size_breakdown
```

```
load truthset_audit.json
audit_summary
```

Use **↑ ↓** and **Enter** to drill into report rows. **Q** to go back.

---

## Step 4 — Exit (in order)

```
quit          # (szeda) → container (root@...:/data#)
exit          # container → Mac (➜ senzing-demo)
```

Do **not** type `quit` at the container `#` prompt — that gives `bash: quit: command not found`.

---

## Quick troubleshooting

| Problem | Fix |
|---------|-----|
| `SENZING_ENGINE_CONFIGURATION_JSON` errors | On Mac: `source ./setup-env.sh` before `docker run` |
| `bash: get: command not found` | Run `sz_explorer` first; use `(szeda)` prompt |
| `bash: quit: command not found` | You already left explorer — use `exit` |
| `cross_source_summary` ERROR | Run `load truthset_snapshot.json` first |
| `Unknown record` | Use `DATA_SOURCE` + `RECORD_ID`, e.g. `get CUSTOMERS 1070` |

---

**Back to:** [README.md](./README.md) · [CHEATSHEET.md](./CHEATSHEET.md) · [EXERCISES.md](./EXERCISES.md)
