// Lists all top-level Firestore collections in the project, so we know which
// belong to the former app vs. Ulama Circle before touching security rules.
const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

admin
  .firestore()
  .listCollections()
  .then((cols) => {
    console.log('Top-level collections:');
    for (const c of cols) console.log('  - ' + c.id);
  })
  .then(() => process.exit(0))
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
