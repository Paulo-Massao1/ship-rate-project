const functions = require("firebase-functions");
const { admin, db } = require("../shared/firestore");
const { TEST_EMAILS } = require("../shared/constants");

exports.onRatingLikeCreated = functions.firestore
  .document("navios/{shipId}/avaliacoes/{ratingId}/likes/{likeId}")
  .onCreate(async (snap, context) => {
    const { shipId, ratingId, likeId } = context.params;
    const likeData = snap.data() || {};
    console.log(`Rating like created by ${likeId} on rating ${ratingId}`);
    let notificationRef = null;
    let notificationClaimed = false;
    let pushSent = false;
    let ownerId = null;

    const ratingRef = db
      .collection("navios")
      .doc(shipId)
      .collection("avaliacoes")
      .doc(ratingId);

    await ratingRef.update({
      likeCount: admin.firestore.FieldValue.increment(1),
    });

    try {
      const ratingDoc = await ratingRef.get();
      if (!ratingDoc.exists) {
        console.log(`Skipping: rating ${ratingId} not found`);
        return;
      }

      const rating = ratingDoc.data() || {};
      ownerId = rating.usuarioId;

      if (!ownerId) {
        console.log("Skipping: missing usuarioId");
        return;
      }

      if (ownerId === likeId) {
        console.log("Skipping: self-like");
        return;
      }

      const likerDoc = await db.collection("usuarios").doc(likeId).get();
      const likerData = likerDoc.data() || {};
      if (TEST_EMAILS.includes(likerData.email)) {
        console.log("Skipping: test account");
        return;
      }

      const ownerDoc = await db.collection("usuarios").doc(ownerId).get();
      if (!ownerDoc.exists) {
        console.log(`Skipping: owner user ${ownerId} not found`);
        return;
      }

      const ownerData = ownerDoc.data() || {};
      if (TEST_EMAILS.includes(ownerData.email)) {
        console.log("Skipping: test account");
        return;
      }

      if (ownerData.pushNotifications === false || !ownerData.fcmToken) {
        console.log("Skipping: no token or notifications disabled");
        return;
      }

      notificationRef = ratingRef
        .collection("rating_like_notification_history")
        .doc(likeId);

      notificationClaimed = await db.runTransaction(async (transaction) => {
        const notificationDoc = await transaction.get(notificationRef);
        if (notificationDoc.exists) {
          return false;
        }

        transaction.set(notificationRef, {
          likerUid: likeId,
          ownerId: ownerId,
          status: "processing",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return true;
      });

      if (!notificationClaimed) {
        console.log("Skipping: already notified");
        return;
      }

      let shipName = "Navio";
      const shipDoc = await db.collection("navios").doc(shipId).get();
      if (shipDoc.exists) {
        shipName = shipDoc.data().nome || shipName;
      }

      let likerName = "";
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
          title: `\u2693 ${shipName}`,
          body: `${likerName} curtiu sua avalia\u00E7\u00E3o`,
        },
        data: {
          shipId: shipId,
          ratingId: ratingId,
          url: "https://shiprate-daf18.web.app",
        },
        token: ownerData.fcmToken,
      };

      await admin.messaging().send(message);
      pushSent = true;
      await notificationRef.set({
        likerName: likerName,
        shipId: shipId,
        ratingId: ratingId,
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
          console.error(
            "Error rolling back rating like notification marker:",
            rollbackErr
          );
        }
      }

      if (
        (err.code === "messaging/registration-token-not-registered" ||
          err.code === "messaging/invalid-registration-token") &&
        ownerId
      ) {
        await db.collection("usuarios").doc(ownerId).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
        console.log(`Removed stale FCM token for user ${ownerId}`);
      } else {
        console.error("Error in onRatingLikeCreated:", err);
      }
    }
  });

exports.onRatingLikeDeleted = functions.firestore
  .document("navios/{shipId}/avaliacoes/{ratingId}/likes/{likeId}")
  .onDelete(async (_, context) => {
    const { shipId, ratingId } = context.params;

    const ratingRef = db
      .collection("navios")
      .doc(shipId)
      .collection("avaliacoes")
      .doc(ratingId);

    try {
      const ratingDoc = await ratingRef.get();
      if (!ratingDoc.exists) return;

      const currentCount = ratingDoc.data().likeCount || 0;
      if (currentCount <= 0) return;

      await ratingRef.update({
        likeCount: admin.firestore.FieldValue.increment(-1),
      });
    } catch (err) {
      console.error("Error in onRatingLikeDeleted:", err);
    }
  });
