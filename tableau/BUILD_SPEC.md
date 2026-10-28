# Tableau Public build spec

How to build and publish the dashboard **"HR Analytics: Attrition, Absence & Time to Hire"**
in Tableau Public web authoring from one Excel file. Every chart uses one sheet of that
file as is. No calculated fields, joins or relationships are needed.

## File to upload

| | |
|---|---|
| File (on the box) | `/workspace/weekly-projects/week-04-hr-analytics/tableau/hr_analytics_dashboard.xlsx` |
| Same file on GitHub | `https://github.com/SpecialSon2244/hr-analytics-attrition-absence-dashboard/raw/main/tableau/hr_analytics_dashboard.xlsx` |
| Size | about 0.03 MB (limit for Tableau Public uploads: 1 GB) |
| Built by | `src/tableau_workbook.py`, checked by `tests/verify_tableau_xlsx.py` (183 checks, 0 errors) |
| CSV copies | `exports/<sheet name>.csv` (same tables, only needed if the Excel upload fails) |

Sheets in the file (the `about` sheet holds notes only, do not chart it):

| Sheet | Rows | Data |
|---|---|---|
| `kpis` | 8 | KPI strip, all three areas (column Source says which) |
| `attrition_by_role` | 11 | IBM (fictional) |
| `attrition_drivers` | 27 | IBM (fictional) |
| `overtime_income` | 8 | IBM (fictional) |
| `absence_reason` | 27 | UCI (real, different company) |
| `absence_calendar` | 60 | UCI (real, different company) |
| `hiring_funnel_SIMULATED` | 24 | SIMULATED |
| `time_to_hire_SIMULATED` | 257 | SIMULATED, one row per filled requisition |
| `hiring_dept_SIMULATED` | 3 | SIMULATED (optional table) |

Facts about the data that the titles depend on:

- All percentages are numbers from 0 to 100 (16.1 means 16.1%). Do not use Tableau's
  "Percentage" format, it would show 1610%.
- The IBM data is a **fictional** dataset created by IBM data scientists. The absence data is
  real but from a **different company** (a courier company in Brazil, 2007 to 2010). The hiring
  data is **SIMULATED**. Never join or blend these sources.
- Every sheet except `time_to_hire_SIMULATED` has one row per mark, so SUM() of a
  percentage returns the stored value. Keep the default SUM aggregation, except where
  this spec says MEDIAN.

## Colours

| Value | Hex | Used in |
|---|---|---|
| Single-colour bars (IBM) | `#1F3A5F` (navy) | Sheets 2 and 3 |
| Reason group "ICD disease" | `#1F3A5F` (navy) | Sheet 5 |
| Reason group "Non-ICD" | `#2A9D8F` (teal) | Sheet 5 |
| SIMULATED charts | `#E76F51` (orange) | Sheets 7 and 8 (Time to hire orange, Time to fill navy `#1F3A5F`) |
| Heatmaps | palette "Orange" sequential (web editor name: "Orange") | Sheets 4 and 6 |
| KPI strip Source | IBM `#1F3A5F`, UCI `#2A9D8F`, SIMULATED `#E76F51` | Sheet 1 |

To set a colour: click the Color card, Edit Colors, pick the value, type the hex. If there
is no hex field, choose the closest swatch and note which one was used.

## Number formats

| Field | Format |
|---|---|
| Any field ending in `%` | Number (Custom), 1 decimal, suffix `%` |
| Headcount, Leavers, Active, Records, Absence hours, Candidates, Applicants | Number (Custom), 0 decimals, thousands separator |
| Time to hire (days), Time to fill (days), Median ... (days) | Number (Custom), 0 decimals, suffix ` days` |

Set once per field: Data pane, field menu, Default Properties, Number Format. If missing,
use the pill menu on Label or axis, Format.

## Step 0. Connect the data

1. Go to https://public.tableau.com and check you are signed in as
   `abhiram.ramakrishnan3146` (profile URL `https://public.tableau.com/app/profile/abhiram.ramakrishnan3146`).
2. Click **Create**, then **Web Authoring**.
3. In "Connect to Data", choose **Files**, upload
   `/workspace/weekly-projects/week-04-hr-analytics/tableau/hr_analytics_dashboard.xlsx`.
4. On the data source page drag the sheet `kpis` onto the canvas. Rename the data source
   (top left) to `kpis`.
5. For each other sheet: Data pane, **New Data Source** (cylinder with a plus), upload the same
   file again, drag only that sheet onto the canvas, rename the data source to the sheet name.
   You end with 8 data sources: `kpis`, `attrition_by_role`, `attrition_drivers`,
   `overtime_income`, `absence_reason`, `absence_calendar`, `hiring_funnel_SIMULATED`,
   `time_to_hire_SIMULATED`. (`hiring_dept_SIMULATED` is optional.)
6. Do not join or relate sheets.

Field roles to check after each upload (field menu, Convert to Dimension / Discrete if
Tableau guessed wrong):

- Text fields (KPI, Source, Display, Department, Job role, Factor, Group, Overtime, Monthly
  income band, Reason, Reason group, Month, Weekday, Stage, Quarter filled, Requisition,
  Hire source, Data) are dimensions.
- `KPI order`, `Factor order`, `Group order`, `Band order`, `Month number`, `Weekday number`,
  `Stage order` are only used for sorting. Leave them as measures.

## Sheet 1. KPI strip

- Data source: `kpis`
- Columns: `Source`, then `KPI`
- Marks: Text. Text: `Display` (drag to Text). Color: `Source` (colours above)
- Sort `KPI`: Sort by Field, `KPI order`, Sum, Ascending. Sort `Source`: Manual,
  IBM (fictional), UCI (real, other company), SIMULATED
- Format: text size 18 bold for the Display, header font 9. Hide the row/column grid lines.
- Title: hide the sheet title (the dashboard has its own).

## Sheet 2. Attrition by job role

- Data source: `attrition_by_role`
- Rows: `Department`, then `Job role`
- Columns: SUM(`Attrition rate %`)
- Marks: Bar, colour `#1F3A5F`. Label: SUM(`Attrition rate %`)
- Sort `Job role`: by field `Attrition rate %`, Sum, Descending. Sort `Department`: by field
  `Attrition rate %`, Sum, Descending (Sales on top)
- Reference line: right-click the axis, Add Reference Line, Entire Table, value AVG(`Company
  attrition rate %`), label "Company 16.1%", line dashed orange `#E76F51`
- Tooltip: add `Headcount`, `Leavers`, `Active`, `Avg tenure (years)`
- Axis title "Attrition rate (%)"
- Title: **"Sales Representatives leave at 39.8%, the highest of any role"**

## Sheet 3. Who leaves (attrition drivers)

- Data source: `attrition_drivers`
- Filter: `Factor`, keep Overtime, Years at company, Monthly income, Business travel
  (untick Age band, Job level, Job satisfaction if space is short; keep all 7 if the sheet is tall
  enough)
- Rows: `Factor`, then `Group`
- Columns: SUM(`Attrition rate %`)
- Sort `Factor`: by field `Factor order`, Sum, Ascending. Sort `Group`: by field `Group order`,
  Sum, Ascending
- Marks: Bar, colour `#1F3A5F`. Label: SUM(`Attrition rate %`)
- Tooltip: add `Headcount`, `Leavers`
- Axis fixed 0 to 45, title "Attrition rate (%)"
- Title: **"Overtime workers leave at 30.5%, others at 10.4%"**

## Sheet 4. Overtime x income heatmap

- Data source: `overtime_income`
- Columns: `Monthly income band`, sort by field `Band order`, Sum, Ascending (Under 3k first)
- Rows: `Overtime`
- Marks: Square. Color: SUM(`Attrition rate %`), palette Orange. Label: SUM(`Attrition rate %`)
- Tooltip: add `Headcount`, `Leavers`
- Title: **"Low pay plus overtime: 56.1% left (64 of 114)"**
- Caption: "Monthly income as in the IBM dataset (no currency given)."

## Sheet 5. Absence hours by reason

- Data source: `absence_reason`
- Filter: `Reason`, Top tab, By field, Top 10 by SUM(`Absence hours`)
- Rows: `Reason`, sorted by field `Absence hours`, Sum, Descending
- Columns: SUM(`Absence hours`)
- Color: `Reason group` (ICD disease navy, Non-ICD teal)
- Label: SUM(`Share of hours %`)
- Tooltip: add `Records`, `Avg hours per record`, `Share of hours %`
- Title: **"Musculoskeletal problems and injuries: 30.7% of absence hours"**

## Sheet 6. Absence by month and weekday

- Data source: `absence_calendar`
- Columns: `Weekday`, sort by field `Weekday number`, Sum, Ascending (Mon to Fri)
- Rows: `Month`, sort by field `Month number`, Sum, Ascending (Jan to Dec)
- Marks: Square. Color: SUM(`Absence hours`), palette Orange. Label: SUM(`Absence hours`)
- Analysis menu, Totals, Show Column Grand Totals (gives hours per weekday at the bottom)
- Tooltip: `Month`, `Weekday`, `Records`, `Absence hours`
- Title: **"Mondays carry 29.1% of absence hours, Thursdays 10.8%"**
- Caption: "3 records without a month (0 hours) are not shown."

## Sheet 7. Recruiting funnel (SIMULATED)

- Data source: `hiring_funnel_SIMULATED`
- Filter: `Department`, show filter, Single value (dropdown), no "All", default
  "All departments"
- Rows: `Stage`, sort by field `Stage order`, Sum, Ascending (Applied on top)
- Columns: SUM(`Candidates`)
- Marks: Bar, colour `#E76F51`. Label: SUM(`Candidates`) and SUM(`% of applicants`)
- Tooltip: add `Conversion from previous stage %`, `Data`
- Title: **"SIMULATED recruiting funnel: 12,109 applicants, 257 hires, 77.6% offer acceptance"**

## Sheet 8. Time to hire by quarter (SIMULATED)

- Data source: `time_to_hire_SIMULATED` (one row per filled requisition)
- Columns: `Quarter filled` (text, sorts correctly A to Z)
- Rows: `Measure Values`. In the Measure Values card keep only `Time to hire (days)` and
  `Time to fill (days)` and set both aggregations to **MEDIAN** (pill menu, Measure,
  Median)
- Color: `Measure Names` (Time to hire `#E76F51`, Time to fill `#1F3A5F`)
- Marks: Line, with markers. Label: line ends
- Tooltip: add CNT(`Requisition`) (renamed "Hires")
- Axis fixed 0 to 50, title "Days (median)"
- Title: **"SIMULATED: median time to hire 33 days, time to fill 37 days"**
- Caption: "2026-Q3 is partial (snapshot 30 Sep 2026)."

## Optional Sheet 9. Hiring by department (SIMULATED)

- Data source: `hiring_dept_SIMULATED`. Text table: Rows `Department`; Measure Values:
  `Requisitions`, `Filled`, `Open`, `Median time to hire (days)`, `Median time to fill (days)`,
  `Offer acceptance %`. Title "SIMULATED: hiring by department".

## Dashboard

- New Dashboard, name the tab **HR Analytics**.
- Size: Fixed, **1200 x 1500** (Dashboard pane, Size, Custom).
- Tiled layout, top to bottom:
  1. Text, height 50: **"HR Analytics: Attrition, Absence & Time to Hire"**, bold, 22 pt.
  2. Text, height 45, 9 pt grey: "Three separate datasets, never joined. Attrition: IBM HR
     Analytics Employee Attrition & Performance, a fictional dataset created by IBM data
     scientists (1,470 employees). Absence: UCI Absenteeism at work, real records of a courier
     company in Brazil, 2007 to 2010 (CC BY 4.0). Time to hire: SIMULATED pipeline. Code:
     github.com/SpecialSon2244/hr-analytics-attrition-absence-dashboard"
  3. Sheet 1 (KPI strip), height 110.
  4. Text, height 30, bold 13 pt navy: "Attrition (IBM, fictional data)".
  5. Horizontal container, height 400: Sheet 2 (left, 50%), Sheet 3 (right, 50%).
  6. Sheet 4, height 170, full width.
  7. Text, height 30, bold 13 pt teal: "Absence (UCI, real records from a different company)".
  8. Horizontal container, height 380: Sheet 5 (left, 55%), Sheet 6 (right, 45%). Put the
     Reason group legend under Sheet 5 and the colour legend of Sheet 6 under Sheet 6.
  9. Text, height 30, bold 13 pt orange: "Time to hire (SIMULATED data, not real records)".
  10. Horizontal container, height 330: Sheet 7 (left, 50%) with its Department filter above
      it, Sheet 8 (right, 50%) with the Measure Names legend under it.
- Hide all other automatic legends.

## Publish

1. Check the titles against `docs/findings.md` (16.1%, 39.8%, 30.5% / 10.4%, 56.1%, 30.7%,
   29.1% / 10.8%, 12,109 / 257 / 77.6%, 33 / 37 days).
2. File, Save to Tableau Public As: **HR Analytics: Attrition, Absence & Time to Hire**.
   Abhiram approved publishing this project on 28 Oct 2026.
3. On the viz page, open the settings (gear) and keep "Show Viz on Profile" on. Add the
   description: "IBM fictional HR data (attrition), UCI absenteeism records (absence) and a
   SIMULATED recruiting pipeline (time to hire). Built with DuckDB and SQL."
4. Copy the public URL (format
   `https://public.tableau.com/app/profile/abhiram.ramakrishnan3146/viz/<WorkbookName>/HRAnalytics`).
5. Save a full-dashboard screenshot as `tableau/screens/dashboard.png` in the repo.
6. Paste the link into the Dashboard section of `README.md` (replace the placeholder line) and
   into the `Dashboard:` line of `LINKEDIN_POST.md`, then commit and push.
