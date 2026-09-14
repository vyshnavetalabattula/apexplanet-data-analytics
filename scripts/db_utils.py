"""
ApexPlanet Data Analytics Internship - Task 2
db_utils.py

Reusable module for connecting Python to a database with SQLAlchemy and
running parameterized queries safely.

By default this targets a local SQLite file (zero setup, portable, and
perfect for an internship project). If you later want to point the exact
same functions at PostgreSQL or MySQL, just change DB_URL below (or set the
DATABASE_URL environment variable) -- nothing else in this file needs to
change, and nothing in your notebook/scripts needs to change either, since
they all go through this module.

Examples of other engines you could swap in:
    PostgreSQL:  "postgresql+psycopg2://user:password@localhost:5432/amazon_sales"
    MySQL:       "mysql+pymysql://user:password@localhost:3306/amazon_sales"
"""

import os
from contextlib import contextmanager

import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine

# ----------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------
DEFAULT_DB_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "data", "db", "amazon_sales.db",
)
DB_URL = os.environ.get("DATABASE_URL", f"sqlite:///{DEFAULT_DB_PATH}")

_engine: Engine | None = None


def get_engine(db_url: str = DB_URL, echo: bool = False) -> Engine:
    """Return a cached SQLAlchemy engine (created once, reused after that)."""
    global _engine
    if _engine is None:
        _engine = create_engine(db_url, echo=echo, future=True)
    return _engine


@contextmanager
def get_connection(db_url: str = DB_URL):
    """Context manager yielding a live DB connection.

    Usage:
        with get_connection() as conn:
            conn.execute(text("..."))
    """
    engine = get_engine(db_url)
    conn = engine.connect()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def run_query(sql: str, params: dict | None = None, db_url: str = DB_URL) -> pd.DataFrame:
    """Run a parameterized SELECT and return the result as a DataFrame.

    Always use `params` for any user-supplied or variable values instead of
    string-formatting them into `sql` -- this avoids SQL injection.

    Example:
        run_query(
            "SELECT * FROM sales WHERE category = :cat LIMIT :n",
            {"cat": "Saree", "n": 10},
        )
    """
    engine = get_engine(db_url)
    with engine.connect() as conn:
        return pd.read_sql(text(sql), conn, params=params or {})


def execute(sql: str, params: dict | None = None, db_url: str = DB_URL) -> int:
    """Run a non-SELECT statement (CREATE, INSERT, UPDATE, DROP, ...).

    Returns the number of rows affected where the driver reports it.
    """
    engine = get_engine(db_url)
    with engine.begin() as conn:  # begin() auto-commits on success
        result = conn.execute(text(sql), params or {})
        return result.rowcount


def table_exists(table_name: str, db_url: str = DB_URL) -> bool:
    engine = get_engine(db_url)
    from sqlalchemy import inspect
    return table_name in inspect(engine).get_table_names()


def explain(sql: str, db_url: str = DB_URL) -> pd.DataFrame:
    """Return the query plan for a SQL statement (SQLite EXPLAIN QUERY PLAN)."""
    return run_query(f"EXPLAIN QUERY PLAN {sql}", db_url=db_url)


if __name__ == "__main__":
    # Quick smoke test when run directly: python scripts/db_utils.py
    eng = get_engine()
    print(f"Connected to: {eng.url}")
    if table_exists("sales"):
        df = run_query("SELECT COUNT(*) AS row_count FROM sales")
        print(df)
    else:
        print("Table 'sales' not found yet -- run scripts/load_data.py first.")
