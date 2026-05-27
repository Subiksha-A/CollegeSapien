# CollegeSapien

CollegeSapien is a monorepo for the Codesapiens initiative, covering the admin dashboard, backend API, and Flutter mobile app for university attendance, timetables, and academic resources.

## Repository Layout

| Path      | App                      | Stack                | Docs               |
| --------- | ------------------------ | -------------------- | ------------------ |
| `admin/`  | Admin dashboard          | Nuxt 3, Vue 3, Pinia | `admin/README.md`  |
| `server/` | API + Firebase Functions | Node.js, Firebase    | `server/README.md` |
| `app/`    | Mobile app               | Flutter              | `app/README.md`    |

## Quickstart

### Prerequisites

- Node.js (use Node 24 for `server/functions`, Node 20+ for `admin`)
- pnpm 11+
- Flutter SDK >= 3.0.0
- Firebase CLI (for local emulators)

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
flutter run --dart-define=CODESAPIENS_API_BASE_URL=https://asia-south1-codesapien-college.cloudfunctions.net/api/api/v1
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for setup, checks, and workflow details.

## Security

Please read [SECURITY.md](./SECURITY.md) for reporting instructions.

## License

Licensed under the [MIT License](./LICENSE).
