#!/usr/bin/env bash
# Downloads the frozen Zenodo data snapshots and verifies them against the
# checksums Zenodo recorded at deposit time. Run this once (or let run.sh
# call it) before `docker compose up`.
set -euo pipefail
cd "$(dirname "$0")"

fetch() {
  local url="$1" dest="$2" md5="$3"
  mkdir -p "$(dirname "$dest")"
  if [ -f "$dest" ] && [ "$(md5sum "$dest" | cut -d' ' -f1)" = "$md5" ]; then
    echo "OK  (cached, checksum verified): $dest"
    return
  fi
  echo "Fetching $dest ..."
  curl -sL "$url" -o "$dest"
  local got
  got="$(md5sum "$dest" | cut -d' ' -f1)"
  if [ "$got" != "$md5" ]; then
    echo "CHECKSUM MISMATCH for $dest"
    echo "  expected: $md5"
    echo "  got:      $got"
    echo "The Zenodo record may have changed, or the download was corrupted. Aborting."
    exit 1
  fi
  echo "OK  (downloaded, checksum verified): $dest"
}

# --- TWR medical dataset : https://doi.org/10.5281/zenodo.21735953 ---
fetch "https://zenodo.org/records/21735953/files/documents.db?download=1" \
      "Trust-Weighted-Ranking/data_in/documents.db" \
      "47f05479d11a0aaed3f14ea77d11de8a"

fetch "https://zenodo.org/records/21735953/files/scimagojr%202025.csv?download=1" \
      "Trust-Weighted-Ranking/data_in/scimagojr 2025.csv" \
      "71daa9a46465c5b6c677429acf062edb"

fetch "https://zenodo.org/records/21735953/files/seed_pubmed_data.xml?download=1" \
      "Trust-Weighted-Ranking/data_in/seed_pubmed_data.xml" \
      "9c42cc479ec5cffb66e0d79bcbf3896f"

# --- LTWR CVE data : https://doi.org/10.5281/zenodo.21727536 ---
fetch "https://zenodo.org/records/21727536/files/corpus.json?download=1" \
      "LTWR/data_in/corpus.json" \
      "22939db28a97a7167969d1f3d2916c79"

fetch "https://zenodo.org/records/21727536/files/ground_truth.json?download=1" \
      "LTWR/data_in/ground_truth.json" \
      "614696f08512ae6c39944fe59c8091aa"

fetch "https://zenodo.org/records/21727536/files/queries.json?download=1" \
      "LTWR/data_in/queries.json" \
      "b360a41a7b33102e4ecc264eda23d0e0"

fetch "https://zenodo.org/records/21727536/files/train_test_split.json?download=1" \
      "LTWR/data_in/train_test_split.json" \
      "a509228d320250d3e63f8c1158b7390d"

# --- .env files (baked into build context, not secret — just config) ---
if [ ! -f "Trust-Weighted-Ranking/.env" ]; then
cat > "Trust-Weighted-Ranking/.env" << 'ENVEOF'
NCBI_EMAIL = " "

DOC_DB_PATH = "./data_in/documents.db"
SJR_CSV_PATH = "./data_in/scimagojr 2025.csv"

SEED_QUERIES_PATH = "./data_in/seed_queries.json"
QUERIES_PATH = "./data_in/queries.json"

OUTPUT_DIR = "./eval_results"
EVAL_LOG_PATH = "./data_out/pipeline_audit_log.csv"
ENVEOF
echo "Wrote Trust-Weighted-Ranking/.env"
fi

if [ ! -f "LTWR/.env" ]; then
cat > "LTWR/.env" << 'ENVEOF'
EMAIL=" "
ENVEOF
echo "Wrote LTWR/.env"
fi

echo
echo "NOTE: queries.json and seed_queries.json are not on the Zenodo record;"
echo "they're already checked into Trust-Weighted-Ranking/data_in/ in the"
echo "repo itself, so no download is needed for those two."
echo
echo "All other data verified against Zenodo checksums:"
echo "  TWR  data  DOI: 10.5281/zenodo.21735953"
echo "  LTWR data  DOI: 10.5281/zenodo.21727536"
