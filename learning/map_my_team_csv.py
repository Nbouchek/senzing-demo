#!/usr/bin/env python3
"""Map my_team.csv to Senzing JSONL (Phase B mapping exercise).

Follows Senzing Generic Entity Specification:
https://senzing.com/docs/entity_specification/
"""

import csv
import json
import os
import sys
from pathlib import Path

INPUT = Path(os.environ.get("CSV_INPUT", "/data/learning/my_team.csv"))
OUTPUT = Path(os.environ.get("JSONL_OUTPUT", "/data/staging/mapped_my_team.jsonl"))
DATA_SOURCE = os.environ.get("SENZING_DATA_SOURCE", "MY_TEAM")


def map_row(row: dict) -> dict:
    """Map one CSV row to Senzing flat JSON."""
    record = {
        "DATA_SOURCE": DATA_SOURCE,
        "RECORD_ID": row["employee_id"],
        "RECORD_TYPE": "PERSON",
        # Resolution attributes — names grouped with PRIMARY label
        "PRIMARY_NAME_FIRST": row["first_name"],
        "PRIMARY_NAME_LAST": row["last_name"],
        "DATE_OF_BIRTH": row["dob"],
        # Address — HOME label via ADDR_TYPE
        "ADDR_TYPE": "HOME",
        "ADDR_LINE1": row["addr_line1"],
        "ADDR_CITY": row["city"],
        "ADDR_STATE": row["state"],
        "ADDR_POSTAL_CODE": row["postal"],
        # Phone — MOBILE label (best practice for personal phones)
        "PHONE_TYPE": "MOBILE",
        "PHONE_NUMBER": row["phone"],
        "EMAIL_ADDRESS": row["email"],
        # Employer is NOT a name — use EMPLOYER, not NAME_ORG on the person
        "EMPLOYER": row["employer"],
        # Payload — useful at match review time, not used for resolution
        "DEPARTMENT": row["department"],
        "HIRE_DATE": row["hire_date"],
        "STATUS": row["status"],
    }
    return record


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
