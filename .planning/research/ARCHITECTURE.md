# Architecture: pytest CI Workflow

**Analysis Date:** 2026-03-23
**Confidence:** HIGH

## Recommendation

**New file required.** Create `.github/workflows/test.yml`. Do not extend existing workflows — `claude.yml`/`claude-code-review.yml` are Claude-specific; `hello.yml`/`main.yml` are demo-only and trigger on all pushes.

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| New `test.yml` file | Separation of concerns — test CI is independent of Claude review workflows |
| Triggers: `pull_request` + `push` to `main` | PR lifecycle + direct merges. All-push triggers (like hello world workflows) waste minutes and clutter commit status |
| Single job, no matrix | Dockerfile pins `python:3.12-slim`; PROJECT.md explicitly requires Python 3.12 — matrix contradicts this |
| `actions/setup-python@v5` `cache: "pip"` | Built-in pip caching; no separate `actions/cache` step needed; cache key derived from `requirements.txt` automatically |
| `pip install -r requirements.txt pytest` | `pytest` is not in `requirements.txt` (production runtime deps only) — must be appended explicitly |
| No `continue-on-error: true` | Non-blocking behavior is a branch protection setting, not a workflow setting — suppressing errors kills visibility |

## Recommended Workflow

**Path:** `.github/workflows/test.yml`

```yaml
name: Tests

on:
  pull_request:
    types: [opened, synchronize, reopened]
  push:
    branches:
      - main

jobs:
  test:
    runs-on: ubuntu-latest
    permissions:
      contents: read

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Python 3.12
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: "pip"

      - name: Install dependencies
        run: pip install -r requirements.txt pytest

      - name: Run tests
        run: pytest
```

## Open Questions

- `actions/setup-python@v5` is current as of Aug 2025 training; verify latest major version tag before implementing.
- If tests are added for `storage.py` (which writes `tasks.json`), the workflow will need `tmp_path` fixture isolation — out of scope for this milestone.

---
*Architecture analysis: 2026-03-23*
