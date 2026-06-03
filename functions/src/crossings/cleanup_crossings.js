const functions = require("firebase-functions");

const { db } = require("../shared/firestore");

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

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Cleaned up ${snapshot.size} expired crossings.`);
  });
