"""SIMULATED recruiting pipeline (seeded, reproducible).

Neither public dataset has recruiting data, so this script generates a
SIMULATED requisition and candidate table. Nothing here is a real measurement.
The only real input is the IBM file, used for the department / job role mix:
each requisition backfills a role in proportion to how many IBM employees in
that department and role left (Attrition = Yes).

All assumptions are listed in ASSUMPTIONS and in docs/simulated_hiring.md.
Output: data/simulated/SIMULATED_requisitions.csv and
        data/simulated/SIMULATED_candidates.csv
"""
import csv
import datetime as dt
import math
import pathlib
import random
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "data" / "simulated"
SEED = 20261028
SNAPSHOT = dt.date(2026, 9, 30)          # pipeline is observed on this date
OPEN_FROM, OPEN_TO = dt.date(2025, 1, 1), dt.date(2026, 6, 30)
N_REQUISITIONS = 300

ASSUMPTIONS = {
    "sources (share of applicants)": {"LinkedIn": 0.32, "Job board": 0.25, "Careers site": 0.20,
                                      "Employee referral": 0.13, "Agency": 0.10},
    # probability an applicant passes each stage, by source
    "screen pass rate": {"LinkedIn": 0.30, "Job board": 0.22, "Careers site": 0.30,
                         "Employee referral": 0.55, "Agency": 0.45},
    "screen -> first interview rate": 0.60,
    "interview pass rate (first interview -> final round)": 0.40,
    "offer accept rate": {"LinkedIn": 0.78, "Job board": 0.74, "Careers site": 0.80,
                          "Employee referral": 0.90, "Agency": 0.70},
    "applicants per requisition (mean, lognormal sigma 0.45)": {1: 45, 2: 32, 3: 24, 4: 16, 5: 12},
    "days, applied -> screen": (2, 10),
    "days, screen -> first interview": (4, 14),
    "days, first interview -> final interview": (5, 15),
    "days, final interview -> offer": (2, 8),
    "days, offer -> decision": (1, 6),
    "days, accept -> start (notice period)": (14, 60),
    "application lag after requisition opens (exponential mean, days)": 9,
    "requisitions cancelled without a hire": 0.06,
}


def job_mix() -> list[tuple[tuple[str, str, int], int]]:
    """(department, job role, typical job level) weighted by IBM leavers."""
    rows = list(csv.DictReader(open(ROOT / "data" / "raw" / "ibm_hr_attrition.csv")))
    leavers = Counter((r["Department"], r["JobRole"]) for r in rows if r["Attrition"] == "Yes")
    levels: dict = {}
    for r in rows:
        levels.setdefault((r["Department"], r["JobRole"]), []).append(int(r["JobLevel"]))
    mix = []
    for key, n in sorted(leavers.items()):
        lv = sorted(levels[key])[len(levels[key]) // 2]  # median job level of the role
        mix.append(((key[0], key[1], lv), n))
    return mix


def days(rng: random.Random, lo_hi: tuple[int, int]) -> int:
    lo, hi = lo_hi
    return rng.randint(lo, hi)


def main() -> None:
    rng = random.Random(SEED)
    OUT.mkdir(parents=True, exist_ok=True)
    mix = job_mix()
    keys, weights = [m[0] for m in mix], [m[1] for m in mix]
    src_names = list(ASSUMPTIONS["sources (share of applicants)"])
    src_w = list(ASSUMPTIONS["sources (share of applicants)"].values())
    span = (OPEN_TO - OPEN_FROM).days

    reqs, cands = [], []
    cid = 0
    for i in range(1, N_REQUISITIONS + 1):
        dept, role, level = rng.choices(keys, weights)[0]
        opened = OPEN_FROM + dt.timedelta(days=rng.randint(0, span))
        mean = ASSUMPTIONS["applicants per requisition (mean, lognormal sigma 0.45)"][level]
        n_app = max(3, round(rng.lognormvariate(math.log(mean) - 0.45 ** 2 / 2, 0.45)))
        cancelled = rng.random() < ASSUMPTIONS["requisitions cancelled without a hire"]
        cancel_date = opened + dt.timedelta(days=rng.randint(20, 90)) if cancelled else None

        pool = []
        for _ in range(n_app):
            cid += 1
            src = rng.choices(src_names, src_w)[0]
            applied = opened + dt.timedelta(days=int(rng.expovariate(1 / ASSUMPTIONS[
                "application lag after requisition opens (exponential mean, days)"])))
            c = {"candidate_id": f"C{cid:06d}", "requisition_id": f"R{i:04d}", "source": src,
                 "applied_date": applied, "screened_date": None, "interview_date": None,
                 "final_interview_date": None, "offer_date": None, "offer_decision_date": None,
                 "offer_outcome": None, "start_date": None}
            if rng.random() < ASSUMPTIONS["screen pass rate"][src]:
                c["screened_date"] = applied + dt.timedelta(days=days(rng, ASSUMPTIONS["days, applied -> screen"]))
            if c["screened_date"] and rng.random() < ASSUMPTIONS["screen -> first interview rate"]:
                c["interview_date"] = c["screened_date"] + dt.timedelta(
                    days=days(rng, ASSUMPTIONS["days, screen -> first interview"]))
                if rng.random() < ASSUMPTIONS["interview pass rate (first interview -> final round)"]:
                    c["final_interview_date"] = c["interview_date"] + dt.timedelta(
                        days=days(rng, ASSUMPTIONS["days, first interview -> final interview"]))
            pool.append(c)

        # Offers go to finalists one at a time, in order of their final interview.
        filled = None
        finalists = sorted((c for c in pool if c["final_interview_date"]), key=lambda c: c["final_interview_date"])
        last = None
        for c in finalists:
            offer = max(c["final_interview_date"], last or c["final_interview_date"]) + dt.timedelta(
                days=days(rng, ASSUMPTIONS["days, final interview -> offer"]))
            if cancel_date and offer > cancel_date:
                break
            c["offer_date"] = offer
            c["offer_decision_date"] = offer + dt.timedelta(days=days(rng, ASSUMPTIONS["days, offer -> decision"]))
            last = c["offer_decision_date"]
            if rng.random() < ASSUMPTIONS["offer accept rate"][c["source"]]:
                c["offer_outcome"] = "Accepted"
                c["start_date"] = last + dt.timedelta(days=days(rng, ASSUMPTIONS["days, accept -> start (notice period)"]))
                filled = c
                break
            c["offer_outcome"] = "Declined"

        # Observe everything as of SNAPSHOT: later events have not happened yet.
        for c in pool:
            for f in ["screened_date", "interview_date", "final_interview_date", "offer_date",
                      "offer_decision_date", "start_date"]:
                if c[f] and c[f] > SNAPSHOT:
                    c[f] = None
            if c["offer_decision_date"] is None:
                c["offer_outcome"] = "Pending" if c["offer_date"] else None
            if c["applied_date"] <= SNAPSHOT:
                cands.append(c)
        if filled and filled["offer_decision_date"]:
            status, closed = "Filled", filled["offer_decision_date"]
        elif cancelled and cancel_date <= SNAPSHOT:
            status, closed = "Cancelled", cancel_date
        else:
            status, closed = "Open", None
        reqs.append({"requisition_id": f"R{i:04d}", "department": dept, "job_role": role, "job_level": level,
                     "opened_date": opened, "closed_date": closed, "status": status,
                     "hired_candidate_id": filled["candidate_id"] if status == "Filled" else None,
                     "is_simulated": True})

    for name, rows in [("SIMULATED_requisitions.csv", reqs), ("SIMULATED_candidates.csv", cands)]:
        with open(OUT / name, "w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(rows[0]) + (["is_simulated"] if "is_simulated" not in rows[0] else []))
            w.writeheader()
            for r in rows:
                r.setdefault("is_simulated", True)
                w.writerow({k: ("" if v is None else v) for k, v in r.items()})
        print(f"{name}: {len(rows)} rows (SIMULATED, seed {SEED})")


if __name__ == "__main__":
    main()
