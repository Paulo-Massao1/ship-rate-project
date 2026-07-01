const functions = require("firebase-functions");
const { admin, db } = require("../shared/firestore");
const { CSPAM_UID } = require("../shared/constants");

exports.backfillDepthRecordCounts = functions.https.onCall(async () => {
  const countsPerPilot = {};
  let pilotRecordCount = 0;

  const recordsSnapshot = await db
    .collectionGroup("registros")
    .get();

  recordsSnapshot.docs.forEach((doc) => {
    const pilotId = doc.data().pilotId;
    if (!pilotId || pilotId === CSPAM_UID) return;
    pilotRecordCount++;
    countsPerPilot[pilotId] = (countsPerPilot[pilotId] || 0) + 1;
  });

  const [existingUserCountersSnapshot, existingPilotStatsSnapshot] =
    await Promise.all([
      db.collection("usuarios").where("depthRecordCount", ">", 0).get(),
      db.collection("pilotStats").where("depthRecordCount", ">", 0).get(),
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
        { depthRecordCount: count },
        { merge: true },
      );
      batch.set(
        db.collection("pilotStats").doc(pilotId),
        {
          depthRecordCount: count,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });

    await batch.commit();
    totalUpdated += chunk.length;
    console.log(`Backfilled ${totalUpdated}/${pilotIdsToWrite.length} pilots.`);
  }

  await db.collection("stats").doc("depthRecords").set(
    {
      totalCount: recordsSnapshot.docs.length,
      pilotRecordCount,
      contributorCount: Object.keys(countsPerPilot).length,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  console.log(
    `Backfill complete: ${totalUpdated} pilots, ` +
    `${recordsSnapshot.docs.length} total records.`,
  );

  return {
    updated: totalUpdated,
    reset: totalReset,
    totalRecords: recordsSnapshot.docs.length,
  };
});
