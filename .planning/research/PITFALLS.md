# Domain Pitfalls: v1.0 Milestone

**Domain:** Adding Docker/GHCR CI, deadline highlighting, and completion history to existing Flask/Python 3.12 task manager
**Researched:** 2026-03-23
**Overall confidence:** HIGH

---

## Critical Pitfalls (blockers — will prevent the feature from working at all)

### Pitfall 1: `Task(**item)` breaks on existing `tasks.json` when `completed_at` is added

**What goes wrong:** `storage.py` deserializes every task via `Task(**item)` where `item` is a raw dict loaded from JSON. Adding `completed_at` to the `Task` dataclass without a default value means every task record that was persisted *before* this change — every record that has no `completed_at` key — raises `TypeError: __init__() missing required argument: 'completed_at'` at startup. The entire application stops loading tasks.

**Why it happens:** Python dataclasses do not silently ignore unknown or missing keyword arguments. `**item` unpacks only what is stored in JSON; old records simply do not have the key. Without a default, Python considers it a required positional argument.

**This project specifically:** `storage.py` line 19 is `task = Task(**item)`. There are no field defaults added automatically; the existing `completed_at`-less JSON file is the live data store. Deployment of the new code against unmodified `tasks.json` will crash on first request.

**Consequences:** Application-wide crash. `load_tasks()` raises on the first task without the field; no page renders.

**Prevention:** Define `completed_at` with a default of `None` in the dataclass — `completed_at: Optional[str] = None`. This is the only safe approach. Do not attempt a migration script that rewrites `tasks.json` before deploying; the default handles both old and new records transparently.

**Detection:** Run the existing test suite against an unmodified `tasks.json` after adding the field. The crash is immediate and unmissable in local testing. The absence of storage tests (noted in CONCERNS.md) means this will only surface at runtime if tests are not run first.

---

### Pitfall 2: GHCR push silently denied — `packages: write` permission absent

**What goes wrong:** `GITHUB_TOKEN` is scoped to the permissions explicitly granted in the workflow job. The default permission set does **not** include `packages: write`. A `docker push ghcr.io/...` step will return HTTP 403 with a message like `denied: installation not allowed to Write organization package`. The push fails but — critically — if the `needs:` dependency is misconfigured, this may not block the workflow from appearing green on unrelated checks.

**Why it happens:** GitHub's default `GITHUB_TOKEN` permissions are read-only for packages. Write access must be explicitly declared at the job level with `permissions: packages: write` (and `contents: read` to allow checkout).

**This project specifically:** No existing workflow sets `permissions:` at all. The new build+push job must include:
```yaml
permissions:
  contents: read
  packages: write
```

**Consequences:** Build job fails at the push step with a permission error. Image never lands in GHCR. If the workflow is structured so the deploy step is skipped on push failure, this is a latent problem that only surfaces in CI.

**Prevention:** Always declare `permissions:` explicitly at the job level, not just at the workflow level. Job-level permissions override workflow-level; be explicit per job.

---

### Pitfall 3: Docker image tag uses mixed-case owner — GHCR rejects it

**What goes wrong:** GHCR image names must be entirely lowercase. `github.repository_owner` and `github.repository` preserve the casing of the GitHub account/org name. If the owner is `nguyenbuitk` (all lowercase already), this is safe. But if any future context uses a mixed-case variant, the push will fail with a Docker naming error.

**Why it happens:** Docker image names follow OCI naming conventions requiring all-lowercase. GHCR enforces this strictly. `docker/build-push-action` does not lowercase the tag automatically.

**This project specifically:** Target image is `ghcr.io/nguyenbuitk/claude-demo`. `nguyenbuitk` is lowercase. However, the correct pattern is to never rely on the owner being lowercase — always normalize. Use `${{ github.repository_owner | lower }}` in the workflow expression, or assign via an environment variable:
```yaml
env:
  IMAGE: ghcr.io/${{ github.repository_owner }}/claude-demo
```
and normalize with `${IMAGE,,}` in a bash step.

**Consequences:** Push step fails with `invalid reference format` or `repository name must be lowercase`.

**Prevention:** Explicitly lowercase the image tag. Use `${{ env.REGISTRY }}/${{ github.repository_owner | lower }}/${{ github.event.repository.name | lower }}` or a dedicated normalization step.

---

## Moderate Pitfalls (will cause incorrect behavior but not a total failure)

### Pitfall 4: Build job runs even when test job fails — `needs:` not configured

**What goes wrong:** Without a `needs: [test]` declaration on the build/push job, GitHub Actions runs all jobs in parallel by default. Tests can fail while the Docker build continues and successfully pushes a broken image to GHCR. The image in the registry is unvalidated.

**Why it happens:** GitHub Actions default is parallel execution. `needs:` must be declared explicitly to enforce ordering and to make the build job skip when the test job fails.

**This project specifically:** The existing workflows (`main.yml`, `hello.yml`) run trivial echo commands — there is no existing pattern of job dependencies to copy from. The new CI workflow must establish this pattern from scratch.

**Consequences:** A broken image is pushed to GHCR. The registry tag `latest` points to a broken build. Any deployment referencing `latest` will pull the broken image.

**Prevention:** Declare `needs: [test]` on the build job. When `test` fails, GitHub marks `build` as skipped (not failed), and the image is never pushed.

**Note on skipped status checks:** A job marked `skipped` due to `needs:` failure reports as "Success" for branch protection purposes. This means branch protection rules set to require the `build` job will be satisfied even when build is skipped. This is expected behavior — the intent is that `test` be the required check, not `build`.

---

### Pitfall 5: `due_date` is `None` for most tasks — template comparison crashes or silently misbehaves

**What goes wrong:** Deadline highlighting requires comparing `task.due_date` against today's date. If the template does `{% if task.due_date <= today %}` or similar, tasks with `due_date = None` will either raise `TypeError: '<=' not supported between instances of 'NoneType' and 'str'` (in Jinja2 with strict comparison) or silently evaluate to an unexpected boolean depending on Python's truthiness rules.

**Why it happens:** `due_date` is declared `Optional[str] = None` in `tasks.py`. The majority of existing tasks will have `None`. Any comparison operation involving `None` and a date string in Python raises `TypeError`.

**This project specifically:** `web.py` already passes `today = date.today().isoformat()` to the template. The template comparison must guard against `None` first:
```jinja2
{% if task.due_date and task.due_date < today %}
  {# overdue — red #}
{% elif task.due_date and task.due_date == today %}
  {# due today — yellow #}
{% endif %}
```
The `task.due_date and` guard short-circuits before the comparison when `due_date` is `None`.

**Consequences:** Without the guard, any page render that includes a task with no due_date raises a `500 Internal Server Error`. The index page becomes inaccessible.

**Prevention:** Always guard optional date fields with a truthiness check before comparing. This applies in both Jinja2 templates and any Python-side logic.

---

### Pitfall 6: Timezone mismatch between server date and user's local date

**What goes wrong:** `web.py` computes `today = date.today().isoformat()` using the server's local timezone. If the server runs in UTC (typical for CI/Docker/cloud), "today" in UTC may differ from the user's local date by up to a day. A task due at 11pm in UTC-5 will show as overdue at 6am local time even though the user has until end-of-day.

**Why it happens:** `date.today()` uses the OS timezone of the process. Docker containers and GitHub Actions runners run in UTC by default. Users in negative UTC offsets will see their tasks flagged overdue too early.

**This project specifically:** The Dockerfile uses `python:3.12-slim` with no timezone configuration — the container is UTC. `web.py`'s `today` variable is computed server-side at request time.

**Consequences:** Incorrect deadline highlighting. Tasks appear red before the user considers them overdue. This is a UX issue, not a crash, but will erode trust in the feature.

**Prevention for v1.0:** Accept the UTC assumption; document it. True client-side timezone handling requires JavaScript. A simple mitigation is to compare `due_date` only at the date granularity (already the case with `YYYY-MM-DD` strings) and treat the discrepancy as acceptable for a personal task manager. Do not use `datetime.now()` — that reintroduces time-of-day complexity. The string comparison `due_date < today` on ISO date strings is correct and consistent.

---

### Pitfall 7: `save_tasks()` does not persist `completed_at` — added field is silently dropped

**What goes wrong:** `storage.py`'s `save_tasks()` function serializes only an explicit set of fields (lines 29-38). Adding `completed_at` to the `Task` dataclass does **not** automatically cause it to be saved. The field will be populated in memory but will not appear in `tasks.json`. On the next `load_tasks()`, the value is lost and reverts to `None` (the default).

**Why it happens:** `save_tasks()` uses an explicit dict rather than `dataclasses.asdict()`. This was intentional (the comment says "avoids surprises"), but the consequence is that every new field must also be added to `save_tasks()` manually.

**This project specifically:** The current serialized fields are: `id`, `title`, `description`, `done`, `priority`, `created_at`, `due_date`, `tags`. `completed_at` is absent. The field will be invisible to persistence until explicitly added to that dict.

**Consequences:** Completion history feature appears to work in a single request cycle but `completed_at` is never persisted. Refreshing the page shows `None` for all completion timestamps. Feature silently does not work.

**Prevention:** When adding `completed_at` to the dataclass, simultaneously add `"completed_at": task.completed_at` to the serialization dict in `save_tasks()`. Treat the dataclass definition and `save_tasks()` as a coupled pair — any field addition requires both to be updated.

---

### Pitfall 8: `complete()` method does not set `completed_at` — timestamp never written

**What goes wrong:** `task.complete()` currently only sets `self.done = True`. If `completed_at` is added as a field but the `complete()` method is not updated to also set `self.completed_at = datetime.now().isoformat()`, the timestamp will always be `None` even for newly completed tasks.

**Why it happens:** The method is a simple one-liner. New fields are not automatically wired to business logic.

**This project specifically:** The `/done/<id>` route calls `task.complete()` directly. Adding `completed_at` as a field without updating `complete()` means the timestamp is never populated.

**Consequences:** `completed_at` is always `None`. The completion history route has no useful data. The feature is structurally present but behaviorally absent.

**Prevention:** Update `complete()` to set `completed_at` at the same time `done` is set to `True`. Guard against overwriting if already set (idempotency): `if not self.completed_at: self.completed_at = datetime.now().isoformat()`.

---

## Minor Pitfalls (low severity — polish and edge cases)

### Pitfall 9: CSS specificity conflict with deadline highlighting

**What goes wrong:** Deadline highlighting requires applying a `red` or `yellow` color to a task row or cell. If the existing CSS for done tasks or priority badges uses the same selectors or higher specificity, the deadline color may be silently overridden by an existing rule.

**Why it happens:** CSS specificity rules are non-obvious. A rule like `.task-row.done { color: grey; }` will override `.task-row.overdue { color: red; }` if both apply and specificity is equal, because source order determines the winner (and `.done` may come later).

**This project specifically:** No CSS was inspected in this analysis. The risk is low for a small project but should be verified by visually testing an overdue task that is also marked done.

**Prevention:** Apply deadline highlighting via inline style (highest specificity, guaranteed to show) during development to confirm the logic works, then move to a CSS class. Use `!important` only as a last resort. Test the combination: overdue + done, overdue + high priority.

---

### Pitfall 10: Completion history route shows done=False tasks if `completed_at` is set

**What goes wrong:** If a task is somehow in a state where `done=False` but `completed_at` is not `None` (e.g., from a data inconsistency or future "reopen" feature), the completion history route must decide how to handle it. Filtering by `completed_at is not None` and filtering by `done=True` are not equivalent.

**Why it happens:** `done` and `completed_at` are two separate fields that can diverge. The `complete()` method sets both atomically, but if future code sets `done` directly without going through `complete()`, or if a reopen feature sets `done=False` without clearing `completed_at`, the fields disagree.

**Prevention for v1.0:** Filter the completion history route by `task.done == True and task.completed_at is not None`. This is conservative and safe. Document that `complete()` is the canonical way to mark completion. The one-way constraint already in the codebase (no reopen path) makes this a latent rather than immediate risk.

---

## Phase-Specific Warnings

| Phase Topic | Pitfall | Severity | Mitigation |
|-------------|---------|----------|------------|
| Add `completed_at` field | `Task(**item)` TypeError on old data (Pitfall 1) | **Blocker** | Default must be `None`; no migration needed |
| Add `completed_at` field | `save_tasks()` does not persist it (Pitfall 7) | **Blocker** | Update serialization dict in `save_tasks()` simultaneously |
| Add `completed_at` field | `complete()` does not set it (Pitfall 8) | **Blocker** | Update `complete()` method at the same time |
| GHCR push workflow | Missing `packages: write` permission (Pitfall 2) | **Blocker** | Declare `permissions:` explicitly in workflow job |
| GHCR push workflow | Build runs despite test failure (Pitfall 4) | Moderate | `needs: [test]` on build job |
| GHCR push workflow | Uppercase owner in image tag (Pitfall 3) | Blocker on some accounts | Lowercase the tag expression |
| Deadline highlighting | None comparison crash (Pitfall 5) | **Blocker** | Guard with `{% if task.due_date and ... %}` |
| Deadline highlighting | Server timezone vs user timezone (Pitfall 6) | Minor/UX | Accept UTC; document the assumption |
| Deadline highlighting | CSS specificity collision (Pitfall 9) | Minor | Test overdue+done combination visually |
| Completion history | Inconsistent `done`/`completed_at` state (Pitfall 10) | Latent | Filter by both fields in the route |

---

## Coupling Map — Fields That Must Change Together

Adding `completed_at` touches **four** locations that must all be updated atomically. Missing any one of them produces a silent failure, not a crash (except Pitfall 1 which crashes immediately):

```
tasks.py  — Task dataclass field definition   (add completed_at: Optional[str] = None)
tasks.py  — complete() method                 (set self.completed_at)
storage.py — save_tasks() serialization dict  (add "completed_at": task.completed_at)
web.py    — new /history route               (read and render task.completed_at)
```

The existing pattern of `save_tasks()` using an explicit dict (not `dataclasses.asdict()`) means this coupling is invisible to the type system. There is no automated warning when a new field is added to the dataclass but not to the serializer.

---

## Sources

- [GitHub Docs: Publishing and installing a package with GitHub Actions](https://docs.github.com/en/packages/managing-github-packages-using-github-actions-workflows/publishing-and-installing-a-package-with-github-actions) — HIGH confidence
- [GitHub Docs: Controlling permissions for GITHUB_TOKEN](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/controlling-permissions-for-github_token) — HIGH confidence
- [GitHub Docs: Working with the Container registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry) — HIGH confidence
- [GitHub community discussion: Repository name must be lowercase](https://github.com/orgs/community/discussions/27086) — HIGH confidence (documented behavior)
- [docker/build-push-action issue #37: lowercase image name](https://github.com/docker/build-push-action/issues/37) — HIGH confidence
- [GitHub Docs: Test before push with GitHub Actions](https://docs.docker.com/build/ci/github-actions/test-before-push/) — HIGH confidence
- [GitHub community discussion: Required status check job skipped when dependent job fails](https://github.com/actions/runner/issues/2566) — HIGH confidence (documented runner behavior)
- [GitHub Docs: Troubleshooting required status checks](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks) — HIGH confidence
- Codebase analysis of `tasks.py`, `storage.py`, `web.py` — HIGH confidence (direct source inspection)

---
*Pitfalls analysis: 2026-03-23*
