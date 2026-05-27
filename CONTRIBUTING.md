# Contributing to CollegeSapien

Thanks for taking the time to contribute.

## Code of Conduct

By participating, you agree to follow the [Code of Conduct](./CODE_OF_CONDUCT.md).

## Repository Layout

- `admin/` — Nuxt 3 admin dashboard
- `server/` — Firebase backend (Cloud Functions + rules)
- `app/` — Flutter mobile app

## Getting Started

### Admin (Nuxt 3)

```bash
cd admin
pnpm install
pnpm dev
```

### Server (Firebase Functions)

```bash
cd server/functions
pnpm install
pnpm build
pnpm serve
```

### Mobile App (Flutter)

```bash
cd app
flutter pub get
flutter run
```

## Running Checks

### Admin

```bash
cd admin
pnpm lint
pnpm build
```

### Server

```bash
cd server/functions
pnpm lint
pnpm build
```

### Mobile App

```bash
cd app
flutter analyze
flutter test
```

## Commit Messages

Use short conventional commits in the format: `type: summary` (example: `feat: add subject filters`).

## Pull Requests

- Keep PRs focused and scoped to one area of the repo.
- Include a brief description, checks run, and screenshots for UI changes.
- Avoid committing secrets or local environment files.
