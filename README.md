# Deutsche Anki

German flashcard web app with spaced repetition, text-to-speech, and AI study assistant.

## Features

- Spaced repetition with FSRS algorithm
- Text-to-speech for German pronunciation
- AI study assistant (BYOK - Bring Your Own Key)
- Real-time card updates
- PWA support for Android

## Tech Stack

- **Frontend**: Static HTML + HTMX + Pico CSS + PWA
- **Backend**: Hono (Cloudflare Pages Function)
- **Database**: Cloudflare D1 (SQLite)
- **Deployment**: GitHub Actions → Cloudflare Pages

## Project Structure

```
deutsche-anki/
├── frontend/           # Static frontend + Worker
│   ├── index.html      # Main HTML file
│   ├── _worker.js      # Hono API (Cloudflare Worker)
│   └── manifest.json   # PWA manifest
├── doc/               # Project documentation
├── schema.sql         # Database schema
├── wrangler.toml      # Cloudflare config
└── package.json       # Dependencies
```

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Create D1 database:
   ```bash
   npx wrangler d1 create deutsche-anki-local
   ```

3. Update `wrangler.toml` with your database ID (from step 2).

4. Run migrations:
   ```bash
   npx wrangler d1 execute deutsche-anki-local --remote --file=./schema.sql
   ```

5. Start development:
   ```bash
   npm run dev
   ```

6. Open http://localhost:8788 in your browser.

## Deployment

1. Push to GitHub repository
2. Add `CLOUDFLARE_API_TOKEN` to GitHub secrets
3. GitHub Actions will deploy automatically on push to main

## Environment Variables

- `CLOUDFLARE_API_TOKEN`: Cloudflare API token for deployment
- `GITHUB_CLIENT_ID` & `GITHUB_CLIENT_SECRET`: For GitHub OAuth
- `GOOGLE_CLIENT_ID` & `GOOGLE_CLIENT_SECRET`: For Google OAuth
- `AI_ENCRYPTION_KEY`: Key for encrypting user AI keys
