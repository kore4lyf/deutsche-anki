CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  oauth_sub TEXT NOT NULL,
  oauth_provider TEXT NOT NULL,
  ai_key_enc TEXT,
  created_at INTEGER NOT NULL,
  UNIQUE(oauth_sub, oauth_provider)
);

CREATE TABLE IF NOT EXISTS decks (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_decks_user ON decks(user_id);

CREATE TABLE IF NOT EXISTS notes (
  id TEXT PRIMARY KEY,
  deck_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  front TEXT NOT NULL,
  back TEXT NOT NULL,
  example TEXT,
  grammar TEXT,
  note TEXT NOT NULL,
  tags TEXT,
  type TEXT NOT NULL,
  cloze_text TEXT,
  created_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_notes_user ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_deck ON notes(deck_id);

CREATE TABLE IF NOT EXISTS cards (
  id TEXT PRIMARY KEY,
  note_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  deck_id TEXT NOT NULL,
  template TEXT NOT NULL,
  due INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_cards_user_due ON cards(user_id, due);

CREATE TABLE IF NOT EXISTS reviews (
  card_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  due INTEGER NOT NULL,
  stability REAL NOT NULL,
  difficulty REAL NOT NULL,
  last_reviewed INTEGER,
  reps INTEGER NOT NULL DEFAULT 0
);
