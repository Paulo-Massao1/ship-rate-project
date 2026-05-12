const { sendOTP } = require("./auth/send_otp");
const { verifyOTP } = require("./auth/verify_otp");
const { checkWhitelist } = require("./auth/check_whitelist");
const { sendPasswordReset } = require("./auth/send_password_reset");
const {
  recalcularMediasAoExcluirAvaliacao,
  recalcularTodasAsMedias,
} = require("./ratings/recalculate_averages");
const { onNewRecord } = require("./navigation_safety/on_new_record");
const { onRecordDeleted } = require("./navigation_safety/on_record_deleted");
const {
  createNavSafetyImageUploadUrls,
  finalizeNavSafetyImages,
  deleteNavSafetyImages,
} = require("./navigation_safety/image_uploads");

exports.sendOTP = sendOTP;
exports.verifyOTP = verifyOTP;
exports.checkWhitelist = checkWhitelist;
exports.recalcularMediasAoExcluirAvaliacao = recalcularMediasAoExcluirAvaliacao;
exports.recalcularTodasAsMedias = recalcularTodasAsMedias;
exports.onNewRecord = onNewRecord;
exports.onRecordDeleted = onRecordDeleted;
exports.createNavSafetyImageUploadUrls = createNavSafetyImageUploadUrls;
exports.finalizeNavSafetyImages = finalizeNavSafetyImages;
exports.deleteNavSafetyImages = deleteNavSafetyImages;
exports.sendPasswordReset = sendPasswordReset;
