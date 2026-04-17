const functions = require("firebase-functions");
const { admin, db } = require("../shared/firestore");
const { auth } = require("../shared/auth");
const { transporter, smtpEmail } = require("../shared/mailer");

exports.sendOTP = functions.https.onCall(async (data) => {
  const email = (data.email || "").toLowerCase().trim();

  if (!email) {
    throw new functions.https.HttpsError("invalid-argument", "Email is required.");
  }

  const authorizedSnapshot = await db
    .collection("authorized_emails")
    .where("email", "==", email)
    .limit(1)
    .get();

  if (authorizedSnapshot.empty) {
    throw new functions.https.HttpsError("permission-denied", "not_authorized");
  }

  try {
    await auth.getUserByEmail(email);
    return { success: false, error: "already-registered" };
  } catch (e) {
    // User doesn't exist — proceed with OTP
  }

  const fifteenMinAgoMs = Date.now() - 15 * 60 * 1000;
  const recentOtpsSnapshot = await db
    .collection("otp_codes")
    .where("email", "==", email)
    .get();
  const recentOtpsCount = recentOtpsSnapshot.docs.filter((d) => {
    const createdAt = d.data().createdAt;
    return createdAt && createdAt.toMillis() >= fifteenMinAgoMs;
  }).length;
  if (recentOtpsCount > 3) {
    return { success: false, error: "rate-limited" };
  }

  const code = String(Math.floor(100000 + Math.random() * 900000));

  await db.collection("otp_codes").add({
    email: email,
    code: code,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    used: false,
    failedAttempts: 0,
  });

  const mailOptions = {
    from: `"ShipRate" <${smtpEmail}>`,
    to: email,
    subject: "ShipRate - Código de Verificação",
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; background: #0a1628; border-radius: 12px;">
        <h2 style="color: #64b5f6; text-align: center; margin-bottom: 8px;">ShipRate</h2>
        <p style="color: #ffffff; text-align: center; font-size: 16px;">Seu código de verificação é:</p>
        <div style="background: #1a2e45; border-radius: 8px; padding: 20px; text-align: center; margin: 24px 0;">
          <span style="font-size: 36px; font-weight: bold; color: #64b5f6; letter-spacing: 8px;">${code}</span>
        </div>
        <p style="color: rgba(255,255,255,0.6); text-align: center; font-size: 14px;">Este código expira em 10 minutos.</p>
        <p style="color: rgba(255,255,255,0.4); text-align: center; font-size: 12px; margin-top: 24px;">Se você não solicitou este código, ignore este e-mail.</p>
      </div>
    `,
  };

  await transporter.sendMail(mailOptions);

  return { success: true };
});
