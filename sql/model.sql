-- Star schema for the HR analytics project.
-- Three sources, three organisations. They are NOT joined to each other:
--   IBM HR attrition (fictional, 1,470 employees)  -> dim_employee, fact_attrition_snapshot
--   UCI absenteeism (real, 36 courier employees)   -> dim_absence_employee, fact_absence
--   SIMULATED recruiting pipeline                  -> fact_requisition, fact_candidate, fact_candidate_stage
-- dim_department and dim_job_role (IBM's departments and roles) are shared by the IBM
-- and SIMULATED tables.

CREATE OR REPLACE TABLE dim_department AS
SELECT row_number() OVER (ORDER BY department)::INT AS department_key, department AS department_name
FROM (SELECT DISTINCT department FROM stg_ibm);

-- "Manager" exists in all three departments, so a job role is department + role.
CREATE OR REPLACE TABLE dim_job_role AS
SELECT row_number() OVER (ORDER BY department, job_role)::INT AS job_role_key, job_role, d.department_key,
       department AS department_name
FROM (SELECT DISTINCT department, job_role FROM stg_ibm) r JOIN dim_department d ON d.department_name = r.department;

CREATE OR REPLACE TABLE dim_date AS
SELECT strftime(d, '%Y%m%d')::INT AS date_key, d::DATE AS date, year(d) AS year, quarter(d) AS quarter,
       'Q' || quarter(d) AS quarter_name, month(d) AS month, strftime(d, '%b') AS month_name,
       strftime(d, '%Y-%m') AS year_month, isodow(d) AS iso_weekday, strftime(d, '%a') AS weekday_name,
       isodow(d) >= 6 AS is_weekend
FROM range(DATE '2025-01-01', DATE '2026-12-31' + 1, INTERVAL 1 DAY) t(d);

CREATE OR REPLACE TABLE dim_employee AS
SELECT e.employee_number AS employee_key, d.department_key, e.department AS department_name,
       e.job_role, e.job_level, e.age,
       CASE WHEN age < 25 THEN '18-24' WHEN age < 35 THEN '25-34' WHEN age < 45 THEN '35-44'
            WHEN age < 55 THEN '45-54' ELSE '55+' END AS age_band,
       e.gender, e.marital_status,
       ['Below college', 'College', 'Bachelor', 'Master', 'Doctor'][e.education] AS education_level,
       e.education_field,
       CASE e.business_travel WHEN 'Non-Travel' THEN 'No travel' WHEN 'Travel_Rarely' THEN 'Travels rarely'
            ELSE 'Travels frequently' END AS business_travel,
       e.distance_from_home,
       e.over_time AS overtime,
       e.monthly_income,
       CASE WHEN monthly_income < 3000 THEN '1. Under 3k' WHEN monthly_income < 5000 THEN '2. 3k-5k'
            WHEN monthly_income < 10000 THEN '3. 5k-10k' ELSE '4. 10k+' END AS income_band,
       e.stock_option_level, e.percent_salary_hike, e.performance_rating,
       ['Low', 'Medium', 'High', 'Very high'][e.job_satisfaction] AS job_satisfaction,
       ['Low', 'Medium', 'High', 'Very high'][e.environment_satisfaction] AS environment_satisfaction,
       ['Bad', 'Good', 'Better', 'Best'][e.work_life_balance] AS work_life_balance,
       e.num_companies_worked, e.total_working_years, e.training_times_last_year,
       e.years_at_company,
       CASE WHEN years_at_company <= 2 THEN '1. 0-2 yrs' WHEN years_at_company <= 5 THEN '2. 3-5 yrs'
            WHEN years_at_company <= 10 THEN '3. 6-10 yrs' ELSE '4. 11+ yrs' END AS tenure_band,
       e.years_in_current_role, e.years_since_last_promotion, e.years_with_current_manager
FROM stg_ibm e JOIN dim_department d ON d.department_name = e.department;

-- One row per IBM employee at the (undated) snapshot. Attrition = Yes means the
-- employee left; the dataset does not say when, nor whether it was voluntary.
CREATE OR REPLACE TABLE fact_attrition_snapshot AS
SELECT employee_number AS employee_key, d.department_key, j.job_role_key,
       1 AS headcount_at_start,
       CASE attrition WHEN 'Yes' THEN 1 ELSE 0 END AS is_leaver,
       CASE attrition WHEN 'Yes' THEN 0 ELSE 1 END AS is_active,
       'Not recorded' AS termination_type,
       years_at_company AS tenure_years, monthly_income
FROM stg_ibm e JOIN dim_department d ON d.department_name = e.department
JOIN dim_job_role j ON j.department_key = d.department_key AND j.job_role = e.job_role;

CREATE OR REPLACE TABLE dim_absence_employee AS
SELECT 'UCI-' || lpad(id::VARCHAR, 2, '0') AS absence_employee_key,
       min(age) AS min_age_in_records, any_value(service_time) AS service_time_years,
       any_value(distance_from_residence_to_work) AS distance_to_work_km,
       any_value(transportation_expense) AS transportation_expense,
       ['High school', 'Graduate', 'Postgraduate', 'Master or doctor'][any_value(education)] AS education_level,
       any_value(son) AS children, any_value(social_drinker) = 1 AS social_drinker,
       any_value(social_smoker) = 1 AS social_smoker, any_value(pet) AS pets,
       any_value(body_mass_index) AS body_mass_index
FROM stg_absence GROUP BY id;

CREATE OR REPLACE TABLE dim_absence_reason AS
SELECT * FROM (VALUES
 (0, 'No reason recorded', 'No reason recorded'),
 (1, 'Infectious and parasitic diseases', 'ICD disease'), (2, 'Neoplasms', 'ICD disease'),
 (3, 'Blood and immune disorders', 'ICD disease'), (4, 'Endocrine, nutritional, metabolic', 'ICD disease'),
 (5, 'Mental and behavioural disorders', 'ICD disease'), (6, 'Nervous system', 'ICD disease'),
 (7, 'Eye and adnexa', 'ICD disease'), (8, 'Ear and mastoid', 'ICD disease'),
 (9, 'Circulatory system', 'ICD disease'), (10, 'Respiratory system', 'ICD disease'),
 (11, 'Digestive system', 'ICD disease'), (12, 'Skin and subcutaneous tissue', 'ICD disease'),
 (13, 'Musculoskeletal and connective tissue', 'ICD disease'), (14, 'Genitourinary system', 'ICD disease'),
 (15, 'Pregnancy and childbirth', 'ICD disease'), (16, 'Perinatal conditions', 'ICD disease'),
 (17, 'Congenital malformations', 'ICD disease'), (18, 'Symptoms and abnormal findings', 'ICD disease'),
 (19, 'Injury, poisoning', 'ICD disease'), (20, 'External causes', 'ICD disease'),
 (21, 'Factors influencing health status', 'ICD disease'),
 (22, 'Patient follow-up', 'Non-ICD'), (23, 'Medical consultation', 'Non-ICD'),
 (24, 'Blood donation', 'Non-ICD'), (25, 'Laboratory examination', 'Non-ICD'),
 (26, 'Unjustified absence', 'Non-ICD'), (27, 'Physiotherapy', 'Non-ICD'),
 (28, 'Dental consultation', 'Non-ICD')
) t(reason_code, reason_name, reason_group);

-- One row per absence record (July 2007 to July 2010). The source has month and
-- weekday but no year, so it does not join to dim_date.
-- Season: UCI's own season code does not line up with the calendar months in the
-- file, so season_by_month is derived from the month (Southern Hemisphere, Brazil):
-- Dec-Feb summer, Mar-May autumn, Jun-Aug winter, Sep-Nov spring.
CREATE OR REPLACE TABLE fact_absence AS
SELECT a.absence_id, 'UCI-' || lpad(a.id::VARCHAR, 2, '0') AS absence_employee_key,
       a.reason_for_absence AS reason_code,
       a.month_of_absence AS month_number,
       CASE WHEN a.month_of_absence BETWEEN 1 AND 12
            THEN ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][a.month_of_absence]
            ELSE 'Not recorded' END AS month_name,
       a.day_of_the_week - 1 AS iso_weekday,
       ['Mon','Tue','Wed','Thu','Fri'][a.day_of_the_week - 1] AS weekday_name,
       ['Summer','Autumn','Winter','Spring'][a.seasons] AS season_uci_code_label,
       CASE WHEN a.month_of_absence IN (12, 1, 2) THEN 'Summer (Dec-Feb)'
            WHEN a.month_of_absence IN (3, 4, 5) THEN 'Autumn (Mar-May)'
            WHEN a.month_of_absence IN (6, 7, 8) THEN 'Winter (Jun-Aug)'
            WHEN a.month_of_absence IN (9, 10, 11) THEN 'Spring (Sep-Nov)'
            ELSE 'Not recorded' END AS season_by_month,
       a.absenteeism_time_in_hours AS absence_hours,
       a.absenteeism_time_in_hours / 8.0 AS absence_days_8h,
       (a.absenteeism_time_in_hours > 0)::INT AS is_absence_spell,
       a.disciplinary_failure = 1 AS disciplinary_failure,
       a.work_load_average_per_day AS work_load_average_per_day,
       a.hit_target, a.age AS age_at_absence, a.service_time AS service_time_years
FROM stg_absence a;

-- SIMULATED: requisitions and candidates.
CREATE OR REPLACE TABLE fact_candidate AS
SELECT c.candidate_id, c.requisition_id, d.department_key, j.job_role_key, r.job_role, c.source,
       strftime(c.applied_date, '%Y%m%d')::INT AS applied_date_key, c.applied_date,
       c.screened_date, c.interview_date, c.final_interview_date, c.offer_date,
       c.offer_decision_date, coalesce(c.offer_outcome, 'No offer') AS offer_outcome, c.start_date,
       CASE WHEN c.offer_outcome = 'Accepted' THEN 'Hired' WHEN c.offer_date IS NOT NULL THEN 'Offer'
            WHEN c.final_interview_date IS NOT NULL THEN 'Final interview'
            WHEN c.interview_date IS NOT NULL THEN 'Interview'
            WHEN c.screened_date IS NOT NULL THEN 'Screened' ELSE 'Applied' END AS furthest_stage,
       CASE WHEN c.offer_outcome = 'Accepted' THEN c.offer_decision_date - c.applied_date END AS time_to_hire_days,
       TRUE AS is_simulated
FROM stg_candidate c JOIN stg_requisition r USING (requisition_id)
JOIN dim_department d ON d.department_name = r.department
JOIN dim_job_role j ON j.department_key = d.department_key AND j.job_role = r.job_role;

CREATE OR REPLACE TABLE fact_candidate_stage AS
WITH s AS (
    SELECT candidate_id, requisition_id, department_key, source, stage, stage_order, stage_date
    FROM fact_candidate,
    LATERAL (VALUES ('1. Applied', 1, applied_date), ('2. Screened', 2, screened_date),
                    ('3. Interview', 3, interview_date), ('4. Final interview', 4, final_interview_date),
                    ('5. Offer', 5, offer_date),
                    ('6. Hired', 6, CASE WHEN offer_outcome = 'Accepted' THEN offer_decision_date END))
        v(stage, stage_order, stage_date))
SELECT candidate_id, requisition_id, department_key, source, stage, stage_order,
       strftime(stage_date, '%Y%m%d')::INT AS stage_date_key, stage_date, TRUE AS is_simulated
FROM s WHERE stage_date IS NOT NULL;

CREATE OR REPLACE TABLE fact_requisition AS
SELECT r.requisition_id, d.department_key, j.job_role_key, r.job_role, r.job_level, r.status,
       strftime(r.opened_date, '%Y%m%d')::INT AS opened_date_key, r.opened_date,
       strftime(r.closed_date, '%Y%m%d')::INT AS closed_date_key, r.closed_date,
       r.hired_candidate_id, h.source AS hired_source,
       CASE WHEN r.status = 'Filled' THEN r.closed_date - r.opened_date END AS time_to_fill_days,
       h.time_to_hire_days,
       (SELECT count(*) FROM fact_candidate c WHERE c.requisition_id = r.requisition_id) AS applicants,
       (SELECT count(*) FROM fact_candidate c WHERE c.requisition_id = r.requisition_id AND c.offer_date IS NOT NULL) AS offers,
       TRUE AS is_simulated
FROM stg_requisition r JOIN dim_department d ON d.department_name = r.department
JOIN dim_job_role j ON j.department_key = d.department_key AND j.job_role = r.job_role
LEFT JOIN fact_candidate h ON h.candidate_id = r.hired_candidate_id;

DROP TABLE stg_ibm; DROP TABLE stg_absence; DROP TABLE stg_requisition; DROP TABLE stg_candidate;
