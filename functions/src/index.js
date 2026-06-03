const { sendOTP } = require("./auth/send_otp");
const { verifyOTP } = require("./auth/verify_otp");
const { checkWhitelist } = require("./auth/check_whitelist");
const { sendPasswordReset } = require("./auth/send_password_reset");
const {
  recalcularMediasAoExcluirAvaliacao,
  recalcularTodasAsMedias,
} = require("./ratings/recalculate_averages");
const {
  onRatingLikeCreated,
  onRatingLikeDeleted,
} = require("./ratings/on_rating_like");
const { onNewRecord } = require("./navigation_safety/on_new_record");
const { onRecordDeleted } = require("./navigation_safety/on_record_deleted");
const {
  createNavSafetyImageUploadUrls,
  finalizeNavSafetyImages,
  deleteNavSafetyImages,
} = require("./navigation_safety/image_uploads");
const { getUserCount } = require("./stats/get_user_count");
const { onLikeCreated, onLikeDeleted } = require("./navigation_safety/on_like");
const { inactivityReminder } = require("./notifications/inactivity_reminder");
const { onCrossingCreated } = require("./crossings/on_crossing_created");
const { cleanupCrossings } = require("./crossings/cleanup_crossings");

exports.sendOTP = sendOTP;
exports.verifyOTP = verifyOTP;
exports.checkWhitelist = checkWhitelist;
exports.recalcularMediasAoExcluirAvaliacao = recalcularMediasAoExcluirAvaliacao;
exports.recalcularTodasAsMedias = recalcularTodasAsMedias;
exports.onRatingLikeCreated = onRatingLikeCreated;
exports.onRatingLikeDeleted = onRatingLikeDeleted;
exports.onNewRecord = onNewRecord;
exports.onRecordDeleted = onRecordDeleted;
exports.createNavSafetyImageUploadUrls = createNavSafetyImageUploadUrls;
exports.finalizeNavSafetyImages = finalizeNavSafetyImages;
exports.deleteNavSafetyImages = deleteNavSafetyImages;
exports.sendPasswordReset = sendPasswordReset;
exports.getUserCount = getUserCount;
exports.onLikeCreated = onLikeCreated;
exports.onLikeDeleted = onLikeDeleted;
exports.inactivityReminder = inactivityReminder;
// Keep the published function names stable to avoid creating duplicate triggers.
exports.onCruzamentoCreated = onCrossingCreated;
exports.cleanupCruzamentos = cleanupCrossings;
