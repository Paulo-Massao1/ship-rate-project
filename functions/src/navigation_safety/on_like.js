const functions = require("firebase-functions");
const { admin, db } = require("../shared/firestore");

const TEST_EMAILS = ["gcbrgame@gmail.com"];

exports.onLikeCreated = functions.firestore
  .document("locais/{locationId}/registros/{recordId}/likes/{likeId}")
  .onCreate(async (snap, context) => {
    const { locationId, recordId, likeId } = context.params;
    const likeData = snap.data() || {};
    console.log(`Like created by ${likeId} on record ${recordId}`);
    let notificationRef = null;
    let notificationClaimed = false;
    let pushSent = false;

    const recordRef = db
      .collection("locais")
      .doc(locationId)
      .collection("registros")
      .doc(recordId);

    await recordRef.update({
      likeCount: admin.firestore.FieldValue.increment(1),
    });

    try {
      const recordDoc = await recordRef.get();
      if (!recordDoc.exists) {
        console.log(`Skipping: record ${recordId} not found`);
        return;
      }

      const record = recordDoc.data();
      const pilotId = record.pilotId;

      if (!pilotId) {
        console.log("Skipping: missing pilotId");
        return;
      }

      if (pilotId === likeId) {
        console.log("Skipping: self-like");
        return;
      }

      const pilotDoc = await db.collection("usuarios").doc(pilotId).get();
      if (!pilotDoc.exists) {
        console.log(`Skipping: owner user ${pilotId} not found`);
        return;
      }

      const pilotData = pilotDoc.data() || {};

      if (TEST_EMAILS.includes(pilotData.email)) {
        console.log("Skipping: test account");
        return;
      }

      if (pilotData.pushNotifications === false || !pilotData.fcmToken) {
        console.log("Skipping: no token or notifications disabled");
        return;
      }

      notificationRef = recordRef
        .collection("like_notification_history")
        .doc(likeId);

      notificationClaimed = await db.runTransaction(async (transaction) => {
        const notificationDoc = await transaction.get(notificationRef);
        if (notificationDoc.exists) {
          return false;
        }

        transaction.set(notificationRef, {
          likerUid: likeId,
          pilotId: pilotId,
          status: "processing",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return true;
      });

      if (!notificationClaimed) {
        console.log("Skipping: already notified");
        return;
      }

      let locationName = "Local";
      const locationDoc = await db.collection("locais").doc(locationId).get();
      if (locationDoc.exists) {
        locationName = locationDoc.data().nome || locationName;
      }

      let likerName = "";
      const likerDoc = await db.collection("usuarios").doc(likeId).get();
      if (likerDoc.exists) {
        likerName = (likerDoc.data()?.nomeGuerra || "").trim();
      }
      if (!likerName) {
        likerName = (likeData.nomeGuerra || "").trim();
      }
      if (!likerName) {
        likerName = "Um pr\u00E1tico";
      }

      const message = {
        notification: {
          title: `\u2693 ${locationName}`,
          body: `${likerName} curtiu seu registro de profundidade`,
        },
        data: {
          locationId: locationId,
          url: "https://shiprate-daf18.web.app",
        },
        token: pilotData.fcmToken,
      };

      await admin.messaging().send(message);
      pushSent = true;
      await notificationRef.set({
        likerName: likerName,
        locationId: locationId,
        recordId: recordId,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "sent",
      }, { merge: true });
      console.log("Push sent successfully");
    } catch (err) {
      console.error(`Push error: ${err?.message || err}`);

      if (notificationClaimed && notificationRef && !pushSent) {
        try {
          await notificationRef.delete();
        } catch (rollbackErr) {
          console.error("Error rolling back like notification marker:", rollbackErr);
        }
      }

      if (
        err.code === "messaging/registration-token-not-registered" ||
        err.code === "messaging/invalid-registration-token"
      ) {
        const recordDoc = await recordRef.get();
        const pilotId = recordDoc.data()?.pilotId;
        if (pilotId) {
          await db.collection("usuarios").doc(pilotId).update({
            fcmToken: admin.firestore.FieldValue.delete(),
          });
          console.log(`Removed stale FCM token for user ${pilotId}`);
        }
      } else {
        console.error("Error in onLikeCreated:", err);
      }
    }
  });

exports.onLikeDeleted = functions.firestore
  .document("locais/{locationId}/registros/{recordId}/likes/{likeId}")
  .onDelete(async (snap, context) => {
    const { locationId, recordId } = context.params;

    const recordRef = db
      .collection("locais")
      .doc(locationId)
      .collection("registros")
      .doc(recordId);

    try {
      const recordDoc = await recordRef.get();
      if (!recordDoc.exists) return;

      const currentCount = recordDoc.data().likeCount || 0;
      if (currentCount <= 0) return;

      await recordRef.update({
        likeCount: admin.firestore.FieldValue.increment(-1),
      });
    } catch (err) {
      console.error("Error in onLikeDeleted:", err);
    }
  });
