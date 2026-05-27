import * as admin from 'firebase-admin';

// Handle flags
const args = process.argv.slice(2);
const isHelp = args.includes('--help') || args.includes('-h');
const isLocal = args.includes('--local');
const isRemote = args.includes('--remote');

if (isHelp || (!isLocal && !isRemote)) {
  console.log(`
Usage:
  npx tsx src/db/seed.ts [options]

Options:
  --local    Seed the local Firestore emulator (127.0.0.1:8080)
  --remote   Seed the remote production Firestore
  `);
  process.exit(0);
}

if (isLocal) {
  console.log('Running in LOCAL mode. Connecting to Firestore & Auth Emulators...');
  process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
  process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
} else {
  console.log('Running in REMOTE mode. Connecting to Production Firebase...');
  // It relies on GOOGLE_APPLICATION_CREDENTIALS or standard firebase login context
}

// Initialize Firebase
if (admin.apps.length === 0) {
  admin.initializeApp({
    projectId: 'collegesapiens',
  });
}

const db = admin.firestore();
const auth = admin.auth();

async function seed() {
  try {
    console.log('\n--- Starting Database Seeding ---');

    // 1. Seed College
    console.log('1. Seeding College (SRMIST)...');
    const collegeId = 'col_srm_001';
    const collegeRef = db.collection('colleges').doc(collegeId);
    await collegeRef.set({
      name: 'SRM Institute of Science and Technology',
      code: 'SRM',
      domains: [],
      city: 'Chennai',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      deletedAt: null,
    });
    console.log('   ✅ SRM College seeded.');

    // 2. Seed User (hp8823)
    console.log('\n2. Seeding Test User...');
    const userEmail = 'hp8823@limegreen.studio';
    const userUid = 'uid_hp8823';

    try {
      await auth.getUser(userUid);
      console.log('   - User already exists in Firebase Auth.');
    } catch (error) {
      await auth.createUser({
        uid: userUid,
        email: userEmail,
        password: 'password123',
        displayName: 'Harsh Patel',
        emailVerified: true,
      });
      console.log('   ✅ User created in Firebase Auth.');
    }

    // Set Custom Claims for superadmin to allow testing everything
    await auth.setCustomUserClaims(userUid, { role: 'superadmin', collegeId });

    await db.collection('users').doc(userUid).set({
      uid: userUid,
      email: userEmail,
      name: 'Harsh Patel',
      collegeName: 'SRM Institute of Science and Technology',
      collegeId: collegeId,
      department: 'Computer Science',
      semester: 6,
      role: 'superadmin',
      isVerified: true,
      attendanceThreshold: 75,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
      deletedAt: null,
    });
    console.log('   ✅ User profile seeded in Firestore.');

    // 3. Seed Subjects
    console.log('\n3. Seeding Subjects...');
    const subjects = [
      { id: 'sub_ai_001', name: 'Artificial Intelligence', code: 'CS101', credits: 4 },
      { id: 'sub_os_002', name: 'Operating Systems', code: 'CS102', credits: 4 },
      { id: 'sub_db_003', name: 'Database Management', code: 'CS103', credits: 3 },
    ];

    for (const sub of subjects) {
      await db.collection('subjects').doc(sub.id).set({
        name: sub.name,
        code: sub.code,
        collegeId: collegeId,
        department: 'Computer Science',
        semester: 6,
        credits: sub.credits,
        createdBy: userUid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        deletedAt: null,
      });
    }
    console.log(`   ✅ Seeded ${subjects.length} subjects.`);

    // 4. Seed Timetable for Semester 6
    console.log('\n4. Seeding Timetable...');
    const timetableRef = db.collection('users').doc(userUid).collection('semesters').doc('6');
    await timetableRef.set({
      subjects: [
        {
          id: 'sub_ai_001',
          name: 'Artificial Intelligence',
          code: 'CS101',
          classes: [
            { day: 'MON', startTime: '09:00', endTime: '10:00', room: 'UB101', type: 'CORE' },
            { day: 'WED', startTime: '11:00', endTime: '12:00', room: 'UB101', type: 'CORE' },
          ],
        },
        {
          id: 'sub_os_002',
          name: 'Operating Systems',
          code: 'CS102',
          classes: [
            { day: 'TUE', startTime: '10:00', endTime: '11:00', room: 'LB204', type: 'CORE' },
            { day: 'THU', startTime: '14:00', endTime: '16:00', room: 'LAB1', type: 'LAB' },
          ],
        },
      ],
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log('   ✅ Seeded timetable for Semester 6.');

    // 5. Seed Attendance
    console.log('\n5. Seeding Attendance...');
    const today = new Date();
    const dates = [1, 2, 3, 4, 5].map(daysAgo => {
      const d = new Date(today);
      d.setDate(d.getDate() - daysAgo);
      return d.toISOString().split('T')[0];
    });

    const batch = db.batch();
    dates.forEach((dateStr, i) => {
      // Make them mostly present, one absent, one leave
      let status = 'Present';
      if (i === 2) status = 'Absent';
      if (i === 4) status = 'Leave';

      const attRef = db
        .collection('users')
        .doc(userUid)
        .collection('attendance')
        .doc(`${dateStr}_sub_ai_001`);
      batch.set(attRef, {
        subjectId: 'sub_ai_001',
        date: dateStr + 'T00:00:00Z',
        status: status,
        dateKey: dateStr,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    await batch.commit();
    console.log('   ✅ Seeded attendance records for AI subject.');

    // 6. Seed Syllabus
    console.log('\n6. Seeding Syllabus Directory...');
    const syllabusList = [
      {
        id: 'syl_ai',
        name: 'AI Final Syllabus',
        code: 'CS101',
        department: 'Computer Science',
        semester: 6,
        link: 'https://example.com/ai_syllabus.pdf',
      },
      {
        id: 'syl_os',
        name: 'OS Final Syllabus',
        code: 'CS102',
        department: 'Computer Science',
        semester: 6,
        link: 'https://example.com/os_syllabus.pdf',
      },
    ];
    for (const s of syllabusList) {
      await db.collection('syllabus').doc(s.id).set(s);
    }
    console.log('   ✅ Seeded syllabus documents.');

    // 7. Seed Hub Resources (Notes & QP)
    console.log('\n7. Seeding Resources Hub...');
    const resources = [
      {
        id: 'res_1',
        name: 'Unit 1 Notes - AI',
        category: 'Notes',
        type: 'PDF',
        department: 'Computer Science',
        uploadedBy: userUid,
        status: 'approved',
      },
      {
        id: 'res_2',
        name: 'Nov 2023 QP - OS',
        category: 'QP',
        type: 'PDF',
        department: 'Computer Science',
        uploadedBy: userUid,
        status: 'approved',
      },
      {
        id: 'res_3',
        name: 'Unit 2 Notes - Spam',
        category: 'Notes',
        type: 'PDF',
        department: 'Computer Science',
        uploadedBy: userUid,
        status: 'pending_moderation',
      },
    ];
    for (const r of resources) {
      await db
        .collection('hub_resources')
        .doc(r.id)
        .set({
          ...r,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          deletedAt: null,
        });
    }
    console.log('   ✅ Seeded hub resources.');

    console.log('\n--- Seeding Complete! ---');
    console.log(`\n👨‍🎓 Test User Credentials:`);
    console.log(`Email:    ${userEmail}`);
    console.log(`Password: password123`);
    console.log(`UID:      ${userUid}`);
    console.log(`Role:     superadmin`);
    console.log(`\nLogin via API to get the session cookie and test the endpoints!`);

    process.exit(0);
  } catch (error) {
    console.error('\n❌ Seeding failed:', error);
    process.exit(1);
  }
}

seed();
