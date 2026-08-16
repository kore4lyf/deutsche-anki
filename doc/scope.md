# Scope

**Product:** Deutsche Anki, a German flashcard web app with spaced repetition, text to speech, real time card updates, and an AI study assistant.
**Workflow:** Lean (project default). Auth, AI, and security run at Medium.
**Specs:** design lives in `doc/SRS.md` and `doc/SDD.md`. This file is the living plan.

## At a glance

| # | Feature | Phase | Status |
|---|---|---|---|
| 1 | Project scaffold and deploy | Foundations | done |
| 2 | Authentication and accounts | Foundations | planned |
| 3 | Data schema and persistence | Foundations | planned |
| 4 | Security baseline | Foundations | planned |
| 5 | Deck management | Core study | planned |
| 6 | Card and note management | Core study | planned |
| 7 | Study and SRS loop | Core study | planned |
| 8 | Browse and search | Core study | planned |
| 9 | Text to speech | Core study | planned |
| 10 | Deck export | Core study | planned |
| 11 | User interface and PWA | Core study | planned |
| 12 | AI assistant overlay and BYOK | AI assistant | planned |
| 13 | AI document ingestion | AI assistant | planned |
| 14 | AI tool calling for cards | AI assistant | planned |
| 15 | Offline study mode | Deferred | dropped |
| 16 | Study reminders | Deferred | dropped |
| 17 | Statistics dashboard | Deferred | dropped |

## Phase 1, Foundations

### 1. Project scaffold and deploy
Set up the monorepo and the free deployment pipeline so the app can go live.
Done when: a hello page on Cloudflare Pages talks to a Pages Function that reads from D1, all deployed from the GitHub repo by GitHub Actions.
- [x] Design it (spec) — see `doc/SDD.md` sections 2, 6
- [x] Build it: /develop scaffold
  - Monorepo with `frontend/` and `functions/`
  - Cloudflare Pages plus Pages Function plus D1 binding
  - GitHub Actions to deploy both
- [x] Verify it: /check verify scaffold
- [x] Test it: /test scaffold

### 2. Authentication and accounts · Medium
Let users sign in with GitHub or Google and own their data, with self service deletion.
Done when: a user logs in with no password, sees only their own decks, and can delete the account and all data.
- [x] Design it (spec) — `doc/SRS.md` FR-1, `doc/SDD.md` 4.1, 6
- [ ] Build it: /develop auth
  - OAuth routes for GitHub and Google
  - Same origin HttpOnly session cookie
  - Account deletion that cascade removes data
- [ ] Verify it: /check verify auth
- [ ] Test it: /test auth

### 3. Data schema and persistence
Create the tables and the note to card derivation that the whole app reads and writes.
Done when: users, decks, notes, cards, and reviews exist with correct indexes and per user isolation.
- [x] Design it (spec) — `doc/SDD.md` 3
- [ ] Build it: /develop schema
  - D1 schema and migrations
  - Note to card derivation (basic one, reverse two, cloze one)
  - Cascade delete on account removal
- [ ] Verify it: /check verify schema
- [ ] Test it: /test schema

### 4. Security baseline · Medium
Stop the common web attacks before features grow.
Done when: all user and AI text is escaped before render, a content security policy is sent, and the AI key is encrypted at rest.
- [x] Design it (spec) — `doc/SRS.md` NFR-2, `doc/SDD.md` 8
- [ ] Build it: /develop security
  - Escape all rendered text, no raw inner HTML
  - Content security policy header
  - AES encryption for the stored AI key
- [ ] Verify it: /check verify security
- [ ] Test it: /test security

## Phase 2, Core study

### 5. Deck management
Let users create, rename, and delete decks, and see due and total counts.
Done when: the home screen lists decks with due counts and study, add, and browse actions.
- [x] Design it (spec) — `doc/SRS.md` FR-2, `doc/SDD.md` 4.2
- [ ] Build it: /develop decks
  - Deck create, rename, delete
  - Due and total count queries
- [ ] Verify it: /check verify decks
- [ ] Test it: /test decks

### 6. Card and note management
Support basic, reverse, and cloze cards, each with a required note.
Done when: a user creates and edits cards of all three types, and every card has a note.
- [x] Design it (spec) — `doc/SRS.md` FR-3, `doc/SDD.md` 3.2, 4.3
- [ ] Build it: /develop cards
  - Note create, edit, delete
  - Type handling and cloze text storage
  - Derive and update scheduling cards
- [ ] Verify it: /check verify cards
- [ ] Test it: /test cards

### 7. Study and SRS loop
Present due cards, show the answer, take a rating, and schedule the next review.
Done when: a user studies a deck or all decks, rates with Again Hard Good Easy, and FSRS sets the next due date.
- [x] Design it (spec) — `doc/SRS.md` FR-4, `doc/SDD.md` 4.4
- [ ] Build it: /develop study
  - Due card query for one deck and all decks
  - Reveal answer and rating buttons
  - ts-fsrs scheduling and storage
- [ ] Verify it: /check verify study
- [ ] Test it: /test study

### 8. Browse and search
Let users find cards by word or tag and preview or edit them.
Done when: the browse view searches cards and offers edit, delete, and text to speech preview.
- [x] Design it (spec) — `doc/SRS.md` FR-3.9, `doc/SDD.md` 4.3
- [ ] Build it: /develop browse
  - Search by front, back, or tag
  - Row actions for edit, delete, preview
- [ ] Verify it: /check verify browse
- [ ] Test it: /test browse

### 9. Text to speech
Speak German on the card front, back, and browse using the browser voice.
Done when: a speaker button plays the German text where the device supports it.
- [x] Design it (spec) — `doc/SRS.md` FR-5, `doc/SDD.md` 4.6
- [ ] Build it: /develop tts
  - Web Speech call with German voice
  - Speaker control on study and browse
- [ ] Verify it: /check verify tts
- [ ] Test it: /test tts

### 10. Deck export
Let a user download a deck as JSON for backup.
Done when: export returns the deck with cards, scheduling, and tags.
- [x] Design it (spec) — `doc/SRS.md` FR-7, `doc/SDD.md` 4.5
- [ ] Build it: /develop export
  - JSON serialization of deck and cards
  - Download from deck or browse
- [ ] Verify it: /check verify export
- [ ] Test it: /test export

### 11. User interface and PWA
Build the Anki style screens with a minimal look and install the app on Android.
Done when: the pages load on mobile, swap without full reloads, and install as a PWA.
- [x] Design it (spec) — `doc/SRS.md` EIR-1, `doc/SDD.md` 5, 10
- [ ] Build it: /develop ui
  - Pico CSS plus HTMX pages (decks, study, add, edit, browse)
  - Manifest and service worker for install
- [ ] Verify it: /check verify ui
- [ ] Test it: /test ui

## Phase 3, AI assistant

### 12. AI assistant overlay and BYOK · Medium
Add a chat panel on every screen that uses the user's own AI key.
Done when: with a key set, the overlay opens everywhere, discloses third party sending, and prompts when no key exists.
- [x] Design it (spec) — `doc/SRS.md` FR-6.1 to 6.4, 6.13, `doc/SDD.md` 4.7
- [ ] Build it: /develop ai-overlay
  - Chat overlay UI on all pages
  - OpenAI compatible client with user key
  - Privacy banner and no key prompt
- [ ] Verify it: /check verify ai-overlay
- [ ] Test it: /test ai-overlay

### 13. AI document ingestion
Turn uploaded text and documents into cards through the assistant.
Done when: a user uploads txt, md, pdf, docx, xls, or csv, and the text is extracted client side before sending.
- [x] Design it (spec) — `doc/SRS.md` FR-6.12, 6.14, `doc/SDD.md` 4.7
- [ ] Build it: /develop ai-docs
  - Client side text extraction for each format
  - Send plain text to the assistant
- [ ] Verify it: /check verify ai-docs
- [ ] Test it: /test ai-docs

### 14. AI tool calling for cards · Medium
Let the assistant create, update, and delete decks and cards, with the current card in context.
Done when: the assistant manages cards through tools and can discuss the card on screen.
- [x] Design it (spec) — `doc/SRS.md` FR-6.5 to 6.11, `doc/SDD.md` 4.7
- [ ] Build it: /develop ai-tools
  - Tool definitions for deck and card actions
  - Current card context in the prompt
  - Enforce user scope on every tool call
- [ ] Verify it: /check verify ai-tools
- [ ] Test it: /test ai-tools

## Phase 4, Deferred (dropped for v1)

### 15. Offline study mode
Dropped from v1. Study needs the API for now.

### 16. Study reminders
Dropped from v1. Push notifications need more setup.

### 17. Statistics dashboard
Dropped from v1. Progress charts come later.

## /scope complete

Plan written to `doc/scope.md`. Seventeen features across four phases. Fourteen are planned for v1, three are dropped. All features show design done because `doc/SRS.md` and `doc/SDD.md` already hold the requirements and design. Project workflow default is Lean. Auth, AI, and security run at Medium because they carry the most risk. Next safe pickup is feature 1, the scaffold, since every later feature builds on it.
