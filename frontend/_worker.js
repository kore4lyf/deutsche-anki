import { Hono } from 'hono';

const app = new Hono();

app.get('/api/health', (c) => {
  return c.json({ status: 'ok', timestamp: Date.now() });
});

app.get('/api/decks', async (c) => {
  const db = c.env.DB;
  if (!db) {
    return c.json([]);
  }
  try {
    const result = await db.prepare('SELECT * FROM decks LIMIT 10').all();
    return c.json(result.results);
  } catch (err) {
    return c.json([]);
  }
});

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    
    // Only handle API routes with the Worker
    if (url.pathname.startsWith('/api/')) {
      return app.fetch(request, env);
    }
    
    // Let Cloudflare Pages handle everything else (static files)
    return env.ASSETS.fetch(request);
  },
};
