const functions = require("firebase-functions");
const { auth } = require("../shared/auth");
const { transporter, smtpEmail } = require("../shared/mailer");

exports.sendPasswordReset = functions.https.onCall(async (data) => {
  const email = (data.email || "").toLowerCase().trim();

  if (!email) {
    throw new functions.https.HttpsError("invalid-argument", "Email is required.");
  }

  try {
    const link = await auth.generatePasswordResetLink(email, {
      url: "https://shiprate-daf18.web.app/",
    });

    const resetUrl = link.replace(
      "https://shiprate-daf18.firebaseapp.com/__/auth/action",
      "https://shiprate-daf18.web.app/reset-password",
    );

    const mailOptions = {
      from: `"ShipRate" <${smtpEmail}>`,
      to: email,
      subject: "Redefinição de Senha – ShipRate",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; background: #0a1628; border-radius: 12px;">
          <h2 style="color: #64b5f6; text-align: center; margin-bottom: 8px;">ShipRate</h2>
          <p style="color: #ffffff; text-align: center; font-size: 16px;">Olá, Prático.</p>
          <p style="color: rgba(255,255,255,0.8); text-align: center; font-size: 14px;">Recebemos uma solicitação para redefinir a senha da sua conta no ShipRate.</p>
          <div style="text-align: center; margin: 24px 0;">
            <a href="${resetUrl}" style="display: inline-block; background: #1565c0; color: #ffffff; text-decoration: none; padding: 14px 32px; border-radius: 8px; font-size: 16px; font-weight: bold;">Redefinir Senha</a>
          </div>
          <p style="color: rgba(255,255,255,0.6); text-align: center; font-size: 13px;">Se o botão não funcionar, copie e cole este link no navegador:</p>
          <p style="color: #64b5f6; text-align: center; font-size: 13px; word-break: break-all;">${resetUrl}</p>
          <p style="color: rgba(255,255,255,0.5); text-align: center; font-size: 13px; margin-top: 24px;">Se você não solicitou esta redefinição, ignore esta mensagem.</p>
          <p style="color: rgba(255,255,255,0.6); text-align: center; font-size: 14px; margin-top: 16px;">Atenciosamente,<br/>Equipe ShipRate</p>
          <p style="color: rgba(255,255,255,0.3); text-align: center; font-size: 11px; margin-top: 24px;">Esta é uma mensagem automática, por favor não responda.</p>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);

    return { success: true };
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      return { success: true };
    }
    throw new functions.https.HttpsError("internal", "Erro ao enviar e-mail de redefinição.");
  }
});
