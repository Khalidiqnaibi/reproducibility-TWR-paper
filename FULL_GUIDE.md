# Full guide: making TWR + LTWR reproducible on GitHub

You're on Windows with Git for Windows already installed. Everything below
uses **Git Bash** (not PowerShell) because `fetch_data.sh` / `run.sh` are
bash scripts — right-click any folder in File Explorer → "Git Bash Here" to
open it there.

---

## 0. Prerequisites (one-time, per machine)

1. **Docker Desktop** — https://www.docker.com/products/docker-desktop/
   Accept the WSL 2 prompt during install, reboot if asked, then launch it
   and wait for "Docker Desktop is running" in the system tray.
   Verify from Git Bash:
   ```bash
   docker --version
   docker compose version
   ```
2. **Git** — you already have this (Git for Windows).

---

## 1. Create the reproducibility repo

```bash
mkdir "reproducibility-TWR-paper" && cd "reproducibility-TWR-paper"
git init
```

Save these 6 files (from earlier in this chat) directly into this folder:
`Dockerfile.twr`, `Dockerfile.ltwr`, `.dockerignore`, `docker-compose.yml`,
`fetch_data.sh`, `run.sh`, `REPRODUCIBILITY.md`.

---

## 2. Bring in TWR and LTWR as submodules

Submodules (not plain clones) so this repo always points at a specific,
citable commit of each — critical for "reproduces the paper" claims.

```bash
git submodule add https://github.com/Khalidiqnaibi/Trust-Weighted-Ranking.git
git submodule add https://github.com/Khalidiqnaibi/LTWR.git
```

Copy the per-repo Docker files in:

```bash
cp Dockerfile.twr  Trust-Weighted-Ranking/Dockerfile
cp Dockerfile.ltwr LTWR/Dockerfile
cp .dockerignore   Trust-Weighted-Ranking/.dockerignore
cp .dockerignore   LTWR/.dockerignore
```

Since submodules are separate git repos, commit the Dockerfiles inside each
one too:
```bash
cd Trust-Weighted-Ranking
git add Dockerfile .dockerignore
git commit -m "Add Dockerfile for reproducible one-command runs"
git push
cd ../LTWR
git add Dockerfile .dockerignore
git commit -m "Add Dockerfile for reproducible one-command runs"
git push
cd ..
```

---

## 3. Fetch the frozen data + generate `.env` files

```bash
chmod +x fetch_data.sh run.sh
./fetch_data.sh
```

This downloads, MD5-verifies, and places:
- `Trust-Weighted-Ranking/data_in/documents.db`
- `Trust-Weighted-Ranking/data_in/scimagojr 2025.csv`
- `Trust-Weighted-Ranking/data_in/seed_pubmed_data.xml`
  (DOI: [10.5281/zenodo.21735953](https://doi.org/10.5281/zenodo.21735953))
- `LTWR/data_in/corpus.json`, `ground_truth.json`, `queries.json`,
  `train_test_split.json`
  (DOI: [10.5281/zenodo.21727536](https://doi.org/10.5281/zenodo.21727536))

`queries.json` and `seed_queries.json` for TWR are **not** re-downloaded —
they're already checked into the `Trust-Weighted-Ranking` repo, so the
script leaves them alone.

It also writes `Trust-Weighted-Ranking/.env` and `LTWR/.env` with exactly
the contents you specified. If you ever need to edit them, edit the copies
inside each submodule directly (`Trust-Weighted-Ranking/.env`, `LTWR/.env`)
— `fetch_data.sh` won't overwrite an `.env` that already exists.

---

## 4. Run it

```bash
./run.sh
```

This calls `fetch_data.sh` (idempotent — skips anything already verified),
then `docker compose up --build`. First run pulls base images and installs
dependencies, so expect several minutes and a few GB of downloads. Every
run after that is fast (Docker caches layers).

Outputs land on your host at:
```
results/twr/data_out/         <- documents.db writes, pipeline_audit_log.csv
results/twr/eval_results/      <- figures, tables, stats output
results/ltwr/                  <- LTWR's eval_results
```

---

## 5. Sanity-check reproducibility before you trust it

Don't just confirm it runs on your dev machine — that's not proof anyone
else can reproduce it. Clone fresh into a throwaway folder and run there:

```bash
cd /c/Users/MSI/Documents/GitHub
git clone --recurse-submodules https://github.com/<you>/reproducibility-TWR-paper.git repro-test
cd repro-test
./run.sh
```

If this works from a clean clone with nothing manually copied in, you have
a genuine one-click artifact.

---

## 6. Push everything

```bash
git add .
git commit -m "Initial one-click reproducibility harness for TWR + LTWR"
git push -u origin main
```

(Create the empty GitHub repo first via github.com if you haven't.)

---

## 7. Make it citable (do this for the actual paper submission)

1. **DOI badges** — add these to the top of `Trust-Weighted-Ranking/README.md`
   and `LTWR/README.md` respectively:
   ```md
   [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21735953.svg)](https://doi.org/10.5281/zenodo.21735953)
   ```
   ```md
   [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21727536.svg)](https://doi.org/10.5281/zenodo.21727536)
   ```
2. **Tag a release** matching your camera-ready submission:
   ```bash
   git tag -a v1.0-camera-ready -m "Camera-ready version submitted to <venue>"
   git push origin v1.0-camera-ready
   ```
3. **Archive the reproducibility repo itself on Zenodo** (GitHub-Zenodo
   integration: https://zenodo.org/account/settings/github/ — flip the
   toggle for this repo, then cut a GitHub release; Zenodo mints a DOI
   automatically). Cite that DOI, plus the two data DOIs, in your paper's
   Data & Code Availability section.
4. Cite the frozen data DOIs (not `scimagojr.com`) anywhere the paper
   describes data sources.

---

## 8. Known gaps worth closing before camera-ready

- `.env.example` in TWR uses `documents.db` / `scimagojr 2025.csv` naming
  that didn't always match `app.py`'s hardcoded fallback defaults
  (`document.db`, `scimagojr_2025.csv`). The `.env` you supplied is now the
  single source of truth and matches what's actually downloaded, but it's
  worth double-checking `app.py` reads these via `os.getenv(...)` rather
  than a hardcoded path anywhere.
- LTWR's `requirements.txt` uses unpinned `>=` versions. For "the exact
  thing that produced these numbers," pin them:
  ```bash
  docker run --rm <ltwr-image> pip freeze > requirements.lock.txt
  ```
  and commit that alongside the original.
- Consider a CI job (GitHub Actions) that runs `./run.sh` on every push to
  `main` and fails if key metrics drift from a stored baseline — catches a
  dependency silently changing your results before a reviewer does. Say
  the word and I'll draft that workflow.
