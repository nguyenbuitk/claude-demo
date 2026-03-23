# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-23)

**Core value:** Every PR shows test results so regressions are caught before they reach main.
**Current focus:** Milestone v1.0 — Phases 2, 3, 4 roadmapped and ready to plan

## Current Position

Phase: Phase 1 not started / Phases 2–4 roadmapped
Plan: —
Status: Roadmap complete — ready for phase planning
Last activity: 2026-03-23 — Phases 2, 3, 4 appended to ROADMAP.md

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 0
- Average duration: -
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. pytest CI Workflow | 3 | - | - |
| 2. Docker CI Pipeline | 3 (TBD) | - | - |
| 3. Deadline Highlighting | 2 (TBD) | - | - |
| 4. Completion History | 3 (TBD) | - | - |

**Recent Trend:**
- Last 5 plans: -
- Trend: -

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Init]: Visibility-only (no PR merge gating) — observe baseline before enforcing
- [Init]: Separate test.yml file — keep test CI distinct from Claude Code review workflows
- [Init]: Omit push-to-main trigger for v1 — PROJECT.md scopes to PR-only; add in future phase if needed
- [Init]: Include conftest.py in Phase 1 — low-effort, prevents sys.path boilerplate spreading
- [Roadmap v1.0]: Single ci.yml with two chained jobs — test + build-and-push appear as unified pipeline in PR checks UI
- [Roadmap v1.0]: Use STACK.md action versions — docker/login-action@v4, docker/metadata-action@v6, docker/build-push-action@v7 (March 2025 releases, verified)
- [Roadmap v1.0]: CSS class name .due-soon for amber rows — semantic, matches feature description
- [Roadmap v1.0]: UTC assumption for deadline comparison — no JavaScript date handling in v1
- [Roadmap v1.0]: Phases 2, 3, 4 are genuinely parallel — DevOps, Dev 1, Dev 2 workstreams touch non-overlapping files; merge DevOps first to establish CI gate
- [Roadmap v1.0]: completed_at field must be updated atomically across Task dataclass, complete(), save_tasks(), and /history route — any partial deployment causes silent data loss

### Pending Todos

- Verify docker/login-action, docker/metadata-action, docker/build-push-action latest major versions at implementation time (knowledge cutoff Aug 2025)
- Confirm recommended merge order for parallel branches: Phase 2 (DevOps) first, then 3 and 4 in any order

### Blockers/Concerns

- [Phase 1]: actions/setup-python@v5 version is training knowledge (cutoff Aug 2025) — verify latest major tag on GitHub Marketplace before writing workflow
- [Phase 2]: GHCR workflow cannot be fully validated without an actual merge to main — validate in two steps: open PR to confirm test job appears, then merge to verify build-and-push pushes the image
- [Phase 2]: packages: write permission must be explicitly declared in the build job or GHCR push returns HTTP 403
- [Phase 4]: No automated tests cover storage.py — the completed_at persistence change has no test coverage; minimum acceptance test is: complete a task, restart server, verify /history shows the timestamp
- [Future]: storage.py hardcodes tasks.json at repo root with no test isolation — dormant now, must be addressed with monkeypatch/tmp_path before any storage tests land

## Session Continuity

Last session: 2026-03-23
Stopped at: Roadmap v1.0 written — Phases 2, 3, 4 appended to .planning/ROADMAP.md; ready to run /gsd:plan-phase for each workstream
Resume file: None
