# Feature Landscape — v1.0 Milestone

**Domain:** Flask task manager — CI/CD + UX feature expansion
**Researched:** 2026-03-23
**Scope:** Three new features added to an existing app

---

## Codebase Baselines Observed

Before assessing features, the following facts from the existing code constrain design:

- `Task.due_date` is `Optional[str]` in ISO format (`YYYY-MM-DD`), or `None`. String comparison (`<`, `>`) against `today` (also ISO string) works correctly for date ordering.
- `today` is already computed in `web.py` as `date.today().isoformat()` and passed to the template.
- The template already has a `.overdue` CSS class (yellow row background at line 93-94) and the Jinja condition `task.due_date and task.due_date < today and not task.done`. Overdue highlighting is partially scaffolded but uses yellow — the same color as the current soon-due intent. CSS needs to be split into two distinct classes.
- `Task.complete()` sets `done = True` only. There is no `completed_at` field in the dataclass, no serialization of it in `storage.py`, and no deserialization in `load_tasks()`. Completion history requires a data model change.
- `storage.py` explicitly lists fields in `save_tasks()` — adding `completed_at` requires both `Task` and `save_tasks()` to be updated.

---

## Feature 1: Deadline Highlighting

### Table Stakes (must-have for v1)

| Behavior | Detail |
|----------|--------|
| Overdue row highlight | Task has `due_date < today` and `not done`. Use red/pink background: `#fde8e8`. The current `.overdue` yellow must be changed — yellow is the soon-due color. |
| Soon-due row highlight | Task has `due_date` in the range `[today, today+3]` (inclusive) and `not done`. Use amber/yellow background: `#fff3cd` (the current `.overdue` color can be repurposed here). |
| No highlight when `due_date` is None | Tasks with no due date render as normal rows. The existing `task.due_date and ...` guard already handles this. |
| No highlight for completed tasks | `done=True` tasks must never be highlighted regardless of due_date. Already guarded by `not task.done`. |
| `today_plus_3` passed from route | Date arithmetic must happen in Python (`web.py`), not Jinja. Pass `today_plus_3` as a template variable alongside `today`. |

### Edge Cases to Handle Explicitly

| Case | Expected Behavior | Note |
|------|-------------------|------|
| `due_date` is None | No highlight | Guard already present |
| `due_date == today` | Soon-due (amber), not overdue (red) | Deadline is today — not yet missed |
| `due_date == today + 1` | Soon-due | Within the 3-day window |
| `due_date == today + 3` | Soon-due (boundary inclusive) | Window is `[today, today+3]` |
| `due_date == today + 4` | No highlight | Outside warning window |
| `done=True` with past due_date | No highlight | Completed tasks are exempt from urgency styling |
| `done=True` shown via `show_done=1` | Render with `.done` strikethrough only | Same exemption applies when completed tasks are visible |

### Implementation Pattern

Two Jinja flags computed per row:

```jinja
{% set overdue  = task.due_date and task.due_date < today and not task.done %}
{% set soon_due = task.due_date and task.due_date >= today
                  and task.due_date <= today_plus_3 and not task.done %}
```

`today_plus_3` computed in `web.py`:

```python
from datetime import date, timedelta
today_plus_3 = (date.today() + timedelta(days=3)).isoformat()
```

Two CSS classes (replacing the single `.overdue`):

```css
tbody tr.overdue td  { background: #fde8e8; }   /* red — past deadline */
tbody tr.soon-due td { background: #fff3cd; }   /* amber — within 3 days */
tbody tr.overdue:hover td  { background: #f5c6cb; }
tbody tr.soon-due:hover td { background: #ffeaa7; }
```

### Nice-to-Have (include only if trivial)

| Feature | Verdict |
|---------|---------|
| Text label in Due Date cell ("OVERDUE", "Soon") | Include — a Jinja conditional adding a small colored span inside the `<td>` costs ~3 lines. Adds clarity for colorblind users. |
| Countdown text ("2 days left") | Defer — requires per-task date arithmetic. Pass a dict or compute in route; adds complexity not justified in v1. |
| Configurable warning threshold | Defer — hardcode 3 days in v1. No UI or config needed. |

### Anti-Features

| Anti-Feature | Why Avoid |
|--------------|-----------|
| Highlighting completed tasks | Completed tasks have no deadline urgency — styling them as overdue is actively misleading. |
| Adding a "Deadline Status" column | The row color conveys the same information. A new column widens an already-wide table. |
| Client-side date computation in JavaScript | `today` is server-computed. Do not duplicate date logic in JS — browser timezone != server timezone. |

---

## Feature 2: Completion History

### Data Model Gap (prerequisite — blocks everything else)

`Task.complete()` does not record a timestamp. All three changes below must be made together:

1. Add `completed_at: Optional[str] = None` to the `Task` dataclass (with default `None` for backward compat).
2. In `Task.complete()`, set `self.completed_at = datetime.now().isoformat()`.
3. In `storage.py`'s `save_tasks()`, add `"completed_at": task.completed_at` to the serialized dict.

`load_tasks()` uses `Task(**item)` and will handle `completed_at` automatically once the field has a default value. Existing `tasks.json` entries without `completed_at` will deserialize with `completed_at=None` — safe.

### Table Stakes (must-have for v1)

| Behavior | Detail |
|----------|--------|
| Dedicated `/history` route | Separate page, not a section on the main page (rationale below). |
| List all `done=True` tasks | All completed tasks, sorted by `completed_at` descending (most recent first). |
| Show: title, priority badge, due_date, completed_at | Core columns for a history log. `completed_at` formatted as a readable date; `None` displays as "—". |
| "History" link in the header | A plain anchor in the `<header>` nav area so users can reach it. |
| Read-only view | No Done/Edit/Delete buttons on the history page. History is a log, not an action surface. |

### Separate Page vs. Section on Main Page

A dedicated `/history` route is the correct choice:

- The main page is already dense: add form + tag filters + task table. Appending a completed-tasks section below requires scrolling past the active task interface.
- `show_done=1` already lets users see completed tasks inline in the main list. History is a different mental model — a chronological log, not a filterable task list.
- A separate route can be linked from the header without adding URL parameters or toggle state to the main page.
- The `index.html` pattern of reusing a single template with a context variable (already done for `editing`) supports adding a `history=True` mode cleanly.

### What to Show on the History Page

| Column | Notes |
|--------|-------|
| Title | Primary identifier |
| Priority | Badge, same style as main list |
| Due Date | Original due date for context; "—" if none |
| Completed At | Formatted readable date (e.g. "2026-03-22"); "—" for legacy tasks |
| Tags | Same tag-badge style as main list |

Omit: description (secondary info, clutters a read-only log), ID (not meaningful in history context), Actions column.

### Pagination

Not needed in v1. Rationale:

- Storage is a flat JSON file. There is no database query to optimize — all tasks are loaded into memory on every request regardless.
- A personal task manager will rarely accumulate hundreds of completed tasks. Loading all in one request is fine.
- If the list grows large, the correct fix is capping the display to the most recent N entries (e.g. `tasks[-100:]`), not adding page-number pagination infrastructure.
- Full server-side pagination (offset/limit query params, page controls) requires `load_tasks()` to support filtering at load time — it does not, and that refactor is out of scope.

### Nice-to-Have (include only if trivial)

| Feature | Verdict |
|---------|---------|
| Sort by `completed_at` descending | Include — one `sorted()` call in the route. |
| Total count ("42 tasks completed") | Include — `{{ tasks | length }}` in the template. |
| Filter history by tag | Defer — adds URL params, filter chip UI, more Jinja. Not justified in v1. |
| "Clear history" / bulk delete | Defer — destructive, needs confirmation, touches multi-delete logic. |

### Anti-Features

| Anti-Feature | Why Avoid |
|--------------|-----------|
| Undo/reopen from history | PROJECT.md explicitly marks "Task reopen/undo completion" as out of scope for this milestone. |
| History as a collapsible section on `GET /` | Doubles page length. `show_done=1` already satisfies inline viewing. |
| Storing history in a separate file | Completed tasks are in `tasks.json` already. A second file adds sync complexity with no benefit. |
| Recovering `completed_at` for pre-existing done tasks | Cannot be done without external data. Accept `None` gracefully — display as "—". |

---

## Feature 3: Docker CI (Build + Push to GHCR)

### Table Stakes (must-have for v1)

| Behavior | Detail |
|----------|--------|
| Trigger on `push` to `main` only | `on: push` with `branches: [main]`. Not on PRs. PRs run `pytest` only (separate workflow). |
| `permissions: packages: write` | Must be declared in the job. Without it, `GITHUB_TOKEN` cannot push to GHCR. Also declare `contents: read`. |
| Login to `ghcr.io` via `docker/login-action@v3` | `registry: ghcr.io`, `username: ${{ github.actor }}`, `password: ${{ secrets.GITHUB_TOKEN }}`. No extra secret required. |
| Tag `latest` on every merge | `ghcr.io/nguyenbuitk/claude-demo:latest` always points to current main. |
| Tag with git SHA | `ghcr.io/nguyenbuitk/claude-demo:sha-<short>`. Immutable — `latest` is mutable, SHA tag is not. Both tags pushed together. |
| `docker/metadata-action@v5` for tag generation | Cleaner than hardcoding tag strings. Avoids manual formatting errors. |
| `docker/build-push-action@v5` | Standard action for Docker builds. |
| New workflow file: `.github/workflows/docker-publish.yml` | Do not modify `main.yml` (hello-world placeholder) or the pytest workflow. |

### Minimal Correct Workflow

```yaml
name: Docker Build & Push

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

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/nguyenbuitk/claude-demo
          tags: |
            type=sha
            type=raw,value=latest

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### Image Tagging Strategy

| Tag | Value | Purpose |
|-----|-------|---------|
| `latest` | Always current main | Easy reference without knowing SHA |
| `sha-<short>` | e.g. `sha-1596c6a` | Immutable, traceable to commit |

Do NOT tag with branch name — there is only one deployable branch (`main`). Branch name tags are noise for single-branch workflows.

Do NOT tag with semantic version (`v1.0.0`) — there is no release tagging convention defined. Semantic version tags require a process to maintain.

### Nice-to-Have (include only if trivial)

| Feature | Verdict |
|---------|---------|
| Build cache (`cache-from: type=gha`) | Include — two lines in `docker/build-push-action`. Meaningful speedup when only source files change. |
| Multi-platform build (`linux/amd64,linux/arm64`) | Defer — doubles build time. Only needed if deploying to ARM hardware, which is not stated. |
| Build attestation (`actions/attest-build-provenance`) | Defer — security supply-chain feature, adds complexity and permissions, not needed in v1. |
| Failure notification (Slack, email) | Defer — no notification infrastructure exists. |

### Anti-Features

| Anti-Feature | Why Avoid |
|--------------|-----------|
| Auto-deploy after push | Explicitly out of scope in PROJECT.md: "push to registry is sufficient for now". |
| Building on PRs | PR checks run pytest only. Docker builds on every PR are expensive and provide no additional signal. |
| Using a PAT instead of `GITHUB_TOKEN` | `GITHUB_TOKEN` with `packages: write` is sufficient for GHCR. A PAT creates rotation overhead and a secret to manage. |
| Pinning actions to `@main` | Always pin to a semantic version tag (`@v4`, `@v5`). Floating `@main` is a supply-chain risk. |
| Combining Docker push and pytest in one workflow | Keep them separate. A broken Docker build should not affect the pytest check status, and vice versa. |

---

## Feature Dependencies

```
Feature 1 (Deadline Highlighting):
  Requires: today_plus_3 computed in web.py (index + edit routes)
  Requires: Two CSS classes (.overdue red, .soon-due amber) in index.html
  Requires: Jinja conditions updated (add soon_due variable, keep overdue)
  No data model changes.

Feature 2 (Completion History):
  Requires: completed_at field added to Task dataclass
  Requires: Task.complete() records datetime.now().isoformat()
  Requires: storage.py save_tasks() serializes completed_at
  Requires: New /history route in web.py
  Requires: History template (new file or index.html extended with history mode)

Feature 3 (Docker CI):
  Requires: Dockerfile exists and is correct (pre-existing, not modified)
  Requires: New .github/workflows/docker-publish.yml
  No code changes.
```

Features 1 and 3 are fully independent of each other and of Feature 2.
Feature 2 is independent of 1 and 3 but is the most invasive — data model change with backward compat requirement.

---

## MVP Priority Order

All three are stated v1.0 deliverables. If parallel development is not possible:

1. **Feature 3 (Docker CI)** — No app code changes, lowest risk, unblocks image availability immediately.
2. **Feature 1 (Deadline Highlighting)** — Mostly template + one route change. `today` already passed; add `today_plus_3` and one CSS class.
3. **Feature 2 (Completion History)** — Most invasive. Data model change + new route + new template. Must not break backward compat with existing `tasks.json`.

---

## Sources

- Direct code inspection: `tasks.py`, `storage.py`, `web.py`, `templates/index.html`, `.github/workflows/main.yml`
- Project scope and out-of-scope list: `.planning/PROJECT.md`
- Confidence: HIGH for all three features (grounded in existing codebase, not external research)
