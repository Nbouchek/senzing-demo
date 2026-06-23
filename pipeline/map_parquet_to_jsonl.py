#!/usr/bin/env python3
"""Map tabular Parquet files to Senzing JSONL for loading."""

import json
import os
import sys
from pathlib import Path

import pandas as pd

INPUT = Path(os.environ.get("PARQUET_INPUT", "/data/incoming/customers/customers.parquet"))
OUTPUT = Path(os.environ.get("JSONL_OUTPUT", "/data/staging/mapped_customers_pq.jsonl"))
DATA_SOURCE = os.environ.get("SENZING_DATA_SOURCE", "CUSTOMERS_PQ")


def map_row(row: pd.Series) -> dict:
    """Map one Parquet row to Senzing flat JSON format."""
    record = {
        "DATA_SOURCE": DATA_SOURCE,
        "RECORD_ID": str(row["record_id"]),
        "RECORD_TYPE": row.get("record_type") or "PERSON",
    }
    if pd.notna(row.get("name_full")):
        record["NAME_FULL"] = row["name_full"]
    if pd.notna(row.get("org_name")):
        record["NAME_ORG"] = row["org_name"]
    if pd.notna(row.get("first_name")):
        record["PRIMARY_NAME_FIRST"] = row["first_name"]
    if pd.notna(row.get("last_name")):
        record["PRIMARY_NAME_LAST"] = row["last_name"]
    if pd.notna(row.get("middle_name")):
        record["PRIMARY_NAME_MIDDLE"] = row["middle_name"]
    if pd.notna(row.get("date_of_birth")):
        record["DATE_OF_BIRTH"] = str(row["date_of_birth"])
    if pd.notna(row.get("address_line1")):
        record["ADDR_TYPE"] = "BUSINESS" if record.get("RECORD_TYPE") == "ORGANIZATION" else "HOME"
        record["ADDR_LINE1"] = row["address_line1"]
        if pd.notna(row.get("address_city")):
            record["ADDR_CITY"] = row["address_city"]
        if pd.notna(row.get("address_state")):
            record["ADDR_STATE"] = row["address_state"]
        if pd.notna(row.get("address_postal")):
            record["ADDR_POSTAL_CODE"] = row["address_postal"]
    if pd.notna(row.get("phone_number")):
        record["PHONE_TYPE"] = "MOBILE"
        record["PHONE_NUMBER"] = row["phone_number"]
    if pd.notna(row.get("email")):
        record["EMAIL_ADDRESS"] = row["email"]
    if pd.notna(row.get("employer")):
        record["EMPLOYER"] = row["employer"]
    if pd.notna(row.get("drivers_license")):
        record["DRLIC_NUMBER"] = row["drivers_license"]
        if pd.notna(row.get("drivers_license_state")):
            record["DRLIC_STATE"] = row["drivers_license_state"]
    if pd.notna(row.get("amount")):
        record["AMOUNT"] = str(row["amount"])
    if pd.notna(row.get("status")):
        record["STATUS"] = row["status"]
    if pd.notna(row.get("txn_date")):
        record["DATE"] = str(row["txn_date"])
    if pd.notna(row.get("category")):
        record["CATEGORY"] = row["category"]
    return record


def main() -> None:
    if not INPUT.exists():
        print(f"ERROR: Parquet file not found: {INPUT}", file=sys.stderr)
        sys.exit(1)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    df = pd.read_parquet(INPUT)
    count = 0
    with OUTPUT.open("w", encoding="utf-8") as handle:
        for _, row in df.iterrows():
            handle.write(json.dumps(map_row(row)) + "\n")
            count += 1
    print(f"Mapped {count} records from {INPUT} -> {OUTPUT} (DATA_SOURCE={DATA_SOURCE})")


if __name__ == "__main__":
    main()
