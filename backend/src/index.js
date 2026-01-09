require('dotenv').config();
const express = require('express');
const { expressjwt: jwt } = require('express-jwt');
const jwksRsa = require('jwks-rsa');
const serverless = require('serverless-http');
const db = require('./db');

const app = express();
app.use(express.json());
const cors = require('cors');

const FRONTEND_ORIGIN = process.env.FRONTEND_ORIGIN || '*';
app.use(cors({ origin: FRONTEND_ORIGIN }));

const DEV_BYPASS = process.env.DEV_BYPASS_AUTH === 'true';
const DEV_TEST_USER = process.env.AUTH0_TEST_USER || 'dev|local';
if (DEV_BYPASS) {
  app.use((req, res, next) => {
    if (!req.headers.authorization) {
      req.auth = { sub: DEV_TEST_USER };
    }
    next();
  });
}

const checkJwt = jwt({
  secret: jwksRsa.expressJwtSecret({
    cache: true,
    rateLimit: true,
    jwksRequestsPerMinute: 5,
    jwksUri: `https://${process.env.AUTH0_DOMAIN}/.well-known/jwks.json`
  }),
  audience: process.env.AUTH0_AUDIENCE,
  issuer: `https://${process.env.AUTH0_DOMAIN}/`,
  algorithms: ['RS256']
});

app.get('/.well-known/health', (req, res) => res.json({ ok: true }));

app.get('/auth/config', (req, res) => {
  const config = {
    auth0Domain: process.env.AUTH0_DOMAIN || null,
    auth0Audience: process.env.AUTH0_AUDIENCE || null,
    frontendOrigin: process.env.FRONTEND_ORIGIN || null,
    auth0ClientId: process.env.AUTH0_CLIENT_ID || null,
    devBypassAuth: DEV_BYPASS ? true : false
  };
  res.json({ data: config });
});
async function getOrCreateUserId(client, auth0Id) {
  const userRes = await client.query('SELECT id FROM users WHERE auth0_id=$1', [auth0Id]);
  if (userRes.rows.length === 0) {
    const insert = await client.query('INSERT INTO users (auth0_id, name, email) VALUES ($1, $2, $3) RETURNING id', [auth0Id, 'User', 'user@example.com']);
    return insert.rows[0].id;
  }
  return userRes.rows[0].id;
}

app.get('/api/users/me', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const result = await client.query('SELECT id, auth0_id, name, email, age, has_completed_onboarding, created_at, updated_at FROM users WHERE auth0_id=$1', [auth0Id]);
    client.release();
    if (result.rows.length === 0) return res.status(404).json({ error: 'not_found' });
    res.json({ data: result.rows[0] });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

app.put('/api/users/me', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const { name, email, age, has_completed_onboarding } = req.body;
    const client = await db.pool.connect();
    
    const userId = await getOrCreateUserId(client, auth0Id);
    
    const update = await client.query(
      'UPDATE users SET name=$1, email=$2, age=$3, has_completed_onboarding=$4, updated_at=NOW() WHERE id=$5 RETURNING id, auth0_id, name, email, age, has_completed_onboarding, created_at, updated_at',
      [name, email, age, has_completed_onboarding, userId]
    );
    client.release();
    res.json({ data: update.rows[0] });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

app.get('/api/journal-entries', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);

    const entries = await client.query('SELECT id, content, goal_tags, mood, date, created_at, updated_at FROM journal_entries WHERE user_id=$1 ORDER BY date DESC', [userId]);
    client.release();
    res.json({ data: entries.rows });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

app.get('/api/journal-entries/:id', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);
    const { id } = req.params;
    const result = await client.query('SELECT id, content, goal_tags, mood, date, created_at, updated_at FROM journal_entries WHERE id=$1 AND user_id=$2', [id, userId]);
    client.release();
    if (result.rows.length === 0) return res.status(404).json({ error: 'not_found' });
    res.json({ data: result.rows[0] });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

app.post('/api/journal-entries', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);
    const { id, content, goal_tags, mood, date } = req.body;
    
    const insert = await client.query(
      'INSERT INTO journal_entries (id, user_id, content, goal_tags, mood, date) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id, content, goal_tags, mood, date, created_at, updated_at',
      [id, userId, content, goal_tags || [], mood, date || new Date()]
    );
    client.release();
    res.status(201).json({ data: insert.rows[0] });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

app.put('/api/journal-entries/:id', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);
    const { id } = req.params;
    const { content, goal_tags, mood, date } = req.body;
    
    const update = await client.query(
      'UPDATE journal_entries SET content=$1, goal_tags=$2, mood=$3, date=$4, updated_at=NOW() WHERE id=$5 AND user_id=$6 RETURNING id, content, goal_tags, mood, date, created_at, updated_at',
      [content, goal_tags || [], mood, date, id, userId]
    );
    client.release();
    if (update.rows.length === 0) return res.status(404).json({ error: 'not_found' });
    res.json({ data: update.rows[0] });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

app.delete('/api/journal-entries/:id', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);
    const { id } = req.params;
    const del = await client.query('DELETE FROM journal_entries WHERE id=$1 AND user_id=$2 RETURNING id', [id, userId]);
    client.release();
    if (del.rows.length === 0) return res.status(404).json({ error: 'not_found' });
    res.status(204).end();
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

app.get('/api/goals', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);

    const goals = await client.query('SELECT id, title, description, category, is_active, created_at, updated_at FROM goals WHERE user_id=$1 ORDER BY created_at DESC', [userId]);
    client.release();
    res.json({ data: goals.rows });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

app.get('/api/goals/:id', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);
    const { id } = req.params;
    const result = await client.query('SELECT id, title, description, category, is_active, created_at, updated_at FROM goals WHERE id=$1 AND user_id=$2', [id, userId]);
    client.release();
    if (result.rows.length === 0) return res.status(404).json({ error: 'not_found' });
    res.json({ data: result.rows[0] });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

app.post('/api/goals', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);
    const { id, title, description, category, is_active } = req.body;
    
    const insert = await client.query(
      'INSERT INTO goals (id, user_id, title, description, category, is_active) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id, title, description, category, is_active, created_at, updated_at',
      [id, userId, title, description, category, is_active !== false]
    );
    client.release();
    res.status(201).json({ data: insert.rows[0] });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

app.put('/api/goals/:id', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);
    const { id } = req.params;
    const { title, description, category, is_active } = req.body;
    
    const update = await client.query(
      'UPDATE goals SET title=$1, description=$2, category=$3, is_active=$4, updated_at=NOW() WHERE id=$5 AND user_id=$6 RETURNING id, title, description, category, is_active, created_at, updated_at',
      [title, description, category, is_active, id, userId]
    );
    client.release();
    if (update.rows.length === 0) return res.status(404).json({ error: 'not_found' });
    res.json({ data: update.rows[0] });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

app.delete('/api/goals/:id', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);
    const { id } = req.params;
    const del = await client.query('DELETE FROM goals WHERE id=$1 AND user_id=$2 RETURNING id', [id, userId]);
    client.release();
    if (del.rows.length === 0) return res.status(404).json({ error: 'not_found' });
    res.status(204).end();
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

app.post('/api/sync', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);

    const { journal_entries = [], goals = [], user = null } = req.body;
    await client.query('BEGIN');

    if (user) {
      await client.query(
        'UPDATE users SET name=$1, email=$2, age=$3, has_completed_onboarding=$4, updated_at=NOW() WHERE id=$5',
        [user.name, user.email, user.age, user.has_completed_onboarding, userId]
      );
    }

    for (const entry of journal_entries) {
      await client.query(
        `INSERT INTO journal_entries (id, user_id, content, goal_tags, mood, date, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT (id) DO UPDATE SET 
           content=EXCLUDED.content, 
           goal_tags=EXCLUDED.goal_tags, 
           mood=EXCLUDED.mood, 
           date=EXCLUDED.date, 
           updated_at=EXCLUDED.updated_at`,
        [entry.id, userId, entry.content, entry.goal_tags || [], entry.mood, entry.date, entry.created_at, entry.updated_at]
      );
    }

    for (const goal of goals) {
      await client.query(
        `INSERT INTO goals (id, user_id, title, description, category, is_active, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT (id) DO UPDATE SET 
           title=EXCLUDED.title, 
           description=EXCLUDED.description, 
           category=EXCLUDED.category, 
           is_active=EXCLUDED.is_active, 
           updated_at=EXCLUDED.updated_at`,
        [goal.id, userId, goal.title, goal.description, goal.category, goal.is_active, goal.created_at, goal.updated_at]
      );
    }

    await client.query('COMMIT');
    client.release();
    res.status(200).json({ status: 'ok' });
  } catch (e) {
    console.error(e);
    try { await db.pool.query('ROLLBACK'); } catch (_) {}
    res.status(500).json({ error: 'server_error' });
  }
});

// Moods
app.get('/api/moods', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);
    // Use to_char to return date as plain string without timezone conversion
    const moods = await client.query("SELECT to_char(date, 'YYYY-MM-DD') as date, mood_level FROM moods WHERE user_id=$1 ORDER BY date DESC", [userId]);
    client.release();
    res.json({ data: moods.rows });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

app.post('/api/moods', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const { date, mood_level } = req.body;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);
    const result = await client.query(
      'INSERT INTO moods (user_id, date, mood_level) VALUES ($1, $2, $3) ON CONFLICT (user_id, date) DO UPDATE SET mood_level=$3 RETURNING date, mood_level',
      [userId, date, mood_level]
    );
    client.release();
    res.status(201).json({ data: result.rows[0] });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

if (process.env.AWS_LAMBDA_FUNCTION_NAME) {
  module.exports.handler = serverless(app);
} else {
  const port = process.env.PORT || 3001;
  app.listen(port, () => console.log('Listening on', port));
}
