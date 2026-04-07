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

  // Generate 6-digit code
  const code = String(Math.floor(100000 + Math.random() * 900000));

  // Store OTP in Firestore
  await db.collection("otp_codes").add({
    email: email,
    code: code,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    used: false,
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

  // Find matching OTP
  const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000);

  const otpSnapshot = await db
    .collection("otp_codes")
    .where("email", "==", email)
    .where("code", "==", code)
    .where("used", "==", false)
    .orderBy("createdAt", "desc")
    .limit(1)
    .get();

  if (otpSnapshot.empty) {
    return { success: false, error: "invalid" };
  }

  const otpDoc = otpSnapshot.docs[0];
  const otpData = otpDoc.data();

  // Check expiration
  const createdAt = otpData.createdAt?.toDate();
  if (!createdAt || createdAt < tenMinutesAgo) {
    return { success: false, error: "expired" };
  }

  // Mark as used
  await otpDoc.ref.update({ used: true });

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

  // Generate custom token
  const token = await admin.auth().createCustomToken(user.uid);

  return { success: true, token: token };
});

exports.recalcularTodasAsMedias = functions.https.onRequest(
  async (req, res) => {
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
