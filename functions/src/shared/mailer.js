const nodemailer = require("nodemailer");

const smtpEmail = process.env.SMTP_EMAIL;
const smtpPassword = process.env.SMTP_PASSWORD;

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: smtpEmail,
    pass: smtpPassword,
  },
});

module.exports = { transporter, smtpEmail };
