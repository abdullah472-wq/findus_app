const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

exports.awardXpOnJobCompleted = functions.firestore
  .document("completed_jobs/{jobId}")
  .onCreate(async (snap, ctx) => {
    const data = snap.data() || {};
    const jobId = ctx.params.jobId;

    const participants = Array.isArray(data.participants) ? data.participants : [];
    if (participants.length < 2) return null;

    const points = 200;

    // ✅ idempotent: same jobId twice reward হবে না
    const batch = db.batch();

    for (const uid of participants) {
      const userRef = db.collection("users").doc(uid);
      const ledgerRef = userRef.collection("xp_ledger").doc(jobId);

      const ledgerSnap = await ledgerRef.get();
      if (ledgerSnap.exists) continue;

      batch.set(ledgerRef, {
        points,
        reason: "job_completed",
        jobId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      batch.set(
        userRef,
        {
          xpPoints: admin.firestore.FieldValue.increment(points),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    await batch.commit();
    return null;
  });