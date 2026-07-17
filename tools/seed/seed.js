/**
 * Firestore seed script for Ulama Circle.
 *
 * Writes test data (sheikhs, categories, lectures) using the Firebase Admin
 * SDK, which bypasses the Firestore security rules — so it works even though
 * the deployed rules block client-side writes to content collections.
 *
 * Idempotent: every doc uses a fixed ID and `.set()`, so re-running overwrites
 * rather than duplicating.
 *
 * Usage:
 *   1. Firebase console → Project settings → Service accounts →
 *      "Generate new private key". Save the JSON as:
 *          tools/seed/service-account.json   (gitignored — it's a real secret)
 *   2. cd tools/seed && npm install
 *   3. node seed.js
 *
 * The audio URLs point at public sample MP3s so playback/download can be
 * tested end-to-end before real lecture audio is uploaded to Storage.
 */

const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();
const { Timestamp } = admin.firestore;

// Reliable public sample MP3s (SoundHelix) — swap for real Storage URLs later.
const SAMPLE_AUDIO = [
  'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
  'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
  'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
];

// ---- Sheikhs ----
const sheikhs = [
  {
    id: 'sharafudeen',
    name: 'Dr. Sharafudeen',
    photoUrl: '',
    language: 'yoruba',
    bio: 'Nigerian Sunni scholar teaching Aqeedah and Tawheed in Yoruba and Arabic.',
    order: 1,
  },
  {
    id: 'aminu_daurawa',
    name: 'Sheikh Aminu Daurawa',
    photoUrl: '',
    language: 'hausa',
    bio: 'Hausa-language scholar based in northern Nigeria, known for Tafsir sessions.',
    order: 2,
  },
  {
    id: 'bilal_philips',
    name: 'Dr. Bilal Philips',
    photoUrl: '',
    language: 'english',
    bio: 'English-language scholar and educator covering foundational Islamic sciences.',
    order: 3,
  },
];

// ---- Quran reciters ----
// listenCount is denormalized (a Cloud Function bumps it in prod). surahCount is
// set below to the actual number of recitation docs we seed for each reciter, so
// the card count and the detail-screen list always agree.
const reciters = [
  {
    id: 'rec_yahuza',
    name: 'Qaari Yahuza Giro',
    coverUrl: '',
    language: 'arabic',
    description: 'Melodious full-mushaf recitation.',
    listenCount: 1434,
    order: 1,
  },
  {
    id: 'rec_abubukar',
    name: 'Qaari Abubukar Ibn Ibrahim',
    coverUrl: '',
    language: 'arabic',
    description: 'Classical tarteel recitation.',
    listenCount: 533,
    order: 2,
  },
  {
    id: 'rec_ibrahim',
    name: 'Qaari Ibrahim Yahya (English translation)',
    coverUrl: '',
    language: 'arabic',
    description: 'Recitation with English translation.',
    listenCount: 167,
    order: 3,
  },
  {
    id: 'rec_idris',
    name: 'Qaari Idris Gashuwa (Quran Recitation)',
    coverUrl: '',
    language: 'arabic',
    description: 'Heartfelt recitation of the last juz.',
    listenCount: 1217,
    order: 4,
  },
];

// Short surahs used to build sample recitations. `take` = how many each reciter
// gets (varies the surah counts).
const surahCatalog = [
  { n: 105, name: 'Suratul Fil' },
  { n: 106, name: 'Suratul Quraysh' },
  { n: 107, name: "Suratul Ma'un" },
  { n: 108, name: 'Suratul Kawthar' },
  { n: 109, name: 'Suratul Kafirun' },
  { n: 112, name: 'Suratul Ikhlas' },
  { n: 113, name: 'Suratul Falaq' },
  { n: 114, name: 'Suratul Nas' },
];
const surahsPerReciter = {
  rec_yahuza: 8,
  rec_abubukar: 6,
  rec_ibrahim: 4,
  rec_idris: 5,
};

// ---- Categories ----
const categories = [
  { id: 'aqeedah', name: 'Aqeedah', order: 1 },
  { id: 'tawheed', name: 'Tawheed', order: 2 },
  { id: 'fiqh', name: 'Fiqh', order: 3 },
  { id: 'seerah', name: 'Seerah', order: 4 },
  { id: 'tafsir', name: 'Tafsir', order: 5 },
];

// ---- Lectures ----
// keywords is a lowercase array (title + sheikh + category words) — mirrors
// what the admin panel will auto-generate on upload.
function kw(...parts) {
  return [
    ...new Set(
      parts
        .join(' ')
        .toLowerCase()
        .split(/[^a-z0-9]+/)
        .filter((w) => w.length > 2)
    ),
  ];
}

const now = Date.now();
const day = 24 * 60 * 60 * 1000;

const lectures = [
  {
    id: 'lec_0001',
    title: 'The Foundations of Tawheed',
    sheikhId: 'sharafudeen',
    category: 'tawheed',
    language: 'yoruba',
    isFeatured: true,
    durationSeconds: 3480,
    fileSizeMb: 33.1,
    ageDays: 1,
  },
  {
    id: 'lec_0002',
    title: 'Understanding the Names and Attributes of Allah',
    sheikhId: 'sharafudeen',
    category: 'aqeedah',
    language: 'yoruba',
    isFeatured: true,
    durationSeconds: 2940,
    fileSizeMb: 28.0,
    ageDays: 3,
  },
  {
    id: 'lec_0003',
    title: 'The Pillars of Iman Explained',
    sheikhId: 'sharafudeen',
    category: 'aqeedah',
    language: 'yoruba',
    isFeatured: false,
    durationSeconds: 3120,
    fileSizeMb: 29.7,
    ageDays: 6,
  },
  {
    id: 'lec_0004',
    title: 'Tafsir of Surah Al-Fatihah',
    sheikhId: 'aminu_daurawa',
    category: 'tafsir',
    language: 'hausa',
    isFeatured: true,
    durationSeconds: 4200,
    fileSizeMb: 40.0,
    ageDays: 2,
  },
  {
    id: 'lec_0005',
    title: 'The Fiqh of Purification (Taharah)',
    sheikhId: 'aminu_daurawa',
    category: 'fiqh',
    language: 'hausa',
    isFeatured: false,
    durationSeconds: 2760,
    fileSizeMb: 26.3,
    ageDays: 8,
  },
  {
    id: 'lec_0006',
    title: 'The Life of the Prophet: The Meccan Period',
    sheikhId: 'aminu_daurawa',
    category: 'seerah',
    language: 'hausa',
    isFeatured: false,
    durationSeconds: 3600,
    fileSizeMb: 34.3,
    ageDays: 11,
  },
  {
    id: 'lec_0007',
    title: 'Introduction to Islamic Belief',
    sheikhId: 'bilal_philips',
    category: 'aqeedah',
    language: 'english',
    isFeatured: true,
    durationSeconds: 3000,
    fileSizeMb: 28.6,
    ageDays: 4,
  },
  {
    id: 'lec_0008',
    title: 'The Fiqh of Salah',
    sheikhId: 'bilal_philips',
    category: 'fiqh',
    language: 'english',
    isFeatured: false,
    durationSeconds: 3300,
    fileSizeMb: 31.5,
    ageDays: 9,
  },
  {
    id: 'lec_0009',
    title: 'The Purpose of Creation',
    sheikhId: 'bilal_philips',
    category: 'tawheed',
    language: 'english',
    isFeatured: false,
    durationSeconds: 2880,
    fileSizeMb: 27.5,
    ageDays: 14,
  },
];

// Varied play counts so "Trending Now" (ordered by playCount) has a real order
// in dev, and so each scholar's denormalized `totalViews` is meaningful. In
// production these are incremented by a Cloud Function.
const playCountById = {
  lec_0001: 1240,
  lec_0002: 980,
  lec_0003: 875,
  lec_0004: 1530,
  lec_0005: 640,
  lec_0006: 410,
  lec_0007: 2100,
  lec_0008: 760,
  lec_0009: 320,
};

async function seed() {
  const sheikhById = Object.fromEntries(sheikhs.map((s) => [s.id, s]));
  const categoryById = Object.fromEntries(categories.map((c) => [c.id, c]));

  // Denormalize each scholar's total views + lecture count from their lectures,
  // so the Scholars grid reads them cheaply (one doc, no per-sheikh aggregate).
  const viewsBySheikh = {};
  const countBySheikh = {};
  for (const l of lectures) {
    viewsBySheikh[l.sheikhId] =
      (viewsBySheikh[l.sheikhId] || 0) + (playCountById[l.id] || 0);
    countBySheikh[l.sheikhId] = (countBySheikh[l.sheikhId] || 0) + 1;
  }

  let batch = db.batch();
  let ops = 0;
  const commit = async () => {
    if (ops > 0) {
      await batch.commit();
      batch = db.batch();
      ops = 0;
    }
  };

  // Sheikhs
  for (const s of sheikhs) {
    const { id, ...data } = s;
    data.totalViews = viewsBySheikh[id] || 0;
    data.lectureCount = countBySheikh[id] || 0;
    batch.set(db.collection('sheikhs').doc(id), data);
    ops++;
  }

  // Categories
  for (const c of categories) {
    const { id, ...data } = c;
    batch.set(db.collection('categories').doc(id), data);
    ops++;
  }

  // Quran reciters + their recitations (one doc per surah).
  let recitationCount = 0;
  for (const r of reciters) {
    const take = surahsPerReciter[r.id] || 0;
    const surahs = surahCatalog.slice(0, take);
    const { id, ...rdata } = r;
    rdata.surahCount = surahs.length;
    batch.set(db.collection('reciters').doc(id), rdata);
    ops++;

    surahs.forEach((s, idx) => {
      const recId = `qr_${id}_${s.n}`;
      batch.set(db.collection('recitations').doc(recId), {
        reciterId: id,
        reciterName: r.name,
        coverUrl: r.coverUrl,
        title: `Recitation Of Qur'an (${s.n}) ${s.name}`,
        surahNumber: s.n,
        audioUrl: SAMPLE_AUDIO[idx % SAMPLE_AUDIO.length],
        durationSeconds: 20 + (s.n % 40),
        order: idx + 1,
        // Varied listens so "most viewed recitation" is meaningful in dev.
        listenCount: ((s.n * 37 + idx * 91) % 900) + 40,
      });
      ops++;
      recitationCount++;
    });
  }
  await commit();

  // Albums group related lectures into a series. '' = standalone lecture.
  const albumById = {
    lec_0001: 'Tawheed Series',
    lec_0002: 'Aqeedah Foundations',
    lec_0003: 'Aqeedah Foundations',
    lec_0004: "Tafsir of the Qur'an",
    lec_0005: 'Fiqh of Worship',
    lec_0006: '',
    lec_0007: 'Foundations of Islam',
    lec_0008: 'Foundations of Islam',
    lec_0009: '',
  };

  // Lectures
  let i = 0;
  for (const l of lectures) {
    const sheikh = sheikhById[l.sheikhId];
    const category = categoryById[l.category];
    const album = albumById[l.id] || '';
    const data = {
      title: l.title,
      sheikhId: l.sheikhId,
      sheikhName: sheikh ? sheikh.name : '',
      audioUrl: SAMPLE_AUDIO[i % SAMPLE_AUDIO.length],
      durationSeconds: l.durationSeconds,
      language: l.language,
      category: l.category,
      album: album,
      isFeatured: l.isFeatured,
      dateAdded: Timestamp.fromMillis(now - l.ageDays * day),
      fileSizeMb: l.fileSizeMb,
      keywords: kw(l.title, sheikh ? sheikh.name : '', category ? category.name : '', l.language, album),
      commentCount: 0,
      playCount: playCountById[l.id] ?? 0,
    };
    batch.set(db.collection('lectures').doc(l.id), data);
    ops++;
    i++;
  }
  await commit();

  console.log(
    `Seeded ${sheikhs.length} sheikhs, ${categories.length} categories, ${lectures.length} lectures, ${reciters.length} reciters, ${recitationCount} recitations.`
  );
  console.log(
    'NOTE: to grant admin access, manually create a doc at admins/{yourUid} with { role: "admin" }.'
  );
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Seed failed:', err);
    process.exit(1);
  });
