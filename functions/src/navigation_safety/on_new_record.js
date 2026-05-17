const functions = require("firebase-functions");
const { admin, db } = require("../shared/firestore");
const { transporter, smtpEmail } = require("../shared/mailer");

const TEST_EMAILS = ["gcbrgame@gmail.com", "spaulomassao@gmail.com"];

exports.onNewRecord = functions.firestore
  .document("locais/{locationId}/registros/{registroId}")
  .onCreate(async (snap, context) => {
    const record = snap.data();
    const { locationId } = context.params;

    if (!record.pilotId) {
      console.log("Skipping notification — no pilotId (likely seed/batch).");
      return;
    }

    try {
      const pilotDoc = await db.collection("usuarios").doc(record.pilotId).get();
      const pilotEmail = pilotDoc.exists ? (pilotDoc.data().email || "") : "";
      if (TEST_EMAILS.includes(pilotEmail)) {
        console.log("Skipping notifications for test account");
        return;
      }
    } catch (err) {
      console.error("Error checking test account:", err);
    }

    const profundidadeTotal = record.profundidadeTotal || "N/A";
    const nomeGuerra = record.nomeGuerra || "Prático";
    const rawDate = record.data;
    let formattedDate = "N/A";
    if (rawDate && rawDate.toDate) {
      const d = rawDate.toDate();
      formattedDate = `${String(d.getDate()).padStart(2, "0")}/${String(d.getMonth() + 1).padStart(2, "0")}/${d.getFullYear()}`;
    } else if (rawDate instanceof Date) {
      formattedDate = `${String(rawDate.getDate()).padStart(2, "0")}/${String(rawDate.getMonth() + 1).padStart(2, "0")}/${rawDate.getFullYear()}`;
    }

    let locationName = "Local desconhecido";
    try {
      const locationDoc = await db.collection("locais").doc(locationId).get();
      if (locationDoc.exists) {
        locationName = locationDoc.data().nome || locationName;
      }
    } catch (err) {
      console.error("Error reading location:", err);
    }

    // --- Email Notification ---
    try {
      const usuariosSnapshot = await db.collection("usuarios").get();
      const pilotEmail = record.email || "";
      const emails = usuariosSnapshot.docs
        .map((doc) => doc.data())
        .filter((u) =>
          u.email &&
          u.emailNotifications !== false &&
          u.email !== pilotEmail &&
          !TEST_EMAILS.includes(u.email)
        )
        .map((u) => u.email);

      if (emails.length > 0) {
        const mailOptions = {
          from: `"ShipRate" <${smtpEmail}>`,
          to: smtpEmail,
          bcc: emails.join(","),
          subject: `ShipRate — Nova profundidade em ${locationName}`,
          html: `
            <div style="font-family: Arial, sans-serif; max-width: 520px; margin: 0 auto; padding: 32px; background: #0a1628; border-radius: 12px;">
              <h2 style="color: #26a69a; text-align: center; margin-bottom: 4px;">⚓ ShipRate</h2>
              <p style="color: rgba(255,255,255,0.5); text-align: center; font-size: 12px; margin-top: 0;">Segurança da Navegação</p>
              <hr style="border: none; border-top: 1px solid rgba(100,181,246,0.15); margin: 20px 0;" />
              <h3 style="color: #ffffff; text-align: center; margin-bottom: 24px;">Nova profundidade registrada</h3>
              <table style="width: 100%; color: #ffffff; font-size: 15px;">
                <tr>
                  <td style="padding: 8px 0; color: rgba(255,255,255,0.6);">Local</td>
                  <td style="padding: 8px 0; text-align: right; font-weight: bold;">${locationName}</td>
                </tr>
                <tr>
                  <td style="padding: 8px 0; color: rgba(255,255,255,0.6);">Profundidade Total</td>
                  <td style="padding: 8px 0; text-align: right; font-weight: bold; color: #26a69a; font-size: 18px;">${profundidadeTotal}m</td>
                </tr>
                <tr>
                  <td style="padding: 8px 0; color: rgba(255,255,255,0.6);">Prático</td>
                  <td style="padding: 8px 0; text-align: right;">${nomeGuerra}</td>
                </tr>
                <tr>
                  <td style="padding: 8px 0; color: rgba(255,255,255,0.6);">Data</td>
                  <td style="padding: 8px 0; text-align: right;">${formattedDate}</td>
                </tr>
              </table>
              <hr style="border: none; border-top: 1px solid rgba(100,181,246,0.15); margin: 20px 0;" />
              <p style="text-align: center; margin-top: 24px;">
                <a href="https://shiprate.web.app" style="background: linear-gradient(135deg, #00897b, #26a69a); color: #ffffff; text-decoration: none; padding: 12px 28px; border-radius: 8px; font-weight: bold; display: inline-block;">Abrir ShipRate</a>
              </p>
              <p style="color: rgba(255,255,255,0.3); text-align: center; font-size: 11px; margin-top: 24px;">Você recebeu este e-mail porque está cadastrado no ShipRate.</p>
            </div>
          `,
        };

        await transporter.sendMail(mailOptions);
        console.log(`Email sent to ${emails.length} pilots for ${locationName}.`);
      }
    } catch (err) {
      console.error("Error sending email notification:", err);
    }

    // --- Push Notification via FCM (token-based) ---
    try {
      const usuariosSnapshot = await db.collection("usuarios").get();

      const tokens = [];
      const tokenToUid = {};

      usuariosSnapshot.docs.forEach((doc) => {
        const data = doc.data();
        // Skip the pilot who created the record
        if (doc.id === record.pilotId) return;
        // Skip test accounts
        if (TEST_EMAILS.includes(data.email)) return;
        // Skip users who disabled push notifications
        if (data.pushNotifications === false) return;
        // Collect valid tokens
        if (data.fcmToken) {
          tokens.push(data.fcmToken);
          tokenToUid[data.fcmToken] = doc.id;
        }
      });

      if (tokens.length === 0) {
        console.log("No FCM tokens to send push notifications to.");
        return;
      }

      // Send in batches of 500 (FCM limit)
      const batchSize = 500;
      for (let i = 0; i < tokens.length; i += batchSize) {
        const batch = tokens.slice(i, i + batchSize);

        const message = {
          notification: {
            title: `⚓ ${locationName}`,
            body: `Nova profundidade: ${profundidadeTotal}m — registrada por ${nomeGuerra} em ${formattedDate}`,
          },
          data: {
            locationId: locationId,
            url: "https://shiprate-daf18.web.app",
          },
          tokens: batch,
        };

        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(`Push batch sent: ${response.successCount} success, ${response.failureCount} failures.`);

        // Clean up invalid/expired tokens
        const tokensToDelete = [];
        response.responses.forEach((resp, idx) => {
          if (resp.error) {
            const code = resp.error.code;
            if (
              code === "messaging/registration-token-not-registered" ||
              code === "messaging/invalid-registration-token"
            ) {
              tokensToDelete.push(batch[idx]);
            }
          }
        });

        // Remove stale tokens from Firestore
        const deletePromises = tokensToDelete.map((token) => {
          const uid = tokenToUid[token];
          if (!uid) return Promise.resolve();
          console.log(`Removing stale FCM token for user ${uid}`);
          return db.collection("usuarios").doc(uid).update({
            fcmToken: admin.firestore.FieldValue.delete(),
          });
        });

        await Promise.all(deletePromises);
      }
    } catch (err) {
      console.error("Error sending push notification:", err);
    }
  });
