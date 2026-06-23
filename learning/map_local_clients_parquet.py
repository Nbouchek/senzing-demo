#!/usr/bin/env python3
"""Map local_clients Parquet to Senzing JSONL (Phase C — same mapping, Parquet input)."""

import json
import os
import sys
from pathlib import Path

import pandas as pd

INPUT = Path(
    os.environ.get("PARQUET_INPUT", "/data/incoming/local_clients/local_clients.parquet")
)
OUTPUT = Path(
    os.environ.get("JSONL_OUTPUT", "/data/staging/mapped_local_clients_pq.jsonl")
)
DATA_SOURCE = os.environ.get("SENZING_DATA_SOURCE", "LOCAL_CLIENTS_PQ")


def map_row(row: pd.Series) -> dict:
    """Map Parquet columns to Senzing JSON."""
    return {
        "DATA_SOURCE": DATA_SOURCE,
        "RECORD_ID": str(row["client_id"]),
        "RECORD_TYPE": "PERSON",
        "PRIMARY_NAME_FIRST": row["first_name"],
        "PRIMARY_NAME_LAST": row["last_name"],
        "DATE_OF_BIRTH": str(row["dob"]),
        "ADDR_TYPE": "HOME",
        "ADDR_LINE1": row["addr_line1"],
        "ADDR_CITY": row["city"],
        "ADDR_STATE": row["state"],
        "ADDR_POSTAL_CODE": str(row["postal"]),
        "PHONE_TYPE": "MOBILE",
        "PHONE_NUMBER": row["phone"],
        "EMAIL_ADDRESS": row["email"],
        "EMPLOYER": row["company"],
        "ACCOUNT_TYPE": row["account_type"],
        "SIGNUP_DATE": str(row["signup_date"]),
    }


def main() -> None:
    if not INPUT.exists():
        print(f"ERROR: Parquet not found: {INPUT}", file=sys.stderr)
        sys.exit(1)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    df = pd.read_parquet(INPUT)
    count = 0
    with OUTPUT.open("w", encoding="utf-8") as handle:
        for _, row in df.iterrows():
            handle.write(json.dumps(map_row(row)) + "\n")
            count += 1
    print(f"Mapped {count} records: {INPUT} -> {OUTPUT} (DATA_SOURCE={DATA_SOURCE})")


if __name__ == "__main__":
    main()
