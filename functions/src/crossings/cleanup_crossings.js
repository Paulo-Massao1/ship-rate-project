const functions = require("firebase-functions");

const { admin } = require("../shared/firestore");
const { db } = require("../shared/firestore");

const BATCH_LIMIT = 499;

exports.cleanupCrossings = functions.pubsub
  .schedule("every 1 hours")
  .timeZone("America/Sao_Paulo")
  .onRun(async () => {
    const now = new Date();
    const snapshot = await db
      .collection("cruzamentos")
      .where("dataHora", "<", now)
      .get();

    if (snapshot.empty) {
      console.log("No crossings to mark as expired.");
      return;
    }

    let expiredCount = 0;
    for (let i = 0; i < snapshot.docs.length; i += BATCH_LIMIT) {
      const batch = db.batch();
      const docs = snapshot.docs
        .slice(i, i + BATCH_LIMIT)
        .filter((doc) => doc.data().status !== "expired");

      if (docs.length === 0) continue;

      docs.forEach((doc) => {
        batch.set(
          doc.ref,
          {
            status: "expired",
            expiredAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      });

      await batch.commit();
      expiredCount += docs.length;
    }

    console.log(`Marked ${expiredCount} crossings as expired.`);
  });
