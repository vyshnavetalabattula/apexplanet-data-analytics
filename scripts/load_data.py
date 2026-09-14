"""
ApexPlanet Data Analytics Internship - Task 2
load_data.py

Loads the cleaned Amazon Sale Report CSV into a local SQLite database
(data/db/amazon_sales.db), creates a small `state_region` lookup table
(used later to demonstrate JOINs), and adds indexes on the columns most
queries filter/group by.

Run once from the scripts/ folder:
    python load_data.py
"""

import os
import sys

import pandas as pd
from sqlalchemy import text

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from db_utils import get_engine, execute  # noqa: E402

CSV_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "data", "processed", "amazon_sale_report_cleaned.csv",
)

# Normalized-state -> region lookup, used to demonstrate JOIN in queries.sql.
# Keys are UPPER/TRIM-normalized so they match messy state values like
# "Punjab", "PUNJAB", "punjab" via UPPER(TRIM(ship_state)).
STATE_REGION_MAP = {
    "DELHI": "North", "NEW DELHI": "North", "PUNJAB": "North", "PB": "North",
    "HARYANA": "North", "HIMACHAL PRADESH": "North", "JAMMU & KASHMIR": "North",
    "LADAKH": "North", "CHANDIGARH": "North", "UTTAR PRADESH": "North",
    "UTTARAKHAND": "North", "RAJASTHAN": "North", "RJ": "North",
    "RAJSTHAN": "North", "RAJSHTHAN": "North",

    "MAHARASHTRA": "West", "GUJARAT": "West", "GOA": "West",
    "DADRA AND NAGAR": "West", "MADHYA PRADESH": "West",

    "KARNATAKA": "South", "TAMIL NADU": "South", "KERALA": "South",
    "ANDHRA PRADESH": "South", "TELANGANA": "South", "PUDUCHERRY": "South",
    "PONDICHERRY": "South", "LAKSHADWEEP": "South",

    "WEST BENGAL": "East", "BIHAR": "East", "JHARKHAND": "East",
    "ODISHA": "East", "ORISSA": "East", "CHHATTISGARH": "East",
    "SIKKIM": "East",

    "ASSAM": "Northeast", "ARUNACHAL PRADESH": "Northeast", "MANIPUR": "Northeast",
    "MEGHALAYA": "Northeast", "MIZORAM": "Northeast", "NAGALAND": "Northeast",
    "NL": "Northeast", "TRIPURA": "Northeast",

    "ANDAMAN & NICOBAR": "Islands/Other", "APO": "Islands/Other",
    "AR": "Islands/Other", "PUNJAB/MOHALI/ZIRAKPUR": "North",
}


def load_sales_table(engine):
    print(f"Reading {CSV_PATH} ...")
    df = pd.read_csv(CSV_PATH, low_memory=False)
    df["date"] = pd.to_datetime(df["date"])
    print(f"Loaded {len(df):,} rows, {len(df.columns)} columns into memory.")

    df.to_sql("sales", engine, if_exists="replace", index=False, chunksize=5000)
    print("Wrote 'sales' table to SQLite.")


def load_region_lookup(engine):
    region_df = pd.DataFrame(
        [{"state_norm": k, "region": v} for k, v in STATE_REGION_MAP.items()]
    )
    region_df.to_sql("state_region", engine, if_exists="replace", index=False)
    print(f"Wrote 'state_region' lookup table ({len(region_df)} states).")


def create_indexes(engine):
    statements = [
        "CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(date)",
        "CREATE INDEX IF NOT EXISTS idx_sales_status ON sales(status)",
        "CREATE INDEX IF NOT EXISTS idx_sales_category ON sales(category)",
        "CREATE INDEX IF NOT EXISTS idx_sales_state ON sales(ship_state)",
        "CREATE INDEX IF NOT EXISTS idx_sales_order_month ON sales(order_month)",
    ]
    for stmt in statements:
        execute(stmt)
        print(f"  {stmt}")


def main():
    engine = get_engine()
    load_sales_table(engine)
    load_region_lookup(engine)
    print("Creating indexes...")
    create_indexes(engine)

    with engine.connect() as conn:
        count = conn.execute(text("SELECT COUNT(*) FROM sales")).scalar()
    print(f"\nDone. 'sales' table has {count:,} rows in {engine.url}")


if __name__ == "__main__":
    main()
