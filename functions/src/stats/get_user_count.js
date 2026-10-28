const functions = require("firebase-functions/v1");
const { db } = require("../shared/firestore");
const {
  USER_COUNT_EXCLUDED_EMAILS,
  USER_COUNT_EXCLUDED_UIDS,
} = require("../shared/constants");

exports.getUserCount = functions.https.onCall(async () => {
  const snapshot = await db.collection("usuarios").get();
  const count = snapshot.docs.filter((doc) => {
    if (USER_COUNT_EXCLUDED_UIDS.includes(doc.id)) return false;
    const data = doc.data();
    const email = String(data.email || "").trim().toLowerCase();
    if (USER_COUNT_EXCLUDED_EMAILS.includes(email)) return false;
    return true;
  }).length;
  return { count };
});
