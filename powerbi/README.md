# Power BI version (build notes)

Everything needed to assemble the `.pbix` in Power BI Desktop (Windows). The `.pbix` itself
is not in the repo yet.

| File | What |
|---|---|
| `model/*.csv` | The star schema tables, exported from DuckDB by `src/export_powerbi.py` |
| `RELATIONSHIPS.md` | Tables, keys and relationships (with a diagram) |
| `measures.dax` | All DAX measures |
| `PAGE_LAYOUT.md` | Report pages and visuals |

Tables with `_SIMULATED` in the name come from the SIMULATED recruiting pipeline.

## Steps

1. Clone the repo on Windows (or download `powerbi/model/` as a zip from GitHub).
2. Power BI Desktop, **Get data, Text/CSV**. Load all 13 files in `powerbi/model/`.
   In Power Query check that:
   - `*_date` columns are Date (locale English (United States) or ISO; the files use yyyy-mm-dd),
   - `*_date_key`, `*_key` (except `absence_employee_key`, `requisition_id`, `candidate_id`) are
     Whole number,
   - `is_*`, `disciplinary_failure`, `social_drinker`, `social_smoker`, `is_weekend` are True/False,
   - empty cells in the SIMULATED date columns stay null (do not replace them).
   Close & Apply.
3. **Model view**: delete any relationships Power BI auto-detected, then create the 13
   relationships in `RELATIONSHIPS.md` (relationship 7 inactive). Hide the fact
   `department_key` columns.
4. Mark `dim_date` as the date table. Set the Sort by column settings listed in `RELATIONSHIPS.md`.
5. **Enter data**: create an empty table `_Measures`. Add every measure from `measures.dax`
   (New measure, paste one at a time). Set formats: rates as Percentage 1 decimal; days and
   hours as Whole number or 1 decimal. Put them in the display folders named in the comments.
6. Build the four pages from `PAGE_LAYOUT.md`.
7. Check the numbers against `docs/findings.md`. With no slicers: Headcount 1,470, Attrition
   Rate 16.1%, Absence Hours 5,124, Absence Hours per Employee per Year 47.4, Median Time to Hire
   (SIMULATED) 33, Median Time to Fill (SIMULATED) 37, Offer Acceptance Rate (SIMULATED) 77.6%.
8. Save as `powerbi/hr_analytics.pbix`. If publishing to the web, keep the SIMULATED labels on
   every recruiting visual.
