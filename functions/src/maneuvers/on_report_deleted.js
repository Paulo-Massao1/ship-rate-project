const functions = require("firebase-functions");
const { admin } = require("../shared/firestore");

exports.onManeuverReportDeleted = functions.firestore
  .document("manobras_relatos/{reportId}")
  .onDelete(async (snapshot, context) => {
    const pilotId = String(snapshot.data()?.pilotId || "").trim();
    const reportId = context.params.reportId;
    if (!pilotId) {
      console.error(`Maneuver report ${reportId} has no pilotId.`);
      return;
    }

    const prefix = `manobras/${pilotId}/${reportId}/`;
    const bucket = admin.storage().bucket();
    const [files] = await bucket.getFiles({ prefix });
    if (files.length === 0) return;

    const results = await Promise.allSettled(
      files.map((file) => file.delete({ ignoreNotFound: true }))
    );
    const failures = results.filter((result) => result.status === "rejected");
    if (failures.length > 0) {
      failures.forEach((failure) => {
        console.error(`Failed to delete file under ${prefix}:`, failure.reason);
      });
      throw new Error(
        `Failed to delete ${failures.length} maneuver media file(s).`
      );
    }
  });
