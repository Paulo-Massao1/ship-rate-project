const functions = require("firebase-functions");
const { admin } = require("../shared/firestore");

exports.onRecordDeleted = functions.firestore
  .document("locais/{locationId}/registros/{recordId}")
  .onDelete(async (_, context) => {
    const { locationId, recordId } = context.params;
    const prefix = `registros/${locationId}/${recordId}/`;
    const bucket = admin.storage().bucket();

    try {
      const [files] = await bucket.getFiles({ prefix });
      if (files.length === 0) {
        console.log(`No storage files found for prefix ${prefix}`);
        return;
      }

      const results = await Promise.allSettled(
        files.map((file) => file.delete({ ignoreNotFound: true }))
      );

      const failures = results.filter((result) => result.status === "rejected");
      if (failures.length > 0) {
        failures.forEach((failure) => {
          console.error(`Failed to delete file under ${prefix}:`, failure.reason);
        });
        throw new Error(
          `Storage cleanup failed for ${failures.length} file(s) under ${prefix}`
        );
      }

      console.log(`Deleted ${files.length} storage file(s) under ${prefix}`);
    } catch (err) {
      console.error(`onRecordDeleted failed for prefix ${prefix}:`, err);
      throw err;
    }
  });
