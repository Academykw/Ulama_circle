// Peek at `categories` and `users` to see whether the former quiz app and
// Ulama Circle have mixed data in the same collections. Read-only.
const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

(async () => {
  for (const name of ['categories', 'users']) {
    const snap = await db.collection(name).limit(25).get();
    console.log(`\n=== ${name} (${snap.size} shown) ===`);
    snap.forEach((d) => {
      const data = d.data();
      const keys = Object.keys(data).slice(0, 6).join(', ');
      console.log(`  ${d.id}  {${keys}}`);
    });
  }
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
