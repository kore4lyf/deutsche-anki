# Software Requirements Specification (SRS)
## Deutsche Anki — German Flashcard Web App

**Version**: 1.1
**Phase**: Requirements (Waterfall Stage 1)
**Status**: Draft — pending sign-off.

### Requirement conventions
- **"shall"** denotes a mandatory requirement.
- Every requirement has a **unique ID** and is **atomic** (one statement).
- **Priority**: `[Critical]` (product unusable without it), `[High]`, `[Medium]`, `[Low]`.
- **Rationale** is given for non-obvious requirements.
- Traceability maps each requirement to a stakeholder need (§9).

---

## 1. Introduction

### 1.1 Purpose
This document specifies the functional and non-functional requirements for **Deutsche Anki**, a web application for practicing German via spaced-repetition flashcards, with text-to-speech, real-time card management, and an AI study assistant. It is the Stage 1 (Requirements) deliverable of a Waterfall process.

### 1.2 Scope
**In scope (v1):** web/Android PWA, per-user accounts, deck/card management, FSRS study, German TTS, AI assistant (BYOK) with tool-calling, deck export, refresh-on-load real-time.

**Out of scope (v1 / v2):** native/desktop apps, custom SRS algorithm, live WebSocket push, offline mode, push reminders, statistics dashboard, Edge TTS caching, full i18n.

### 1.3 Definitions
- **SRS**: Spaced Repetition System (learning); also this "Software Requirements Specification".
- **FSRS**: Free Spaced Repetition Scheduler algorithm.
- **PWA**: Progressive Web App.
- **HTMX**: library for server-driven HTML fragment swapping.
- **BYOK**: Bring Your Own Key (user-supplied AI API key).
- **Cloze / Reverse**: card types (see FR-3.3–FR-3.4).
- **TTS**: Text-to-Speech.

### 1.4 References
- `project.md` (Stage 2 design input). `ts-fsrs` library. Cloudflare D1/Workers docs. MDN Web Speech API. Pico CSS, HTMX docs.

### 1.5 Overview
§2 overall description; §3 functional; §4 non-functional; §5 interfaces; §6 data; §7 constraints; §8 acceptance; §9 traceability.

---

## 2. Overall Description

### 2.1 Product Perspective
A self-contained web application. A static frontend is delivered to browsers; a serverless API stores and serves data. The product follows Anki-like study UX but is a custom build (required for real-time, no-desktop operation — see §7).

### 2.2 Product Functions (summary)
Account login; deck management; card management (Basic/Reverse/Cloze, each with a note); FSRS study; German TTS; AI chat assistant; deck export; refresh-on-load real-time.

### 2.3 User Characteristics
German-language learners of any level; able to use a web browser and install a PWA on Android; may optionally supply an AI API key.

### 2.4 Constraints
See §7.

### 2.5 Assumptions and Dependencies
- Cloudflare Pages and Cloudflare free tiers remain available.
- The user's browser supports the Web Speech API (Android Chrome recommended; iOS Safari limited).
- Users wanting AI features can obtain a compatible API key.
- `ts-fsrs` remains runnable in the chosen serverless runtime.

---

## 3. Functional Requirements

### FR-1 — Authentication & Accounts  `[High]`
- **FR-1.1** The system shall authenticate users via **GitHub or Google** OAuth.
- **FR-1.2** The system shall not require the user to create or remember a password. *Rationale: minimize login friction.*
- **FR-1.3** The system shall create a user record upon first successful login.
- **FR-1.4** The system shall scope all stored user data by `user_id`. `[Critical]`
- **FR-1.5** The system shall store session tokens in HttpOnly cookies.
- **FR-1.6** The system shall allow a user to delete their account and all associated decks, cards, and data. `[High]`

### FR-2 — Deck Management  `[High]`
- **FR-2.1** The system shall allow a user to create a deck. `[Critical]`
- **FR-2.2** The system shall allow a user to rename a deck they own. `[Medium]`
- **FR-2.3** The system shall allow a user to delete a deck they own. `[Medium]`
- **FR-2.4** The system shall display the count of due cards per deck. `[High]`
- **FR-2.5** The system shall display the total card count per deck. `[Medium]`

### FR-3 — Card Management  `[Critical]`
- **FR-3.1** The system shall allow manual card creation with fields: deck, front, back, example, grammar, tags. `[Critical]`
- **FR-3.2** The system shall support the Basic card type. `[Critical]`
- **FR-3.3** The system shall support the Reverse card type (both language directions). `[High]`
- **FR-3.4** The system shall support the Cloze card type. `[High]`
- **FR-3.5** The system shall require a non-empty `note` field on every card. `[High]` *Rationale: stakeholder requirement that every card carries a note.*
- **FR-3.6** The system shall store Cloze masked text using `{{cN::...}}` syntax. `[Medium]`
- **FR-3.10** The system shall assign **exactly one** card type (Basic, Reverse, or Cloze) to each note. `[High]`
- **FR-3.7** The system shall allow editing of an existing card. `[High]`
- **FR-3.8** The system shall allow deletion of an existing card. `[High]`
- **FR-3.9** The system shall provide a Browse view searchable by word or tag. `[Medium]`

### FR-4 — Study / SRS  `[Critical]`
- **FR-4.1** The system shall present due cards for a **selected deck or across all decks**. `[Critical]`
- **FR-4.2** The system shall reveal a card's answer upon explicit user action. `[Critical]`
- **FR-4.3** The system shall offer rating options: Again, Hard, Good, Easy. `[Critical]`
- **FR-4.4** The system shall compute the next review date using the FSRS algorithm. `[Critical]`
- **FR-4.5** The system shall persist FSRS state (stability, difficulty, due) per card. `[Critical]`
- **FR-4.6** The system shall display a "No cards due" state when none are due. `[Low]`

### FR-5 — Text-to-Speech  `[High]`
- **FR-5.1** The system shall provide playback of German text via TTS. `[High]`
- **FR-5.2** The system shall provide a TTS control on the card front. `[Medium]`
- **FR-5.3** The system shall provide a TTS control on the card back. `[Medium]`
- **FR-5.4** The system shall provide a TTS control in the Browse preview. `[Low]`

### FR-6 — AI Assistant  `[High]`
- **FR-6.1** The system shall provide an AI chat overlay accessible from every screen. `[High]`
- **FR-6.2** The system shall require a user-supplied AI API key compatible with the **OpenAI Chat Completions API** (any provider, base URL, and model). `[High]` *Rationale: avoid operator cost and centralize privacy responsibility with the user.*
- **FR-6.3** The system shall encrypt the user's AI key at rest. `[High]`
- **FR-6.4** The system shall disable AI features and prompt for a key when none is set. `[Medium]`
- **FR-6.5** The assistant shall be able to create a deck via tools. `[Medium]`
- **FR-6.6** The assistant shall be able to update a deck via tools. `[Medium]`
- **FR-6.7** The assistant shall be able to delete a deck via tools. `[Medium]`
- **FR-6.8** The assistant shall be able to create a card via tools. `[Medium]`
- **FR-6.9** The assistant shall be able to update a card via tools. `[Medium]`
- **FR-6.10** The assistant shall be able to delete a card via tools. `[Medium]`
- **FR-6.11** The assistant shall receive context of the currently viewed card. `[High]`
- **FR-6.12** The system shall allow the user to submit text or a document for card generation by the assistant. `[Medium]`
- **FR-6.13** The system shall disclose that submitted content is sent to a third-party AI provider. `[High]`
- **FR-6.14** The system shall accept document inputs in formats including **.txt, .md, .pdf, .docx, .xls, .csv**, and shall extract plain text before sending to the assistant. `[Medium]`

### FR-7 — Export  `[Medium]`
- **FR-7.1** The system shall export a deck as JSON containing cards, scheduling, and tags. `[Medium]`
- **FR-7.2** The system may optionally export a deck as `.apkg`. `[Low]`

### FR-8 — Real-time  `[High]`
- **FR-8.1** The system shall reflect any create/update/delete via the API on the next page load. `[High]`
- **FR-8.2** The system shall reflect a user's own edit immediately after the edit action without a manual refresh. `[Medium]`

---

## 4. Non-Functional Requirements

### NFR-1 — Performance  `[High]`
- **NFR-1.1** Study and deck views shall render within **2 seconds** for a deck of up to 1000 cards on a broadband connection.
- **NFR-1.2** The system shall operate within Cloudflare Free limits (**100,000 requests/day**).

### NFR-2 — Security  `[Critical]`
- **NFR-2.1** The system shall HTML-escape all user- and AI-supplied text before rendering. `[Critical]`
- **NFR-2.2** The system shall send a Content-Security-Policy header that disallows inline scripts. `[High]`
- **NFR-2.3** The system shall treat AI-generated output as untrusted. `[High]`
- **NFR-2.4** If markdown is rendered, the system shall sanitize it with a vetted sanitizer. `[Medium]`

### NFR-3 — Reliability  `[Medium]`
- **NFR-3.1** The system shall support database point-in-time recovery for at least **30 days**.

### NFR-4 — Usability  `[Medium]`
- **NFR-4.1** The system shall present a minimalist, uncluttered layout.
- **NFR-4.2** The system shall use semantic HTML with labeled form controls.
- **NFR-4.3** The system shall be usable at a **360px** viewport width (Android). `[High]`

### NFR-5 — Portability  `[High]`
- **NFR-5.1** The system shall run in current versions of Chrome, Edge, and Firefox. `[High]`
- **NFR-5.2** The system shall be installable as a PWA on Android. `[High]`

### NFR-6 — Cost  `[High]`
- **NFR-6.1** The system shall run entirely within free service tiers (Cloudflare Pages, Cloudflare Free, D1 Free). *Rationale: no budget allocated.*

### NFR-7 — Privacy  `[High]`
- **NFR-7.1** The system shall disclose AI third-party data sharing in the UI. (Linked to FR-6.13.)

---

## 5. External Interface Requirements

### EIR-1 — User Interface  `[Medium]`
- **EIR-1.1** The UI shall follow an Anki-style layout (Decks, Study, Add/Edit, Browse).
- **EIR-1.2** The UI shall swap content via HTMX fragments without full page reloads.
- **EIR-1.3** The UI shall be styled with a minimalist CSS framework.

### EIR-2 — API  `[High]`
- **EIR-2.1** The API shall exchange JSON over HTTPS. `[High]`
- **EIR-2.2** The API shall be **same-origin** with the frontend (Cloudflare Pages + Pages Functions); cross-origin CORS is not required. `[High]`

### EIR-3 — Hardware  `[Low]`
- **EIR-3.1** The system shall require only a device with a browser and audio output.

### EIR-4 — Communications  `[Critical]`
- **EIR-4.1** All client–server communication shall use HTTPS. `[Critical]`
- **EIR-4.2** AI provider communication shall use HTTPS with the user's key. `[High]`

---

## 6. Data Requirements

- **DR-1** The system shall store users with a unique id, OAuth subject, and encrypted AI key. `[High]`
- **DR-2** The system shall store decks linked to a `user_id`. `[Critical]`
- **DR-3** The system shall store notes with fields: front, back, example, grammar, note, tags, type, cloze_text. `[Critical]`
- **DR-4** The system shall store cards as scheduling instances derived from notes (basic→1, reverse→2, cloze→1). `[Critical]`
- **DR-5** The system shall store FSRS review state per card (due, stability, difficulty, last_reviewed, reps). `[Critical]`
- **DR-6** The system shall encrypt per-user AI keys at rest. `[High]`
- **DR-7** The system shall retain user data until the user deletes it via FR-1.6. `[Medium]`

---

## 7. Constraints

- **C-1** Technical: the frontend shall be a static site on **Cloudflare Pages** (deployed from the GitHub repo); no server code or secrets shall run on the frontend host. `[High]`
- **C-2** Technical: the product shall target web and Android only; no desktop client. `[Medium]`
- **C-3** Budget/Regulatory: no paid services; free tiers only. `[High]`
- **C-4** Technical: implementation language shall be TypeScript. `[Medium]`
- **C-5** Dependency: AI features require a third-party provider accessed via BYOK. `[High]`
- **C-6** Dependency: TTS quality depends on the device's Web Speech API support. `[Medium]`

---

## 8. Acceptance Criteria (verifiable)

| ID | Acceptance test |
|---|---|
| FR-1.1–1.6 | A user can log in via GitHub **or Google** with no password; data is isolated per user; token is HttpOnly; user can delete account + data. |
| FR-2.1–2.5 | User can create/rename/delete decks; home shows due + total counts. |
| FR-3.1–3.10 | User can create Basic/Reverse/Cloze cards, each with a note and exactly one type; edit/delete works; Browse search returns matches. |
| FR-4.1–4.6 | Due cards show for a selected deck **or all decks**; answer reveals; ratings persist; next due date follows FSRS; empty state shows. |
| FR-5.1–5.4 | TTS plays German on front/back/Browse where the browser supports it. |
| FR-6.1–6.14 | Overlay opens everywhere; with an **OpenAI-compatible** key, assistant adds/updates/deletes decks/cards and sees current card; accepts **.txt/.md/.pdf/.docx/.xls/.csv** (text extracted); discloses third-party sending; no key → prompt. |
| FR-7.1 | Export downloads a JSON deck with cards + scheduling + tags. |
| FR-8.1–8.2 | Edits appear on reload and immediately after a user edit. |
| NFR-1.1–1.2 | Render ≤2s for 1000-card deck; stays within 100k req/day. |
| NFR-2.1–2.4 | Injecting `<script>` in a card renders as text, not executed; CSP header present. |
| NFR-3.1 | A deleted/erroneous record can be restored from backup within 30 days. |
| NFR-4.3 / NFR-5.1–5.2 | Usable at 360px; installs as PWA on Android; runs in Chrome/Edge/Firefox. |
| NFR-6.1 | No paid plan required to operate. |
| NFR-7.1 | AI sharing disclosure visible in UI. |
| EIR-2.1–2.2 / EIR-4.1 | API is JSON/HTTPS and same-origin with the frontend. |
| DR-1–DR-7 | Schema supports isolated users, notes, derived cards, FSRS state, encrypted keys, deletion. |
| C-1–C-6 | Architecture respects static frontend, no-desktop, free-tier, TypeScript, BYOK dependency. |

---

## 9. Traceability (Stakeholder Need → Requirements)

| Stakeholder need | Requirement(s) |
|---|---|
| Practice German via SRS on web/Android, no desktop | FR-4.x, NFR-5.x, C-2 |
| Real-time updatable cards | FR-8.x |
| Free to operate | NFR-6.1, C-3 |
| German pronunciation | FR-5.x |
| AI assistant: manage decks/cards + discuss current card | FR-6.x |
| Per-user accounts, simple login | FR-1.x |
| Card types Basic/Reverse/Cloze, each with a note | FR-3.x |
| Export decks | FR-7.x |
| Secure handling of untrusted content | NFR-2.x |
| User owns AI cost/privacy (BYOK) | FR-6.2, FR-6.13, C-5 |
| User controls their data (deletion) | FR-1.6, DR-7 |
| Deployable without a separate server bill | C-1, C-3, EIR-2.x |
