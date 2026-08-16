# System Design Document (SDD)
## Deutsche Anki — German Flashcard Web App

**Version**: 1.1
**Phase**: System Design (Waterfall Stage 2)
**Inputs**: `doc/SRS.md` (v1.2), `doc/project.md`
**Status**: Draft — pending sign-off.

---

## 1. Introduction

### 1.1 Purpose
Translate the SRS into a concrete, reviewable technical design that balances scalability, reliability, availability, maintainability, security, and cost. Stage 2 deliverable; implementation follows sign-off.

### 1.2 Constraints (from SRS §7 / stakeholder)
- **Budget**: $0 — free tiers only (C-3).
- **Timeline / Team**: solo developer, hobby scale; speed-to-working-product valued.
- **Tech stack**: TypeScript only (C-4); static frontend (C-1); no desktop (C-2).
- **Dependencies**: AI via BYOK third-party (C-5); TTS depends on device Web Speech (C-6).

### 1.3 Quality Targets (measurable SLAs / budgets)
| Attribute | Target | Basis |
|---|---|---|
| Availability | **99.9%** (not 99.99%) | Cloudflare-managed; we sacrifice extra nines to avoid cost/complexity |
| Latency (study/deck view) | **≤ 2 s** for ≤1000-card deck | NFR-1.1 |
| Throughput | within **100k req/day** | NFR-1.2 |
| Cost | **$0** | NFR-6.1 |
| Recovery (data) | **≤ 30 days** point-in-time | NFR-3.1 |

### 1.4 References
`doc/SRS.md`, `doc/project.md`, Cloudflare Workers/D1, Hono, HTMX, Pico CSS, `ts-fsrs`, Web Speech API, OpenAI-compatible API.

---

## 2. Architectural Design

### 2.1 Pattern Choice — Monolith Worker (not microservices)
**Decision**: a single Hono Worker (monolith) behind one D1 database; frontend is static.
**Why**: hobby scale, solo dev, free tier. Microservices / event-driven would be **over-engineering for scale we don't need** (red flag avoided). Clear module boundaries (§4) keep it maintainable without distributed complexity.
**Sacrificed**: independent per-service scaling and deploy isolation.

### 2.2 High-Level Architecture
```
┌─────────────────────────┐   HTTPS (fetch / HTMX)   ┌──────────────────────────┐
│ Frontend (static)       │ ───────────────────────▶ │ Pages Function (Hono)      │
│ Cloudflare Pages        │                          │ bound to D1               │
│ HTML+HTMX+Pico, PWA     │ ◀─────────────────────── │ Auth/Decks/Cards/Study/    │
│ Web Speech (TTS)        │   JSON / HTML fragments   │ Export/AI modules (§4)     │
│ AI chat overlay         │                          └───────────┬───────────────┘
└─────────────────────────┘                                      │ D1 binding
        ▲                                                        ▼
        │ OAuth (GitHub/Google)                        ┌──────────────────────┐
        └──────────────────────────────────────────── │ D1 (SQLite)          │
                                                       └──────────────────────┘
                                  ┌──────────────────────────┐
                                  │ External: OAuth, AI (BYOK)│
                                  └──────────────────────────┘
```

### 2.3 Component Boundaries & Ownership (avoids "no clear ownership")
| Module | Owner/Responsibility | Depends on |
|---|---|---|
| Auth | login, session, deletion | users table, OAuth |
| Decks | deck CRUD + counts | decks |
| Cards/Notes | note CRUD + cards derivation | notes, cards |
| Study/SRS | due queue + `ts-fsrs` | cards, reviews |
| Export | JSON serialization | decks, notes, cards, reviews |
| TTS | client playback (no backend) | Web Speech API |
| AI | chat proxy + tools + doc extraction | Auth (key), Decks/Cards |

### 2.4 Data Flow (happy path — study)
1. `GET /api/cards?due=1&deck=:id` → Worker queries D1 (indexed `user_id,due`) → HTML fragment.
2. Rate → `POST /api/review {cardId,rating}` → `ts-fsrs` computes next `due` → write `reviews`.
3. Frontend swaps next card (FR-8.2 immediate). No reload required for own edit.

---

## 3. Database Design (D1 / SQLite)

### 3.1 Schema (DDL)
```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  oauth_sub TEXT NOT NULL,
  oauth_provider TEXT NOT NULL,   -- 'github' | 'google'
  ai_key_enc TEXT,                -- AES-GCM encrypted BYOK key (base64)
  created_at INTEGER NOT NULL,
  UNIQUE(oauth_sub, oauth_provider)
);
CREATE TABLE decks (
  id TEXT PRIMARY KEY, user_id TEXT NOT NULL, name TEXT NOT NULL, created_at INTEGER NOT NULL
);
CREATE INDEX idx_decks_user ON decks(user_id);
CREATE TABLE notes (
  id TEXT PRIMARY KEY, deck_id TEXT NOT NULL, user_id TEXT NOT NULL,
  front TEXT NOT NULL, back TEXT NOT NULL, example TEXT, grammar TEXT,
  note TEXT NOT NULL, tags TEXT, type TEXT NOT NULL,  -- basic|reverse|cloze
  cloze_text TEXT, created_at INTEGER NOT NULL
);
CREATE INDEX idx_notes_user ON notes(user_id);
CREATE INDEX idx_notes_deck ON notes(deck_id);
CREATE TABLE cards (
  id TEXT PRIMARY KEY, note_id TEXT NOT NULL, user_id TEXT NOT NULL,
  deck_id TEXT NOT NULL, template TEXT NOT NULL,  -- forward|reverse|cloze
  due INTEGER NOT NULL, created_at INTEGER NOT NULL
);
CREATE INDEX idx_cards_user_due ON cards(user_id, due);
CREATE TABLE reviews (
  card_id TEXT PRIMARY KEY, user_id TEXT NOT NULL, due INTEGER NOT NULL,
  stability REAL NOT NULL, difficulty REAL NOT NULL, last_reviewed INTEGER, reps INTEGER NOT NULL DEFAULT 0
);
```

### 3.2 Notes → Cards Derivation (FR-3.2–3.4, 3.10)
basic→1 card; reverse→2 (forward + reverse); cloze→1 (from `cloze_text`). Edit updates content; FSRS state preserved per card.

### 3.3 Data Partitioning & Replication
- **Partitioning**: no sharding. Isolation is logical via `user_id` on every table (DR-2/4). Sufficient at hobby scale; single D1 DB.
- **Replication**: D1 native; **Global Read Replication is a paid feature** — deferred. We accept slightly higher read latency for free tier (trade-off).
- **Backup**: D1 Time Travel (30 days) → satisfies NFR-3.1 and recovery SLA.

---

## 4. Module Specifications
(Responsibilities per §2.3. Each returns escaped HTML/JSON; errors use standard problem format, see §8.)

### 4.1 Auth (FR-1) — `/auth/*`
OAuth GitHub/Google → upsert `users` → **HttpOnly Secure SameSite=Lax** session cookie (same-origin). `/auth/delete` cascade-deletes all user rows. Key decrypted per request only.

### 4.2 Decks (FR-2)
`GET/POST/PATCH/DELETE /api/decks`. List aggregates due/total via indexed queries.

### 4.3 Cards/Notes (FR-3)
`GET/POST/PATCH/DELETE /api/notes`, `GET /api/browse?q=`. Validates `note` non-empty, `type` enum, `cloze_text` when cloze. Derives `cards`.

### 4.4 Study/SRS (FR-4)
`GET /api/cards?due=1&deck=` → due cards; `POST /api/review` → `ts-fsrs` scheduling.

### 4.5 Export (FR-7)
`GET /api/decks/:id/export` → JSON deck snapshot.

### 4.6 TTS (FR-5)
Client-only Web Speech (`lang='de-DE'`). Optional Worker Edge-TTS proxy + R2 cache (deferred).

### 4.7 AI Assistant (FR-6)
`POST /api/ai/chat`: OpenAI-compatible client (configurable baseURL/model, decrypted user key). **Tools**: create/update/delete deck & card. **Context**: current card injected. **Doc input**: extract text client-side (`pdfjs-dist`, `mammoth`, `xlsx`, `csv-parse`, `marked`) from `.txt/.md/.pdf/.docx/.xls/.csv` before send. (No server-side parsing — keeps the Worker lean.) Disabled + prompt when no key (FR-6.4). Privacy banner (FR-6.13).

---

## 5. State, Caching, Consistency

### 5.1 State Management
- **System of record**: D1 (server). Single source of truth (FR-8.1).
- **Client state**: ephemeral UI (current card, chat history) + same-origin HttpOnly session cookie. No client DB required for v1.
- **Consistency model**: read-after-write; edits reflected on next fetch / immediate DOM swap (FR-8.2). No distributed consistency needed.

### 5.2 Caching Layers
| Layer | What | Invalidation |
|---|---|---|
| Cloudflare CDN | static frontend assets | deploy = new hash |
| Client | deck-list / last study session | refresh-on-load (FR-8) |
| D1 queries | **not cached** | SRS needs fresh `due` |
| AI responses | **not cached** | privacy + cost; per-request |

**Trade-off**: we sacrifice response caching for data freshness and simplicity (no invalidation bugs).

### 5.3 Observability
- Cloudflare Worker **logs + metrics** (request count, errors, duration) via dashboard.
- Structured error logging; optional free error tracker (e.g. Sentry free tier) — deferred.
- No alerting at hobby scale (red flag "ignoring ops" mitigated by Cloudflare's built-in uptime).

---

## 6. Infrastructure & Deployment Plan

### 6.1 Topology
- **Repo**: monorepo — `frontend/` (static → Cloudflare Pages), `functions/` (Hono → Cloudflare Pages Function + D1).
- **Deploy**: GitHub Actions — (a) build frontend → publish to Pages; (b) `wrangler deploy` Worker + migrate D1.
- **Networking**: one Cloudflare domain (e.g. `*.pages.dev` or custom); frontend + API same-origin; no cross-origin CORS needed.

### 6.2 Deployment Strategy
- **Rolling / direct deploy** via `wrangler` (no blue-green needed at this scale — avoids over-engineering).
- **Preview deployments** per PR (Cloudflare Workers preview) for review.
- **Rollback**: `wrangler rollback` + D1 Time Travel for data.

### 6.3 Scaling Plan
- Horizontal: Cloudflare auto-scales Workers; D1 scales with storage.
- If traffic grows beyond free tier, upgrade D1/Workers plan (no code change).

---

## 7. Design for Failure

| Failure | Mitigation |
|---|---|
| D1 outage / data loss | Time Travel 30-day recovery (§3.3) |
| AI provider timeout/error | graceful disable; user sees message; retry with backoff; **circuit breaker** after N failures |
| TTS unsupported on device | TTS button hidden; app still usable |
| Rate limit (100k/day) | return `429` with retry-after; frontend backs off |
| Auth provider down | login unavailable; existing sessions persist until expiry |
| Secret leak | AI key encrypted at rest; rotate via user settings |

**SPOF acknowledgement**: Cloudflare is the single infrastructure provider (accepted; managed HA, meets 99.9%). Avoids building multi-cloud redundancy we don't need.

---

## 8. Security Design (NFR-2)
- **XSS**: all user/AI text escaped; `textContent` for dynamic inserts; no raw `innerHTML`.
- **CSP**: `default-src 'self'; script-src 'self' <HTMX-CDN-with-SRI>`; no inline scripts.
- **BYOK encryption**: AES-GCM with key from Worker secret; `ai_key_enc` base64; decrypt per request; never to frontend.
- **Session**: HttpOnly, Secure, SameSite=Lax (same-origin); signed.
- **CORS**: not required — frontend and API are same-origin (Cloudflare Pages + Pages Functions).
- **Least privilege**: every query scoped by `user_id`; tools execute within caller's `user_id`.

---

## 9. Trade-offs Documented (Why X over Y, what sacrificed)

| Decision | Chosen | Rejected | Sacrificed |
|---|---|---|---|
| DB | Cloudflare D1 (SQLite) | MongoDB Atlas + server | TCP/server management, richer queries |
| Real-time | Refresh-on-load | WebSocket push | sub-second cross-device sync |
| TTS | Web Speech API | Edge TTS + R2 | neural voice quality / consistency |
| Backend shape | Monolith Worker | Microservices | independent scaling/isolation |
| Caching | Minimal (no D1 cache) | Redis/CDN caching | peak latency / infra cost |
| Deployment | Direct `wrangler` | Blue-green/canary | zero-downtime sophistication |
| HA target | 99.9% | 99.99% | extra nines cost/complexity |
| Provider | Cloudflare-only | Multi-cloud | vendor lock-in risk |

**Guiding principle**: *just enough* — solve current needs (hobby scale, $0) while keeping modules extensible for v2 (offline, stats, reminders).

---

## 10. User Interface Design (mockups)
(As §5 in v1.0 — Decks, Study, Add/Edit, Browse, AI overlay; Pico CSS + HTMX + PWA.) *See prior version; unchanged.*

## 11. API Specification
(As §7 in v1.0 — endpoint table mapped to SRS IDs.) *See prior version; unchanged.*

## 12. Traceability (SRS → Design)
(As §8 in v1.0.) *See prior version; extended by §3.3, §5, §6, §7, §9 above.*

## 13. Open Items (non-blocking)
- TTS fallback when no German voice installed.
- Export JSON exact schema.
- Study queue ordering within a day.
- v2: offline PWA, push reminders, stats, Edge TTS + R2.
