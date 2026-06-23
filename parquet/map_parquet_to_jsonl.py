#!/usr/bin/env python3
"""Map tabular Parquet columns to Senzing JSONL (pipeline tutorial step 3)."""

import json
from pathlib import Path

import pandas as pd

INPUT = Path("/data/parquet/customers.parquet")
OUTPUT = Path("/data/parquet/mapped_customers_pq.jsonl")
DATA_SOURCE = "CUSTOMERS_PQ"


def map_row(row: pd.Series) -> dict:
    """Map one Parquet row to Senzing flat JSON format."""
    record = {
        "DATA_SOURCE": DATA_SOURCE,
        "RECORD_ID": str(row["customer_id"]),
        "RECORD_TYPE": row.get("record_type") or "PERSON",
    }
    if pd.notna(row.get("first_name")):
        record["PRIMARY_NAME_FIRST"] = row["first_name"]
    if pd.notna(row.get("last_name")):
        record["PRIMARY_NAME_LAST"] = row["last_name"]
    if pd.notna(row.get("middle_name")):
        record["PRIMARY_NAME_MIDDLE"] = row["middle_name"]
    if pd.notna(row.get("date_of_birth")):
        record["DATE_OF_BIRTH"] = str(row["date_of_birth"])
    if pd.notna(row.get("address_line1")):
        record["ADDR_TYPE"] = "HOME"
        record["ADDR_LINE1"] = row["address_line1"]
    if pd.notna(row.get("phone_number")):
        record["PHONE_TYPE"] = "MOBILE"
        record["PHONE_NUMBER"] = row["phone_number"]
    if pd.notna(row.get("email")):
        record["EMAIL_ADDRESS"] = row["email"]
    if pd.notna(row.get("amount")):
        record["AMOUNT"] = str(row["amount"])
    if pd.notna(row.get("status")):
        record["STATUS"] = row["status"]
    if pd.notna(row.get("txn_date")):
        record["DATE"] = str(row["txn_date"])
    return record


def main() -> None:
    df = pd.read_parquet(INPUT)
    count = 0
    with OUTPUT.open("w", encoding="utf-8") as handle:
        for _, row in df.iterrows():
            handle.write(json.dumps(map_row(row)) + "\n")
            count += 1
    print(f"Mapped {count} records -> {OUTPUT}")


if __name__ == "__main__":
    main()
