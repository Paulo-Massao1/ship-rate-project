const functions = require("firebase-functions");
const { admin, db } = require("../shared/firestore");

const TEST_EMAILS = ["gcbrgame@gmail.com", "spaulomassao@gmail.com"];
const CSPAM_UID = "vvmd4t7NHgYEiRbE3aPPcyGscdq1";
const INACTIVITY_DAYS = 90;
const REMINDER_COOLDOWN_DAYS = 30;

exports.inactivityReminder = functions.pubsub
  .schedule("every monday 13:00")
  .timeZone("America/Sao_Paulo")
  .onRun(async () => {
    const now = new Date();
    const inactivityThreshold = new Date(now);
    inactivityThreshold.setDate(inactivityThreshold.getDate() - INACTIVITY_DAYS);

    const reminderCooldown = new Date(now);
    reminderCooldown.setDate(reminderCooldown.getDate() - REMINDER_COOLDOWN_DAYS);

    const usuariosSnapshot = await db.collection("usuarios").get();
    let remindersSent = 0;

    for (const userDoc of usuariosSnapshot.docs) {
      const uid = userDoc.id;
      const userData = userDoc.data();

      if (uid === CSPAM_UID) continue;
      if (TEST_EMAILS.includes(userData.email)) continue;
      if (userData.pushNotifications === false) continue;
      if (!userData.fcmToken) continue;

      if (userData.lastReminderSent) {
        const lastSent = userData.lastReminderSent.toDate
          ? userData.lastReminderSent.toDate()
          : new Date(userData.lastReminderSent);
        if (lastSent > reminderCooldown) continue;
      }

      try {
        const ratingsSnapshot = await db
          .collectionGroup("avaliacoes")
          .where("usuarioId", "==", uid)
          .orderBy("dataAvaliacao", "descending")
          .limit(1)
          .get();

        let lastActivity = null;

        if (!ratingsSnapshot.empty) {
          const ratingData = ratingsSnapshot.docs[0].data();
          const ts = ratingData.dataAvaliacao;
          lastActivity = ts && ts.toDate ? ts.toDate() : null;
        }

        if (lastActivity && lastActivity > inactivityThreshold) continue;

        const message = {
          notification: {
            title: "⚓ ShipRate",
            body: "Faz tempo que você não avalia um navio. Sua contribuição ajuda todos os práticos!",
          },
          data: {
            url: "https://shiprate-daf18.web.app",
          },
          token: userData.fcmToken,
        };

        await admin.messaging().send(message);
        await db.collection("usuarios").doc(uid).update({
          lastReminderSent: admin.firestore.FieldValue.serverTimestamp(),
        });

        remindersSent++;
      } catch (err) {
        if (
          err.code === "messaging/registration-token-not-registered" ||
          err.code === "messaging/invalid-registration-token"
        ) {
          await db.collection("usuarios").doc(uid).update({
            fcmToken: admin.firestore.FieldValue.delete(),
          });
          console.log(`Removed stale FCM token for user ${uid}`);
        } else {
          console.error(`Error processing user ${uid}:`, err);
        }
      }
    }

    console.log(`Inactivity reminders sent: ${remindersSent}`);
  });
