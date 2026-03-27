# Phase 2 — CI/CD Pipeline

**Goal:** Push to main → GitHub Actions tự động test + build + push image lên GHCR
**Branch:** `gsd/phase-02-ci-cd-pipeline`
**Completed:** 2026-03-24

## Progress

| Step | Resource | Status |
|------|----------|--------|
| 1 | GitHub Actions: `test` job | ✅ Done (2026-03-24) |
| 2 | GitHub Actions: `build-and-push` job (GHCR) | ✅ Done (2026-03-24) |

---

## Step 1: `test` Job ✅

**Kết quả thực tế** — `.github/workflows/ci.yml`:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
          cache: 'pip'
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest
      - name: Run tests
        run: pytest
```

**Trigger:** Mọi `pull_request` và `push` lên `main`

---

## Step 2: `build-and-push` Job (GHCR) ✅

**Kết quả thực tế:**

```yaml
  build-and-push:
    needs: [test]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
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
          images: ghcr.io/${{ github.repository_owner }}/claude-demo
          tags: |
            type=raw,value=latest
            type=sha,prefix=sha-,format=short
      - name: Build and push image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

**Tags được push:**
- `ghcr.io/nguyenbuitk/claude-demo:latest`
- `ghcr.io/nguyenbuitk/claude-demo:sha-<short-commit>`

**Lưu ý:**
- Dùng `GITHUB_TOKEN` (không cần tạo secret thêm) → `packages: write` permission
- `needs: [test]` → chỉ build nếu test pass
- Chỉ chạy trên `push` to `main` (không chạy trên PR)

---

## Toàn bộ Pipeline Flow (Phase 2)

```
git push origin main
        │
        ▼
  GitHub Actions
        │
        ├─► [test] ──────────────────────────────────────────►  pytest 8/8 pass
        │         └── (nếu fail → dừng, không build)
        │
        └─► [build-and-push] (chỉ sau test pass + push to main)
                    │
                    ├── docker build (multi-stage)
                    ├── docker tag :latest + :sha-xxxxx
                    └── docker push → ghcr.io/nguyenbuitk/claude-demo
```

---

## Key Values

```
GHCR Image  : ghcr.io/nguyenbuitk/claude-demo:latest
              ghcr.io/nguyenbuitk/claude-demo:sha-<commit>
Registry    : GitHub Container Registry (GHCR)
Auth        : GITHUB_TOKEN (automatic, không cần setup)
```

---

## Verify Checklist

- [x] PR mở → `test` job chạy tự động
- [x] Merge to main → `build-and-push` job chạy sau `test`
- [x] Image xuất hiện tại `ghcr.io/nguyenbuitk/claude-demo`
- [x] Tags `:latest` và `:sha-xxx` đều được push
- [x] Build fail nếu test fail (dependency `needs: [test]`)
