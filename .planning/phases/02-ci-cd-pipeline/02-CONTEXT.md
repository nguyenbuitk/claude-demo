# Phase 2: CI/CD Pipeline - Context

**Gathered:** 2026-03-24
**Status:** Ready for planning

<domain>
## Phase Boundary

GitHub Actions CI/CD pipeline: run tests on every PR and push to main; build and push Docker image to GHCR only on merge to main, gated on tests passing. No multi-environment, no staging — single pipeline targeting main branch.

</domain>

<decisions>
## Implementation Decisions

### Workflow file layout
- **D-01:** Single `ci.yml` file — two jobs, not two separate files
- **D-02:** `test` job triggers on: all PRs (`pull_request`) + push to `main`
- **D-03:** `build-and-push` job has `needs: [test]` + `if: github.ref == 'refs/heads/main'` — never runs on PRs
- **D-04:** File lives at `.github/workflows/ci.yml`

### Locked from requirements (CI-01 to CI-04)
- **D-05:** Registry: `ghcr.io/nguyenbuitk/claude-demo`
- **D-06:** Image tags: `:latest` + `:sha-<commit>` on every main merge
- **D-07:** Auth: `GITHUB_TOKEN` only — no manually created secrets
- **D-08:** Failed `test` job blocks `build-and-push` from running

### Claude's Discretion
- Short SHA format: 7 chars (e.g. `sha-a1b2c3d`) — Docker convention
- Pip dependency caching via `actions/setup-python` built-in cache — always enable, zero config overhead
- `runs-on: ubuntu-latest` for both jobs
- Python version: `3.12` to match Dockerfile

</decisions>

<specifics>
## Specific Ideas

- No special behavior needed for PR image builds — tests only, no push
- Existing workflows (`claude.yml`, `claude-code-review.yml`) are unrelated Claude Code integrations — do not modify them

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### CI/CD requirements
- `.planning/REQUIREMENTS.md` — CI-01 through CI-04 (test triggers, build-and-push gate, GHCR tags, GITHUB_TOKEN auth)
- `.planning/ROADMAP.md` — Phase 2 success criteria (5 acceptance criteria for the pipeline)

### Existing workflows (read-only — do not modify)
- `.github/workflows/claude.yml` — Claude Code action, unrelated to CI pipeline
- `.github/workflows/claude-code-review.yml` — Claude review action, unrelated to CI pipeline

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Dockerfile` — multi-stage build, gunicorn entrypoint (`web:app`), port 5000 — planner should reference this for the build step
- `requirements.txt` — pip deps for caching key
- `tests/` — pytest suite (8 tests), no extra test runner config needed

### Integration Points
- `GITHUB_TOKEN` has `packages: write` permission needed for GHCR push — planner must include permissions block in workflow
- Image name must match: `ghcr.io/${{ github.repository_owner }}/claude-demo` → resolves to `ghcr.io/nguyenbuitk/claude-demo`

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 02-ci-cd-pipeline*
*Context gathered: 2026-03-24*
