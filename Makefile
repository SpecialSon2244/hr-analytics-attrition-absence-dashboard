VENV=.venv
PY=$(VENV)/bin/python
.PHONY: all setup data simulate build validate findings charts tableau powerbi docs test clean
all: data simulate build validate findings charts tableau powerbi docs test
setup:
	python3 -m venv $(VENV) && $(VENV)/bin/pip install -r requirements.txt
data:        ## download IBM + UCI files to data/raw/ and check rows, columns, sha256
	$(PY) src/download.py
simulate:    ## SIMULATED recruiting pipeline -> data/simulated/
	$(PY) src/simulate_hiring.py
build:       ## Polars cleaning + DuckDB star schema -> data/hr.duckdb
	$(PY) src/build.py
validate:    ## data checks -> docs/validation.md
	$(PY) src/validate.py > /dev/null
findings:    ## sql/findings.sql -> docs/findings_results.md, docs/findings.json, docs/findings.md
	$(PY) src/findings.py > /dev/null && $(PY) src/report.py > /dev/null
charts:      ## static PNGs for the README -> images/
	$(PY) src/charts.py
tableau:     ## tableau/hr_analytics_dashboard.xlsx + exports/*.csv
	$(PY) src/tableau_workbook.py
powerbi:     ## star schema tables -> powerbi/model/*.csv
	$(PY) src/export_powerbi.py
docs:        ## docs/data_dictionary.md
	$(PY) src/data_dictionary.py
test:        ## check the Tableau workbook against the findings
	$(PY) tests/verify_tableau_xlsx.py
clean:
	rm -f data/hr.duckdb
