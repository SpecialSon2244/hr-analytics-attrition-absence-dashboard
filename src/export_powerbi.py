"""Write the star schema tables to powerbi/model/*.csv for the Power BI model.

Tables from the SIMULATED recruiting pipeline carry SIMULATED in the file name.
"""
import pathlib

import duckdb

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "powerbi" / "model"

TABLES = {
    # shared dimensions (IBM departments and job roles; used by IBM and SIMULATED facts)
    "dim_department": "SELECT * FROM dim_department ORDER BY 1",
    "dim_job_role": "SELECT * FROM dim_job_role ORDER BY 1",
    "dim_date": "SELECT * FROM dim_date ORDER BY 1",
    # workforce / attrition (IBM, fictional)
    "dim_employee": "SELECT * EXCLUDE (department_key, department_name) FROM dim_employee ORDER BY 1",
    "fact_attrition_snapshot": "SELECT * FROM fact_attrition_snapshot ORDER BY 1",
    # absence (UCI, real, different company)
    "dim_absence_employee": "SELECT * FROM dim_absence_employee ORDER BY 1",
    "dim_absence_reason": "SELECT * FROM dim_absence_reason ORDER BY 1",
    "dim_absence_month": """
        SELECT m AS month_number,
               CASE WHEN m = 0 THEN 'Not recorded'
                    ELSE ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m] END AS month_name,
               CASE WHEN m IN (12, 1, 2) THEN 'Summer (Dec-Feb)' WHEN m IN (3, 4, 5) THEN 'Autumn (Mar-May)'
                    WHEN m IN (6, 7, 8) THEN 'Winter (Jun-Aug)' WHEN m IN (9, 10, 11) THEN 'Spring (Sep-Nov)'
                    ELSE 'Not recorded' END AS season_by_month
        FROM range(0, 13) t(m)""",
    "dim_weekday": """SELECT * FROM (VALUES (1, 'Mon', 'Monday'), (2, 'Tue', 'Tuesday'), (3, 'Wed', 'Wednesday'),
                      (4, 'Thu', 'Thursday'), (5, 'Fri', 'Friday')) t(iso_weekday, weekday_name, weekday_long)""",
    "fact_absence": "SELECT * EXCLUDE (month_name, weekday_name, season_by_month) FROM fact_absence ORDER BY 1",
    # recruiting (SIMULATED)
    "fact_requisition_SIMULATED": "SELECT * EXCLUDE (job_role) FROM fact_requisition ORDER BY 1",
    "fact_candidate_SIMULATED": "SELECT * EXCLUDE (job_role) FROM fact_candidate ORDER BY 1",
    "fact_candidate_stage_SIMULATED": "SELECT * FROM fact_candidate_stage ORDER BY candidate_id, stage_order",
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(ROOT / "data" / "hr.duckdb"), read_only=True)
    for name, sql in TABLES.items():
        rel = con.sql(sql)
        rel.write_csv(str(OUT / f"{name}.csv"))
        print(f"{name}.csv: {len(rel.fetchall()):,} rows, {len(rel.columns)} columns")


if __name__ == "__main__":
    main()
