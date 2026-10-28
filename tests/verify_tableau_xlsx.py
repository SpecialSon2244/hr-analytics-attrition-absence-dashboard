"""Open tableau/hr_analytics_dashboard.xlsx with openpyxl and check it against
docs/findings.json (generated from the same DuckDB build by src/findings.py)."""
import json
import pathlib
import sys

from openpyxl import load_workbook

ROOT = pathlib.Path(__file__).resolve().parents[1]
wb = load_workbook(ROOT / "tableau" / "hr_analytics_dashboard.xlsx", read_only=True)
F = json.loads((ROOT / "docs" / "findings.json").read_text())
errors: list[str] = []
checks = 0


def sheet(name):
    rows = list(wb[name].iter_rows(values_only=True))
    return [dict(zip(rows[0], r)) for r in rows[1:]]


def eq(label, got, want, tol=0.051):
    global checks
    checks += 1
    if got is None or want is None or abs(float(got) - float(want)) > tol:
        errors.append(f"{label}: xlsx={got} findings={want}")


strip = lambda s: str(s).split(". ", 1)[-1]  # noqa: E731

# 1. KPI strip
k = {r["KPI"]: r["Value"] for r in sheet("kpis")}
w, a, h = F["f1_workforce_overall"][0], F["f20_absence_overall"][0], F["f30_hiring_overall_SIMULATED"][0]
eq("kpi headcount", k["Headcount"], w["employees"])
eq("kpi attrition", k["Attrition rate"], w["attrition_pct"])
eq("kpi tenure", k["Avg tenure"], w["avg_tenure_years"])
eq("kpi absence hours", k["Absence hours"], a["total_hours"])
eq("kpi hours per employee per year", k["Absence hours per employee per year"], a["hours_per_employee_per_year"])
eq("kpi median time to hire", k["Median time to hire"], h["median_time_to_hire_days"])
eq("kpi median time to fill", k["Median time to fill"], h["median_time_to_fill_days"])
eq("kpi offer acceptance", k["Offer acceptance"], h["offer_accept_pct"])

# 2. attrition_by_role: roles summed over departments vs f4, departments vs f2
role = sheet("attrition_by_role")
for f in F["f4_by_job_role"]:
    rows = [r for r in role if r["Job role"] == f["job_role"]]
    eq(f"role {f['job_role']} headcount", sum(r["Headcount"] for r in rows), f["employees"], 0.5)
    eq(f"role {f['job_role']} leavers", sum(r["Leavers"] for r in rows), f["leavers"], 0.5)
for f in F["f2_by_department"]:
    rows = [r for r in role if r["Department"] == f["department"]]
    hc, lv = sum(r["Headcount"] for r in rows), sum(r["Leavers"] for r in rows)
    eq(f"dept {f['department']} rate", 100 * lv / hc, f["attrition_pct"])

# 3. attrition_drivers vs f3, f5-f9, f11
drv = sheet("attrition_drivers")
for key, factor, col in [("f3_by_overtime", "Overtime", "overtime"), ("f5_by_tenure_band", "Years at company", "tenure_band"),
                         ("f6_by_income_band", "Monthly income", "income_band"), ("f7_by_travel", "Business travel", "business_travel"),
                         ("f8_by_age_band", "Age band", "age_band"), ("f9_by_job_satisfaction", "Job satisfaction", "job_satisfaction"),
                         ("f11_by_job_level", "Job level", "job_level")]:
    for f in F[key]:
        g = f"Level {f[col]}" if col == "job_level" else strip(f[col])
        r = next((r for r in drv if r["Factor"] == factor and r["Group"] == g), None)
        if r is None:
            errors.append(f"drivers: missing {factor} / {g}")
            continue
        eq(f"driver {factor} {g} rate", r["Attrition rate %"], f["attrition_pct"])
        eq(f"driver {factor} {g} headcount", r["Headcount"], f["employees"], 0.5)
    if sum(r["Headcount"] for r in drv if r["Factor"] == factor) != 1470:
        errors.append(f"drivers: {factor} groups do not add up to 1,470")

# 4. overtime_income vs f10
oi = sheet("overtime_income")
for f in F["f10_overtime_x_income"]:
    r = next(r for r in oi if r["Overtime"] == f"Overtime: {f['overtime']}" and r["Monthly income band"] == strip(f["income_band"]))
    eq(f"ot x income {f['overtime']} {f['income_band']}", r["Attrition rate %"], f["attrition_pct"])

# 5. absence_reason vs f21, absence_calendar vs f22 / f24
ar = sheet("absence_reason")
for f in F["f21_absence_by_reason"]:
    if f["hours"] == 0:
        continue
    r = next(r for r in ar if r["Reason"] == f["reason_name"])
    eq(f"reason {f['reason_name']} hours", r["Absence hours"], f["hours"], 0.5)
    eq(f"reason {f['reason_name']} share", r["Share of hours %"], f["pct_of_hours"])
cal = sheet("absence_calendar")
month0 = 0  # 3 records have month 0 and are not in the calendar sheet; check their hours separately
for f in F["f24_absence_by_month"]:
    eq(f"month {f['month_name']} hours", sum(r["Absence hours"] for r in cal if r["Month number"] == f["month_number"]),
       f["hours"], 0.5)
total_cal = sum(r["Absence hours"] for r in cal)
eq("calendar total hours (month 0 rows hold 0 hours)", total_cal, a["total_hours"], 0.5)
for f in F["f22_absence_by_weekday"]:
    got = sum(r["Absence hours"] for r in cal if r["Weekday number"] == f["iso_weekday"])
    eq(f"weekday {f['weekday_name']} hours", got, f["hours"], 0.5)

# 6. SIMULATED sheets vs f31, f30, f33, f35
fun = sheet("hiring_funnel_SIMULATED")
for f in F["f31_funnel_SIMULATED"]:
    r = next(r for r in fun if r["Department"] == "All departments" and r["Stage"] == strip(f["stage"]))
    eq(f"funnel {f['stage']}", r["Candidates"], f["candidates"], 0.5)
tth = sheet("time_to_hire_SIMULATED")
eq("filled requisitions", len(tth), h["filled"], 0.5)
vals = sorted(r["Time to hire (days)"] for r in tth)
n = len(vals)
med = (vals[n // 2] + vals[(n - 1) // 2]) / 2
eq("median time to hire from rows", med, h["median_time_to_hire_days"])
dep = sheet("hiring_dept_SIMULATED")
for f in F["f33_by_department_SIMULATED"]:
    r = next(r for r in dep if r["Department"] == f["department"])
    eq(f"hiring {f['department']} reqs", r["Requisitions"], f["requisitions"], 0.5)
    eq(f"hiring {f['department']} median tth", r["Median time to hire (days)"], f["median_time_to_hire_days"])
    eq(f"hiring {f['department']} median ttf", r["Median time to fill (days)"], f["median_time_to_fill_days"])
for f in F["f35_offer_acceptance_by_department_SIMULATED"]:
    r = next(r for r in dep if r["Department"] == f["department"])
    eq(f"hiring {f['department']} offer acceptance", r["Offer acceptance %"], f["offer_accept_pct"])

# Shape checks: no empty cells (except the first funnel stage, which has no previous stage)
for name in wb.sheetnames:
    if name == "about":
        continue
    rows = list(wb[name].iter_rows(values_only=True))
    for r in rows[1:]:
        d = dict(zip(rows[0], r))
        d.pop("Conversion from previous stage %", None) if d.get("Stage") == "Applied" else None
        if any(v is None for v in d.values()):
            errors.append(f"{name}: empty cell in {r}")
            break
    if name.endswith("_SIMULATED") and "Data" not in rows[0]:
        errors.append(f"{name}: no SIMULATED label column")
    print(f"{name}: {len(rows) - 1} rows, columns: {', '.join(rows[0])}")

size = (ROOT / "tableau" / "hr_analytics_dashboard.xlsx").stat().st_size
print(f"file size: {size / 1e6:.2f} MB; {checks} value checks; {len(errors)} errors")
for e in errors:
    print("ERROR", e)
sys.exit(1 if errors else 0)
