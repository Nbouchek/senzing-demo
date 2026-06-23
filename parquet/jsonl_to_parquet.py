#!/usr/bin/env python3
"""Convert Senzing-style JSONL into tabular Parquet (simulates a data lake export)."""

import json
import os
from pathlib import Path

import pandas as pd

INPUT = Path(os.environ.get("JSONL_INPUT", "/data/customers.jsonl"))
OUTPUT = Path(os.environ.get("PARQUET_OUTPUT", "/data/parquet/customers.parquet"))


def flatten_record(record: dict) -> dict:
    """Flatten nested FEATURES into columns."""
    row = {
        "record_id": record["RECORD_ID"],
        "amount": record.get("AMOUNT"),
        "status": record.get("STATUS"),
        "txn_date": record.get("DATE"),
        "category": record.get("CATEGORY"),
    }
    for feature in record.get("FEATURES", []):
        if "RECORD_TYPE" in feature:
            row["record_type"] = feature["RECORD_TYPE"]
        if "NAME_FULL" in feature:
            row["name_full"] = feature["NAME_FULL"]
        if "NAME_ORG" in feature:
            row["org_name"] = feature["NAME_ORG"]
        if "NAME_FIRST" in feature:
            row["first_name"] = feature.get("NAME_FIRST")
            row["last_name"] = feature.get("NAME_LAST")
            row["middle_name"] = feature.get("NAME_MIDDLE")
        if "DATE_OF_BIRTH" in feature:
            row["date_of_birth"] = feature["DATE_OF_BIRTH"]
        if "ADDR_LINE1" in feature:
            row["address_line1"] = feature["ADDR_LINE1"]
            row["address_city"] = feature.get("ADDR_CITY")
            row["address_state"] = feature.get("ADDR_STATE")
            row["address_postal"] = feature.get("ADDR_POSTAL_CODE")
        if "PHONE_NUMBER" in feature:
            row["phone_number"] = feature["PHONE_NUMBER"]
        if "EMAIL_ADDRESS" in feature:
            row["email"] = feature["EMAIL_ADDRESS"]
        if "EMPLOYER" in feature:
            row["employer"] = feature["EMPLOYER"]
        if "DRIVERS_LICENSE_NUMBER" in feature:
            row["drivers_license"] = feature["DRIVERS_LICENSE_NUMBER"]
            row["drivers_license_state"] = feature.get("DRIVERS_LICENSE_STATE")
    return row


def main() -> None:
    rows = []
    with INPUT.open(encoding="utf-8") as handle:
        for line in handle:
            rows.append(flatten_record(json.loads(line)))

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    df = pd.DataFrame(rows)
    df.to_parquet(OUTPUT, index=False)
    print(f"Wrote {len(df)} rows to {OUTPUT}")


if __name__ == "__main__":
    main()
