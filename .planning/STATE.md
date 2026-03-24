# Project State

**Project:** DevOps Learning Roadmap v1.0
**Updated:** 2026-03-24

## Project Reference

See: `.planning/PROJECT.md`

**Core value:** Every concept learned must be practiced hands-on and deployable to production-grade environments.
**Current focus:** Phase 1 — Dockerize

## Current Status

- Phase 1 (Dockerize): Not started
- Phase 2 (CI/CD Pipeline): Not started

## Decisions

| Decision | Rationale |
|----------|-----------|
| GitHub Actions over GitLab | Repo is on GitHub |
| claude-demo Flask app as practice target | Existing app, minimal setup overhead |
| GHCR for image registry | Free with GitHub, no extra setup |

## Blockers

None

## Notes

- `Dockerfile` may or may not exist — check before planning Phase 1
- `ci.yml` workflow was previously planned in a different GSD context — can reuse logic
- `/health` endpoint needs to be added to `web.py`
