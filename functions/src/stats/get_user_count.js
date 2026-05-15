const functions = require("firebase-functions");
const { db } = require("../shared/firestore");

exports.getUserCount = functions.https.onCall(async () => {
  const testEmails = ["gcbrgame@gmail.com", "spaulomassao@gmail.com"];
  const snapshot = await db.collection("usuarios").get();
  const count = snapshot.docs.filter(
    (doc) => !testEmails.includes(doc.data().email)
  ).length;
  return { count };
});
