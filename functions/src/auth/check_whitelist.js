const functions = require("firebase-functions");
const { db } = require("../shared/firestore");

exports.checkWhitelist = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be signed in.");
  }

  const email = (context.auth.token.email || "").toLowerCase().trim();
  if (!email) {
    return { whitelisted: false };
  }

  const snapshot = await db
    .collection("authorized_emails")
    .where("email", "==", email)
    .limit(1)
    .get();

  return { whitelisted: !snapshot.empty };
});
