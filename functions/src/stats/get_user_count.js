const functions = require("firebase-functions");
const { db } = require("../shared/firestore");
const { TEST_EMAILS } = require("../shared/constants");

exports.getUserCount = functions.https.onCall(async () => {
  const snapshot = await db.collection("usuarios").get();
  const count = snapshot.docs.filter((doc) => {
    const data = doc.data();
    if (TEST_EMAILS.includes(data.email)) return false;
    return true;
  }).length;
  return { count };
});
