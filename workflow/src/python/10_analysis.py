from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "data" / "raw"
PROC = ROOT / "data" / "processed"
OUT_TABLES = ROOT / "output" / "tables"
OUT_FIGS = ROOT / "output" / "figures"

for p in (PROC, OUT_TABLES, OUT_FIGS):
    p.mkdir(parents=True, exist_ok=True)

# TODO: load data and run analysis
