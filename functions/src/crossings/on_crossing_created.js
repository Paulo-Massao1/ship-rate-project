const functions = require("firebase-functions");

const { admin, db } = require("../shared/firestore");
const { TEST_EMAILS } = require("../shared/constants");

exports.onCrossingCreated = functions.firestore
  .document("cruzamentos/{docId}")
  .onCreate(async (snap) => {
    const data = snap.data();
    const {
      pilotoId: pilotId,
      nomeGuerra: pilotCallSign,
      nomeNavio: shipName,
      local: location,
      direcao: direction,
      dataHora: crossingDateTime,
    } = data;

    if (!pilotId) {
      console.log("Skipping notification - no pilotoId.");
      return;
    }

    try {
      const pilotDoc = await db.collection("usuarios").doc(pilotId).get();
      const pilotEmail = pilotDoc.exists ? (pilotDoc.data().email || "") : "";
      if (TEST_EMAILS.includes(pilotEmail)) {
        console.log("Skipping notifications for test account");
        return;
      }
    } catch (error) {
      console.error("Error checking test account:", error);
    }

    const brasiliaTime = new Date(crossingDateTime.toDate().getTime());
    const formattedTime =
      `${String(brasiliaTime.getUTCDate()).padStart(2, "0")}/` +
      `${String(brasiliaTime.getUTCMonth() + 1).padStart(2, "0")} ` +
      `${String(brasiliaTime.getUTCHours()).padStart(2, "0")}:` +
      `${String(brasiliaTime.getUTCMinutes()).padStart(2, "0")}`;

    try {
      const usersSnapshot = await db.collection("usuarios").get();

      const tokens = [];
      const tokenToUid = {};

      usersSnapshot.docs.forEach((doc) => {
        const userData = doc.data();
        if (doc.id === pilotId) return;
        if (TEST_EMAILS.includes(userData.email)) return;
        if (userData.pushCruzamento === false) return;
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
        console.log("No FCM tokens to send push notifications to.");
        return;
      }

      const batchSize = 500;
      for (let i = 0; i < tokens.length; i += batchSize) {
        const batch = tokens.slice(i, i + batchSize);

        const message = {
          notification: {
            title: `Novo cruzamento: ${shipName}`,
            body:
              `${pilotCallSign} registrou cruzamento previsto em ` +
              `${location} as ${formattedTime} - ${direction}`,
          },
          data: {
            url: "https://shiprate-daf18.web.app",
          },
          tokens: batch,
        };

        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(
          `Push batch sent: ${response.successCount} success, ` +
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
      console.error("Error sending crossing push notification:", error);
    }
  });
