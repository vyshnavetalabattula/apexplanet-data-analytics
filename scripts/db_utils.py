"""
ApexPlanet Data Analytics Internship - Task 2
db_utils.py — reusable module for connecting Python to the SQLite database
and safely running queries.

Tries SQLAlchemy first (recommended, matches the task brief); if SQLAlchemy
isn't installed in the environment, transparently falls back to Python's
built-in sqlite3 module so this module works anywhere.

Usage:
    from db_utils import get_connection, run_query, run_parameterized_query

    conn = get_connection()
    df = run_query("SELECT * FROM orders LIMIT 5", conn)
"""
import os
import sqlite3
import pandas as pd

try:
    from sqlalchemy import create_engine, text
    HAS_SQLALCHEMY = True
except ImportError:
    HAS_SQLALCHEMY = False

DEFAULT_DB_PATH = os.path.join(
    os.path.dirname(__file__), "..", "data", "processed", "amazon_sales.db"
)


def get_connection(db_path: str = DEFAULT_DB_PATH):
    """
    Return a database connection.
    - If SQLAlchemy is available: returns a SQLAlchemy Engine
      (works with any backend — e.g. swap to
      `postgresql://user:pass@host/db` for PostgreSQL in production).
    - Otherwise: returns a plain sqlite3.Connection.
    """
    db_path = os.path.abspath(db_path)
    if HAS_SQLALCHEMY:
        return create_engine(f"sqlite:///{db_path}")
    return sqlite3.connect(db_path)


# Backwards-compatible alias
get_engine = get_connection


def run_query(sql: str, conn=None) -> pd.DataFrame:
    """Execute a raw SQL SELECT statement and return the result as a DataFrame."""
    if conn is None:
        conn = get_connection()
    return pd.read_sql(sql, conn)


def run_parameterized_query(sql: str, params: dict, conn=None) -> pd.DataFrame:
    """
    Execute a parameterized SQL query safely (protects against SQL injection).

    Example (works the same whether SQLAlchemy or sqlite3 is used):
        run_parameterized_query(
            "SELECT * FROM orders WHERE ship_state = :state AND amount > :min_amt",
            {"state": "KARNATAKA", "min_amt": 1000},
        )
    """
    if conn is None:
        conn = get_connection()

    if HAS_SQLALCHEMY:
        with conn.connect() as c:
            result = c.execute(text(sql), params)
            rows = result.fetchall()
            cols = result.keys()
        return pd.DataFrame(rows, columns=cols)
    else:
        cur = conn.cursor()
        cur.execute(sql, params)  # sqlite3 supports :name placeholders natively
        rows = cur.fetchall()
        cols = [d[0] for d in cur.description]
        return pd.DataFrame(rows, columns=cols)


def execute_script(sql_path: str, conn=None):
    """Run a full .sql script (multiple statements) against the database,
    e.g. to (re)create views or indexes."""
    if conn is None:
        conn = get_connection()

    raw_conn = conn.raw_connection() if HAS_SQLALCHEMY else conn
    try:
        with open(sql_path, "r") as f:
            script = f.read()
        cursor = raw_conn.cursor()
        cursor.executescript(script)
        raw_conn.commit()
    finally:
        if HAS_SQLALCHEMY:
            raw_conn.close()


if __name__ == "__main__":
    conn = get_connection()
    df = run_query("SELECT COUNT(*) AS row_count FROM orders", conn)
    print(df)
    print("Using SQLAlchemy:", HAS_SQLALCHEMY)
