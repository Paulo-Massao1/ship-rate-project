const { sendOTP } = require("./auth/send_otp");
const { verifyOTP } = require("./auth/verify_otp");
const {
  recalcularMediasAoExcluirAvaliacao,
  recalcularTodasAsMedias,
} = require("./ratings/recalculate_averages");
const { onNewRecord } = require("./navigation_safety/on_new_record");

exports.sendOTP = sendOTP;
exports.verifyOTP = verifyOTP;
exports.recalcularMediasAoExcluirAvaliacao = recalcularMediasAoExcluirAvaliacao;
exports.recalcularTodasAsMedias = recalcularTodasAsMedias;
exports.onNewRecord = onNewRecord;
