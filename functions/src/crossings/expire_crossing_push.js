const functions = require("firebase-functions");

const { admin, db } = require("../shared/firestore");

exports.expireCrossingPush = functions.pubsub
  .schedule("0 6 * * *")
  .timeZone("America/Sao_Paulo")
  .onRun(async () => {
    const now = new Date();
    const snapshot = await db
      .collection("usuarios")
      .where("pushCruzamento", "==", true)
      .where("pushCruzamentoExpiry", "<", now)
      .get();

    if (snapshot.empty) {
      console.log("Expired crossing push for 0 pilots");
      return;
    }

    const BATCH_LIMIT = 499;
    let updatedCount = 0;

    for (let i = 0; i < snapshot.docs.length; i += BATCH_LIMIT) {
      const batch = db.batch();
      const docs = snapshot.docs.slice(i, i + BATCH_LIMIT);

      docs.forEach((doc) => {
        batch.update(doc.ref, {
          pushCruzamento: false,
          pushCruzamentoExpiry: admin.firestore.FieldValue.delete(),
        });
      });

      await batch.commit();
      updatedCount += docs.length;
    }

    console.log(`Expired crossing push for ${updatedCount} pilots`);
  });
