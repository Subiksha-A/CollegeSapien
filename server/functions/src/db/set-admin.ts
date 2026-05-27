import * as admin from 'firebase-admin';

const args = process.argv.slice(2);
const isLocal = args.includes('--local');
const isRemote = args.includes('--remote');

if (!isLocal && !isRemote) {
  console.log('Usage: npx tsx src/db/set-admin.ts [--local | --remote]');
  process.exit(0);
}

if (isLocal) {
  process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
  process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
  console.log('Running in LOCAL mode.');
} else {
  console.log('Running in REMOTE mode.');
}

if (admin.apps.length === 0) {
  admin.initializeApp({ projectId: 'collegesapiens' });
}

async function setAdmin() {
  const targetEmail = process.argv.find(a => a.includes('@')) || 'harsh@limegreen.studio';
  const email = targetEmail;
  const role = 'superadmin';
  const collegeId = 'col_srm_001';

  console.log(`Looking up user: ${email}`);
  const user = await admin.auth().getUserByEmail(email);
  console.log(`Found UID: ${user.uid}`);

  await admin.auth().setCustomUserClaims(user.uid, { role, collegeId });
  console.log(`Custom claims set: role=${role}, collegeId=${collegeId}`);

  await admin.firestore().collection('users').doc(user.uid).set(
    { role, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
    { merge: true }
  );
  console.log('Firestore role updated.');
  console.log('\nDone. Ask the user to sign out and sign back in to refresh their token.');
  process.exit(0);
}

setAdmin().catch(err => {
  console.error('Failed:', err);
  process.exit(1);
});
