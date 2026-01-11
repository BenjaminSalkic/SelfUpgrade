require('dotenv').config();
const express = require('express');
const { expressjwt: jwt } = require('express-jwt');
const jwksRsa = require('jwks-rsa');
const serverless = require('serverless-http');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { body, param, validationResult } = require('express-validator');
const xss = require('xss');
const db = require('./db');
const { encrypt, decrypt, encryptFields, decryptFields } = require('./crypto');

const app = express();

// ===========================================
// SECURITY MIDDLEWARE
// ===========================================

// Security headers (XSS protection, content security policy, etc.)
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  crossOriginEmbedderPolicy: false,
}));

// Rate limiting - protect against DDoS and brute force
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per window
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'too_many_requests', message: 'Too many requests, please try again later.' },
  skip: (req) => req.path === '/.well-known/health', // Skip health checks
});
app.use(limiter);

// Stricter rate limit for auth-related endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20, // Only 20 auth attempts per 15 minutes
  message: { error: 'too_many_requests', message: 'Too many authentication attempts.' },
});

// Body parsing with size limit to prevent payload attacks
app.use(express.json({ limit: '1mb' }));

// CORS configuration - require explicit origin in production
const cors = require('cors');
const FRONTEND_ORIGIN = process.env.FRONTEND_ORIGIN;
const corsOptions = {
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, curl, etc.) in development
    if (!origin && process.env.NODE_ENV !== 'production') {
      return callback(null, true);
    }
    // In production, require explicit origin match
    if (FRONTEND_ORIGIN && (origin === FRONTEND_ORIGIN || FRONTEND_ORIGIN === '*')) {
      return callback(null, true);
    }
    // Allow Vercel preview deployments
    if (origin && origin.includes('vercel.app')) {
      return callback(null, true);
    }
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
};
app.use(cors(corsOptions));

// ===========================================
// XSS SANITIZATION HELPER
// ===========================================
function sanitizeInput(obj) {
  if (!obj || typeof obj !== 'object') return obj;
  const sanitized = {};
  for (const [key, value] of Object.entries(obj)) {
    if (typeof value === 'string') {
      sanitized[key] = xss(value);
    } else if (Array.isArray(value)) {
      sanitized[key] = value.map(v => typeof v === 'string' ? xss(v) : v);
    } else {
      sanitized[key] = value;
    }
  }
  return sanitized;
}

// ===========================================
// VALIDATION MIDDLEWARE
// ===========================================
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: 'validation_error',
      details: errors.array().map(e => ({ field: e.path, message: e.msg }))
    });
  }
  next();
};

// Validation schemas
const userValidation = [
  body('name').optional().isString().isLength({ max: 100 }).trim(),
  body('email').optional().isEmail().normalizeEmail(),
  body('age').optional().isInt({ min: 0, max: 150 }),
  body('has_completed_onboarding').optional().isBoolean(),
];

const journalEntryValidation = [
  body('id').optional().isUUID(),
  body('content').isString().isLength({ min: 1, max: 50000 }).trim(),
  body('goal_tags').optional().isArray(),
  body('mood').optional().isString().isLength({ max: 50 }),
  body('date').optional().isISO8601(),
];

const goalValidation = [
  body('id').optional().isUUID(),
  body('title').isString().isLength({ min: 1, max: 200 }).trim(),
  body('description').optional().isString().isLength({ max: 2000 }).trim(),
  body('category').optional().isString().isLength({ max: 50 }),
  body('is_active').optional().isBoolean(),
];

const moodValidation = [
  body('date').isISO8601(),
  body('mood_level').isInt({ min: 1, max: 5 }),
];

const uuidParamValidation = [
  param('id').isUUID(),
];

// ===========================================
// DEVELOPMENT AUTH BYPASS (disable in production)
// ===========================================
const DEV_BYPASS = process.env.DEV_BYPASS_AUTH === 'true' && process.env.NODE_ENV !== 'production';
const DEV_TEST_USER = process.env.AUTH0_TEST_USER || 'dev|local';
if (DEV_BYPASS) {
  console.warn('WARNING: Development auth bypass is enabled. This should never be used in production!');
  app.use((req, res, next) => {
    if (!req.headers.authorization) {
      req.auth = { sub: DEV_TEST_USER };
    }
    next();
  });
}

// ===========================================
// JWT AUTHENTICATION
// ===========================================
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

// ===========================================
// ERROR HANDLING (sanitized responses)
// ===========================================
function handleError(res, error, context = 'operation') {
  // Log full error for debugging (but not sensitive data)
  console.error(`Error in ${context}:`, {
    message: error.message,
    code: error.code,
    // Don't log stack traces in production
    ...(process.env.NODE_ENV !== 'production' && { stack: error.stack })
  });

  // Return sanitized error to client
  if (error.code === '23505') {
    return res.status(409).json({ error: 'conflict', message: 'Resource already exists' });
  }
  if (error.code === '23503') {
    return res.status(400).json({ error: 'invalid_reference', message: 'Invalid reference' });
  }
  return res.status(500).json({ error: 'server_error', message: 'An unexpected error occurred' });
}

// ===========================================
// SENSITIVE DATA FIELDS
// ===========================================
const SENSITIVE_USER_FIELDS = ['email', 'name'];
const SENSITIVE_JOURNAL_FIELDS = ['content'];

// ===========================================
// PUBLIC ROUTES
// ===========================================
app.get('/.well-known/health', (req, res) => res.json({ ok: true }));

app.get('/auth/config', authLimiter, (req, res) => {
  const config = {
    auth0Domain: process.env.AUTH0_DOMAIN || null,
    auth0Audience: process.env.AUTH0_AUDIENCE || null,
    frontendOrigin: process.env.FRONTEND_ORIGIN || null,
    auth0ClientId: process.env.AUTH0_CLIENT_ID || null,
    // Don't expose dev bypass status in production
    devBypassAuth: process.env.NODE_ENV !== 'production' && DEV_BYPASS
  };
  res.json({ data: config });
});

// ===========================================
// DATABASE HELPERS
// ===========================================
async function getOrCreateUserId(client, auth0Id) {
  const userRes = await client.query('SELECT id FROM users WHERE auth0_id=$1', [auth0Id]);
  if (userRes.rows.length === 0) {
    const insert = await client.query(
      'INSERT INTO users (auth0_id, name, email) VALUES ($1, $2, $3) RETURNING id',
      [auth0Id, encrypt('User'), encrypt('user@example.com')]
    );
    return insert.rows[0].id;
  }
  return userRes.rows[0].id;
}

// ===========================================
// USER ROUTES
// ===========================================
app.get('/api/users/me', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const result = await client.query(
      'SELECT id, auth0_id, name, email, age, has_completed_onboarding, created_at, updated_at FROM users WHERE auth0_id=$1',
      [auth0Id]
    );
    client.release();
    if (result.rows.length === 0) return res.status(404).json({ error: 'not_found' });

    // Decrypt sensitive fields before sending to client
    const user = decryptFields(result.rows[0], SENSITIVE_USER_FIELDS);
    res.json({ data: user });
  } catch (e) {
    handleError(res, e, 'get user');
  }
});

app.put('/api/users/me', checkJwt, userValidation, handleValidationErrors, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const sanitized = sanitizeInput(req.body);
    const { name, email, age, has_completed_onboarding } = sanitized;

    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);

    console.log(`[USER PUT] Updating user ${userId}, name: ${name}, email: ${email}`);
    const encryptedName = encrypt(name);
    const encryptedEmail = encrypt(email);
    console.log(`[USER PUT] Name encrypted: ${name} -> ${encryptedName?.substring(0, 50)}...`);
    console.log(`[USER PUT] Email encrypted: ${email} -> ${encryptedEmail?.substring(0, 50)}...`);

    // Encrypt sensitive fields before storing
    const update = await client.query(
      'UPDATE users SET name=$1, email=$2, age=$3, has_completed_onboarding=$4, updated_at=NOW() WHERE id=$5 RETURNING id, auth0_id, name, email, age, has_completed_onboarding, created_at, updated_at',
      [encryptedName, encryptedEmail, age, has_completed_onboarding, userId]
    );
    client.release();

    // Decrypt for response
    const user = decryptFields(update.rows[0], SENSITIVE_USER_FIELDS);
    res.json({ data: user });
  } catch (e) {
    handleError(res, e, 'update user');
  }
});

// ===========================================
// JOURNAL ENTRY ROUTES
// ===========================================
app.get('/api/journal-entries', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);

    const entries = await client.query(
      'SELECT id, content, goal_tags, mood, date, created_at, updated_at FROM journal_entries WHERE user_id=$1 ORDER BY date DESC',
      [userId]
    );
    client.release();

    // Decrypt content for each entry
    const decryptedEntries = entries.rows.map(entry => decryptFields(entry, SENSITIVE_JOURNAL_FIELDS));
    res.json({ data: decryptedEntries });
  } catch (e) {
    handleError(res, e, 'get journal entries');
  }
});

app.get('/api/journal-entries/:id', checkJwt, uuidParamValidation, handleValidationErrors, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);
    const { id } = req.params;

    const result = await client.query(
      'SELECT id, content, goal_tags, mood, date, created_at, updated_at FROM journal_entries WHERE id=$1 AND user_id=$2',
      [id, userId]
    );
    client.release();

    if (result.rows.length === 0) return res.status(404).json({ error: 'not_found' });
    const entry = decryptFields(result.rows[0], SENSITIVE_JOURNAL_FIELDS);
    res.json({ data: entry });
  } catch (e) {
    handleError(res, e, 'get journal entry');
  }
});

app.post('/api/journal-entries', checkJwt, journalEntryValidation, handleValidationErrors, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);

    const sanitized = sanitizeInput(req.body);
    const { id, content, goal_tags, mood, date } = sanitized;

    console.log(`[JOURNAL POST] Creating entry for user ${userId}, content length: ${content?.length || 0}`);
    const encryptedContent = encrypt(content);
    console.log(`[JOURNAL POST] Content encrypted: ${content?.substring(0, 20)}... -> ${encryptedContent?.substring(0, 50)}...`);

    const insert = await client.query(
      'INSERT INTO journal_entries (id, user_id, content, goal_tags, mood, date) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id, content, goal_tags, mood, date, created_at, updated_at',
      [id, userId, encryptedContent, goal_tags || [], mood, date || new Date()]
    );
    client.release();

    const entry = decryptFields(insert.rows[0], SENSITIVE_JOURNAL_FIELDS);
    res.status(201).json({ data: entry });
  } catch (e) {
    handleError(res, e, 'create journal entry');
  }
});

app.put('/api/journal-entries/:id', checkJwt, uuidParamValidation, journalEntryValidation, handleValidationErrors, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);
    const { id } = req.params;

    const sanitized = sanitizeInput(req.body);
    const { content, goal_tags, mood, date } = sanitized;

    console.log(`[JOURNAL PUT] Updating entry ${id}, content length: ${content?.length || 0}`);
    const encryptedContent = encrypt(content);
    console.log(`[JOURNAL PUT] Content encrypted: ${content?.substring(0, 20)}... -> ${encryptedContent?.substring(0, 50)}...`);

    const update = await client.query(
      'UPDATE journal_entries SET content=$1, goal_tags=$2, mood=$3, date=$4, updated_at=NOW() WHERE id=$5 AND user_id=$6 RETURNING id, content, goal_tags, mood, date, created_at, updated_at',
      [encryptedContent, goal_tags || [], mood, date, id, userId]
    );
    client.release();

    if (update.rows.length === 0) return res.status(404).json({ error: 'not_found' });
    const entry = decryptFields(update.rows[0], SENSITIVE_JOURNAL_FIELDS);
    res.json({ data: entry });
  } catch (e) {
    handleError(res, e, 'update journal entry');
  }
});

app.delete('/api/journal-entries/:id', checkJwt, uuidParamValidation, handleValidationErrors, async (req, res) => {
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
    handleError(res, e, 'delete journal entry');
  }
});

// ===========================================
// GOAL ROUTES
// ===========================================
app.get('/api/goals', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);

    const goals = await client.query(
      'SELECT id, title, description, category, is_active, created_at, updated_at FROM goals WHERE user_id=$1 ORDER BY created_at DESC',
      [userId]
    );
    client.release();
    res.json({ data: goals.rows });
  } catch (e) {
    handleError(res, e, 'get goals');
  }
});

app.get('/api/goals/:id', checkJwt, uuidParamValidation, handleValidationErrors, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);
    const { id } = req.params;

    const result = await client.query(
      'SELECT id, title, description, category, is_active, created_at, updated_at FROM goals WHERE id=$1 AND user_id=$2',
      [id, userId]
    );
    client.release();

    if (result.rows.length === 0) return res.status(404).json({ error: 'not_found' });
    res.json({ data: result.rows[0] });
  } catch (e) {
    handleError(res, e, 'get goal');
  }
});

app.post('/api/goals', checkJwt, goalValidation, handleValidationErrors, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);

    const sanitized = sanitizeInput(req.body);
    const { id, title, description, category, is_active } = sanitized;

    const insert = await client.query(
      'INSERT INTO goals (id, user_id, title, description, category, is_active) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id, title, description, category, is_active, created_at, updated_at',
      [id, userId, title, description, category, is_active !== false]
    );
    client.release();
    res.status(201).json({ data: insert.rows[0] });
  } catch (e) {
    handleError(res, e, 'create goal');
  }
});

app.put('/api/goals/:id', checkJwt, uuidParamValidation, goalValidation, handleValidationErrors, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);
    const { id } = req.params;

    const sanitized = sanitizeInput(req.body);
    const { title, description, category, is_active } = sanitized;

    const update = await client.query(
      'UPDATE goals SET title=$1, description=$2, category=$3, is_active=$4, updated_at=NOW() WHERE id=$5 AND user_id=$6 RETURNING id, title, description, category, is_active, created_at, updated_at',
      [title, description, category, is_active, id, userId]
    );
    client.release();

    if (update.rows.length === 0) return res.status(404).json({ error: 'not_found' });
    res.json({ data: update.rows[0] });
  } catch (e) {
    handleError(res, e, 'update goal');
  }
});

app.delete('/api/goals/:id', checkJwt, uuidParamValidation, handleValidationErrors, async (req, res) => {
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
    handleError(res, e, 'delete goal');
  }
});

// ===========================================
// SYNC ROUTE
// ===========================================
app.post('/api/sync', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);

    const { journal_entries = [], goals = [], user = null } = req.body;
    await client.query('BEGIN');

    if (user) {
      const sanitizedUser = sanitizeInput(user);
      await client.query(
        'UPDATE users SET name=$1, email=$2, age=$3, has_completed_onboarding=$4, updated_at=NOW() WHERE id=$5',
        [encrypt(sanitizedUser.name), encrypt(sanitizedUser.email), sanitizedUser.age, sanitizedUser.has_completed_onboarding, userId]
      );
    }

    for (const entry of journal_entries) {
      const sanitizedEntry = sanitizeInput(entry);
      await client.query(
        `INSERT INTO journal_entries (id, user_id, content, goal_tags, mood, date, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT (id) DO UPDATE SET
           content=EXCLUDED.content,
           goal_tags=EXCLUDED.goal_tags,
           mood=EXCLUDED.mood,
           date=EXCLUDED.date,
           updated_at=EXCLUDED.updated_at`,
        [sanitizedEntry.id, userId, encrypt(sanitizedEntry.content), sanitizedEntry.goal_tags || [], sanitizedEntry.mood, sanitizedEntry.date, sanitizedEntry.created_at, sanitizedEntry.updated_at]
      );
    }

    for (const goal of goals) {
      const sanitizedGoal = sanitizeInput(goal);
      await client.query(
        `INSERT INTO goals (id, user_id, title, description, category, is_active, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT (id) DO UPDATE SET
           title=EXCLUDED.title,
           description=EXCLUDED.description,
           category=EXCLUDED.category,
           is_active=EXCLUDED.is_active,
           updated_at=EXCLUDED.updated_at`,
        [sanitizedGoal.id, userId, sanitizedGoal.title, sanitizedGoal.description, sanitizedGoal.category, sanitizedGoal.is_active, sanitizedGoal.created_at, sanitizedGoal.updated_at]
      );
    }

    await client.query('COMMIT');
    client.release();
    res.status(200).json({ status: 'ok' });
  } catch (e) {
    try { await db.pool.query('ROLLBACK'); } catch (_) {}
    handleError(res, e, 'sync');
  }
});

// ===========================================
// MOOD ROUTES
// ===========================================
app.get('/api/moods', checkJwt, async (req, res) => {
  try {
    const auth0Id = req.auth.sub;
    const client = await db.pool.connect();
    const userId = await getOrCreateUserId(client, auth0Id);

    const moods = await client.query(
      "SELECT to_char(date, 'YYYY-MM-DD') as date, mood_level FROM moods WHERE user_id=$1 ORDER BY date DESC",
      [userId]
    );
    client.release();
    res.json({ data: moods.rows });
  } catch (e) {
    handleError(res, e, 'get moods');
  }
});

app.post('/api/moods', checkJwt, moodValidation, handleValidationErrors, async (req, res) => {
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
    handleError(res, e, 'create mood');
  }
});

// ===========================================
// GLOBAL ERROR HANDLER
// ===========================================
app.use((err, req, res, next) => {
  // Handle JWT errors
  if (err.name === 'UnauthorizedError') {
    return res.status(401).json({ error: 'unauthorized', message: 'Invalid or missing authentication token' });
  }
  // Handle CORS errors
  if (err.message === 'Not allowed by CORS') {
    return res.status(403).json({ error: 'forbidden', message: 'Origin not allowed' });
  }
  // Generic error
  handleError(res, err, 'unhandled');
});

// ===========================================
// SERVER STARTUP
// ===========================================
const BUILD_VERSION = '2026-01-11-encryption-debug';
console.log(`[STARTUP] SelfUpgrade Backend v${BUILD_VERSION}`);
console.log(`[STARTUP] NODE_ENV: ${process.env.NODE_ENV}`);
console.log(`[STARTUP] ENCRYPTION_KEY set: ${!!process.env.ENCRYPTION_KEY}`);

if (process.env.AWS_LAMBDA_FUNCTION_NAME) {
  module.exports.handler = serverless(app);
} else {
  const port = process.env.PORT || 3001;
  app.listen(port, '0.0.0.0', () => console.log(`[STARTUP] Listening on port ${port}`));
}
