# CollegeSapien Admin

The CollegeSapien admin dashboard powers moderation and operational workflows for colleges, users, resources, and reports.

## Location

This app lives in `admin/` at the root of the CollegeSapien monorepo.

## Prerequisites

- Node.js 20+
- pnpm 11+

## Setup

```bash
cd admin
pnpm install
```

Copy the environment template and provide Firebase config values:

```bash
cp .env.example .env
```

## Development

```bash
pnpm dev
```

## Useful Scripts

```bash
pnpm lint
pnpm build
pnpm preview
```

## License

Licensed under the [MIT License](../LICENSE).
