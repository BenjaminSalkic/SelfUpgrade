# SelfUpgrade Backend

This is a minimal Express backend scaffold designed to run in AWS Lambda or locally.

Features
- Express API with Auth0 JWT verification (via JWKS)
- Postgres (pg) connection helper
- Example endpoints: `/journals`, `/goals`, `/sync`
- `sql/schema.sql` contains the initial schema

Quick local run

1. Copy `.env.example` to `.env` and set `DATABASE_URL`, `AUTH0_DOMAIN`, and `AUTH0_AUDIENCE`.
2. Install deps:

```bash
cd backend
npm install
```

3. Start locally:

```bash
npm run dev
```

Deploying to AWS
- You can deploy using Serverless Framework, SAM, or build a container image for Lambda. The `serverless-http` wrapper is included to allow running Express inside Lambda.

Notes
- The `/sync` endpoint is a placeholder; you'll need to implement merge logic for client->server sync.

Auth0 setup (high level)

1. Create an Auth0 tenant at https://auth0.com.
2. Create an API in Auth0 (Dashboard → APIs) and set its Identifier to a value you'll use as `AUTH0_AUDIENCE` (e.g. `https://selfupgrade.api`).
3. Create an Application for your frontend (SPA or Regular Web App). Enable Google and Apple connections under "Connections → Social".
4. For Google and Apple, configure client IDs/secrets in the respective provider consoles and enable them in Auth0.
5. In the Application settings, set the Allowed Callback URLs and Allowed Web Origins to your frontend addresses (e.g. `http://localhost:8080` and your deployed domain). For mobile, configure allowed callback schemes as documented by Auth0.
6. In your Flutter app, request an access token using the `audience` you set (this will yield an access token scoped to your API).

Local dev tips

- To ease local backend development, set `DEV_BYPASS_AUTH=true` in `.env` and `AUTH0_TEST_USER` to a stable string (e.g. `auth0|local`). This will make the backend behave as if the request is authenticated with that user when no `Authorization` header is present. Do NOT enable this in production.

