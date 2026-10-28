# Metric definitions

The same definitions are used in SQL (`sql/findings.sql`), the Tableau workbook
(`src/tableau_workbook.py`) and the Power BI measures (`powerbi/measures.dax`).

## Headcount and attrition (IBM, fictional)

| Metric | Definition |
|---|---|
| Headcount | Employees in the snapshot (1 row each in `fact_attrition_snapshot`), including those who later left |
| Active employees | Headcount with Attrition = No |
| Leavers | Headcount with Attrition = Yes |
| Attrition rate | Leavers / Headcount x 100. The IBM file is one undated snapshot, so this is not an annual rate |
| Average tenure | Average `YearsAtCompany` |
| Tenure band | 0-2, 3-5, 6-10, 11+ years at company |
| Income band | Monthly income under 3k, 3k-5k, 5k-10k, 10k+ (no currency is given in the dataset) |

The IBM data has no leaving date and no reason for leaving (voluntary or not), so the
model sets `termination_type = 'Not recorded'`.

## Absence (UCI, real)

| Metric | Definition |
|---|---|
| Absence records | Rows in `fact_absence` (740) |
| Absence spells | Records with more than 0 hours (696) |
| Absence hours | Sum of "Absenteeism time in hours" |
| Hours per employee per year | Absence hours / 36 employees / 3. The file covers July 2007 to July 2010 (about 3 years) and has no year column |
| Absence days | Hours / 8 (assumes an 8-hour working day) |
| Bradford factor (annualised) | (spells / 3)^2 x (days / 3). Descriptive only |
| Absence rate (Power BI only) | Absence hours / assumed scheduled hours. The source does not contain scheduled hours, so the Power BI measure uses an explicit, editable assumption of 8 h x 220 days per employee per year. Not used in any finding |
| Season | Derived from the month for the Southern Hemisphere (Dec-Feb summer, Mar-May autumn, Jun-Aug winter, Sep-Nov spring). UCI's season code does not match the months, so it is kept but not used |

## Time to hire (SIMULATED)

| Metric | Definition |
|---|---|
| Time to hire | Days from the hired candidate's application to the date they accepted the offer |
| Time to fill | Days from the requisition opening to the offer acceptance |
| Offer acceptance rate | Accepted offers / (accepted + declined) offers. Pending offers are left out |
| Funnel % of applicants | Candidates reaching a stage / all applicants |
| Stage conversion | Candidates reaching a stage / candidates reaching the previous stage |
| Requisition status | Filled, Open or Cancelled on the snapshot date 30 Sep 2026 |
