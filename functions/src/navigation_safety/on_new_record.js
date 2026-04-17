const functions = require("firebase-functions");
const { admin, db } = require("../shared/firestore");
const { transporter, smtpEmail } = require("../shared/mailer");

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
      if (pilotEmail === "gcbrgame@gmail.com") {
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
        .filter((u) => u.email && u.emailNotifications !== false && u.email !== pilotEmail)
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

    // --- Push Notification via FCM ---
    try {
      const message = {
        topic: "all_pilots",
        notification: {
          title: `Nova profundidade — ${locationName}`,
          body: `${profundidadeTotal}m por ${nomeGuerra} em ${formattedDate}`,
        },
        data: {
          locationId: locationId,
        },
      };

      await admin.messaging().send(message);
      console.log(`Push notification sent to topic all_pilots for ${locationName}.`);
    } catch (err) {
      console.error("Error sending push notification:", err);
    }
  });
