const functions = require("firebase-functions");
const { admin, db } = require("../shared/firestore");
const { CSPAM_UID } = require("../shared/constants");

async function decrementCrossingCounters(pilotId) {
  const statsRef = db.collection("stats").doc("crossings");
  const hasRankedPilot = pilotId && pilotId !== CSPAM_UID;
  const userRef = hasRankedPilot
    ? db.collection("usuarios").doc(pilotId)
    : null;
  const pilotStatsRef = hasRankedPilot
    ? db.collection("pilotStats").doc(pilotId)
    : null;

  await db.runTransaction(async (transaction) => {
    const statsDoc = await transaction.get(statsRef);
    const statsCount = statsDoc.exists
      ? (statsDoc.data().totalCount || 0)
      : 0;

    const userDoc = userRef ? await transaction.get(userRef) : null;
    const userCount =
      userDoc && userDoc.exists ? (userDoc.data().crossingCount || 0) : 0;
    const pilotStatsDoc = pilotStatsRef
      ? await transaction.get(pilotStatsRef)
      : null;
    const pilotStatsCount = pilotStatsDoc && pilotStatsDoc.exists
      ? (pilotStatsDoc.data().crossingCount || 0)
      : 0;

    transaction.set(
      statsRef,
      {
        totalCount: Math.max(statsCount - 1, 0),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    if (!hasRankedPilot) return;

    if (userRef && userCount > 0) {
      transaction.set(
        userRef,
        { crossingCount: userCount - 1 },
        { merge: true },
      );
    }

    if (pilotStatsRef && pilotStatsCount > 0) {
      transaction.set(
        pilotStatsRef,
        {
          crossingCount: pilotStatsCount - 1,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
  });
}

exports.onCrossingDeleted = functions.firestore
  .document("cruzamentos/{docId}")
  .onDelete(async (snap) => {
    const data = snap.data();
    const pilotId = data.pilotoId || data.pilotId || data.usuarioId;

    try {
      await decrementCrossingCounters(pilotId);
    } catch (error) {
      console.error("Error decrementing crossing counters:", error);
    }
  });
