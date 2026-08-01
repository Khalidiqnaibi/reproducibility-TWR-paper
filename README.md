# TWR / LTWR Reproducibility

This repo lets you rebuild and rerun everything behind the Trust-Weighted Retrieval (TWR) paper and its learned follow-up (LTWR) without setting up Python environments by hand. You need Docker, that's it.

Both experiment pipelines live in their own repos and are pulled in here as submodules, pinned to the exact commits used for the results in the paper:

- [Trust-Weighted-Ranking](https://github.com/Khalidiqnaibi/Trust-Weighted-Ranking) — the original TWR pipeline, medical/PubMed domain
- [LTWR](https://github.com/Khalidiqnaibi/LTWR) — learned trust weights, CVE domain

## What you need

- Docker Desktop, with WSL2 backend if you're on Windows ([docker.com](https://www.docker.com/products/docker-desktop/))
- Enough disk space — the built images pull in torch, faiss, sentence-transformers, so budget a few GB
- That's it. No local Python, no manually installed dependencies.

## Running it

```bash
git clone --recurse-submodules https://github.com/Khalidiqnaibi/reproducibility-TWR-paper.git
cd reproducibility-TWR-paper
./run.sh
```

`run.sh` does two things: pulls the frozen datasets from Zenodo and checks them against known checksums, then builds and runs both pipelines with `docker compose`.

First run takes a while — it's downloading and installing everything from scratch (mostly torch, which alone is over 500MB). After that, Docker caches the layers, so rebuilds after a code change are quick. Rebuilds only get slow again if `requirements.txt` changes in either repo.

Results show up on your machine under:

```
results/twr/eval_results/
results/twr/data_out/
results/ltwr/
```

## Where the data comes from

Neither pipeline's raw data lives in this repo or the submodules — it's pulled from Zenodo, frozen at the exact version used for the paper's numbers:

- TWR's medical corpus, PubMed seed data, and the SCImago journal rank snapshot: [10.5281/zenodo.21735953](https://doi.org/10.5281/zenodo.21735953)
- LTWR's CVE corpus, ground truth, and train/test split: [10.5281/zenodo.21727536](https://doi.org/10.5281/zenodo.21727536)

I froze these on purpose. SCImago's rankings, for instance, aren't static — they update over time, so re-scraping them later would silently give you different trust weights than the ones the paper reports. `fetch_data.sh` checksums every download so if either Zenodo record ever changes, or a download gets corrupted partway, it'll fail loudly instead of quietly running on the wrong data.

## Config

Each pipeline reads its own `.env`, generated automatically the first time you run `fetch_data.sh`. You shouldn't need to touch these, but if you do, edit them directly in `Trust-Weighted-Ranking/.env` and `LTWR/.env` — the script won't overwrite one that already exists.

## If something breaks

A few things I ran into while setting this up, in case they save you the same debugging loop:

- **`docker: command not found`** — Docker Desktop isn't running, or isn't on PATH. Restart the app, and if you're on Git Bash specifically, close and reopen the terminal after installing (PATH doesn't refresh in an already-open shell).
- **Virtualization errors on Windows** — needs VT-x/SVM enabled in BIOS. Check Task Manager → Performance → CPU for the "Virtualization" field.
- **Build takes forever every single time, even for a one-line change** — usually means the model-download step or the pip install got invalidated unnecessarily. Both Dockerfiles here are ordered so that code edits don't force a re-download; if you're seeing this, check whether `requirements.txt` actually changed.

## Updating to a newer commit of either pipeline

```bash
git submodule update --remote --merge
git add Trust-Weighted-Ranking LTWR
git commit -m "Sync submodules"
git push
```

Then rebuild with `docker compose up --build`.
