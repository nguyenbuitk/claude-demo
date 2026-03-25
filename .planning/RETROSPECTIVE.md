# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

---

## Milestone: v1.0 — Docker + CI/CD Foundation

**Shipped:** 2026-03-25
**Phases:** 2 | **Plans:** 3 | **Duration:** 3 days (2026-03-21 → 2026-03-24)

### What Was Built
- `GET /health` endpoint with pytest test suite (TDD approach, 8 tests total)
- Multi-stage Dockerfile (builder + runtime stages) with Python urllib HEALTHCHECK, non-root user
- GitHub Actions CI/CD: `test` job (pytest on PR + push to main) + `build-and-push` job (GHCR `:latest` + `:sha-<commit>`, gated on test success, main branch only)

### What Worked
- **TDD for health endpoint**: Writing test first made acceptance criteria crystal-clear before any code was touched
- **`GITHUB_TOKEN` only**: Using the built-in token eliminated all secret management overhead — zero friction
- **Multi-stage Dockerfile**: Builder/runtime separation was straightforward and produced a clean, small image
- **GSD planning + execution flow**: discuss → plan → execute → verify → ship worked well even for a 3-day sprint
- **Checkpoint discipline**: Knowing which things needed live GitHub CI (smoke tests) vs. what could be verified statically prevented wasted iteration

### What Was Inefficient
- **Worktree merge conflicts**: STATE.md and ROADMAP.md were modified in both the main worktree and the executor worktree, causing merge conflicts that required manual resolution — could be avoided by not modifying those files before the worktree completes
- **Smoke tests deferred**: The 3 live GitHub Actions checks (PR suppression, GHCR visibility, failing-test gate) remain unverified — ideally these would be scripted or at least in a checklist that runs before milestone completion
- **Roadmap rewrite mid-milestone**: Updating phases 3-6 happened at the end of v1.0 rather than at the start — ideally the full roadmap exists before any execution begins

### Patterns Established
- **Conventional commits with phase scope**: `feat(02-01):`, `docs(phase-02):` — makes git log scannable
- **Branch per phase**: `gsd/phase-02-ci-cd-pipeline` → PR → main — clean traceability
- **OIDC for AWS (planned)**: No static access keys is the right default for all CI/CD going forward
- **ECS-first over K8s**: For AWS learning, ECS Fargate is a more efficient stepping stone than jumping straight to EKS

### Key Lessons
1. **Docker layer order matters for cache**: `COPY requirements.txt` → `RUN pip install` → `COPY . .` is the correct order to avoid reinstalling deps on every code change
2. **`needs:` + `if:` together**: `needs: [test]` only skips the job on failure; `if: github.ref == 'refs/heads/main'` is still needed separately to suppress on PRs — both are required
3. **`GITHUB_TOKEN` needs `packages: write` permission**: Not documented prominently but required for GHCR push — always add `permissions: packages: write` to the `build-and-push` job
4. **GSD infra planning**: For AWS phases, `autonomous: false` checkpoints are critical — never let agents `terraform apply` without human confirmation

### Cost Observations
- Model mix: ~70% opus (planning + execution), ~30% sonnet (verification + checking)
- Sessions: 1 main session covering both phases
- Notable: Parallel tool calls significantly reduced planning time; gsd-planner + gsd-plan-checker ran sequentially but verification was fast

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Duration | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | 3 days | 2 | Initial GSD setup + Docker + CI/CD |

### Cumulative Quality

| Milestone | Tests | Verified | Zero-Dep Additions |
|-----------|-------|----------|--------------------|
| v1.0 | 8 | 5/5 must-haves | 3 plans autonomous |

### Top Lessons (Verified Across Milestones)

1. **Checkpoint early for live infrastructure**: Any task touching real external systems (AWS, GitHub CI, GHCR) needs a human checkpoint — don't automate blindly
2. **Plan the full roadmap before executing phase 1**: Having phases 3-6 defined before starting prevents roadmap rewrites mid-execution
