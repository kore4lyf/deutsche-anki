# Project

## Overview
Deutsche Anki: a **German (Deutsche) flashcard web app** for spaced-repetition practice on **web and Android**, with **text-to-speech** and **real-time card updates**. No desktop.

## Key decisions
- **Custom app** (not Anki): required for real-time updates without desktop.
- **Auth**: **per-user accounts** — each user has their own decks, cards, and progress. Use GitHub OAuth or Cloudflare Access. Data scoped by `user_id`.
- **Real-time**: **refresh on load** — cards re-fetch on page open / after an edit. No WebSocket push needed (sufficient for solo study).
- **Accessible**: web (any browser) + Android (via PWA install). No native app needed.

## Stack (simple, all TypeScript)
- **Frontend**: static HTML + **HTMX** (no framework, no build step) + **Pico CSS** (modern minimalist, classless, CDN, zero JS/build) + **PWA** (manifest + service worker).
- **Host (frontend)**: **Cloudflare Pages** — code on GitHub, deployed from the repo, free. Same origin as the API.
- **Backend / API**: small serverless API — **Hono** as a **Cloudflare Pages Function** (same origin as the frontend), free, GitHub-connected.
- **Database**: **Cloudflare D1** (serverless **SQLite**, Free plan: ~10 DBs, 5 GB storage) — free, serverless, no separate host.
- **SRS**: `ts-fsrs` (free spaced-repetition algorithm) — no custom engine.
- **TTS** (researched, all free):
  - **Primary**: **Web Speech API** (browser-native, zero infra, works on Cloudflare Pages). German voices on Android Chrome / Edge. Caveat: device-dependent voice availability.
  - **Upgrade**: **Microsoft Edge TTS** (neural German, no API key) via a small Cloudflare Worker route to avoid CORS. Unofficial but free.
  - **Fallback**: **Wiktionary / Wikimedia Commons** human audio via MediaWiki API (incomplete coverage).
  - **Rejected**: dict.cc (no API, scraping/ToS/CORS issues); cloud TTS free tiers (need keys); self-hosted (too heavy for serverless).

## Architecture
1. Browser (Cloudflare Pages) loads HTMX UI, installed as PWA on Android.
2. HTMX calls the serverless API (cards CRUD + review/scheduling).
3. API reads/writes **D1 (SQLite)**; `ts-fsrs` computes next-review scheduling.
4. Any edit is instantly visible on all devices (real-time via shared API).
5. TTS speaks German via Web Speech API on the client.

## API (outline)
- `GET    /cards`          list due / all cards
- `POST   /cards`          create card (word, translation, example, grammar)
- `PATCH  /cards/:id`      update card (real-time)
- `POST   /review`         submit review -> FSRS scheduling
- `GET    /decks/:id/export`  export a deck (JSON; optional `.apkg`)
- `GET    /audio?word=...` (optional) fetch TTS audio URL

## Pages & UI (Anki-style)
Minimalist Pico CSS, laid out like standard Anki. HTMX swaps fragments; no page reloads.

1. **Decks / Home** (`/`)
   - List of decks with **due count** and total cards (like Anki deck overview).
   - "Study" button per deck; "Add" and "Browse" in the header.

2. **Study / Review** (`/study/:deck`)
   - **Card front**: German word + 🔊 TTS button. "Show Answer" button.
   - **Card back** (after reveal): translation, example sentence, grammar note + 🔊.
   - Rating row (FSRS): **Again · Hard · Good · Easy** → `POST /review`.
   - Auto-advances to next due card; shows "No cards due" when empty.

3. **Add / Edit Card** (`/add`, `/edit/:id`)
   - Form: Deck selector, Front (German), Back (translation), Example, Grammar, Tags.
   - Save → `POST /cards` or `PATCH /cards/:id` (real-time update).

4. **Browse** (`/browse`)
   - Searchable table of all cards (search by word/tag) — like Anki browser.
   - Each row: edit / delete; click to preview with TTS.

5. **(Optional) Deck settings / Stats** — SRS parameters, reviews-over-time. Defer to later.

6. **Export Deck** (on Deck / Browse)
   - "Export" button → `GET /decks/:id/export` downloads the deck as **JSON** (our schema: cards, scheduling, tags) for backup/portability.
   - Optional: generate an **`.apkg`** (Anki format) so decks can also be used in Anki. More complex; defer unless needed.

## Deployment
- **Frontend**: Cloudflare Pages (from repo).
- **API + DB**: **Cloudflare Pages Function** (Hono) + **D1 (SQLite)**, free tier, deployed from GitHub. Same origin as the frontend.
- Both free; no desktop; no paid services.

## Feasibility (verified)
- **Frontend on Cloudflare Pages**: static HTML + HTMX, no build step. PWA (manifest + service worker) served with free HTTPS/CDN. Deployed from the GitHub repo. Same origin as the API — no CORS needed.
- **Backend on Cloudflare Workers + D1**: D1 is on the Free plan (serverless SQLite, no TCP/server needed — Cloudflare-native). Local dev via `wrangler dev` (simulates Workers + D1). TypeScript native; `ts-fsrs` (pure TS) runs in Workers runtime. D1 accessed via a Worker binding (no connection string).
- **TTS**: Web Speech API = zero infra. Edge TTS upgrade feasible — Workers support outbound WebSocket (`fetch` + `Upgrade: websocket`), so a Worker route can proxy Microsoft neural German TTS (no API key).
- **Real-time**: API + DB is single source of truth; edits reflect on next fetch. Optional WebSocket push later.
- **Free-tier limits (fine for hobby)**: Cloudflare Pages bandwidth; D1 Free ~10 DBs / 5 GB storage; Pages Functions 100k req/day.

## Auth & accounts
- **Method (recommended): GitHub OAuth** — one-click login, no password, minimal dev effort (standard OAuth flow in the Worker). Alternative: Cloudflare Access (zero auth code, GitHub/Google as IdP) if you prefer zero backend auth.
- Per-user: each user owns their decks/cards/progress; all queries scoped by `user_id`. No shared/global decks.
- **AI key = BYOK (Bring Your Own Key)**: each user pastes their own AI API key (stored encrypted per user). No AI cost to the operator. AI features disabled with a prompt if no key is set.
- Secrets (OAuth client, encryption key) stored as Cloudflare Worker secrets — never in the frontend.

## Content creation
- **Empty on first start** — no preloaded data; user builds their own.
- **Manual**: user creates decks and cards by hand via Add/Edit form.
- **AI-assisted**: user can add decks/cards via AI (see assistant below).

## Card types
Every card supports these and **every card has a `note`** (free-text user/AI note):
1. **Basic** — German front → translation/example back.
2. **Reverse** — also generates the EN→DE direction (practice both ways).
3. **Cloze** — fill-in-the-blank sentence (e.g. "Ich ___ Deutsch.") for grammar/context practice.

## AI Assistant (chat overlay)
- A chat UI **overlay** available on every screen, powered by an LLM (OpenAI/Claude) with **tool/function calling**.
- The assistant can **add, remove, or update a deck or a card** via tools exposed by the Worker API.
- The assistant **sees the current card** in context, so the user can discuss it (e.g. ask for mnemonics, pronunciation tips, example usage) to memorize better.
- User can also paste **text or a document** and ask the assistant to generate cards from it.
- **BYOK**: user provides their own AI API key (stored encrypted per user); no key → AI features prompt the user to add one. **Privacy note**: anything the user sends to the assistant goes to the third-party AI provider — surface this clearly in the UI.
- AI is optional: manual + empty-start always work without it.

## Security (recommended)
- **XSS**: never inject raw user/AI text via `innerHTML`. The Worker returns HTML with all card/AI content **HTML-escaped**; on the client, prefer `textContent` / `hx-swap` with escaped fragments. Treat AI output as untrusted.
- Add a **Content-Security-Policy** header (no inline scripts; HTMX loaded from CDN with SRI). No `eval`.
- If rendering markdown (notes), sanitize with a vetted sanitizer (e.g. DOMPurify) — never raw.
- Encrypt per-user AI keys at rest; OAuth tokens in HttpOnly cookies.

## Data model (D1 / SQLite)
**Two-table model (recommended)** to cleanly support basic/reverse/cloze:
- `users(id, oauth_sub, ai_key_encrypted, ...)` — created on first login.
- `decks(id, user_id, name, created_at)`.
- `notes(id, deck_id, user_id, front, back, example, grammar, note, tags, type, cloze_text, created_at)` — the **content source of truth**. `type` ∈ {basic, reverse, cloze}; `note` always present; `cloze_text` holds `{{c1::...}}` for cloze.
- `cards(id, note_id, user_id, deck_id, template, due, ...)` — **scheduling instances** derived from a note:
  - basic → 1 card; reverse → 2 cards (DE→EN, EN→DE); cloze → 1 card rendered from `cloze_text`.
- `reviews(card_id, user_id, due, stability, difficulty, last_reviewed, reps)` — FSRS state; `due` drives the due queue.

## Repo & deployment
- **Monorepo** (one GitHub repo): `frontend/` (static site → Cloudflare Pages) + `functions/` (Hono API → Cloudflare Pages Function + D1).
- Deploy both via **GitHub Actions**: frontend to Pages, worker via `wrangler deploy`.
- `wrangler.toml` binds D1; Worker secrets hold OAuth client + AI API key.
- Frontend and API share one Cloudflare origin (no cross-origin CORS).

## Scope
- First version: documentation/notes only (no code yet).
- Out of scope: native mobile apps, custom SRS math (use ts-fsrs), desktop, live WebSocket push.

## Recommendations (items 5–11)
5. **FSRS tuning**: use `ts-fsrs` defaults; desired retention ~0.90. Per-user override later. No setup needed for v1.
6. **Audio**: **Web Speech API** for v1 (zero infra). Edge TTS + R2 caching is a later enhancement.
7. **PWA offline**: defer — v1 is online-only. Add service-worker caching later if wanted.
8. **Study reminders**: defer — PWA push notifications need SW + subscription; v2.
9. **Testing/CI**: GitHub Actions runs `tsc` + lint on push; add a few unit tests for FSRS scheduling. Keep light.
10. **i18n / a11y**: UI in **English**; rely on Pico for contrast/layout; ensure form labels + semantic HTML. Full i18n deferred.
11. **Stats**: defer to v2 (reviews-over-time, per-deck analytics).

## Notes / open questions
- **GitHub-only backend rejected**: using the repo/GitHub API as a DB would require a commit on every data change — wrong model for dynamic, real-time flashcard data. Chose **Cloudflare Workers + D1** instead: serverless, no separate server, GitHub-deployable.
- **DB choice**: switched from MongoDB → **Cloudflare D1 (SQLite)** to avoid the Mongo TCP/server issue and stay fully serverless.
- Web Speech API voice quality varies by device; Edge TTS / Wiktionary fallback optional.
- Edge TTS is unofficial; Web Speech API is the safe default if it breaks.
