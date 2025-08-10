> What are the highest ROI bash tools I can build to leverage in my day to day development tasks for both personal and professional projects?

Love this question. “Highest ROI” for shell stuff = anything that 1) you do >2–3×/week, 2) touches multiple tools (git, Docker, package managers, CI), or 3) reduces context switches. Here’s a tight, battle-tested set you can build fast and actually use daily.

---

# The Big 5 (start here)

1. **`proj` – project switcher + bootstrap**

* **What it does:** cd into a repo with fuzzy find, auto-loads per-project env (direnv), starts services (docker-compose up -d), opens editor/tmux layout, runs status checks.
* **Why ROI:** Kills setup friction many times per day.
* **Core idea (zsh/bash both fine):**

  ```bash
  #!/usr/bin/env bash
  set -Eeuo pipefail
  proj_root="${PROJ_ROOT:-$HOME/code}"
  sel="$(fd . "$proj_root" -t d -d 2 | fzf)"
  [[ -z "${sel:-}" ]] && exit 1
  cd "$sel"
  command -v direnv >/dev/null && eval "$(direnv export bash)" || true
  [[ -f .ops/devup ]] && ./.ops/devup || docker compose up -d
  [[ -f .tmux.layout ]] && tmux new-session "bash -lc 'tmux source-file .tmux.layout'"
  ```

  Tip: keep per-project `./.ops/devup` small and idempotent.

2. **`issue` – ticket → branch → commit scaffolding**

* **What it does:** Pulls ticket data (via `gh` or API), creates branch `feat/<id>-kebab-title`, seeds commit/PR templates, opens TODOs file.
* **Why ROI:** Standardizes naming & speeds PR flow.
* **Extras:** Auto-assign labels, move card to “In Progress,” set default estimate (you like 3 points), create a changelog stub.

3. **`devdb` – one button DB lifecycle**

* **What it does:** `devdb reset|migrate|seed|dump|load` across stacks (Rails, Node/Prisma, Supabase). Detects project type and runs the right commands.
* **Why ROI:** DB thrash is constant; make it boring.
* **Sketch:**

  ```bash
  case "${1:-}" in
    reset)   if [[ -f bin/rails ]]; then bin/rails db:drop db:create db:migrate
             elif [[ -f package.json ]]; then npx prisma migrate reset --force
             elif [[ -f supabase/config.toml ]]; then supabase db reset
             fi ;;
    dump)    pg_dump "$DATABASE_URL" > .tmp/dev.dump.sql ;;
    *) echo "usage: devdb {reset|migrate|seed|dump|load}" ;;
  esac
  ```

4. **`q` – fast code search + preview**

* **What it does:** `q "needle"` -> ripgrep+fzf preview with bat; open file+line in your editor.
* **Why ROI:** Faster than IDE search, works anywhere.
* **Sketch:**

  ```bash
  rg --line-number --hidden -S "${1:?query}" \
    | fzf --delimiter : --nth 3.. --preview 'bat --style=numbers --color=always {1} --line-range {2}:+' \
    | awk -F: '{print "+"$2" "$1}' | xargs -r ${EDITOR:-code} -g
  ```

5. **`ship` – release assistant**

* **What it does:** Verifies clean state, runs tests/lint, updates version, generates CHANGELOG from commits, tags, pushes, optionally triggers CI release workflow.
* **Why ROI:** Makes releases safe and consistent.

# High-Impact “Support” Tools (quick wins)

* **`guard` – preflight checks**: node/ruby versions, env vars, ports free, migrations pending, feature flags. Exit with helpful fixes.
* **`logs` – smart tailing**: multiplex `docker compose logs -f` with grep presets (errors, slow requests, job failures) and timestamps.
* **`envpick` – environment switcher**: pick `.env.*` with fzf and export it into current shell (or write `.env.local`).
* **`lintfix` – opinionated format+lint**: runs prettier/eslint/rubocop/go fmt based on what’s detected; supports staged-only.
* **`bench` – micro-bench helper**: time a command N runs, compute p50/p95, compare two commands (A/B) for quick perf checks.
* **`tkt` – time tracker**: start/stop, annotate, and export CSV/Markdown (you already have scripts—wrap them into a nicer UX).
* **`snap` – local backups & sync**: rsync dotfiles, db dumps, and notes to a chosen target; prune by retention policy.

# Effort → Impact cheat sheet

* **1–2 hrs, huge impact:** `proj`, `q`, `devdb`
* **Half-day, big impact:** `issue`, `ship`, `logs`
* **1 hr, steady value:** `guard`, `envpick`, `lintfix`, `bench`

# Make them feel pro: shared scaffolding

Drop a tiny standard library every script can source:

```bash
# ~/.tooling/lib.sh
set -Eeuo pipefail

log()  { printf "[%(%H:%M:%S)T] %s\n" -1 "$*" >&2; }
die()  { log "ERROR: $*"; exit 1; }
ok()   { log "OK: $*"; }
need() { command -v "$1" >/dev/null || die "Missing dep: $1"; }
retry(){ local n=0; local max=${2:-3}; until "$1"; do ((n++<max)) || return 1; sleep $((2**n)); done; }
tmpf() { mktemp "${TMPDIR:-/tmp}/tool.XXXXXX"; }
trap 's=$?; [[ $s -ne 0 ]] && log "failed with $s";' EXIT
```

Then your tools start with:

```bash
#!/usr/bin/env bash
. "${TOOL_LIB:-$HOME/.tooling/lib.sh}"
```

# Glue it into your world

* **zsh users:** wrap executables with lightweight zfunctions for completion; keep the scripts in `~/.tooling/bin` and add it to `$PATH`.
* **Git integration:** wire `guard`, `lintfix`, and tests into `pre-commit` and `pre-push` (but keep fast paths; use `--staged`).
* **CI parity:** have `guard` and `ship` call the same make targets CI uses (`make test`, `make build`, etc.) so local ≈ CI.
* **Per-project config:** read `.toolrc` (INI or env) so the same tools adapt to Rails vs Supabase vs Node.

# Concrete next steps (weekend plan)

1. Create `~/.tooling/{bin,templates}` and `~/.tooling/lib.sh`.
2. Build **`proj`**, **`q`**, and **`devdb`** first. You’ll feel them immediately.
3. Add **`issue`** (use `gh api`), then **`ship`** once you have a release you actually care about.
4. Backfill **`guard`**, **`lintfix`**, and **`logs`** as 15–30 min snacks.
