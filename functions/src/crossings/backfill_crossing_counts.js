const functions = require("firebase-functions");
const { admin, db } = require("../shared/firestore");
const { CSPAM_UID } = require("../shared/constants");

exports.backfillCrossingCounts = functions.https.onCall(async () => {
  const countsPerPilot = {};

  const crossingsSnapshot = await db.collection("cruzamentos").get();

  crossingsSnapshot.docs.forEach((doc) => {
    const data = doc.data();
    const pilotId = data.pilotoId || data.pilotId || data.usuarioId;
    if (!pilotId || pilotId === CSPAM_UID) return;
    countsPerPilot[pilotId] = (countsPerPilot[pilotId] || 0) + 1;
  });

  const [existingUserCountersSnapshot, existingPilotStatsSnapshot] =
    await Promise.all([
      db.collection("usuarios").where("crossingCount", ">", 0).get(),
      db.collection("pilotStats").where("crossingCount", ">", 0).get(),
    ]);

  const pilotIds = new Set(Object.keys(countsPerPilot));
  existingUserCountersSnapshot.docs.forEach((doc) => {
    if (doc.id !== CSPAM_UID) pilotIds.add(doc.id);
  });
  existingPilotStatsSnapshot.docs.forEach((doc) => {
    if (doc.id !== CSPAM_UID) pilotIds.add(doc.id);
  });

  const pilotIdsToWrite = Array.from(pilotIds);

  const batchSize = 250;
  let totalUpdated = 0;
  let totalReset = 0;

  for (let i = 0; i < pilotIdsToWrite.length; i += batchSize) {
    const batch = db.batch();
    const chunk = pilotIdsToWrite.slice(i, i + batchSize);

    chunk.forEach((pilotId) => {
      const count = countsPerPilot[pilotId] || 0;
      if (count === 0) totalReset++;
      batch.set(
        db.collection("usuarios").doc(pilotId),
        { crossingCount: count },
        { merge: true },
      );
      batch.set(
        db.collection("pilotStats").doc(pilotId),
        {
          crossingCount: count,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });

    await batch.commit();
    totalUpdated += chunk.length;
    console.log(`Backfilled ${totalUpdated}/${pilotIdsToWrite.length} pilots.`);
  }

  await db.collection("stats").doc("crossings").set(
    {
      totalCount: crossingsSnapshot.docs.length,
      contributorCount: Object.keys(countsPerPilot).length,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  console.log(
    `Backfill complete: ${totalUpdated} pilots, ` +
      `${crossingsSnapshot.docs.length} total crossings.`,
  );

  return {
    updated: totalUpdated,
    reset: totalReset,
    totalCrossings: crossingsSnapshot.docs.length,
  };
});
