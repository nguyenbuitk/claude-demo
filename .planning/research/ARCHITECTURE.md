# Architecture Patterns

**Domain:** Flask task manager — milestone v1.0 feature integration
**Researched:** 2026-03-23
**Scope:** How three new capabilities (DevOps CI/CD, deadline highlighting, completion history) integrate into the existing flat architecture.

---

## Existing Architecture Snapshot

The app is intentionally flat — no service layer, no ORM, no abstraction between routes and storage.

```
tasks.py        — Task dataclass (data model only, .complete() is only method)
storage.py      — load_tasks() / save_tasks() — direct JSON file read/write
web.py          — Flask routes, call storage directly, build template context
templates/
  index.html    — single Jinja2 template, shared list + edit view via `editing` var
tasks.json      — persistence, flat list of dicts
.github/
  workflows/    — 4 existing files: claude.yml, claude-code-review.yml,
                   hello.yml, main.yml — none run pytest
```

Critical existing-state observations:

1. `tasks.py` already has `due_date: Optional[str] = None` field.
2. `storage.py` already serializes `due_date`.
3. `web.py` already computes `today = date.today().isoformat()` and passes it to the template.
4. `index.html` already has CSS class `.overdue` (lines 93-94) and already computes the `overdue` Jinja2 variable (lines 222-223): `{% set overdue = task.due_date and task.due_date < today and not task.done %}`.

This means **deadline highlighting for overdue tasks is already partially implemented**. The gap is the yellow "warning" class for tasks due within 3 days.

---

## Feature 1: GitHub Actions — Test + Build/Push Workflow

### Recommended approach: new dedicated workflow file

**Decision: create `.github/workflows/ci.yml`, do not extend any existing workflow.**

The four existing workflows serve unrelated purposes:
- `claude.yml` and `claude-code-review.yml` — Claude AI agent and code review automation
- `hello.yml` and `main.yml` — demo hello-world jobs that trigger on all pushes

PROJECT.md records the decision explicitly: "Separate workflow file for tests — keep test CI distinct from Claude Code review workflows." This reasoning extends to the Docker build/push job — both belong together in `ci.yml` since they form a single pipeline.

### Job chaining: the `needs` keyword

GitHub Actions chains jobs using `needs`. The build+push job declares `needs: test` and only runs after the test job completes successfully. Both jobs live in the same workflow file so they share the same trigger and appear as a unified pipeline in the PR/commit checks UI.

Structural outline:

```yaml
# .github/workflows/ci.yml

on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      # checkout, setup python 3.12, pip install -r requirements.txt pytest, run pytest

  build-and-push:
    needs: test                   # sequential gate — skipped if test fails
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    permissions:
      packages: write
      contents: read
    steps:
      # docker/login-action to ghcr.io, docker/build-push-action
```

Key integration points:
- `needs: test` is the only mechanism needed — GitHub Actions skips `build-and-push` automatically when `test` fails.
- The `if:` guard restricts Docker push to main branch pushes only. Tests still run on every PR. This matches PROJECT.md: "push to registry is sufficient" / "build and push Docker image on merge to main."
- `pytest` is not in `requirements.txt` (production deps only) — the test job must `pip install -r requirements.txt pytest` explicitly.
- GHCR image name: `ghcr.io/nguyenbuitk/claude-demo` (from PROJECT.md).
- GHCR authentication uses the automatically-provided `GITHUB_TOKEN` with `permissions: packages: write`. No manual secret required.
- The `Dockerfile` is already correct and complete — the build job uses it as-is with no modifications.

### Files touched

| File | Change |
|------|--------|
| `.github/workflows/ci.yml` | New file — entire DevOps workstream lives here |
| No other files | DevOps workstream is fully isolated from application code |

---

## Feature 2: Deadline Highlighting

### Current state — partial implementation already exists

From `index.html`:
- Line 93: `tbody tr.overdue td { background: #fff3cd; }` — CSS exists
- Line 94: `tbody tr.overdue:hover td { background: #ffeaa7; }` — CSS exists
- Lines 222-223: `{% set overdue = task.due_date and task.due_date < today and not task.done %}` — Jinja2 logic exists

What is missing: a second CSS class (e.g., `.warning`) for tasks due within 3 days, and the Jinja2 logic to assign it.

### Recommended approach: Jinja2 template filter registered in web.py

Three placement options exist for the date arithmetic:

**Option A — Pure Jinja2 inline arithmetic.** Not possible — Jinja2 cannot subtract date strings without a filter or extension.

**Option B — Python computes full CSS class per task in the route handler.** Builds a `{task.id: css_class}` dict and passes it to the template. Works, but adds iteration overhead in the route and couples presentation logic to the route handler.

**Option C — Jinja2 template filter (recommended).** Register a `days_until` filter in `web.py`. The filter converts a date string to an integer day count. The template uses it inline, consistent with the existing `overdue` computation pattern already in the template.

```python
# in web.py, after app = Flask(__name__)
from datetime import date as date_cls

@app.template_filter('days_until')
def days_until_filter(due_date_str):
    if not due_date_str:
        return None
    due = date_cls.fromisoformat(due_date_str)
    return (due - date_cls.today()).days
```

Template extension:
```jinja2
{% set days = task.due_date | days_until %}
{% set overdue = task.due_date and task.due_date < today and not task.done %}
{% set warning = days is not none and days >= 0 and days <= 3 and not task.done %}
<tr class="{{ 'done' if task.done else '' }}{{ ' overdue' if overdue else '' }}{{ ' warning' if warning else '' }}">
```

Note: `warning` must check `days >= 0` to avoid double-classing a task that is already overdue (past due date returns negative days). The `overdue` class takes precedence.

### Color semantics

The existing `.overdue` color (`#fff3cd`) is amber/yellow. For a meaningful red/yellow distinction:
- `.overdue` (past due) should be red — recommend `#fde8e8` background (matches `.badge-high` palette already in the template).
- `.warning` (due within 3 days) should be amber/yellow — use the current `#fff3cd` value.

This requires updating the existing `.overdue` CSS rule color and adding a new `.warning` CSS rule. Both changes are localized to the `<style>` block in `index.html`.

### Files touched

| File | Change |
|------|--------|
| `web.py` | Add `days_until` template filter (~6 lines) |
| `templates/index.html` | Add `.warning` CSS rule; adjust `.overdue` color to red; extend row class Jinja2 logic |
| No data model changes | `due_date` already on Task; `today` already in template context |

---

## Feature 3: Completion History

### Data model: Task needs a `completed_at` field

**Add `completed_at: Optional[str] = None` to the Task dataclass.**

Without it, the `/history` route can show completed tasks but cannot show when they were completed — the feature spec requires "ngày hoàn thành" (completion date). `created_at` is the wrong field. The field must be set at completion time.

### Backwards-compatibility strategy — no migration needed

`storage.py` reconstructs Task objects via `Task(**item)` where `item` is a dict from the JSON file. Existing records in `tasks.json` do not have a `completed_at` key, so `**item` will not pass that argument. This is safe because `completed_at = None` is the dataclass default — missing keys in JSON translate to the default value on load.

On the next write of any task (add, complete, edit, delete triggers `save_tasks()`), all tasks in memory are reserialized and will include `"completed_at": null` or the actual timestamp. This is transparent and requires no one-time migration script.

### Changes required

**tasks.py:**
- Add field: `completed_at: Optional[str] = None`
- Update `.complete()`:
  ```python
  def complete(self):
      self.done = True
      self.completed_at = datetime.now().isoformat()
  ```
  This is the only location where `done` is set to True, so this is the complete and correct integration point. No other code paths need updating.

**storage.py:**
- Add `"completed_at": task.completed_at` to the serialization dict in `save_tasks()`.
- No change to `load_tasks()` — `Task(**item)` handles the missing key via the dataclass default.

**web.py:**
- Add `GET /history` route:
  ```python
  @app.route("/history")
  def history():
      tasks = load_tasks()
      completed = [t for t in tasks if t.done]
      completed.sort(key=lambda t: t.completed_at or "", reverse=True)
      return render_template("history.html", tasks=completed)
  ```
  Tasks completed before this feature was deployed will have `completed_at = None` and sort to the end (empty string sorts before any ISO timestamp).

**templates/history.html:**
- New template. Shows: ID, title, priority, completed_at (or "—" if None), tags. No action buttons except optional delete.
- Reuse the same CSS header (inline or extracted to a base layout). For v1 scope, inline duplication is acceptable to keep changes minimal.

**templates/index.html:**
- Add a "History" nav link in the header. One-line addition, isolated to the `<header>` block.

### Decision: new /history route, not reusing GET /

`GET /` already has two modes (list and edit via `editing` context variable). Adding a third history mode would require more `{% if %}` branches throughout the template, which is already at 222 lines with multiple modes. The history view is architecturally distinct: read-only, no add form, different columns, different context variables. A dedicated route and template is the correct separation.

### Files touched

| File | Change |
|------|--------|
| `tasks.py` | Add `completed_at: Optional[str] = None`; update `.complete()` |
| `storage.py` | Add `completed_at` to `save_tasks()` serialization dict |
| `web.py` | Add `GET /history` route |
| `templates/history.html` | New file |
| `templates/index.html` | Add "History" link in header (~1 line) |

---

## Component Boundaries and Integration Map

```
                     tasks.py          storage.py        web.py              templates/
                     ──────────        ──────────        ──────────          ────────────
Feature 1 (DevOps)                                                           (none)
  └─ ci.yml only ──────────────────────────────────────────────────────────► (no touch)

Feature 2 (Highlight)                                    days_until filter ► index.html
  └─ due_date exists  (already serialized)               (6 lines added)     row class + CSS

Feature 3 (History)  completed_at   serialize it    ►   /history route  ►   history.html
                     .complete()    (1 line in           (new)               (new)
                     sets it        save_tasks)                              index.html header
```

---

## Build Order and Parallelism Analysis

### True parallelism assessment

| Workstream | Shared files | Conflict risk |
|------------|--------------|---------------|
| DevOps (ci.yml) | None — entirely new file | None |
| Dev 1 (deadline highlighting) | `web.py`, `index.html` | Low |
| Dev 2 (completion history) | `tasks.py`, `storage.py`, `web.py`, `index.html` | Low |

**All three workstreams are genuinely independent** — no workstream depends on a change from another, and no workstream blocks another from starting.

The only merge conflict risk: Dev 1 and Dev 2 both touch `index.html` and `web.py`. However:
- In `index.html`, Dev 1 modifies the `<style>` block and the `<tbody>` row class logic; Dev 2 adds one line to the `<header>`. These are in different sections of the file — semantic merge conflict is unlikely.
- In `web.py`, Dev 1 adds a template filter near the top (after `app = Flask()`); Dev 2 adds a route near the bottom. Different locations — low conflict risk.

### Recommended sequence within each workstream

**DevOps:**
1. Create `ci.yml` with `test` job only
2. Open a test PR; verify pytest runs and check appears in PR UI
3. Add `build-and-push` job with `needs: test`
4. Merge to main; verify image in `ghcr.io/nguyenbuitk/claude-demo`

**Dev 1 (deadline highlighting):**
1. Decide color semantics (red for overdue, amber for warning)
2. Update `.overdue` CSS color in `index.html`
3. Add `days_until` filter to `web.py`
4. Add `.warning` CSS rule and extend row class logic in `index.html`
5. Manual test: create tasks with past due date (overdue), due in 2 days (warning), due in 5 days (no highlight)

**Dev 2 (completion history):**
1. Add `completed_at` field to `tasks.py` with `= None` default
2. Update `.complete()` method in `tasks.py`
3. Add `completed_at` to `save_tasks()` in `storage.py`
4. Add `/history` route to `web.py`
5. Create `templates/history.html`
6. Add "History" nav link to `templates/index.html`
7. Manual test: complete a task, navigate to `/history`, confirm timestamp shown; also verify existing tasks.json loads without error

---

## Scalability Considerations

| Concern | Impact of these features |
|---------|--------------------------|
| tasks.json grows unbounded | History page makes this visible — completed tasks are never purged. Not a new problem, but now surfaced to users. |
| Gunicorn 4 workers, no file locking | `completed_at` is set inside the same write path as `done` — no new concurrency surface introduced. |
| Docker image in GHCR | Images accumulate; GHCR has retention settings. Not scoped here but worth noting. |

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: One-time JSON migration script for completed_at

**What goes wrong:** Write a script that reads `tasks.json`, adds `"completed_at": null` to each record, rewrites the file.

**Why bad:** Unnecessary. The `= None` default on the dataclass handles missing keys transparently on load. Migration scripts require coordination, can corrupt data if run twice, and create operational risk.

**Instead:** Rely on the dataclass default. Tasks resave with the field on their next write operation.

### Anti-Pattern 2: Computing CSS classes in the route handler

**What goes wrong:** Iterate tasks in `web.py`, compute a CSS class string per task, pass `row_classes = {task.id: css_class}` to the template.

**Why bad:** Couples presentation (CSS class names) to the route handler, requires template to do a dict lookup per row, duplicates the iteration that already happens in the template loop.

**Instead:** Register a `days_until` Jinja2 filter. Date arithmetic stays in Python (testable); CSS class assignment stays in the template (presentation layer).

### Anti-Pattern 3: Reusing index.html for history via an `if history_view` branch

**What goes wrong:** Add `{% if history_view %}...{% else %}...{% endif %}` throughout `index.html` to handle the history view as a third mode alongside list and edit.

**Why bad:** The template is already 222 lines with two modes. A third mode would make the template unmaintainable. The history view needs none of the add form, tag filters, drag handles, or done/edit/delete action buttons.

**Instead:** New `history.html` template. The duplication of the `<style>` block is acceptable at v1 scope.

### Anti-Pattern 4: Using continue-on-error to "not block merges"

**What goes wrong:** Adding `continue-on-error: true` to the test job in `ci.yml` to satisfy the "tests do not block merging" requirement.

**Why bad:** `continue-on-error: true` marks the job as passing even when tests fail, which destroys visibility — the entire point of the feature.

**Instead:** The "not block merging" requirement is about branch protection rules (a GitHub repository settings concern), not workflow configuration. The workflow should fail loudly on test failure; enforcement is opt-in via branch protection separately.

---

## Sources

- Codebase direct inspection (HIGH confidence): `tasks.py`, `storage.py`, `web.py`, `templates/index.html`, `.github/workflows/*.yml`, `Dockerfile`, `requirements.txt`
- GitHub Actions `needs` keyword: https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/using-jobs-in-a-workflow#defining-prerequisite-jobs (MEDIUM confidence — standard mechanism, not re-fetched)
- GHCR authentication via GITHUB_TOKEN with `permissions: packages: write`: standard pattern (MEDIUM confidence)
- Flask `app.template_filter` decorator for Jinja2 custom filters: standard Flask/Jinja2 mechanism (HIGH confidence)
