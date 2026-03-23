# Project Research Summary

**Project:** Claude Demo — v1.0 (Docker CI + Deadline Highlighting + Completion History)
**Domain:** Flask task manager — CI/CD pipeline + UX feature expansion
**Researched:** 2026-03-23
**Confidence:** HIGH

## Executive Summary

This milestone adds three independent workstreams to an existing Flask task manager: a GitHub Actions workflow that runs pytest then builds and pushes a Docker image to GHCR on merge to main; deadline-based row highlighting (red for overdue, amber for due within 3 days); and a completion history view backed by a new `completed_at` timestamp field. All three are genuinely parallel — they touch different files with only minor, non-conflicting overlap in `web.py` and `index.html`.

The recommended approach is a single `ci.yml` workflow with two chained jobs (`test` then `build-and-push`), pure server-side Jinja2/CSS for deadline highlighting with no new dependencies, and a `completed_at: Optional[str] = None` field added atomically across four locations (`Task` dataclass, `complete()` method, `save_tasks()` serializer, and the new `/history` route). The existing stack is sufficient for all three features — no new Python packages, no JavaScript frameworks, no database changes.

The highest-risk area is the `completed_at` field: four coupled code locations must all be updated together, and missing any one produces silent data loss rather than a crash. The second-highest risk is the GHCR workflow: the `packages: write` permission must be explicitly declared or the push fails with a 403. Both risks are straightforward to prevent with disciplined implementation.

---

## Key Findings

### Recommended Stack

No new dependencies are required. The existing Flask 3.1.3 / Jinja2 3.1.2 / Python 3.12 stack handles all three features natively.

**Core technologies:**
- `docker/setup-buildx-action@v4` + `docker/login-action@v4` + `docker/metadata-action@v6` + `docker/build-push-action@v7` — Docker CI pipeline; all Node 24 runtime cohort released March 2025
- `GITHUB_TOKEN` with `permissions: packages: write` — GHCR authentication; zero-config, no PAT required
- `date.today() + timedelta(days=3)` passed as `today_plus_3` to Jinja2 template — deadline window computation; no new date library needed
- `completed_at: Optional[str] = None` on `Task` dataclass — completion timestamp; backward-compatible with existing `tasks.json`

**Version conflict to resolve:** STACK.md recommends `docker/login-action@v4` / `docker/metadata-action@v6` / `docker/build-push-action@v7` (March 2025 releases). FEATURES.md references the older `@v3` / `@v5` / `@v5` versions. Use STACK.md versions — they are verified against release notes.

### Expected Features

**Must have (table stakes for v1.0):**
- Overdue row highlight (red `#fde8e8`) for tasks where `due_date < today` and `not done`
- Soon-due row highlight (amber `#fff3cd`) for tasks where `due_date` in `[today, today+3]` and `not done`
- No deadline highlighting for `done=True` tasks regardless of `due_date`
- `GET /history` route — completed tasks sorted by `completed_at` descending, read-only
- `completed_at` timestamp shown in history view; "—" for legacy tasks with `None`
- Docker build and push triggered only on merge to main, gated behind passing tests
- SHA tag + `latest` tag both pushed to `ghcr.io/nguyenbuitk/claude-demo`

**Nice-to-have (include only if trivial):**
- Text label in Due Date cell ("OVERDUE" / "Soon") — ~3 Jinja lines, accessibility benefit for colorblind users
- Build cache (`cache-from: type=gha`) — two lines in `docker/build-push-action`, meaningful speedup
- Completed task count on history page — `{{ tasks | length }}` in template, essentially free

**Defer to v2+:**
- Countdown text ("2 days left") — per-task arithmetic, adds route complexity not justified in v1
- History pagination — JSON storage loads all tasks regardless; infrastructure overhead exceeds benefit at current scale
- Task reopen/undo — explicitly out of scope in PROJECT.md
- Multi-platform Docker build (`linux/amd64,linux/arm64`) — doubles build time; no ARM deployment target stated

### Architecture Approach

All three features integrate into the existing flat architecture (no service layer, direct route-to-storage calls). DevOps is fully isolated to a new workflow file. Deadline highlighting adds a `days_until` Jinja2 template filter to `web.py` and CSS/logic changes to `index.html`. Completion history adds a dedicated `history.html` template and `/history` route — a new file rather than a third mode in the already-222-line `index.html`.

**Major components touched:**
1. `.github/workflows/ci.yml` (new) — two-job pipeline: `test` (all triggers) then `build-and-push` (main push only, `needs: test`)
2. `tasks.py` + `storage.py` — `completed_at` field; must be updated as an atomic coupled pair
3. `web.py` — `days_until` filter registration (~6 lines), `GET /history` route, `today_plus_3` in template context
4. `templates/index.html` — CSS class updates, Jinja row logic extension, "History" nav link (~1 line)
5. `templates/history.html` (new) — read-only completed task log

### Critical Pitfalls

1. **`completed_at` without `= None` default crashes `load_tasks()` on existing data** — All existing `tasks.json` records lack the key; `Task(**item)` raises `TypeError` at startup. Fix: define as `completed_at: Optional[str] = None`. No migration script needed.

2. **`packages: write` absent from workflow job** — `GITHUB_TOKEN` default does not grant package write access; GHCR push returns HTTP 403. Fix: explicitly declare `permissions: contents: read` and `packages: write` in the build job.

3. **`save_tasks()` silently drops `completed_at`** — The serializer uses an explicit field list, not `dataclasses.asdict()`. Adding the dataclass field without updating the serializer dict means timestamps are never persisted; the bug is invisible until a page refresh. Fix: treat `Task` field additions and `save_tasks()` updates as an atomic change.

4. **`complete()` not updated — `completed_at` is always `None`** — The `/done/<id>` route calls `task.complete()` directly. If `complete()` is not updated, the history feature is structurally present but produces no useful data. Fix: update `complete()` at the same time as the dataclass field.

5. **`due_date is None` comparison crash in template** — Most tasks have no due date. Any Jinja comparison of `None` against a date string raises `TypeError` (500 error on the index page). Fix: always guard with `{% if task.due_date and task.due_date < today %}`.

---

## Parallelism Assessment

**All three workstreams are confirmed genuinely independent.** No workstream depends on a change from another, and no workstream blocks another from starting.

| Workstream | Files exclusively owned | Files shared | Conflict risk |
|------------|------------------------|--------------|---------------|
| DevOps (ci.yml) | `.github/workflows/ci.yml` | None | None |
| Dev 1 (deadline highlighting) | — | `web.py` (filter, near top), `index.html` (style block + tbody logic) | Low |
| Dev 2 (completion history) | `tasks.py`, `storage.py`, `templates/history.html` | `web.py` (route, near bottom), `index.html` (header nav, 1 line) | Low |

Shared-file conflicts are low-risk because the two workstreams touch different sections: Dev 1 modifies the `<style>` block and `<tbody>` row logic in `index.html`; Dev 2 adds one line to the `<header>`. In `web.py`, Dev 1 adds a template filter near the top and Dev 2 adds a route near the bottom.

**Recommended merge order** (even when developed in parallel): merge DevOps first so the CI gate is in place before app feature branches land on main.

---

## Implications for Roadmap

### Phase 1: Docker CI Pipeline

**Rationale:** Zero app code changes; entirely isolated to a new workflow file. Lowest risk, and establishing the `needs: test` gate before app changes merge is the correct sequencing.
**Delivers:** pytest on every PR; Docker image pushed to GHCR (`latest` + SHA tag) on every merge to main.
**Implements:** `.github/workflows/ci.yml` with `test` job (all triggers) and `build-and-push` job (main push only, `needs: test`).
**Avoids:** Pitfall 2 (missing `packages: write`), Pitfall 4 (build without test gate), Pitfall 3 (uppercase image tag — lowercase the owner expression).
**Research flag:** None needed — canonical GitHub Actions + GHCR pattern, verified against official Docker and GitHub docs.

### Phase 2: Deadline Highlighting

**Rationale:** No data model changes required. `due_date` already exists on `Task`; `today` is already passed to the template. The entire change is presentational: one filter registration, one new CSS class, updated Jinja row logic. Minimal blast radius.
**Delivers:** Red row for overdue tasks, amber row for tasks due within 3 days; no highlight for completed tasks.
**Implements:** `days_until` Jinja2 filter in `web.py`; `.overdue` (red) and `.due-soon` (amber) CSS in `index.html`; extended row class Jinja logic; `today_plus_3` passed from route.
**Avoids:** Pitfall 5 (None comparison crash), Pitfall 9 (CSS specificity — test overdue+done combination visually).
**Research flag:** None needed — server-side Jinja2 with ISO string comparison, established pattern.

### Phase 3: Completion History

**Rationale:** Most invasive workstream due to data model change. Four locations must be updated atomically. Implement all four changes in a single commit to avoid any window where the field exists in the dataclass but not the serializer.
**Delivers:** `completed_at` timestamp recorded on task completion; `GET /history` read-only view sorted by completion date descending; "History" nav link in header.
**Implements:** `Task.completed_at` field + `complete()` method update + `save_tasks()` serializer update + `/history` route + `history.html` template + nav link in `index.html` header.
**Avoids:** Pitfall 1 (no default = crash on load), Pitfall 3 (field without serializer update), Pitfall 4 (complete() not updated), Pitfall 10 (filter by both `done=True` and `completed_at is not None`).
**Research flag:** None needed — implementation derived from direct codebase inspection, HIGH confidence.

### Phase Ordering Rationale

- All three phases can be developed in parallel and are suitable for parallel workstreams.
- If serial order is required: DevOps first (zero risk, establishes CI baseline), Deadline Highlighting second (presentational only), Completion History last (data model change, highest internal coupling).
- The four-location coupling in Phase 3 (`Task` field, `complete()`, `save_tasks()`, `/history`) must be treated as a single atomic changeset — any partial deployment produces silent data loss.

---

## Open Questions / Decisions Before Implementation

1. **Action version conflict:** STACK.md specifies `docker/login-action@v4` / `docker/metadata-action@v6` / `docker/build-push-action@v7`. FEATURES.md references `@v3` / `@v5` / `@v5`. Use STACK.md versions — confirmed against March 2025 release notes.

2. **Workflow file: one or two?** ARCHITECTURE.md recommends a single `ci.yml` combining `test` and `build-and-push` jobs. FEATURES.md recommends a separate `docker-publish.yml`. Recommendation: single `ci.yml` — both jobs share a trigger and appear as a unified pipeline in the PR checks UI.

3. **CSS class name for soon-due:** STACK.md uses `.due-soon`, ARCHITECTURE.md uses `.warning`, FEATURES.md uses `.soon-due`. Pick one name before writing. Recommendation: `.due-soon` (semantic, matches the feature description).

4. **UTC timezone for deadline comparison:** Server runs UTC; users in negative UTC offsets may see tasks flagged overdue before end-of-day. Decision for v1: accept UTC assumption, document it. Do not add JavaScript date handling in v1.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Docker action versions verified against March 2025 release notes; Python stack confirmed by direct `requirements.txt` inspection |
| Features | HIGH | Derived from direct inspection of `tasks.py`, `storage.py`, `web.py`, `templates/index.html` |
| Architecture | HIGH | Direct source inspection; overdue CSS class is partially scaffolded already in `index.html` lines 93-94 |
| Pitfalls | HIGH | Grounded in specific code lines (`storage.py` line 19 `Task(**item)`, explicit field list in `save_tasks()`); corroborated by GitHub official docs |

**Overall confidence:** HIGH

### Gaps to Address During Implementation

- No automated tests cover `storage.py` — the `completed_at` persistence change has no test coverage. Minimum acceptance test: complete a task, restart server, verify `/history` shows the timestamp.
- GHCR workflow cannot be fully validated without an actual merge to main. Validate in two steps: open a PR to confirm the `test` job appears in the PR checks UI, then merge to verify the `build-and-push` job pushes the image.

---

## Sources

### Primary (HIGH confidence)
- Codebase direct inspection: `tasks.py`, `storage.py`, `web.py`, `templates/index.html`, `.github/workflows/*.yml`, `Dockerfile`, `requirements.txt`
- [docker/build-push-action v7.0.0 releases](https://github.com/docker/build-push-action/releases) — action version
- [docker/login-action v4.0.0 releases](https://github.com/docker/login-action/releases) — action version
- [docker/metadata-action v6.0.0 releases](https://github.com/docker/metadata-action/releases) — action version
- [GitHub Docs: Controlling permissions for GITHUB_TOKEN](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/controlling-permissions-for-github_token) — `packages: write` requirement
- [GitHub Docs: Working with the Container registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry) — GHCR authentication pattern
- [Docker docs: Manage tags and labels with GitHub Actions](https://docs.docker.com/build/ci/github-actions/manage-tags-labels/) — image tagging strategy
- [GitHub community: Repository name must be lowercase](https://github.com/orgs/community/discussions/27086) — GHCR lowercase enforcement
- [docker/build-push-action issue #37: lowercase image name](https://github.com/docker/build-push-action/issues/37) — confirmed behavior

### Secondary (MEDIUM confidence)
- [GitHub Actions: Pushing container images to GHCR](https://dev.to/willvelida/pushing-container-images-to-github-container-registry-with-github-actions-1m6b) — community article, corroborated by official patterns

---
*Research completed: 2026-03-23*
*Ready for roadmap: yes*
