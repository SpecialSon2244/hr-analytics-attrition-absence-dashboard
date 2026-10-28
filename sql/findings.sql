-- Named queries used by src/findings.py, src/tableau_workbook.py and the tests.
-- IBM data is fictional; hiring data is SIMULATED; absence data is real (UCI).

-- name: f1_workforce_overall
SELECT sum(headcount_at_start) AS employees, sum(is_active) AS active, sum(is_leaver) AS leavers,
       round(100.0 * sum(is_leaver) / sum(headcount_at_start), 1) AS attrition_pct,
       round(avg(tenure_years), 1) AS avg_tenure_years,
       round(avg(tenure_years) FILTER (WHERE is_active = 1), 1) AS avg_tenure_active,
       round(avg(tenure_years) FILTER (WHERE is_leaver = 1), 1) AS avg_tenure_leavers,
       round(median(monthly_income) FILTER (WHERE is_active = 1)) AS median_income_active,
       round(median(monthly_income) FILTER (WHERE is_leaver = 1)) AS median_income_leavers
FROM fact_attrition_snapshot;

-- name: f2_by_department
SELECT d.department_name AS department, count(*) AS employees, sum(is_leaver) AS leavers,
       round(100.0 * sum(is_leaver) / count(*), 1) AS attrition_pct
FROM fact_attrition_snapshot f JOIN dim_department d USING (department_key)
GROUP BY 1 ORDER BY attrition_pct DESC;

-- name: f3_by_overtime
SELECT e.overtime, count(*) AS employees, sum(is_leaver) AS leavers,
       round(100.0 * sum(is_leaver) / count(*), 1) AS attrition_pct
FROM fact_attrition_snapshot f JOIN dim_employee e USING (employee_key)
GROUP BY 1 ORDER BY 1;

-- name: f4_by_job_role
SELECT e.job_role, count(*) AS employees, sum(is_leaver) AS leavers,
       round(100.0 * sum(is_leaver) / count(*), 1) AS attrition_pct
FROM fact_attrition_snapshot f JOIN dim_employee e USING (employee_key)
GROUP BY 1 ORDER BY attrition_pct DESC;

-- name: f5_by_tenure_band
SELECT e.tenure_band, count(*) AS employees, sum(is_leaver) AS leavers,
       round(100.0 * sum(is_leaver) / count(*), 1) AS attrition_pct
FROM fact_attrition_snapshot f JOIN dim_employee e USING (employee_key)
GROUP BY 1 ORDER BY 1;

-- name: f6_by_income_band
SELECT e.income_band, count(*) AS employees, sum(is_leaver) AS leavers,
       round(100.0 * sum(is_leaver) / count(*), 1) AS attrition_pct
FROM fact_attrition_snapshot f JOIN dim_employee e USING (employee_key)
GROUP BY 1 ORDER BY 1;

-- name: f7_by_travel
SELECT e.business_travel, count(*) AS employees, sum(is_leaver) AS leavers,
       round(100.0 * sum(is_leaver) / count(*), 1) AS attrition_pct
FROM fact_attrition_snapshot f JOIN dim_employee e USING (employee_key)
GROUP BY 1 ORDER BY attrition_pct DESC;

-- name: f8_by_age_band
SELECT e.age_band, count(*) AS employees, sum(is_leaver) AS leavers,
       round(100.0 * sum(is_leaver) / count(*), 1) AS attrition_pct
FROM fact_attrition_snapshot f JOIN dim_employee e USING (employee_key)
GROUP BY 1 ORDER BY 1;

-- name: f9_by_job_satisfaction
SELECT e.job_satisfaction, count(*) AS employees, sum(is_leaver) AS leavers,
       round(100.0 * sum(is_leaver) / count(*), 1) AS attrition_pct
FROM fact_attrition_snapshot f JOIN dim_employee e USING (employee_key)
GROUP BY 1 ORDER BY CASE e.job_satisfaction WHEN 'Low' THEN 1 WHEN 'Medium' THEN 2 WHEN 'High' THEN 3 ELSE 4 END;

-- name: f10_overtime_x_income
SELECT e.overtime, e.income_band, count(*) AS employees, sum(is_leaver) AS leavers,
       round(100.0 * sum(is_leaver) / count(*), 1) AS attrition_pct
FROM fact_attrition_snapshot f JOIN dim_employee e USING (employee_key)
GROUP BY 1, 2 ORDER BY 1, 2;

-- name: f11_by_job_level
SELECT e.job_level, count(*) AS employees, sum(is_leaver) AS leavers,
       round(100.0 * sum(is_leaver) / count(*), 1) AS attrition_pct,
       round(median(e.monthly_income)) AS median_monthly_income
FROM fact_attrition_snapshot f JOIN dim_employee e USING (employee_key)
GROUP BY 1 ORDER BY 1;

-- name: f12_department_tenure_income
SELECT d.department_name AS department, count(*) AS employees, sum(is_active) AS active,
       round(avg(tenure_years), 1) AS avg_tenure_years,
       round(avg(tenure_years) FILTER (WHERE is_leaver = 1), 1) AS avg_tenure_leavers,
       round(median(f.monthly_income)) AS median_monthly_income
FROM fact_attrition_snapshot f JOIN dim_department d USING (department_key)
GROUP BY 1 ORDER BY 1;

-- name: f20_absence_overall
SELECT count(*) AS records, sum(is_absence_spell) AS spells_with_hours,
       count(DISTINCT absence_employee_key) AS employees, sum(absence_hours) AS total_hours,
       round(sum(absence_hours) / count(DISTINCT absence_employee_key), 1) AS hours_per_employee,
       round(sum(absence_hours) / count(DISTINCT absence_employee_key) / 3.0, 1) AS hours_per_employee_per_year,
       round(avg(absence_hours) FILTER (WHERE is_absence_spell = 1), 1) AS avg_hours_per_spell,
       median(absence_hours) FILTER (WHERE is_absence_spell = 1) AS median_hours_per_spell
FROM fact_absence;

-- name: f21_absence_by_reason
SELECT r.reason_code, r.reason_name, r.reason_group, count(*) AS records, sum(absence_hours) AS hours,
       round(100.0 * sum(absence_hours) / (SELECT sum(absence_hours) FROM fact_absence), 1) AS pct_of_hours,
       round(avg(absence_hours), 1) AS avg_hours
FROM fact_absence a JOIN dim_absence_reason r USING (reason_code)
GROUP BY ALL ORDER BY hours DESC;

-- name: f22_absence_by_weekday
SELECT iso_weekday, weekday_name, count(*) AS records, sum(absence_hours) AS hours,
       round(100.0 * sum(absence_hours) / (SELECT sum(absence_hours) FROM fact_absence), 1) AS pct_of_hours,
       round(avg(absence_hours), 1) AS avg_hours
FROM fact_absence GROUP BY ALL ORDER BY 1;

-- name: f23_absence_by_season
SELECT season_by_month, count(*) AS records, sum(absence_hours) AS hours,
       round(100.0 * sum(absence_hours) / (SELECT sum(absence_hours) FROM fact_absence), 1) AS pct_of_hours,
       round(avg(absence_hours), 1) AS avg_hours
FROM fact_absence WHERE month_number BETWEEN 1 AND 12 GROUP BY ALL ORDER BY hours DESC;

-- name: f24_absence_by_month
SELECT month_number, month_name, count(*) AS records, sum(absence_hours) AS hours,
       round(avg(absence_hours), 1) AS avg_hours
FROM fact_absence WHERE month_number BETWEEN 1 AND 12 GROUP BY ALL ORDER BY 1;

-- name: f25_bradford
-- Bradford factor = S^2 x D (S = absence spells, D = days absent, hours / 8).
-- The file covers about 3 years (Jul 2007 to Jul 2010) without a year column, so the
-- annualised version uses S/3 and D/3: (S/3)^2 x (D/3).
WITH b AS (
    SELECT absence_employee_key, sum(is_absence_spell) AS spells, sum(absence_days_8h) AS days,
           sum(absence_hours) AS hours,
           (sum(is_absence_spell) / 3.0) ^ 2 * (sum(absence_days_8h) / 3.0) AS bradford_annual
    FROM fact_absence GROUP BY 1)
SELECT count(*) AS employees, round(median(bradford_annual)) AS median_bradford_annual,
       round(max(bradford_annual)) AS max_bradford_annual,
       sum((bradford_annual >= 250)::INT) AS employees_bradford_250_plus,
       (SELECT round(100.0 * sum(hours) / (SELECT sum(absence_hours) FROM fact_absence), 1)
        FROM (SELECT hours FROM b ORDER BY hours DESC LIMIT 5)) AS top5_share_of_hours_pct
FROM b;

-- name: f25b_bradford_top10
WITH b AS (
    SELECT absence_employee_key, sum(is_absence_spell) AS spells, round(sum(absence_days_8h), 1) AS days,
           sum(absence_hours) AS hours,
           round((sum(is_absence_spell) / 3.0) ^ 2 * (sum(absence_days_8h) / 3.0)) AS bradford_annual
    FROM fact_absence GROUP BY 1)
SELECT * FROM b ORDER BY bradford_annual DESC LIMIT 10;

-- name: f26_disciplinary
SELECT disciplinary_failure, count(*) AS records, sum(absence_hours) AS hours
FROM fact_absence GROUP BY 1 ORDER BY 1;

-- name: f30_hiring_overall_SIMULATED
SELECT count(*) AS requisitions, sum((status = 'Filled')::INT) AS filled,
       sum((status = 'Open')::INT) AS open, sum((status = 'Cancelled')::INT) AS cancelled,
       sum(applicants) AS applicants,
       round(avg(time_to_fill_days) , 1) AS avg_time_to_fill_days,
       median(time_to_fill_days) AS median_time_to_fill_days,
       round(avg(time_to_hire_days), 1) AS avg_time_to_hire_days,
       median(time_to_hire_days) AS median_time_to_hire_days,
       (SELECT round(100.0 * sum((offer_outcome = 'Accepted')::INT) / sum((offer_outcome IN ('Accepted', 'Declined'))::INT), 1)
        FROM fact_candidate) AS offer_accept_pct
FROM fact_requisition;

-- name: f31_funnel_SIMULATED
SELECT stage, count(*) AS candidates,
       round(100.0 * count(*) / (SELECT count(*) FROM fact_candidate), 2) AS pct_of_applicants
FROM fact_candidate_stage GROUP BY 1 ORDER BY 1;

-- name: f32_by_source_SIMULATED
SELECT source, count(*) AS applicants, sum((offer_date IS NOT NULL)::INT) AS offers,
       sum((offer_outcome = 'Accepted')::INT) AS hires,
       round(100.0 * sum((offer_outcome = 'Accepted')::INT) / count(*), 2) AS hire_per_100_applicants,
       round(100.0 * sum((offer_outcome = 'Accepted')::INT) / nullif(sum((offer_outcome IN ('Accepted', 'Declined'))::INT), 0), 1) AS offer_accept_pct,
       round(avg(time_to_hire_days), 1) AS avg_time_to_hire_days
FROM fact_candidate GROUP BY 1 ORDER BY hire_per_100_applicants DESC;

-- name: f33_by_department_SIMULATED
SELECT d.department_name AS department, count(*) AS requisitions, sum((status = 'Filled')::INT) AS filled,
       round(avg(time_to_fill_days), 1) AS avg_time_to_fill_days,
       median(time_to_fill_days) AS median_time_to_fill_days,
       round(avg(time_to_hire_days), 1) AS avg_time_to_hire_days,
       median(time_to_hire_days) AS median_time_to_hire_days,
       sum(applicants) AS applicants, sum(offers) AS offers
FROM fact_requisition r JOIN dim_department d USING (department_key)
GROUP BY 1 ORDER BY requisitions DESC;

-- name: f34_hires_by_quarter_SIMULATED
SELECT year(closed_date) || '-Q' || quarter(closed_date) AS quarter_filled, count(*) AS hires,
       round(avg(time_to_hire_days), 1) AS avg_time_to_hire_days,
       median(time_to_hire_days) AS median_time_to_hire_days,
       median(time_to_fill_days) AS median_time_to_fill_days
FROM fact_requisition WHERE status = 'Filled' GROUP BY 1 ORDER BY 1;

-- name: f35_offer_acceptance_by_department_SIMULATED
SELECT d.department_name AS department,
       sum((offer_outcome = 'Accepted')::INT) AS accepted, sum((offer_outcome = 'Declined')::INT) AS declined,
       sum((offer_outcome = 'Pending')::INT) AS pending,
       round(100.0 * sum((offer_outcome = 'Accepted')::INT) / sum((offer_outcome IN ('Accepted', 'Declined'))::INT), 1) AS offer_accept_pct
FROM fact_candidate c JOIN dim_department d USING (department_key)
GROUP BY 1 ORDER BY 1;
