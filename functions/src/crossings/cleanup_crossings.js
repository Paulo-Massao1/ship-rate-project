const functions = require("firebase-functions");

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
      console.log("No expired crossings to clean up.");
      return;
    }

    let deletedCount = 0;
    for (let i = 0; i < snapshot.docs.length; i += BATCH_LIMIT) {
      const batch = db.batch();
      const docs = snapshot.docs.slice(i, i + BATCH_LIMIT);

      docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      deletedCount += docs.length;
    }

    console.log(`Cleaned up ${deletedCount} expired crossings.`);
  });
