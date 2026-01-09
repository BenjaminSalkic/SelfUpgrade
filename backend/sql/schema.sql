-- Simple Postgres schema for SelfUpgrade backend
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth0_id text UNIQUE NOT NULL,
  email text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS journals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  title text,
  body text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS goals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  title text,
  meta jsonb,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS moods (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  date date NOT NULL,
  mood_level integer NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, date)
);
