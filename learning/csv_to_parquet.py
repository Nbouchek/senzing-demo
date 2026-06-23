#!/usr/bin/env python3
"""Convert a flat CSV to Parquet (simulates a data-lake export for Phase C)."""

import os
import sys
from pathlib import Path

import pandas as pd

INPUT = Path(os.environ.get("CSV_INPUT", "/data/learning/my_team.csv"))
OUTPUT = Path(os.environ.get("PARQUET_OUTPUT", "/data/parquet/my_team.parquet"))


def main() -> None:
    if not INPUT.exists():
        print(f"ERROR: CSV not found: {INPUT}", file=sys.stderr)
        sys.exit(1)

    df = pd.read_csv(INPUT)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(OUTPUT, index=False)
    print(f"Wrote {len(df)} rows to {OUTPUT}")


if __name__ == "__main__":
    main()
