const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// ---------------------------------------------------------------------------
// SMTP CONFIGURATION (via .env file in functions/ directory)
// ---------------------------------------------------------------------------
const smtpEmail = process.env.SMTP_EMAIL;
const smtpPassword = process.env.SMTP_PASSWORD;

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: smtpEmail,
    pass: smtpPassword,
  },
});

const db = admin.firestore();

/// 🔑 MAPA OFICIAL DE CHAVES (BACKEND ⇄ FRONTEND)
const MAPA_CHAVES = {
  "Dispositivo de Embarque/Desembarque": "dispositivo",
  "Temperatura da Cabine": "temp_cabine",
  "Limpeza da Cabine": "limpeza_cabine",
  "Passadiço – Equipamentos": "passadico_equip",
  "Passadiço – Temperatura": "passadico_temp",
  "Comida": "comida",
  "Relacionamento com comandante/tripulação": "relacionamento",
};

/// ---------------------------------------------------------------------------
/// RECALCULA MÉDIAS AO EXCLUIR UMA AVALIAÇÃO
/// ---------------------------------------------------------------------------
exports.recalcularMediasAoExcluirAvaliacao = functions.firestore
  .document("navios/{navioId}/avaliacoes/{avaliacaoId}")
  .onDelete(async (_, context) => {
    const navioId = context.params.navioId;

    const avaliacoesRef = db
      .collection("navios")
      .doc(navioId)
      .collection("avaliacoes");

    const snapshot = await avaliacoesRef.get();

    if (snapshot.empty) {
      await db.collection("navios").doc(navioId).update({
        medias: {},
      });
      return;
    }

    const soma = {};
    const contagem = {};

    snapshot.docs.forEach((doc) => {
      const data = doc.data();
      const itens = data.itens || {};

      Object.entries(itens).forEach(([chave, valor]) => {
        const keyPadrao = MAPA_CHAVES[chave];
        const nota = valor?.nota;

        if (keyPadrao && typeof nota === "number") {
          soma[keyPadrao] = (soma[keyPadrao] || 0) + nota;
          contagem[keyPadrao] = (contagem[keyPadrao] || 0) + 1;
        }
      });
    });

    const medias = {};
    Object.keys(soma).forEach((chave) => {
      medias[chave] = Number(
        (soma[chave] / contagem[chave]).toFixed(2)
      );
    });

    await db.collection("navios").doc(navioId).update({
      medias,
    });
  });

/// ---------------------------------------------------------------------------
/// RECALCULA TODAS AS MÉDIAS (MANUAL / CORREÇÃO GLOBAL)
/// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// SEND OTP — Checks authorized_emails and sends 6-digit code
// ---------------------------------------------------------------------------
exports.sendOTP = functions.https.onCall(async (data) => {
  const email = (data.email || "").toLowerCase().trim();

  if (!email) {
    throw new functions.https.HttpsError("invalid-argument", "Email is required.");
  }

  // Check if email is in authorized_emails collection
  const authorizedSnapshot = await db
    .collection("authorized_emails")
    .where("email", "==", email)
    .limit(1)
    .get();

  if (authorizedSnapshot.empty) {
    throw new functions.https.HttpsError("permission-denied", "not_authorized");
  }

  // Check if a Firebase Auth user already exists with this email
  try {
    await admin.auth().getUserByEmail(email);
    // User exists — return error
    return { success: false, error: "already-registered" };
  } catch (e) {
    // User doesn't exist — proceed with OTP
  }

  // Rate limit: more than 3 OTPs in the last 15 minutes for this email
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

  // Generate 6-digit code
  const code = String(Math.floor(100000 + Math.random() * 900000));

  // Store OTP in Firestore
  await db.collection("otp_codes").add({
    email: email,
    code: code,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    used: false,
    failedAttempts: 0,
  });

  // Send email
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

// ---------------------------------------------------------------------------
// VERIFY OTP — Validates code and returns custom auth token
// ---------------------------------------------------------------------------
exports.verifyOTP = functions.https.onCall(async (data) => {
  const email = (data.email || "").toLowerCase().trim();
  const code = (data.code || "").trim();

  if (!email || !code) {
    throw new functions.https.HttpsError("invalid-argument", "Email and code are required.");
  }

  // Gather recent OTP docs for this email (last 15 minutes) to enforce
  // rate limits and locate a possible match for the code.
  const fifteenMinAgoMs = Date.now() - 15 * 60 * 1000;
  const emailOtpsSnapshot = await db
    .collection("otp_codes")
    .where("email", "==", email)
    .get();
  const recentDocs = emailOtpsSnapshot.docs.filter((d) => {
    const createdAt = d.data().createdAt;
    return createdAt && createdAt.toMillis() >= fifteenMinAgoMs;
  });

  // Rate limit: more than 5 failed attempts in the last 15 minutes
  const totalFailedAttempts = recentDocs.reduce(
    (sum, d) => sum + (d.data().failedAttempts || 0),
    0
  );
  if (totalFailedAttempts > 5) {
    return { success: false, error: "too-many-attempts" };
  }

  // Find matching OTP among recent docs
  const matchingDoc = recentDocs.find((d) => d.data().code === code);

  if (!matchingDoc) {
    // Wrong code — increment failedAttempts on the most recent OTP doc
    // for this email so repeated bad guesses accumulate.
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

  // Atomically check expiration / used state and mark the OTP as used.
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

  // Get nomeGuerra from authorized_emails
  const authorizedSnapshot = await db
    .collection("authorized_emails")
    .where("email", "==", email)
    .limit(1)
    .get();

  const nomeGuerra = authorizedSnapshot.empty
    ? ""
    : authorizedSnapshot.docs[0].data().nomeGuerra || "";

  // Create or get Firebase Auth user
  let user;
  try {
    user = await admin.auth().getUserByEmail(email);
    // Update displayName if different
    if (user.displayName !== nomeGuerra && nomeGuerra) {
      await admin.auth().updateUser(user.uid, { displayName: nomeGuerra });
    }
  } catch (err) {
    if (err.code === "auth/user-not-found") {
      user = await admin.auth().createUser({
        email: email,
        displayName: nomeGuerra,
      });
    } else {
      throw new functions.https.HttpsError("internal", "Error creating user.");
    }
  }

  // Create/update usuarios document so home screen can find nomeGuerra
  await db.collection("usuarios").doc(user.uid).set({
    nomeGuerra: nomeGuerra,
    email: email,
  }, { merge: true });

  // Generate custom token
  const token = await admin.auth().createCustomToken(user.uid);

  return { success: true, token: token };
});

// ---------------------------------------------------------------------------
// ON NEW RECORD — Notify all pilots when a new depth record is created
// ---------------------------------------------------------------------------
exports.onNewRecord = functions.firestore
  .document("locais/{locationId}/registros/{registroId}")
  .onCreate(async (snap, context) => {
    const record = snap.data();
    const { locationId } = context.params;

    // Rate limiting: skip records without a valid pilotId (seed/batch operations)
    if (!record.pilotId) {
      console.log("Skipping notification — no pilotId (likely seed/batch).");
      return;
    }

    // Skip notifications for test account
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

    // Read record data
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

    // Read location name
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

exports.recalcularTodasAsMedias = functions.https.onRequest(
  async (req, res) => {
    const providedKey =
      req.get("x-admin-api-key") || req.get("x-api-key") || "";
    const expectedKey = process.env.ADMIN_API_KEY || "";
    if (!expectedKey || providedKey !== expectedKey) {
      res.status(401).send("Unauthorized");
      return;
    }

    try {
      const naviosSnapshot = await db.collection("navios").get();

      for (const navioDoc of naviosSnapshot.docs) {
        const avaliacoesSnapshot = await navioDoc.ref
          .collection("avaliacoes")
          .get();

        if (avaliacoesSnapshot.empty) {
          await navioDoc.ref.update({ medias: {} });
          continue;
        }

        const soma = {};
        const contagem = {};

        avaliacoesSnapshot.docs.forEach((doc) => {
          const data = doc.data();
          const itens = data.itens || {};

          Object.entries(itens).forEach(([chave, valor]) => {
            const keyPadrao = MAPA_CHAVES[chave];
            const nota = valor?.nota;

            if (keyPadrao && typeof nota === "number") {
              soma[keyPadrao] = (soma[keyPadrao] || 0) + nota;
              contagem[keyPadrao] = (contagem[keyPadrao] || 0) + 1;
            }
          });
        });

        const medias = {};
        Object.keys(soma).forEach((chave) => {
          medias[chave] = Number(
            (soma[chave] / contagem[chave]).toFixed(2)
          );
        });

        await navioDoc.ref.update({ medias });
      }

      res.status(200).send("Médias recalculadas com sucesso");
    } catch (err) {
      console.error(err);
      res.status(500).send("Erro ao recalcular médias");
    }
  }
);
