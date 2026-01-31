# SelfUpgrade

<div align="center">

![SelfUpgrade Banner](./docs/screenshots/banner.png)

**A comprehensive personal growth and journaling application**

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-18+-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![Auth0](https://img.shields.io/badge/Auth0-Secured-EB5424?logo=auth0&logoColor=white)](https://auth0.com)

[Features](#-features) • [Tech Stack](#-technology-stack) • [Architecture](#-architecture) • [Setup](#-getting-started) • [Deployment](#-deployment)

</div>

---

## Project Overview

**SelfUpgrade** is a modern, cross-platform application designed for personal growth, self-reflection, and habit tracking through daily journaling, mood tracking, and goal management. Built with an **offline-first architecture**, the app ensures seamless functionality even without internet connectivity, with intelligent synchronization when connection is restored.

### Key Highlights

- **Offline-First**: Full functionality without internet connection using local Hive database
- **Enterprise Security**: Auth0 authentication with AES-256-GCM encryption for sensitive data
- **Cross-Platform**: Single codebase for iOS, Android, and Web using Flutter
- **Cloud Sync**: Automatic synchronization with cloud backend for multi-device access
- **Modern UI**: Beautiful gradient-based design with responsive layouts for all screen sizes
- **Privacy-Focused**: End-to-end encryption for journal entries and personal information

---

## Features

### Core Functionality

| Feature | Description | Platforms |
|---------|-------------|-----------|
| **Journal Entries** | Create, edit, and delete daily journal entries with mood tracking and goal tagging | iOS, Android, Web |
| **Goal Management** | Set personal goals with categories, track progress, and link to journal entries | iOS, Android, Web |
| **Mood Tracking** | Daily mood logging with historical visualization and trend analysis | iOS, Android, Web |
| **Progress Analytics** | View statistics, streaks, and insights about your personal growth journey | iOS, Android, Web |
| **Offline Mode** | Full CRUD operations available without internet connection | iOS, Android, Web |
| **Cloud Sync** | Automatic or manual synchronization across all your devices | iOS, Android, Web |
| **Secure Authentication** | OAuth2/OIDC via Auth0 with social login support (Google, Apple) | iOS, Android, Web |
| **Data Encryption** | AES-256-GCM encryption for journal content and sensitive user data | Server-side |
| **Dark Theme** | Eye-friendly dark mode with gradient accents | iOS, Android, Web |
| **Responsive Design** | Adaptive layouts for mobile, tablet, and desktop screens | iOS, Android, Web |
| **Notifications** | Customizable reminders for journaling and goal reviews | iOS, Android |
| **Search & Filter** | Find entries by content, mood, goals, or date range | iOS, Android, Web |
| **Pull to Refresh** | Manual sync trigger with intuitive gesture | iOS, Android |

### Advanced Features

| Feature | Description | Status |
|---------|-------------|--------|
| **Conflict Resolution** | Last-write-wins merge strategy for sync conflicts | Implemented |
| **Goal Categories** | Organize goals by custom categories (Health, Career, Relationships, etc.) | Implemented |
| **Mood Trends** | Visualize mood patterns over time with charts | Implemented |
| **Onboarding Tutorial** | Interactive welcome and setup flow for new users | Implemented |
| **Debug Mode** | Developer tools for troubleshooting sync and auth issues | Implemented |
| **Token Management** | Secure storage of refresh tokens with automatic refresh | Implemented |

---

## Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Client Applications                       │
├──────────────┬──────────────┬──────────────┬────────────────┤
│   iOS App    │ Android App  │   Web App    │  Future: Watch │
│  (Flutter)   │  (Flutter)   │ (Flutter Web)│      App       │
└──────┬───────┴──────┬───────┴──────┬───────┴────────┬───────┘
       │              │              │                │
       └──────────────┴──────────────┴────────────────┘
                           │
                   ┌───────▼────────┐
                   │  Local Storage │
                   │  (Hive Boxes)  │
                   └───────┬────────┘
                           │
                   ┌───────▼────────┐
                   │  Sync Service  │
                   │ (Pull/Push)    │
                   └───────┬────────┘
                           │
                    [Internet]
                           │
       ┌───────────────────▼───────────────────┐
       │        Backend API (Express)          │
       │  - JWT Verification (Auth0 JWKS)      │
       │  - Rate Limiting & Security Headers   │
       │  - Field-Level Encryption/Decryption  │
       └───────────────┬───────────────────────┘
                       │
       ┌───────────────▼───────────────────┐
       │   PostgreSQL Database (Render)    │
       │   - Encrypted sensitive fields    │
       │   - User data, entries, goals     │
       └───────────────────────────────────┘
```

### Offline-First Strategy

1. **Local-First Operations**: All CRUD operations write to local Hive database immediately
2. **Background Sync**: Automatic synchronization when network is available
3. **Conflict Resolution**: Server timestamp-based merge (last write wins)
4. **Optimistic Updates**: UI updates instantly, syncs in background
5. **Queue Management**: Failed sync operations are queued and retried

### Data Flow

```
User Action → Local Hive DB → UI Update (Instant)
                  ↓
            Sync Service
                  ↓
        [Check Network Status]
                  ↓
        Backend API (if online)
                  ↓
        PostgreSQL Database
```

---

## Technology Stack

### Frontend

| Technology | Purpose | Version |
|------------|---------|---------|
| **Flutter** | Cross-platform UI framework | 3.0+ |
| **Dart** | Programming language | 3.0+ |
| **Hive** | Local NoSQL database (offline storage) | 2.2.3 |
| **Provider** | State management | 6.0.5 |
| **Auth0 Flutter SDK** | Authentication & OAuth2 | 1.14.0 |
| **flutter_secure_storage** | Secure token storage (Keychain/KeyStore) | 8.0.0 |
| **http** | REST API client | 0.13.6 |
| **flutter_markdown** | Markdown rendering | 0.7.0 |
| **flutter_local_notifications** | Push notifications | 17.2.1 |
| **uuid** | UUID generation | 4.0.0 |

### Backend

| Technology | Purpose | Version |
|------------|---------|---------|
| **Node.js** | Runtime environment | 18+ |
| **Express** | Web framework | 4.18.2 |
| **PostgreSQL** | Relational database | 15+ |
| **pg** | PostgreSQL client | 8.10.0 |
| **express-jwt** | JWT validation middleware | 7.7.5 |
| **jwks-rsa** | Auth0 JWKS verification | 2.0.6 |
| **helmet** | Security headers | 7.1.0 |
| **express-rate-limit** | DDoS protection | 7.1.5 |
| **express-validator** | Input validation | 7.0.1 |
| **xss** | XSS sanitization | 1.0.14 |
| **crypto (Node.js)** | AES-256-GCM encryption | Built-in |
| **serverless-http** | AWS Lambda adapter | 3.0.0 |

### Infrastructure & DevOps

| Service | Purpose | Details |
|---------|---------|---------|
| **Render** | Backend hosting | Docker container deployment, PostgreSQL instance |
| **Vercel** | Web app hosting (optional) | Static site deployment for Flutter Web |
| **Auth0** | Identity management | OAuth2/OIDC, social login (Google, Apple) |
| **GitHub** | Version control | Source code repository |
| **Docker** | Containerization | Backend deployment packaging |

### Security & Encryption

- **AES-256-GCM**: Symmetric encryption for sensitive fields (journal content, user data)
- **JWT (RS256)**: Asymmetric token signing via Auth0
- **HTTPS/TLS**: All API communications encrypted in transit
- **Keychain/KeyStore**: Platform-native secure storage for tokens
- **Rate Limiting**: 100 requests/15min general, 20 requests/15min for auth endpoints
- **Helmet.js**: Security headers (XSS protection, CSP, etc.)

---

## Platforms & Deployment

### Mobile Apps

#### iOS
- **Target**: iOS 12.0+
- **Status**: Production-ready
- **Distribution**: App Store (requires Apple Developer account)
- **Bundle ID**: `com.selfupgrade.app` (configurable)

#### Android
- **Target**: Android 5.0+ (API 21+)
- **Status**: Production-ready
- **Distribution**: Google Play Store
- **Package**: `com.selfupgrade.app` (configurable)

### Web Application

- **Framework**: Flutter Web
- **Hosting**: Vercel / Netlify (configured)
- **URL**: Configurable via `FRONTEND_ORIGIN` environment variable
- **Build Output**: Static HTML/JS/CSS in `build/web/`

### Backend API

- **Hosting**: [Render](https://render.com)
- **Type**: Docker container (Node.js)
- **Database**: PostgreSQL 15+ (Render managed instance)
- **Health Check**: `/.well-known/health`
- **API Base URL**: Set via `BACKEND_URL` in frontend config

---

## Getting Started

### Prerequisites

- **Flutter SDK**: 3.0.0 or higher ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Node.js**: 18+ ([Download](https://nodejs.org/))
- **PostgreSQL**: 15+ (local or hosted)
- **Auth0 Account**: Free tier available ([Sign up](https://auth0.com))
- **Git**: For version control
- **Xcode** (macOS, for iOS builds)
- **Android Studio** (for Android builds)

### Local Development Setup

#### 1. Clone the Repository

```bash
git clone <repository-url>
cd SelfUpgrade
```

#### 2. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Copy environment template
cp .env.example .env
```

**Edit `.env` with your configuration:**

```env
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/selfupgrade

# Auth0 Configuration
AUTH0_DOMAIN=your-tenant.auth0.com
AUTH0_AUDIENCE=https://selfupgrade.api
AUTH0_CLIENT_ID=your-client-id

# Frontend (for CORS)
FRONTEND_ORIGIN=http://localhost:8080

# Encryption (generate with: openssl rand -hex 32)
ENCRYPTION_KEY=your-64-character-hex-key

# Development Auth Bypass (NEVER use in production!)
DEV_BYPASS_AUTH=true
AUTH0_TEST_USER=auth0|local

# Server
PORT=3001
NODE_ENV=development
```

**Initialize the database:**

```bash
# Create database
createdb selfupgrade

# Run schema
psql -d selfupgrade -f sql/schema.sql
```

**Start the backend server:**

```bash
# Development mode (with auto-reload)
npm run dev

# Production mode
npm start
```

The API will be available at `http://localhost:3001`

#### 3. Frontend Setup

```bash
cd ../frontend

# Install Flutter dependencies
flutter pub get

# Generate code (for Hive adapters)
flutter pub run build_runner build --delete-conflicting-outputs
```

**Create `lib/config.dart`:**

```dart
class Config {
  static const String backendUrl = 'http://localhost:3001';
  
  // Auth0 Configuration
  static const String auth0Domain = 'your-tenant.auth0.com';
  static const String auth0ClientId = 'your-client-id';
  static const String auth0Audience = 'https://selfupgrade.api';
  static const String auth0RedirectUri = 'selfupgrade://callback';
  
  // Feature flags
  static const bool enableSync = true;
  static const bool enableNotifications = true;
}
```

**Run the app:**

```bash
# iOS Simulator
flutter run -d ios

# Android Emulator
flutter run -d android

# Web Browser
flutter run -d chrome

# List available devices
flutter devices
```

#### 4. Auth0 Configuration

1. **Create Auth0 Account** at [auth0.com](https://auth0.com)

2. **Create API**:
   - Go to Applications → APIs
   - Click "Create API"
   - Name: `SelfUpgrade API`
   - Identifier: `https://selfupgrade.api` (must match `AUTH0_AUDIENCE`)
   - Signing Algorithm: RS256

3. **Create Application**:
   - Go to Applications → Applications
   - Click "Create Application"
   - Name: `SelfUpgrade Mobile/Web`
   - Type: Native (for mobile) or Single Page Application (for web)
   - Note the **Client ID** and **Domain**

4. **Configure Callbacks**:
   - Allowed Callback URLs:
     - `selfupgrade://callback` (mobile)
     - `http://localhost:8080/callback` (web dev)
     - `https://your-domain.com/callback` (web prod)
   - Allowed Logout URLs:
     - `selfupgrade://logout` (mobile)
     - `http://localhost:8080` (web dev)
     - `https://your-domain.com` (web prod)

5. **Enable Social Connections** (optional):
   - Go to Authentication → Social
   - Enable Google, Apple, etc.
   - Configure with your OAuth credentials

6. **Configure Scopes**:
   - In your API settings, ensure `openid`, `profile`, `email`, and `offline_access` are enabled

---

## Configuration

### Environment Variables

#### Backend (`.env`)

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `DATABASE_URL` | PostgreSQL connection string | Yes | `postgresql://user:pass@host:5432/db` |
| `AUTH0_DOMAIN` | Auth0 tenant domain | Yes | `tenant.auth0.com` |
| `AUTH0_AUDIENCE` | Auth0 API identifier | Yes | `https://selfupgrade.api` |
| `AUTH0_CLIENT_ID` | Auth0 application client ID | Yes | `abc123...` |
| `FRONTEND_ORIGIN` | Allowed CORS origin | Yes | `https://app.example.com` |
| `ENCRYPTION_KEY` | 64-char hex key for AES-256 | Yes | `openssl rand -hex 32` |
| `PORT` | Server port | No | `3001` |
| `NODE_ENV` | Environment mode | No | `production` |
| `DEV_BYPASS_AUTH` | Skip auth in dev (DANGEROUS) | No | `false` |

#### Frontend (`lib/config.dart`)

| Constant | Description | Example |
|----------|-------------|---------|
| `backendUrl` | Backend API base URL | `https://api.example.com` |
| `auth0Domain` | Auth0 tenant domain | `tenant.auth0.com` |
| `auth0ClientId` | Auth0 client ID | `abc123...` |
| `auth0Audience` | API identifier | `https://selfupgrade.api` |
| `auth0RedirectUri` | OAuth callback URL | `selfupgrade://callback` |

---

## Building for Production

### Backend Deployment (Render)

1. **Push to GitHub**:
   ```bash
   git push origin main
   ```

2. **Create Render Service**:
   - Go to [Render Dashboard](https://dashboard.render.com)
   - Click "New +" → "Web Service"
   - Connect your GitHub repository
   - Use existing `Dockerfile`
   - Set environment variables from Render dashboard
   - Deploy!

3. **Configure PostgreSQL**:
   - Create a PostgreSQL instance on Render
   - Copy the Internal Database URL
   - Set as `DATABASE_URL` environment variable
   - Run schema via Render shell or `psql`

### iOS Build & Deployment

```bash
cd frontend

# Build release IPA
flutter build ios --release

# Open Xcode to archive and upload
open ios/Runner.xcworkspace
```

**Xcode Steps**:
1. Product → Archive
2. Distribute App → App Store Connect
3. Upload to TestFlight
4. Submit for App Store Review

### Android Build & Deployment

```bash
cd frontend

# Build release APK
flutter build apk --release

# Or build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

**Google Play Console**:
1. Create app in [Play Console](https://play.google.com/console)
2. Upload `build/app/outputs/bundle/release/app-release.aab`
3. Complete store listing
4. Submit for review

### Web Deployment (Vercel)

```bash
cd frontend

# Build for web
flutter build web --release

# Deploy to Vercel
cd build/web
vercel --prod
```

**Or use Vercel GitHub Integration**:
1. Connect repository to Vercel
2. Set build command: `cd frontend && flutter build web --release`
3. Set output directory: `frontend/build/web`
4. Deploy automatically on push

---

## Screenshots

### Mobile App

<div align="center">

| Welcome Screen | Journal Entries | Create Entry |
|:--------------:|:---------------:|:------------:|
| ![Welcome](./docs/screenshots/welcome.png) | ![Home](./docs/screenshots/home.png) | ![Entry](./docs/screenshots/entry.png) |

| Goals Management | Progress Analytics | Mood Tracking |
|:----------------:|:------------------:|:-------------:|
| ![Goals](./docs/screenshots/goals.png) | ![Progress](./docs/screenshots/progress.png) | ![Mood](./docs/screenshots/mood.png) |

</div>

### Web Application

<div align="center">

| Desktop View | Tablet View | Mobile Responsive |
|:------------:|:-----------:|:-----------------:|
| ![Desktop](./docs/screenshots/web-desktop.png) | ![Tablet](./docs/screenshots/web-tablet.png) | ![Mobile Web](./docs/screenshots/web-mobile.png) |

</div>

> **Note**: Screenshots are illustrative. Add your actual screenshots to `docs/screenshots/` folder.

---

## Security & Privacy

### Data Protection

- **Encryption at Rest**: Journal entries, goal titles/descriptions, and user PII encrypted with AES-256-GCM
- **Encryption in Transit**: All API calls over HTTPS/TLS 1.2+
- **Secure Token Storage**: OAuth tokens stored in platform keychains (iOS Keychain, Android KeyStore)
- **No Third-Party Analytics**: No tracking or data sharing with third parties
- **GDPR Compliant**: User data deletion endpoints available

### Authentication & Authorization

- **OAuth2/OIDC**: Industry-standard authentication via Auth0
- **JWT Validation**: All API requests verify RS256-signed tokens
- **Refresh Tokens**: Secure refresh flow with `offline_access` scope
- **Rate Limiting**: Protection against brute force attacks
- **CORS Policies**: Strict origin validation

### Security Best Practices

- Helmet.js security headers
- XSS sanitization on all inputs
- SQL injection prevention (parameterized queries)
- CSRF protection
- Rate limiting (100 req/15min general, 20 req/15min auth)
- Input validation with express-validator
- Environment variable secrets (never committed)

---

## Testing

### Backend Tests

```bash
cd backend

# Run unit tests
npm test

# Run with coverage
npm run test:coverage

# Run integration tests
npm run test:integration
```

### Frontend Tests

```bash
cd frontend

# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Integration tests
flutter drive --target=test_driver/app.dart
```

---

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Coding Standards

- **Dart**: Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- **JavaScript**: Use ESLint with provided config
- **Commits**: Use [Conventional Commits](https://www.conventionalcommits.org/)
- **Documentation**: Update README and inline docs for new features

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Team & Credits

**SelfUpgrade** was developed as part of a group project focusing on modern app development practices, security, and cross-platform deployment.

### Contributors

- **Benjamin Salkić** - Lead Developer (Frontend, Backend, Architecture, Deployment)

### Acknowledgments

- [Flutter Team](https://flutter.dev) for the excellent cross-platform framework
- [Auth0](https://auth0.com) for secure authentication infrastructure
- [Render](https://render.com) for reliable hosting

---

## Support & Contact

- **Issues**: [GitHub Issues](../../issues)
- **Discussions**: [GitHub Discussions](../../discussions)
- **Email**: support@selfupgrade.app (if applicable)

---

## Roadmap

### Planned Features

- **Rich Text Editor**: Markdown and formatting support for journal entries
- **File Attachments**: Add photos and documents to entries
- **Habit Tracker**: Daily habit check-ins with streak tracking
- **Export Data**: PDF and JSON export of all user data
- **Dark/Light Theme Toggle**: User preference for color scheme
- **Multi-Language Support**: Internationalization (i18n)
- **AI Insights**: Optional ML-powered mood and pattern analysis
- **Collaborative Goals**: Share goals with accountability partners
- **Apple Watch App**: Quick mood logging and reminders
- **Desktop Apps**: Native macOS and Windows applications

### Future Improvements

- End-to-end encryption (client-side encryption keys)
- Biometric authentication (Face ID, Touch ID)
- Offline image caching and compression
- WebSocket real-time sync
- GraphQL API migration
- Automated backup to cloud storage (iCloud, Google Drive)

---

<div align="center">

**Made with ❤️ for personal growth enthusiasts**

⭐ Star this repo if you find it helpful!

</div>
