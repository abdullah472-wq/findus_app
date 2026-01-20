const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

async function copyCollection(oldName, newName) {
  const oldCol = db.collection(oldName);
  const newCol = db.collection(newName);

  const snap = await oldCol.get();
  console.log("Found docs:", snap.size);

  let batch = db.batch();
  let op = 0;
  let total = 0;

  for (const doc of snap.docs) {
    batch.set(newCol.doc(doc.id), doc.data(), { merge: true });
    op++;
    total++;

    // Firestore batch limit 500
    if (op === 450) {
      await batch.commit();
      batch = db.batch();
      op = 0;
    }
  }

  if (op > 0) await batch.commit();
  console.log("Copied docs:", total);
}

copyCollection("notificationId", "notifications")
  .then(() => console.log("DONE"))
  .catch(console.error);