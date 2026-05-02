const { sendOTP } = require("./auth/send_otp");
const { verifyOTP } = require("./auth/verify_otp");
const { checkWhitelist } = require("./auth/check_whitelist");
const { sendPasswordReset } = require("./auth/send_password_reset");
const {
  recalcularMediasAoExcluirAvaliacao,
  recalcularTodasAsMedias,
} = require("./ratings/recalculate_averages");
const { onNewRecord } = require("./navigation_safety/on_new_record");

exports.sendOTP = sendOTP;
exports.verifyOTP = verifyOTP;
exports.checkWhitelist = checkWhitelist;
exports.recalcularMediasAoExcluirAvaliacao = recalcularMediasAoExcluirAvaliacao;
exports.recalcularTodasAsMedias = recalcularTodasAsMedias;
exports.onNewRecord = onNewRecord;
exports.sendPasswordReset = sendPasswordReset;
