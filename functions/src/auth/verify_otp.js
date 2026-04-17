const functions = require("firebase-functions");
const { admin, db } = require("../shared/firestore");
const { auth } = require("../shared/auth");

exports.verifyOTP = functions.https.onCall(async (data) => {
  const email = (data.email || "").toLowerCase().trim();
  const code = (data.code || "").trim();

  if (!email || !code) {
    throw new functions.https.HttpsError("invalid-argument", "Email and code are required.");
  }

  const fifteenMinAgoMs = Date.now() - 15 * 60 * 1000;
  const emailOtpsSnapshot = await db
    .collection("otp_codes")
    .where("email", "==", email)
    .get();
  const recentDocs = emailOtpsSnapshot.docs.filter((d) => {
    const createdAt = d.data().createdAt;
    return createdAt && createdAt.toMillis() >= fifteenMinAgoMs;
  });

  const totalFailedAttempts = recentDocs.reduce(
    (sum, d) => sum + (d.data().failedAttempts || 0),
    0
  );
  if (totalFailedAttempts > 5) {
    return { success: false, error: "too-many-attempts" };
  }

  const matchingDoc = recentDocs.find((d) => d.data().code === code);

  if (!matchingDoc) {
    if (recentDocs.length > 0) {
      const mostRecent = recentDocs.reduce((a, b) =>
        a.data().createdAt.toMillis() >= b.data().createdAt.toMillis() ? a : b
      );
      await mostRecent.ref.update({
        failedAttempts: admin.firestore.FieldValue.increment(1),
      });
    }
    return { success: false, error: "invalid" };
  }

  const txResult = await db.runTransaction(async (tx) => {
    const snap = await tx.get(matchingDoc.ref);
    if (!snap.exists) return { error: "invalid" };
    const d = snap.data();
    if (d.used) return { error: "invalid" };
    const createdAt = d.createdAt?.toDate();
    if (!createdAt || (Date.now() - createdAt.getTime()) > 10 * 60 * 1000) {
      return { error: "expired" };
    }
    tx.update(matchingDoc.ref, { used: true });
    return { ok: true };
  });

  if (txResult.error) {
    return { success: false, error: txResult.error };
  }

  const authorizedSnapshot = await db
    .collection("authorized_emails")
    .where("email", "==", email)
    .limit(1)
    .get();

  const nomeGuerra = authorizedSnapshot.empty
    ? ""
    : authorizedSnapshot.docs[0].data().nomeGuerra || "";

  let user;
  try {
    user = await auth.getUserByEmail(email);
    if (user.displayName !== nomeGuerra && nomeGuerra) {
      await auth.updateUser(user.uid, { displayName: nomeGuerra });
    }
  } catch (err) {
    if (err.code === "auth/user-not-found") {
      user = await auth.createUser({
        email: email,
        displayName: nomeGuerra,
      });
    } else {
      throw new functions.https.HttpsError("internal", "Error creating user.");
    }
  }

  await db.collection("usuarios").doc(user.uid).set({
    nomeGuerra: nomeGuerra,
    email: email,
  }, { merge: true });

  const token = await auth.createCustomToken(user.uid);

  return { success: true, token: token };
});
