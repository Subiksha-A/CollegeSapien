# CollegeSapien Server (API)

Backend API and Firebase Functions for the CollegeSapien platform.

## Location

This app lives in `server/` with Cloud Functions in `server/functions`.

## Prerequisites

- Node.js 24
- pnpm 11+
- Firebase CLI (for local emulators)

## Setup

```bash
cd server/functions
pnpm install
pnpm build
pnpm serve
```

## 1. System Entities & Edge Cases

### 1.1 Base Entity Structure

All entities include standard audit fields:

- `createdAt`: Timestamp
- `updatedAt`: Timestamp
- `deletedAt`: Timestamp (nullable, for soft deletes)

### 1.2 Authentication & User State

- **Flow (Passwordless Email Link)**:
  1. Flutter App: `FirebaseAuth.instance.sendSignInLinkToEmail(email, ...)`
  2. User clicks link -> Redirects back to app -> `FirebaseAuth.instance.signInWithEmailLink(...)`
  3. Flutter App: Once signed in, calls `/auth/sync` with the Firebase ID Token.
- **State**: The `isVerified` flag in Firestore is synchronized with Firebase Auth's `email_verified` claim.
- **SES Utility**: SES is retained in `shared/ses` for system notifications, resource moderation alerts, or custom branded emails, but removed from the core passwordless auth loop to reduce latency.

### 1.3 Colleges & Domains

- **State**: Colleges are managed by Superadmins.
- **Fields**: Name, Code, Domains (allowed email domains for auto-verification/association).
- **Edge Cases**:
  - Users select a college during onboarding.
  - Superadmin can assign moderators specifically to a `collegeId`.

### 1.4 Subjects & Timetable (Semester Managed)

- **State**: Subjects are globally managed per `collegeId`.
- **Flows**:
  - Users select from existing subjects for their college. If missing, they can create one which becomes available to others in the same college.
  - Timetables are managed per user, per semester: `users/{uid}/semesters/{semesterId}/timetable`.
  - When users advance a semester, they create a new timetable.

### 1.5 Attendance Tracking

- **State**: Records are stored individually: `users/{uid}/attendance/{date}_{subjectId}`.
- **Edge Cases**:
  - **Past Updates**: Users can update previous days to Present, Absent, Leave, or None.
  - **Correction (None)**: Soft deletes the attendance record.

### 1.6 Grade Prediction (Internal vs External)

- **State**: Dynamic calculation of external marks based on internal performance.
- **Edge Cases**:
  - User inputs earned internals ($x$) and max possible internals ($y$).
  - External marks are out of $(100 - y)$.
  - API calculates the exact marks needed in the external exam to achieve specific grades (O, A+, A, etc.).

### 1.7 Moderation, Roles & Reports

- **Roles**: `user`, `moderator` (college-specific or global), `superadmin`.
- **Entities**: Reports (spam, incorrect, abusive).
- **Flows**:
  - Web Admin Panel endpoints for full CRUD across Colleges, Users, Subjects, Resources, and Reports.
  - Soft delete applied to reported resources to preserve audit trails.

---

## 2. API Endpoints

**Base URL:** `https://asia-south1-codesapien-college.cloudfunctions.net/api/api/v1`

All app requests should send:

- `Authorization: Bearer <Firebase ID token>`
- `X-Firebase-AppCheck: <Firebase App Check token>` outside local emulators

The Flutter app should be started with `--dart-define=CODESAPIENS_API_BASE_URL=<base-url>` when using a custom domain or emulator.

### Auth (`/auth`)

- `POST /sync`: Sync Firebase Auth token with Firestore profile and return onboarding status.
- `POST /onboard`: Create/update the student's profile after verified Firebase Auth.
- `POST /signup`: Backward-compatible profile creation endpoint.
- `POST /login`: Backward-compatible session sync endpoint.
- `GET /me`: Returns profile.
- `PATCH /me`: Updates safe profile fields only.
- `POST /logout`: Clears cookie.

### Colleges (`/colleges`)

- `GET /`: List all colleges (public).
- `GET /:id/subjects`: List subjects for a specific college (public).

### Subjects (`/subjects`)

- `POST /`: User creates a new subject for their college.

### Attendance (`/attendance`)

- `POST /`: Upsert attendance for a specific day/subject.
- `POST /sync`: Bulk update/correction of past attendance.
- `GET /summary`: Returns % and Safe to Skip metrics for current semester.

### Semesters & Timetable (`/timetable`)

- `POST /`: Upload/Update timetable for current semester.
- `GET /`: Get current semester timetable.
- `POST /parse`: Gemini Vision parse.

### CGPA & Grade Prediction (`/cgpa`)

- `POST /calculate`: Parse grade sheet image.
- `POST /predict`: Input `(earned_internal, max_internal, target_grade)` -> Output needed external marks.

### Resources Hub (`/resources`)

- `GET /syllabus`: Filter by college, department, semester.
- `GET /hub`: View notes and question papers.
- `POST /upload`: Upload resource.
- `POST /report`: Report a resource/user.

### Admin & Moderation (`/admin`)

- `GET /colleges`, `POST /colleges`, `PUT /colleges/:id`, `DELETE /colleges/:id`
- `GET /users`, `PATCH /users/:id/role`
- `GET /reports`, `PATCH /reports/:id/resolve`
- `DELETE /resources/:id` (Soft delete)

---

## 3. Tooling

- **Emails**: AWS SES (using `@aws-sdk/client-ses`).
- **Database**: Firestore.
- **Files**: Firebase Storage with path-scoped rules.
- **Abuse Protection**: Firebase App Check for non-emulator API calls.
- **Secrets**: Firebase Functions Secret Manager params for `GEMINI_API_KEY`, `AWS_ACCESS_KEY_ID`, and `AWS_SECRET_ACCESS_KEY`.
- **Validation**: Zod.
- **Docs**: Swagger.

## 4. Secrets & Rotation

Three secrets are required. All are stored in Firebase Secret Manager and injected at deploy time.

| Secret                  | Purpose                                     | Rotation cadence               |
| ----------------------- | ------------------------------------------- | ------------------------------ |
| `GEMINI_API_KEY`        | Gemini Vision (timetable parse, CGPA scan)  | On compromise or every 90 days |
| `AWS_ACCESS_KEY_ID`     | SES transactional email (send login links)  | On compromise or every 90 days |
| `AWS_SECRET_ACCESS_KEY` | SES transactional email (paired with above) | Same as above                  |

**Set / rotate a secret:**

```bash
firebase functions:secrets:set GEMINI_API_KEY
firebase functions:secrets:set AWS_ACCESS_KEY_ID
firebase functions:secrets:set AWS_SECRET_ACCESS_KEY
```

After rotating, redeploy functions so the new version picks up the updated secret:

```bash
firebase deploy --only functions
```

**Verify a secret is set:**

```bash
firebase functions:secrets:access GEMINI_API_KEY
```

> **Important:** Never commit secret values to git. The `.env` file is git-ignored.

---

## 5. Deployment Notes

1. Set required secrets:
   ```bash
   firebase functions:secrets:set GEMINI_API_KEY
   firebase functions:secrets:set AWS_ACCESS_KEY_ID
   firebase functions:secrets:set AWS_SECRET_ACCESS_KEY
   ```
2. Deploy backend, rules, and indexes together:
   ```bash
   firebase deploy --only functions,firestore:rules,firestore:indexes,storage
   ```
3. Keep Firestore client access minimal. Business writes should go through the API; direct Storage access is only for user/resource file bytes.
4. Register Firebase App Check providers for Android/iOS before enforcing production traffic.
