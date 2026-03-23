# Requirements: v1.0 Full-Stack Feature Expansion

**Defined:** 2026-03-23
**Core Value:** Every PR shows test results so regressions are caught before they reach main.

---

## v1 Requirements

### Docker CI — Build & Push to GHCR

- [x] **CI-01**: Workflow file `.github/workflows/ci.yml` chứa cả test job lẫn build+push job
- [x] **CI-02**: Job `test` chạy pytest trên mọi pull request và push lên `main`
- [ ] **CI-03**: Job `build-and-push` chỉ chạy sau khi `test` pass (`needs: test`)
- [ ] **CI-04**: Job `build-and-push` chỉ trigger khi push lên nhánh `main` (không chạy trên PR)
- [ ] **CI-05**: Docker image được push lên `ghcr.io/nguyenbuitk/claude-demo`
- [ ] **CI-06**: Image được tag với `latest` và `sha-<commit-sha>` cùng lúc
- [ ] **CI-07**: Xác thực GHCR bằng `GITHUB_TOKEN` với `permissions: packages: write` — không cần secret thủ công

### Deadline Highlighting

- [ ] **HL-01**: Task có `due_date` đã qua (< hôm nay) và chưa done được highlight màu đỏ (`#fde8e8`)
- [ ] **HL-02**: Task có `due_date` trong khoảng từ hôm nay đến 3 ngày tới (inclusive) và chưa done được highlight màu vàng/amber (`#fff3cd`)
- [ ] **HL-03**: Task không có `due_date` (None) không được highlight
- [ ] **HL-04**: Task đã `done=True` không được highlight dù due_date đã qua
- [ ] **HL-05**: Task đến hạn đúng hôm nay được highlight amber (soon-due), không phải đỏ (overdue)

### Completion History

- [ ] **HI-01**: Field `completed_at: Optional[str] = None` được thêm vào `Task` dataclass
- [ ] **HI-02**: `Task.complete()` ghi timestamp ISO vào `completed_at` khi hoàn thành
- [ ] **HI-03**: `storage.py` serialize và persist `completed_at` vào `tasks.json`
- [ ] **HI-04**: Load `tasks.json` cũ (không có `completed_at`) không bị lỗi — backward compatible
- [ ] **HI-05**: Route `GET /history` hiển thị tất cả task đã hoàn thành (`done=True`)
- [ ] **HI-06**: Danh sách history được sắp xếp theo `completed_at` mới nhất trước
- [ ] **HI-07**: Trang history hiển thị: title, priority, due_date, completed_at (hoặc "—" nếu None), tags
- [ ] **HI-08**: Link "History" được thêm vào header của `index.html`
- [ ] **HI-09**: Trang history là read-only — không có nút Done/Edit/Delete

---

## v2 Requirements

### Docker CI (nâng cao)

- **CI-v2-01**: Build cache (`cache-from: type=gha`) để tăng tốc build lần sau
- **CI-v2-02**: Multi-platform build (`linux/amd64,linux/arm64`) cho ARM deployment
- **CI-v2-03**: Build attestation (supply-chain security)

### Deadline Highlighting (nâng cao)

- **HL-v2-01**: Text label "OVERDUE" / "Soon" trong ô Due Date (hỗ trợ colorblind)
- **HL-v2-02**: Countdown "2 ngày còn lại" trong ô Due Date
- **HL-v2-03**: Cấu hình được ngưỡng cảnh báo (mặc định 3 ngày)

### Completion History (nâng cao)

- **HI-v2-01**: Lọc history theo tag
- **HI-v2-02**: Xóa history / bulk delete (có confirm)
- **HI-v2-03**: Phân trang nếu danh sách > 100 task

---

## Out of Scope

| Feature | Lý do |
|---------|-------|
| Auto-deploy sau khi push lên GHCR | Deferred — push to registry là đủ cho v1 |
| Block merge nếu test fail | Explicit decision — visibility only, branch protection là bước tiếp theo |
| Test coverage reporting | Deferred to future phase |
| Task reopen / undo completion | Out of scope theo PROJECT.md |
| GHCR package visibility setting | Manual action trên GitHub UI, không phải code |
| Migration script cho `completed_at` | Không cần — dataclass default `None` xử lý backward compat tự động |

---

## Traceability

| Requirement | Phase | Workstream | Status |
|-------------|-------|------------|--------|
| CI-01 | Phase 2 | DevOps | Pending |
| CI-02 | Phase 2 | DevOps | Pending |
| CI-03 | Phase 2 | DevOps | Pending |
| CI-04 | Phase 2 | DevOps | Pending |
| CI-05 | Phase 2 | DevOps | Pending |
| CI-06 | Phase 2 | DevOps | Pending |
| CI-07 | Phase 2 | DevOps | Pending |
| HL-01 | Phase 3 | Dev 1 | Pending |
| HL-02 | Phase 3 | Dev 1 | Pending |
| HL-03 | Phase 3 | Dev 1 | Pending |
| HL-04 | Phase 3 | Dev 1 | Pending |
| HL-05 | Phase 3 | Dev 1 | Pending |
| HI-01 | Phase 4 | Dev 2 | Pending |
| HI-02 | Phase 4 | Dev 2 | Pending |
| HI-03 | Phase 4 | Dev 2 | Pending |
| HI-04 | Phase 4 | Dev 2 | Pending |
| HI-05 | Phase 4 | Dev 2 | Pending |
| HI-06 | Phase 4 | Dev 2 | Pending |
| HI-07 | Phase 4 | Dev 2 | Pending |
| HI-08 | Phase 4 | Dev 2 | Pending |
| HI-09 | Phase 4 | Dev 2 | Pending |

**Coverage:**
- v1 requirements: 21 total
- Mapped to phases: 21
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-23*
*Last updated: 2026-03-23 after milestone v1.0 definition*
