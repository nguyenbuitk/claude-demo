# Technology Stack: v1.0 Feature Expansion

**Project:** Claude Demo — Docker GHCR Push + Deadline Highlighting + Completion History
**Researched:** 2026-03-23
**Scope:** Stack additions for the three new milestone features only. Existing pytest CI stack is already resolved (see prior research round).

---

## Context: What Already Exists

| Component | Current state |
|-----------|--------------|
| `actions/checkout@v4` | Confirmed in existing workflows |
| `actions/setup-python@v5` | Established for pytest CI |
| Runner: `ubuntu-latest` | All existing workflows |
| Flask 3.1.3 / Jinja2 3.1.2 | `requirements.txt` |
| Python 3.12 | Dockerfile + CI |
| `Task` dataclass | `tasks.py` — has `due_date`, `done`, `created_at` |
| `storage.py` | Direct JSON serialization; explicit field list in `save_tasks()` |

---

## Feature 1: Docker Build + Push to GHCR on Merge to Main

### Required GitHub Actions

| Action | Version | Purpose | Confidence |
|--------|---------|---------|------------|
| `actions/checkout@v4` | v4 | Check out code | HIGH — already in repo |
| `docker/setup-buildx-action` | v4 | Enable BuildKit (required for `build-push-action`) | HIGH — v4.0.0 released March 2025; same Node 24 runtime cohort as other v4 actions |
| `docker/login-action` | v4 | Authenticate to ghcr.io using GITHUB_TOKEN | HIGH — v4.0.0 released March 2025; current stable |
| `docker/metadata-action` | v6 | Generate image tags (commit SHA + latest) | HIGH — v6.0.0 released March 2025; current stable |
| `docker/build-push-action` | v7 | Build and push the image | HIGH — v7.0.0 released March 2025; current stable |

**Note:** All four Docker actions jumped to Node 24 runtime in the March 2025 release wave. Using v4/v6/v7 as listed above keeps the runtime consistent across actions and avoids deprecation warnings about older Node versions.

### Authentication to ghcr.io

Use `GITHUB_TOKEN`. No PAT or external secret needed.

```yaml
- uses: docker/login-action@v4
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

The workflow job **must** declare `packages: write` permission or the push will be rejected with a 403. The `contents: read` permission is also required for checkout.

```yaml
permissions:
  contents: read
  packages: write
```

**Confidence:** HIGH — this is the canonical GHCR authentication pattern documented by GitHub. GITHUB_TOKEN is scoped to the repository, so no manual secret rotation is required.

### Image Tagging Strategy

Use `docker/metadata-action@v6` with two tag types:

```yaml
- id: meta
  uses: docker/metadata-action@v6
  with:
    images: ghcr.io/nguyenbuitk/claude-demo
    tags: |
      type=sha
      type=raw,value=latest,enable={{is_default_branch}}
```

- `type=sha` produces `ghcr.io/nguyenbuitk/claude-demo:sha-<7-char-commit>` (e.g., `sha-860c190`).
- `type=raw,value=latest,enable={{is_default_branch}}` only applies the `latest` tag when the triggering branch is the repository's default branch (main). This prevents PRs from accidentally overwriting `latest`.

**Confidence:** HIGH — verified against official Docker docs at `docs.docker.com/build/ci/github-actions/manage-tags-labels/`.

### Canonical Workflow Skeleton

```yaml
name: docker-publish

on:
  push:
    branches: [main]

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - uses: docker/setup-buildx-action@v4

      - uses: docker/login-action@v4
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - id: meta
        uses: docker/metadata-action@v6
        with:
          images: ghcr.io/nguyenbuitk/claude-demo
          tags: |
            type=sha
            type=raw,value=latest,enable={{is_default_branch}}

      - uses: docker/build-push-action@v7
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

This must be a **new workflow file** (e.g., `.github/workflows/docker-publish.yml`), separate from the pytest CI workflow. Do not mix test-on-PR and build-on-merge logic into a single file.

---

## Feature 2: Deadline Highlighting (Overdue = Red, Due ≤3 Days = Yellow)

### Approach: Pure Python + Jinja2 + CSS Classes. No JavaScript.

The existing stack (Flask + Jinja2 + plain HTML) is sufficient. No new libraries are needed.

#### Python side (in `web.py` route, before rendering)

Compute deadline status in the route handler and pass it to the template, or compute it inline in Jinja2 using `now()`. The cleanest approach is to pass today's date as a template variable and compare in Jinja2 using its built-in filters.

Pass `today` and `deadline_delta` as context:

```python
from datetime import date, timedelta

# In the GET / route:
today = date.today()
deadline_soon = today + timedelta(days=3)
return render_template("index.html", tasks=tasks, today=today, deadline_soon=deadline_soon, ...)
```

#### Jinja2 template logic

```jinja2
{% set status_class = "" %}
{% if task.due_date %}
  {% if task.due_date < today.isoformat() %}
    {% set status_class = "overdue" %}
  {% elif task.due_date <= deadline_soon.isoformat() %}
    {% set status_class = "due-soon" %}
  {% endif %}
{% endif %}
<tr class="{{ status_class }}">
```

String comparison of ISO date strings (`YYYY-MM-DD`) is lexicographically correct — no date parsing needed in the template.

#### CSS (in `templates/index.html` or a linked stylesheet)

```css
tr.overdue   { background-color: #fde8e8; }  /* light red  */
tr.due-soon  { background-color: #fefce8; }  /* light yellow */
```

**Do NOT add:** any JavaScript date libraries, moment.js, day.js, or any new npm/Python package. This is a pure server-rendered comparison.

**Confidence:** HIGH — Jinja2 3.1.x supports variable assignment (`{% set %}`), ISO string comparison is reliable, and no new dependencies are introduced.

---

## Feature 3: Task Completion History

### Does `Task` need a `completed_at` field?

**Yes. Add `completed_at: Optional[str] = None` to the `Task` dataclass.**

Rationale: The existing `done: bool` field only records *whether* a task is complete, not *when*. A completion history view requires the timestamp. Without it, there is no data to display.

**Proposed change to `tasks.py`:**

```python
completed_at: Optional[str] = None   # ISO datetime, set when task is marked done
```

Update the `complete()` method to set it:

```python
def complete(self):
    self.done = True
    self.completed_at = datetime.now().isoformat()
```

### Storage changes required

**`save_tasks()` must be updated** to include `completed_at` in the serialized dict. The current implementation uses an explicit field list — any new field must be added manually or the data will be silently dropped on the next save.

```python
# Add to the dict in save_tasks():
"completed_at": task.completed_at,
```

**`load_tasks()` is backward-compatible.** `Task(**item)` will accept dicts without `completed_at` because the field has a default of `None`. Existing `tasks.json` records will load without error and `completed_at` will be `None`.

**No migration script is needed** — old records simply show no completion date.

### Filtering in the route

The existing `?show_done=0` filter hides completed tasks. The new history view is a separate route (e.g., `GET /history`) that returns only tasks where `done is True`, sorted by `completed_at` descending. No new storage mechanism needed — load all tasks, filter in Python.

**Confidence:** HIGH — derived from direct inspection of `tasks.py` and `storage.py`.

---

## What NOT to Add

| Item | Reason to skip |
|------|----------------|
| Any JS framework (htmx, Alpine, React) | All three features are server-rendered; no interactivity needed |
| A database (SQLite, Postgres) | Out of scope; JSON file storage is the stated design |
| `python-dateutil` or `arrow` | ISO string comparison in Jinja2 is sufficient for highlighting; no parsing library needed |
| `pytest-cov` or coverage reporting | Explicitly deferred in PROJECT.md |
| A separate `completed_tasks.json` | Unnecessary split; filter in-memory at query time |
| Docker layer caching in the workflow | Nice-to-have; adds complexity (cache action config); defer to a later phase |

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| GHCR auth | `GITHUB_TOKEN` | PAT stored as secret | PAT requires rotation, broader scope, manual setup; GITHUB_TOKEN is zero-config and scoped |
| Image tagging | `type=sha` + `type=raw,value=latest` | Manual `${{ github.sha }}` | `docker/metadata-action` handles OCI labels, multi-platform metadata, and edge cases automatically |
| Deadline comparison | ISO string comparison in Jinja2 | Parse `datetime` in template | Jinja2 has no `datetime.strptime`; string comparison is simpler and correct for `YYYY-MM-DD` |
| Completion timestamp | New `completed_at` field | Derive from `updated_at` | No `updated_at` field exists; adding `completed_at` is explicit and unambiguous |
| History view | New `GET /history` route | Reuse `GET /` with filter param | Separate route is cleaner; avoids complicating the existing `?show_done` filter logic |

---

## Summary of Required Changes

| File | Change |
|------|--------|
| `.github/workflows/docker-publish.yml` | New file — GHCR build+push workflow |
| `tasks.py` | Add `completed_at: Optional[str] = None`; update `complete()` to set it |
| `storage.py` | Add `"completed_at": task.completed_at` to `save_tasks()` dict |
| `web.py` | Pass `today` + `deadline_soon` to template; add `GET /history` route |
| `templates/index.html` | Add CSS classes for `.overdue` / `.due-soon`; add Jinja2 conditional logic; add history view |

No new Python packages. No new npm packages. No changes to `requirements.txt`.

---

## Sources

- Codebase inspection: `tasks.py`, `storage.py`, `requirements.txt`, `Dockerfile`, `.github/workflows/`
- [docker/build-push-action releases — v7.0.0 confirmed](https://github.com/docker/build-push-action/releases) — HIGH confidence
- [docker/login-action releases — v4.0.0 confirmed](https://github.com/docker/login-action/releases) — HIGH confidence
- [docker/metadata-action releases — v6.0.0 confirmed](https://github.com/docker/metadata-action/releases) — HIGH confidence
- [docker/setup-buildx-action releases — v4.0.0 confirmed](https://github.com/docker/setup-buildx-action/releases) — HIGH confidence
- [Docker docs: Manage tags and labels with GitHub Actions](https://docs.docker.com/build/ci/github-actions/manage-tags-labels/) — HIGH confidence
- [GitHub Actions: Pushing container images to GHCR](https://dev.to/willvelida/pushing-container-images-to-github-container-registry-with-github-actions-1m6b) — MEDIUM confidence (community article, corroborated by official patterns)
