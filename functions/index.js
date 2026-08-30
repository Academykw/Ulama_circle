/**
 * Ulama Circle Cloud Functions (2nd gen).
 *
 *  - sendTopicNotification  (callable, admin-only) — push to an FCM topic;
 *      backs the admin panel's "Notifications" module.
 *  - incrementPlayCount     (callable) — bump a lecture's playCount + its
 *      scholar's totalViews. O(1); safe to call on every play.
 *  - onLectureWritten       (trigger) — keep sheikh.lectureCount accurate.
 *  - onRecitationWritten    (trigger) — keep reciter.surahCount accurate.
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const {
  onDocumentWritten,
  onDocumentCreated,
} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const inc = (n) => admin.firestore.FieldValue.increment(n || 1);

async function assertAdmin(auth) {
  if (!auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const doc = await db.collection("admins").doc(auth.uid).get();
  if (!doc.exists) {
    throw new HttpsError("permission-denied", "Admins only.");
  }
}

// Rolls up a daily counter in stats_daily/{YYYY-MM-DD} for the time-series chart.
async function bumpDaily(field) {
  const key = new Date().toISOString().slice(0, 10);
  await db.collection("stats_daily").doc(key).set(
    { date: key, [field]: inc(1) },
    { merge: true },
  );
}

// Per-lecture daily rollup — powers "top lectures this week / today". One tiny
// doc per lecture per day; the admin sums the last N days client-side.
async function bumpLectureDaily(lectureId, title, sheikhName) {
  const key = new Date().toISOString().slice(0, 10);
  await db
    .collection("lecture_stats_daily")
    .doc(`${key}__${lectureId}`)
    .set(
      {
        date: key,
        lectureId,
        title: title || "",
        sheikhName: sheikhName || "",
        plays: inc(1),
      },
      { merge: true },
    );
}

exports.sendTopicNotification = onCall({ invoker: "public" }, async (req) => {
  await assertAdmin(req.auth);
  const { topic, title, body, type } = req.data || {};
  if (!topic || !title) {
    throw new HttpsError("invalid-argument", "topic and title are required.");
  }
  const messageId = await admin.messaging().send({
    topic,
    notification: { title, body: body || "" },
    data: { type: type || "general" },
    android: { priority: "high" },
  });
  return { messageId };
});

exports.incrementPlayCount = onCall({ invoker: "public" }, async (req) => {
  if (!req.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const { lectureId } = req.data || {};
  if (!lectureId) {
    throw new HttpsError("invalid-argument", "lectureId is required.");
  }
  const lectureRef = db.collection("lectures").doc(lectureId);
  const snap = await lectureRef.get();
  if (!snap.exists) return { ok: false };
  await lectureRef.update({ playCount: inc(1) });
  const sheikhId = snap.get("sheikhId");
  if (sheikhId) {
    await db.collection("sheikhs").doc(sheikhId).set({ totalViews: inc(1) }, { merge: true });
  }
  await bumpDaily("plays");
  await bumpLectureDaily(lectureId, snap.get("title"), snap.get("sheikhName"));
  return { ok: true };
});

exports.incrementRecitationListen = onCall({ invoker: "public" }, async (req) => {
  if (!req.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const { recitationId } = req.data || {};
  if (!recitationId) {
    throw new HttpsError("invalid-argument", "recitationId is required.");
  }
  const ref = db.collection("recitations").doc(recitationId);
  const snap = await ref.get();
  if (!snap.exists) return { ok: false };
  await ref.update({ listenCount: inc(1) });
  const reciterId = snap.get("reciterId");
  if (reciterId) {
    await db.collection("reciters").doc(reciterId).set({ listenCount: inc(1) }, { merge: true });
  }
  await bumpDaily("listens");
  return { ok: true };
});

// Keep the scholar's lecture count in sync (aggregate — cheap).
exports.onLectureWritten = onDocumentWritten("lectures/{id}", async (event) => {
  const before = event.data.before.exists ? event.data.before.data() : null;
  const after = event.data.after.exists ? event.data.after.data() : null;
  const sheikhIds = new Set();
  if (before && before.sheikhId) sheikhIds.add(before.sheikhId);
  if (after && after.sheikhId) sheikhIds.add(after.sheikhId);
  for (const sid of sheikhIds) {
    const agg = await db.collection("lectures").where("sheikhId", "==", sid).count().get();
    await db.collection("sheikhs").doc(sid).set(
      { lectureCount: agg.data().count },
      { merge: true },
    );
  }
});

// Count new users per day for the growth chart (guests included; registered
// users tracked separately in newRegistered).
exports.onUserCreated = onDocumentCreated("users/{uid}", async (event) => {
  const data = event.data ? event.data.data() : null;
  const key = new Date().toISOString().slice(0, 10);
  const fields = { date: key, newUsers: inc(1) };
  if (data && data.isGuest === false) fields.newRegistered = inc(1);
  await db.collection("stats_daily").doc(key).set(fields, { merge: true });
});

// Keep the reciter's surah count in sync.
exports.onRecitationWritten = onDocumentWritten("recitations/{id}", async (event) => {
  const before = event.data.before.exists ? event.data.before.data() : null;
  const after = event.data.after.exists ? event.data.after.data() : null;
  const reciterIds = new Set();
  if (before && before.reciterId) reciterIds.add(before.reciterId);
  if (after && after.reciterId) reciterIds.add(after.reciterId);
  for (const rid of reciterIds) {
    const agg = await db.collection("recitations").where("reciterId", "==", rid).count().get();
    await db.collection("reciters").doc(rid).set(
      { surahCount: agg.data().count },
      { merge: true },
    );
  }
});
