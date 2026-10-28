"""Download the two public source files (with retries) and check their shape.

- IBM HR Analytics Employee Attrition & Performance: public mirror in IBM's own
  GitHub repo IBM/employee-attrition-aif360 (same file as the Kaggle dataset).
- UCI Absenteeism at work (id 445), zip from archive.ics.uci.edu.
"""
import hashlib
import io
import pathlib
import time
import zipfile

import requests

ROOT = pathlib.Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"

IBM_URL = "https://raw.githubusercontent.com/IBM/employee-attrition-aif360/master/data/emp_attrition.csv"
UCI_URL = "https://archive.ics.uci.edu/static/public/445/absenteeism+at+work.zip"

EXPECTED = {
    # file: (data rows, columns, sha256 of the file as downloaded on 2026-10-28)
    "ibm_hr_attrition.csv": (1470, 35, "a5c31e38bd7fafc9bc333884eb181b06b41b8e5e488e8f7ccb27199fb3be7659"),
    "Absenteeism_at_work.csv": (740, 21, "41930631aa5b14f91fde29ae595cefad2beac464ddf837bf8150487e40038320"),
}


def get(url: str, tries: int = 6) -> bytes:
    for i in range(tries):
        try:
            r = requests.get(url, timeout=60)
            r.raise_for_status()
            return r.content
        except requests.RequestException as e:
            wait = 2 ** i
            print(f"  retry {i + 1}/{tries} after error: {e} (sleep {wait}s)")
            time.sleep(wait)
    raise RuntimeError(f"could not download {url}")


def check(name: str) -> None:
    rows, cols, sha = EXPECTED[name]
    data = (RAW / name).read_bytes()
    lines = data.decode("utf-8").strip().splitlines()
    sep = ";" if name.startswith("Absent") else ","
    n_cols = len(lines[0].split(sep))
    assert len(lines) - 1 == rows, f"{name}: {len(lines) - 1} rows, expected {rows}"
    assert n_cols == cols, f"{name}: {n_cols} columns, expected {cols}"
    digest = hashlib.sha256(data).hexdigest()
    note = "sha256 matches" if digest == sha else f"sha256 CHANGED ({digest})"
    print(f"{name}: {rows} rows, {cols} columns, {note}")


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    if not (RAW / "ibm_hr_attrition.csv").exists():
        (RAW / "ibm_hr_attrition.csv").write_bytes(get(IBM_URL))
    if not (RAW / "Absenteeism_at_work.csv").exists():
        with zipfile.ZipFile(io.BytesIO(get(UCI_URL))) as z:
            (RAW / "Absenteeism_at_work.csv").write_bytes(z.read("Absenteeism_at_work.csv"))
    for name in EXPECTED:
        check(name)


if __name__ == "__main__":
    main()
