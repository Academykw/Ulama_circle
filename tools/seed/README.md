# Seed script

Populates Firestore with test data (sheikhs, categories, lectures) for Ulama Circle.

Uses the Firebase Admin SDK, so it **bypasses security rules** — this is why it
can write to the admin-only content collections.

## Run it

1. **Get a service account key** (this is a real secret — keep it out of git):
   Firebase console → ⚙ Project settings → **Service accounts** →
   **Generate new private key**. Save the downloaded JSON as:

   ```
   tools/seed/service-account.json
   ```

2. **Install + run:**

   ```
   cd tools/seed
   npm install
   node seed.js
   ```

You should see `Seeded 3 sheikhs, 5 categories, 9 lectures.`

## Notes

- **Idempotent** — fixed doc IDs + `.set()`, so re-running overwrites, never duplicates.
- **Audio** points at public SoundHelix sample MP3s so the download/play flow is
  testable before real audio is uploaded to Storage.
- **Admin access:** the script can't safely guess your UID. After signing into
  the app once, create a doc at `admins/{yourUid}` with `{ role: "admin" }`
  (from the Firebase console) to unlock admin-only writes.
