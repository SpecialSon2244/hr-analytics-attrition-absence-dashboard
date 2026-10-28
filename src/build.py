"""Clean the raw files with Polars and build the DuckDB star schema (sql/model.sql)."""
import pathlib
import re

import duckdb
import polars as pl

ROOT = pathlib.Path(__file__).resolve().parents[1]
DB = ROOT / "data" / "hr.duckdb"


def snake(name: str) -> str:
    name = name.strip().replace("/", "_per_")
    name = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "_", name)
    return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")


def staging() -> dict[str, pl.DataFrame]:
    ibm = pl.read_csv(ROOT / "data" / "raw" / "ibm_hr_attrition.csv")
    ibm = ibm.rename({c: snake(c) for c in ibm.columns}).rename({"years_with_curr_manager": "years_with_current_manager"})
    # constant columns carry no information (EmployeeCount=1, Over18=Y, StandardHours=80)
    assert ibm["employee_count"].n_unique() == 1 and ibm["over18"].n_unique() == 1 and ibm["standard_hours"].n_unique() == 1
    ibm = ibm.drop("employee_count", "over18", "standard_hours")
    assert ibm["employee_number"].is_unique().all()

    ab = pl.read_csv(ROOT / "data" / "raw" / "Absenteeism_at_work.csv", separator=";")
    ab = ab.rename({c: snake(c) for c in ab.columns})
    ab = ab.with_row_index("absence_id", offset=1).with_columns(pl.col("absence_id").cast(pl.Int32))

    req = pl.read_csv(ROOT / "data" / "simulated" / "SIMULATED_requisitions.csv", try_parse_dates=True)
    cand = pl.read_csv(ROOT / "data" / "simulated" / "SIMULATED_candidates.csv", try_parse_dates=True)
    return {"stg_ibm": ibm, "stg_absence": ab, "stg_requisition": req, "stg_candidate": cand}


def main() -> None:
    DB.unlink(missing_ok=True)
    con = duckdb.connect(str(DB))
    for name, df in staging().items():
        con.register(f"{name}_df", df.to_arrow())
        con.execute(f"CREATE TABLE {name} AS SELECT * FROM {name}_df")
        con.unregister(f"{name}_df")
    con.execute((ROOT / "sql" / "model.sql").read_text())
    for (t,) in con.execute("SELECT table_name FROM information_schema.tables ORDER BY 1").fetchall():
        n = con.execute(f"SELECT count(*) FROM {t}").fetchone()[0]
        print(f"{t}: {n:,} rows")
    con.close()


if __name__ == "__main__":
    main()
