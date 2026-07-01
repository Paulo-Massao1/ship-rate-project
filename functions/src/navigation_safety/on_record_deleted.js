const functions = require("firebase-functions");
const { admin, db } = require("../shared/firestore");
const { CSPAM_UID } = require("../shared/constants");

async function decrementDepthRecordCounters(pilotId) {
  const statsRef = db.collection("stats").doc("depthRecords");
  const hasRankedPilot = pilotId && pilotId !== CSPAM_UID;
  const userRef = hasRankedPilot ? db.collection("usuarios").doc(pilotId) : null;
  const pilotStatsRef = hasRankedPilot
    ? db.collection("pilotStats").doc(pilotId)
    : null;

  await db.runTransaction(async (transaction) => {
    const statsDoc = await transaction.get(statsRef);
    const statsCount = statsDoc.exists
      ? (statsDoc.data().totalCount || 0)
      : 0;
    const statsPilotCount = statsDoc.exists
      ? (statsDoc.data().pilotRecordCount || 0)
      : 0;

    const userDoc = userRef ? await transaction.get(userRef) : null;
    const userCount = userDoc && userDoc.exists
      ? (userDoc.data().depthRecordCount || 0)
      : 0;
    const pilotStatsDoc = pilotStatsRef
      ? await transaction.get(pilotStatsRef)
      : null;
    const pilotStatsCount = pilotStatsDoc && pilotStatsDoc.exists
      ? (pilotStatsDoc.data().depthRecordCount || 0)
      : 0;

    const statsUpdate = {
      totalCount: Math.max(statsCount - 1, 0),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (hasRankedPilot) {
      statsUpdate.pilotRecordCount = Math.max(statsPilotCount - 1, 0);
    }

    transaction.set(statsRef, statsUpdate, { merge: true });

    if (!hasRankedPilot) return;

    if (userRef && userCount > 0) {
      transaction.set(
        userRef,
        { depthRecordCount: userCount - 1 },
        { merge: true },
      );
    }

    if (pilotStatsRef && pilotStatsCount > 0) {
      transaction.set(
        pilotStatsRef,
        {
          depthRecordCount: pilotStatsCount - 1,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
  });
}

exports.onRecordDeleted = functions.firestore
  .document("locais/{locationId}/registros/{recordId}")
  .onDelete(async (snap, context) => {
    const { locationId, recordId } = context.params;
    const deletedData = snap.data();

    // Decrement depth record counters.
    try {
      await decrementDepthRecordCounters(deletedData.pilotId);
    } catch (err) {
      console.error("Error decrementing depth record counters:", err);
    }

    // Clean up storage files
    const prefix = `registros/${locationId}/${recordId}/`;
    const bucket = admin.storage().bucket();

    try {
      const [files] = await bucket.getFiles({ prefix });
      if (files.length === 0) {
        console.log(`No storage files found for prefix ${prefix}`);
        return;
      }

      const results = await Promise.allSettled(
        files.map((file) => file.delete({ ignoreNotFound: true }))
      );

      const failures = results.filter((result) => result.status === "rejected");
      if (failures.length > 0) {
        failures.forEach((failure) => {
          console.error(`Failed to delete file under ${prefix}:`, failure.reason);
        });
        throw new Error(
          `Storage cleanup failed for ${failures.length} file(s) under ${prefix}`
        );
      }

      console.log(`Deleted ${files.length} storage file(s) under ${prefix}`);
    } catch (err) {
      console.error(`onRecordDeleted failed for prefix ${prefix}:`, err);
      throw err;
    }
  });
