const crypto = require("crypto");
const functions = require("firebase-functions");
const { admin } = require("../shared/firestore");

const MAX_MEDIA_PER_SECTION = 3;
const MAX_MEDIA_SIZE_BYTES = 20 * 1024 * 1024;
const UPLOAD_URL_TTL_MS = 15 * 60 * 1000;
const ALLOWED_SECTIONS = new Set(["approach", "mooring"]);
const EXTENSION_BY_CONTENT_TYPE = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
  "video/mp4": "mp4",
  "video/quicktime": "mov",
};

function assertSignedIn(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be signed in."
    );
  }
}

function normalizeContentType(value) {
  const contentType = String(value || "").trim().toLowerCase();
  if (["image/jpg", "image/pjpeg"].includes(contentType)) {
    return "image/jpeg";
  }
  if (contentType === "image/x-png") return "image/png";
  return contentType;
}

function assertValidId(value, name) {
  if (
    typeof value !== "string" ||
    !/^[A-Za-z0-9_-]{1,128}$/.test(value)
  ) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${name} is invalid.`
    );
  }
}

function assertValidSection(section) {
  if (!ALLOWED_SECTIONS.has(section)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "section must be approach or mooring."
    );
  }
}

function assertValidMediaFile(rawFile) {
  const contentType = normalizeContentType(rawFile?.contentType);
  const sizeInBytes = Number(rawFile?.sizeInBytes);

  if (!Object.hasOwn(EXTENSION_BY_CONTENT_TYPE, contentType)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Unsupported maneuver media type."
    );
  }
  if (
    !Number.isInteger(sizeInBytes) ||
    sizeInBytes <= 0 ||
    sizeInBytes > MAX_MEDIA_SIZE_BYTES
  ) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Maneuver media must be greater than 0 bytes and at most 20 MB."
    );
  }

  return { contentType, sizeInBytes };
}

function buildPath({ uid, reportId, section, fileName }) {
  return `manobras/${uid}/${reportId}/${section}/${fileName}`;
}

function assertOwnedPath(path, uid) {
  const normalized = String(path || "").trim();
  const escapedUid = uid.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const pattern = new RegExp(
    `^manobras/${escapedUid}/[A-Za-z0-9_-]{1,128}/` +
      "(approach|mooring)/[A-Za-z0-9._-]+$"
  );

  if (!pattern.test(normalized)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "The media path does not belong to the signed-in user."
    );
  }
  return normalized;
}

function buildDownloadUrl(bucketName, path, token) {
  return (
    `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/` +
    `${encodeURIComponent(path)}?alt=media&token=${token}`
  );
}

exports.createManeuverMediaUploadUrls = functions.https.onCall(
  async (data, context) => {
    assertSignedIn(context);

    const reportId = String(data?.reportId || "").trim();
    const section = String(data?.section || "").trim();
    const files = Array.isArray(data?.files) ? data.files : [];

    assertValidId(reportId, "reportId");
    assertValidSection(section);
    if (files.length === 0 || files.length > MAX_MEDIA_PER_SECTION) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `files must contain between 1 and ${MAX_MEDIA_PER_SECTION} entries.`
      );
    }

    const uid = context.auth.uid;
    const bucket = admin.storage().bucket();
    const timestamp = Date.now();
    const uploads = await Promise.all(
      files.map(async (rawFile, index) => {
        const { contentType } = assertValidMediaFile(rawFile);
        const extension = EXTENSION_BY_CONTENT_TYPE[contentType];
        const randomSuffix = crypto.randomBytes(6).toString("hex");
        const fileName = `${timestamp}_${index}_${randomSuffix}.${extension}`;
        const path = buildPath({ uid, reportId, section, fileName });
        const [uploadUrl] = await bucket.file(path).getSignedUrl({
          version: "v4",
          action: "write",
          expires: Date.now() + UPLOAD_URL_TTL_MS,
          contentType,
        });

        return {
          path,
          contentType,
          uploadUrl,
          uploadHeaders: { "Content-Type": contentType },
        };
      })
    );

    return { uploads };
  }
);

exports.finalizeManeuverMedia = functions.https.onCall(
  async (data, context) => {
    assertSignedIn(context);

    const paths = Array.isArray(data?.paths) ? data.paths : [];
    if (paths.length === 0 || paths.length > MAX_MEDIA_PER_SECTION) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `paths must contain between 1 and ${MAX_MEDIA_PER_SECTION} entries.`
      );
    }

    const uniquePaths = [
      ...new Set(paths.map((path) => assertOwnedPath(path, context.auth.uid))),
    ];
    const bucket = admin.storage().bucket();
    const bucketName = bucket.name;
    const uploads = await Promise.all(
      uniquePaths.map(async (path) => {
        const file = bucket.file(path);
        const [metadata] = await file.getMetadata().catch(() => {
          throw new functions.https.HttpsError(
            "not-found",
            "Uploaded maneuver media was not found."
          );
        });
        assertValidMediaFile({
          contentType: metadata.contentType,
          sizeInBytes: Number(metadata.size),
        });

        const downloadToken = crypto.randomUUID();
        await file.setMetadata({
          metadata: { firebaseStorageDownloadTokens: downloadToken },
        });

        return {
          path,
          downloadUrl: buildDownloadUrl(bucketName, path, downloadToken),
        };
      })
    );

    return { uploads };
  }
);

exports.deleteManeuverMedia = functions.https.onCall(
  async (data, context) => {
    assertSignedIn(context);

    const paths = Array.isArray(data?.paths) ? data.paths : [];
    if (paths.length === 0) return { deletedCount: 0 };
    if (paths.length > MAX_MEDIA_PER_SECTION * 2) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Too many maneuver media paths."
      );
    }

    const uniquePaths = [
      ...new Set(paths.map((path) => assertOwnedPath(path, context.auth.uid))),
    ];
    const bucket = admin.storage().bucket();
    await Promise.all(
      uniquePaths.map((path) =>
        bucket.file(path).delete({ ignoreNotFound: true })
      )
    );
    return { deletedCount: uniquePaths.length };
  }
);
