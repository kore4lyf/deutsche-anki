# Deutsche Anki

[![Deploy to Cloudflare Pages](https://github.com/kore4lyf/deutsche-anki/actions/workflows/deploy.yml/badge.svg)](https://github.com/kore4lyf/deutsche-anki/actions/workflows/deploy.yml)

A German flashcard web app for practicing vocabulary with spaced repetition, text-to-speech, and an AI study assistant. Built for web and Android (PWA), no desktop required.

## Features

- **Spaced Repetition** — FSRS algorithm schedules reviews for optimal retention
- **Card Types** — Basic, Reverse (bidirectional), and Cloze (fill-in-the-blank)
- **Text-to-Speech** — German pronunciation via Web Speech API
- **AI Assistant** — Chat overlay that can create/edit cards (BYOK: bring your own API key)
- **Real-time Updates** — Edits reflect instantly across devices
- **PWA** — Install on Android for a native-like experience
- **Export** — Download decks as JSON for backup

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | HTML, HTMX, Pico CSS |
| Backend | Hono (Cloudflare Worker) |
| Database | Cloudflare D1 (SQLite) |
| SRS | ts-fsrs |
| Hosting | Cloudflare Pages |
| CI/CD | GitHub Actions |

## Quick Start

```bash
# Install dependencies
npm install

# Create D1 database
npx wrangler d1 create deutsche-anki-local

# Copy the database_id to wrangler.toml, then run migrations
npx wrangler d1 execute deutsche-anki-local --remote --file=./schema.sql

# Start dev server
npm run dev
```

Open [http://localhost:8788](http://localhost:8788)

## Project Structure

```
deutsche-anki/
├── frontend/
│   ├── index.html        # Main HTML page
│   ├── _worker.js        # Hono API (Cloudflare Worker)
│   └── manifest.json     # PWA manifest
├── doc/                  # Specs and design docs
│   ├── SRS.md           # Software requirements
│   ├── SDD.md           # System design
│   └── scope.md         # Feature tracking
├── schema.sql           # Database migrations
├── wrangler.toml        # Cloudflare config
└── package.json
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/decks` | List user decks |
| POST | `/api/decks` | Create deck |
| GET | `/api/notes` | List notes |
| POST | `/api/notes` | Create note |
| GET | `/api/cards?due=1` | Get due cards |
| POST | `/api/review` | Submit review |

## Deployment

1. Create a Cloudflare API token with D1 and Pages permissions
2. Add it as `CLOUDFLARE_API_TOKEN` in GitHub repo secrets
3. Push to `master` — GitHub Actions deploys automatically

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `CLOUDFLARE_API_TOKEN` | Deployment authentication |
| `GITHUB_CLIENT_ID` | GitHub OAuth (planned) |
| `GITHUB_CLIENT_SECRET` | GitHub OAuth (planned) |
| `GOOGLE_CLIENT_ID` | Google OAuth (planned) |
| `GOOGLE_CLIENT_SECRET` | Google OAuth (planned) |
| `AI_ENCRYPTION_KEY` | Encrypt user AI keys at rest |

## License

MIT
