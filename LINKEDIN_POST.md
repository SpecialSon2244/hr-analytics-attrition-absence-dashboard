# LinkedIn post (draft, not posted)

Why do people leave, and when are they absent? I built an HR analytics project around the questions HR teams ask every month.

Three sources in one DuckDB star schema, kept strictly apart: IBM's HR attrition dataset (1,470 employees, fictional data created by IBM data scientists), real absence records from a Brazilian courier company (UCI, 740 records), and a clearly labelled SIMULATED recruiting pipeline for time to hire.

What I found:
→ Overall attrition is 16.1%, but 30.5% of employees who work overtime left, against 10.4% of those who don't.
→ Overtime on low pay is the danger zone: 56.1% of people earning under 3k a month and working overtime left.
→ The first two years matter most: 29.8% attrition at 0–2 years of tenure, 8.1% after 11+ years. Sales Representatives leave at 39.8%.
→ Musculoskeletal problems and injuries cause 30.7% of 5,124 absence hours, and Mondays carry 29.1% of hours vs 10.8% on Thursdays.
→ In the SIMULATED hiring funnel, median time to hire is 33 days, time to fill 37 days, offer acceptance 77.6%.

Stack: Python, DuckDB and SQL for the star schema, Polars for cleaning, a Tableau Public dashboard, and a Power BI model with DAX measures (attrition rate, Bradford factor, time to hire, offer acceptance).

Biggest lesson: be honest about your data. Fictional, real and simulated data can sit in one project, but every chart has to say which one it shows.

Dashboard: https://public.tableau.com/app/profile/abhiram.ramakrishnan3146/viz/HRAnalyticsAttritionAbsenceTimetoHire/Dashboard1
Code: https://github.com/SpecialSon2244/hr-analytics-attrition-absence-dashboard

Which HR metric would you add next: internal mobility, engagement, or cost per hire?

#DataAnalytics #PeopleAnalytics #HRAnalytics #SQL #DuckDB #Tableau #PowerBI
