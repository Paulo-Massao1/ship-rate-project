const functions = require("firebase-functions");

const { admin, db } = require("../shared/firestore");
const { TEST_EMAILS } = require("../shared/constants");

function timestampMillis(timestamp) {
  return timestamp && typeof timestamp.toDate === "function"
    ? timestamp.toDate().getTime()
    : null;
}

function formatBrasiliaTime(timestamp) {
  const brasiliaTime = new Date(
    timestamp.toDate().getTime() - 3 * 60 * 60 * 1000,
  );
  return (
    `${String(brasiliaTime.getUTCDate()).padStart(2, "0")}/` +
    `${String(brasiliaTime.getUTCMonth() + 1).padStart(2, "0")} ` +
    `${String(brasiliaTime.getUTCHours()).padStart(2, "0")}:` +
    `${String(brasiliaTime.getUTCMinutes()).padStart(2, "0")}`
  );
}

exports.onCrossingUpdated = functions.firestore
  .document("cruzamentos/{docId}")
  .onUpdate(async (change) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const beforeTime = timestampMillis(beforeData.dataHora);
    const afterTime = timestampMillis(afterData.dataHora);

    if (!beforeTime || !afterTime || beforeTime === afterTime) {
      return;
    }

    const {
      pilotoId: pilotId,
      nomeGuerra: pilotCallSign,
      nomeNavio: shipName,
      local: location,
      dataHora: crossingDateTime,
    } = afterData;

    if (!pilotId) {
      console.log("Skipping update notification - no pilotoId.");
      return;
    }

    try {
      const pilotDoc = await db.collection("usuarios").doc(pilotId).get();
      const pilotEmail = pilotDoc.exists ? (pilotDoc.data().email || "") : "";
      if (TEST_EMAILS.includes(pilotEmail)) {
        console.log("Skipping update notifications for test account");
        return;
      }
    } catch (error) {
      console.error("Error checking test account:", error);
    }

    const formattedTime = formatBrasiliaTime(crossingDateTime);

    try {
      const usersSnapshot = await db.collection("usuarios").get();

      const tokens = [];
      const tokenToUid = {};
      const now = Date.now();

      usersSnapshot.docs.forEach((doc) => {
        const userData = doc.data();
        if (doc.id === pilotId) return;
        if (TEST_EMAILS.includes(userData.email)) return;
        if (userData.pushCruzamento === false) return;
        if (
          userData.pushCruzamentoExpiry &&
          typeof userData.pushCruzamentoExpiry.toDate === "function" &&
          userData.pushCruzamentoExpiry.toDate().getTime() < now
        ) {
          return;
        }
        if (
          userData.pushCruzamento === undefined &&
          userData.pushNotifications === false
        ) {
          return;
        }
        if (userData.fcmToken) {
          tokens.push(userData.fcmToken);
          tokenToUid[userData.fcmToken] = doc.id;
        }
      });

      if (tokens.length === 0) {
        console.log("No FCM tokens to send update notifications to.");
        return;
      }

      const batchSize = 500;
      for (let i = 0; i < tokens.length; i += batchSize) {
        const batch = tokens.slice(i, i + batchSize);

        const message = {
          notification: {
            title: `Hor\u00e1rio atualizado: ${shipName}`,
            body:
              `${pilotCallSign} atualizou o hor\u00e1rio do cruzamento em ` +
              `${location} para ${formattedTime}`,
          },
          data: {
            url: "https://shiprate-daf18.web.app",
          },
          tokens: batch,
        };

        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(
          `Update push batch sent: ${response.successCount} success, ` +
          `${response.failureCount} failures.`,
        );

        const staleTokens = [];
        response.responses.forEach((result, index) => {
          if (result.error) {
            const code = result.error.code;
            if (
              code === "messaging/registration-token-not-registered" ||
              code === "messaging/invalid-registration-token"
            ) {
              staleTokens.push(batch[index]);
            }
          }
        });

        const deletePromises = staleTokens.map((token) => {
          const uid = tokenToUid[token];
          if (!uid) return Promise.resolve();
          console.log(`Removing stale FCM token for user ${uid}`);
          return db.collection("usuarios").doc(uid).update({
            fcmToken: admin.firestore.FieldValue.delete(),
          });
        });

        await Promise.all(deletePromises);
      }
    } catch (error) {
      console.error("Error sending crossing update notification:", error);
    }
  });
