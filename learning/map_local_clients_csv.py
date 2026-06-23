#!/usr/bin/env python3
"""Map local_clients.csv to Senzing JSONL (your own-data mapping exercise).

Expected resolution after load (use sz_explorer to verify):
  CL001 + CL002  -> same entity (Sarah/Sara Chen typo)
  CL003 + CL004  -> same entity (Michael Brown, two emails)
  CL005          -> single entity
  CL006          -> may relate to CUSTOMERS (Robert Smith, same address/DOB)
  CL007 + CL008  -> related, not merged (couple at same address)
  CL009 + CL010  -> same entity (Pat Taylor, St vs Road)
"""

import csv
import json
import os
import sys
from pathlib import Path

INPUT = Path(os.environ.get("CSV_INPUT", "/data/learning/local_clients.csv"))
OUTPUT = Path(os.environ.get("JSONL_OUTPUT", "/data/staging/mapped_local_clients.jsonl"))
DATA_SOURCE = os.environ.get("SENZING_DATA_SOURCE", "LOCAL_CLIENTS")


def map_row(row: dict) -> dict:
    """Map one CSV row to Senzing flat JSON."""
    return {
        "DATA_SOURCE": DATA_SOURCE,
        "RECORD_ID": row["client_id"],
        "RECORD_TYPE": "PERSON",
        "PRIMARY_NAME_FIRST": row["first_name"],
        "PRIMARY_NAME_LAST": row["last_name"],
        "DATE_OF_BIRTH": row["dob"],
        "ADDR_TYPE": "HOME",
        "ADDR_LINE1": row["addr_line1"],
        "ADDR_CITY": row["city"],
        "ADDR_STATE": row["state"],
        "ADDR_POSTAL_CODE": row["postal"],
        "PHONE_TYPE": "MOBILE",
        "PHONE_NUMBER": row["phone"],
        "EMAIL_ADDRESS": row["email"],
        "EMPLOYER": row["company"],
        "ACCOUNT_TYPE": row["account_type"],
        "SIGNUP_DATE": row["signup_date"],
    }


def main() -> None:
    if not INPUT.exists():
        print(f"ERROR: CSV not found: {INPUT}", file=sys.stderr)
        sys.exit(1)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    with INPUT.open(encoding="utf-8") as handle, OUTPUT.open("w", encoding="utf-8") as out:
        for row in csv.DictReader(handle):
            out.write(json.dumps(map_row(row)) + "\n")
            count += 1
    print(f"Mapped {count} records: {INPUT} -> {OUTPUT} (DATA_SOURCE={DATA_SOURCE})")


if __name__ == "__main__":
    main()
