"""
ApexPlanet Data Analytics Internship - Task 1
Data Cleaning & Preprocessing script for the Amazon Sale Report dataset.
"""
import pandas as pd
import numpy as np

RAW_PATH = "../data/raw/Amazon_Sale_Report.csv"
PROCESSED_PATH = "../data/processed/amazon_sale_report_cleaned.csv"

cleaning_log = []


def log(msg):
    print(msg)
    cleaning_log.append(msg)


def load_data(path):
    df = pd.read_csv(path, low_memory=False)
    log(f"Loaded raw data: {df.shape[0]:,} rows x {df.shape[1]} columns")
    return df


def clean(df):
    df = df.copy()

    # 1. Standardize column names -----------------------------------------
    df.columns = (
        df.columns.str.strip()
        .str.lower()
        .str.replace(" ", "_")
        .str.replace("-", "_")
    )
    log("Standardized column names to snake_case and stripped whitespace")

    # 2. Drop fully/near-fully empty or redundant columns -------------------
    drop_cols = [c for c in ["unnamed:_22"] if c in df.columns]
    if drop_cols:
        df = df.drop(columns=drop_cols)
        log(f"Dropped empty/junk columns: {drop_cols}")

    # currency / ship_country are constant (single value + NaN) -> not
    # informative for analysis, but we keep them and just note it.
    log("Note: 'currency' (INR) and 'ship_country' (IN) are constant fields")

    # 3. Remove exact duplicate rows -----------------------------------------
    before = len(df)
    df = df.drop_duplicates()
    log(f"Removed {before - len(df):,} duplicate rows (found {before-len(df):,})")

    # 4. Fix data types -------------------------------------------------------
    df["date"] = pd.to_datetime(df["date"], format="%m-%d-%y", errors="coerce")
    log("Converted 'date' column to datetime")

    for col in ["status", "fulfilment", "sales_channel", "ship_service_level",
                "category", "size", "courier_status", "currency",
                "ship_state", "ship_country", "fulfilled_by"]:
        if col in df.columns:
            df[col] = df[col].astype("category")
    log("Converted categorical text columns to 'category' dtype")

    df["b2b"] = df["b2b"].astype(bool)

    # 5. Handle missing values --------------------------------------------
    # Amount / currency missing almost always corresponds to Cancelled orders
    # with Qty = 0 -> fill Amount with 0 rather than dropping the order.
    missing_amount = df["amount"].isna().sum()
    df["amount"] = df["amount"].fillna(0)
    log(f"Filled {missing_amount:,} missing 'amount' values with 0 "
        f"(orders with Qty=0 / Cancelled status)")

    # courier_status missing -> mostly Cancelled orders never shipped
    missing_courier = df["courier_status"].isna().sum()
    if "courier_status" in df.columns:
        df["courier_status"] = df["courier_status"].cat.add_categories(["Not Shipped"])
        df["courier_status"] = df["courier_status"].fillna("Not Shipped")
    log(f"Filled {missing_courier:,} missing 'courier_status' values with 'Not Shipped'")

    # ship-city/state/postal/country missing (33 rows) -> drop, too few to impute
    before = len(df)
    df = df.dropna(subset=["ship_city", "ship_state", "ship_postal_code", "ship_country"])
    log(f"Dropped {before - len(df):,} rows missing shipping address details")

    # promotion_ids: NaN simply means "no promotion applied" -> fill flag
    df["has_promotion"] = df["promotion_ids"].notna()
    df = df.drop(columns=["promotion_ids"])
    log("Converted 'promotion_ids' into boolean 'has_promotion' flag")

    # fulfilled_by: NaN means fulfilled directly by Amazon (not via Easy Ship)
    df["fulfilled_by"] = df["fulfilled_by"].cat.add_categories(["Amazon Fulfilled"])
    df["fulfilled_by"] = df["fulfilled_by"].fillna("Amazon Fulfilled")
    log("Filled missing 'fulfilled_by' with 'Amazon Fulfilled'")

    # 6. Handle outliers in Amount using IQR ---------------------------------
    q1, q3 = df["amount"].quantile([0.25, 0.75])
    iqr = q3 - q1
    lower, upper = q1 - 1.5 * iqr, q3 + 1.5 * iqr
    outliers = df[(df["amount"] < lower) | (df["amount"] > upper)]
    log(f"IQR bounds for 'amount': [{lower:.2f}, {upper:.2f}] -> "
        f"{len(outliers):,} outlier rows flagged (kept, not removed, since high-value "
        f"orders are legitimate sales)")
    df["amount_outlier_flag"] = (df["amount"] < lower) | (df["amount"] > upper)

    # 7. Derived columns for analysis ----------------------------------------
    df["order_month"] = df["date"].dt.to_period("M").astype(str)
    df["order_week"] = df["date"].dt.to_period("W").astype(str)
    df["order_day"] = df["date"].dt.date
    log("Added derived columns: order_month, order_week, order_day")

    return df


def main():
    df_raw = load_data(RAW_PATH)
    df_clean = clean(df_raw)
    df_clean.to_csv(PROCESSED_PATH, index=False)
    log(f"\nSaved cleaned dataset: {df_clean.shape[0]:,} rows x {df_clean.shape[1]} columns "
        f"-> {PROCESSED_PATH}")

    with open("../data/processed/cleaning_log.txt", "w") as f:
        f.write("\n".join(cleaning_log))

    return df_clean


if __name__ == "__main__":
    main()
