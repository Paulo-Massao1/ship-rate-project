const crypto = require("crypto");
const functions = require("firebase-functions");
const { admin } = require("../shared/firestore");

const MAX_IMAGES_PER_RECORD = 3;
const MAX_IMAGE_SIZE_BYTES = 20 * 1024 * 1024;
const UPLOAD_URL_TTL_MS = 15 * 60 * 1000;
const SUPPORTED_CONTENT_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
]);

function normalizeContentType(contentType) {
  const value = String(contentType || "").trim().toLowerCase();

  switch (value) {
    case "image/jpg":
    case "image/jpeg":
    case "image/pjpeg":
      return "image/jpeg";
    case "image/x-png":
    case "image/png":
      return "image/png";
    case "image/webp":
      return "image/webp";
    default:
      return value;
  }
}

function extensionForContentType(contentType) {
  switch (contentType) {
    case "image/png":
      return "png";
    case "image/webp":
      return "webp";
    case "image/jpeg":
    default:
      return "jpg";
  }
}

function assertSignedIn(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be signed in."
    );
  }
}

function assertValidLocationAndRecordIds(locationId, recordId) {
  if (
    typeof locationId !== "string" ||
    typeof recordId !== "string" ||
    locationId.trim().length === 0 ||
    recordId.trim().length === 0
  ) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "locationId and recordId are required."
    );
  }
}

function assertSupportedImage(contentType, sizeInBytes) {
  if (!SUPPORTED_CONTENT_TYPES.has(contentType)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Unsupported image format. Use JPEG, PNG, or WEBP."
    );
  }

  if (
    typeof sizeInBytes !== "number" ||
    !Number.isFinite(sizeInBytes) ||
    sizeInBytes <= 0 ||
    sizeInBytes > MAX_IMAGE_SIZE_BYTES
  ) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Each image must be greater than 0 bytes and at most 20 MB."
    );
  }
}

function ensureManagedRecordPath(path) {
  const normalized = String(path || "").trim();

  if (!/^registros\/[^/]+\/[^/]+\/[^/]+$/.test(normalized)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid storage path."
    );
  }

  return normalized;
}

function extractStoragePath(value) {
  const input = String(value || "").trim();
  if (!input) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Image path or URL is required."
    );
  }

  if (input.startsWith("registros/")) {
    return ensureManagedRecordPath(input);
  }

  if (input.startsWith("gs://")) {
    const withoutScheme = input.slice("gs://".length);
    const slashIndex = withoutScheme.indexOf("/");
    if (slashIndex < 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid gs:// image path."
      );
    }

    return ensureManagedRecordPath(withoutScheme.slice(slashIndex + 1));
  }

  try {
    const url = new URL(input);
    const objectMatch = url.pathname.match(/\/o\/(.+)$/);
    if (objectMatch) {
      return ensureManagedRecordPath(decodeURIComponent(objectMatch[1]));
    }
  } catch (_) {
    // Handled below.
  }

  throw new functions.https.HttpsError(
    "invalid-argument",
    "Unsupported image URL."
  );
}

function buildFirebaseDownloadUrl(bucketName, path, token) {
  return (
    `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/` +
    `${encodeURIComponent(path)}?alt=media&token=${token}`
  );
}

exports.createNavSafetyImageUploadUrls = functions.https.onCall(
  async (data, context) => {
    assertSignedIn(context);

    const locationId = String(data?.locationId || "").trim();
    const recordId = String(data?.recordId || "").trim();
    const files = Array.isArray(data?.files) ? data.files : [];

    assertValidLocationAndRecordIds(locationId, recordId);

    if (files.length === 0 || files.length > MAX_IMAGES_PER_RECORD) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `files must contain between 1 and ${MAX_IMAGES_PER_RECORD} entries.`
      );
    }

    const bucket = admin.storage().bucket();
    const bucketName = bucket.name;
    const timestamp = Date.now();

    const uploads = await Promise.all(
      files.map(async (rawFile, index) => {
        const contentType = normalizeContentType(rawFile?.contentType);
        const sizeInBytes = Number(rawFile?.sizeInBytes);
        assertSupportedImage(contentType, sizeInBytes);

        const extension = extensionForContentType(contentType);
        const path = `registros/${locationId}/${recordId}/${timestamp}_${index}.${extension}`;
        const file = bucket.file(path);

        const [uploadUrl] = await file.getSignedUrl({
          version: "v4",
          action: "write",
          expires: Date.now() + UPLOAD_URL_TTL_MS,
          contentType,
        });

        return {
          path,
          contentType,
          uploadUrl,
          uploadHeaders: {
            "Content-Type": contentType,
          },
        };
      })
    );

    return { uploads };
  }
);

exports.finalizeNavSafetyImages = functions.https.onCall(async (data, context) => {
  assertSignedIn(context);

  const paths = Array.isArray(data?.paths) ? data.paths : [];
  if (paths.length === 0 || paths.length > MAX_IMAGES_PER_RECORD) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `paths must contain between 1 and ${MAX_IMAGES_PER_RECORD} entries.`
    );
  }

  const uniquePaths = [...new Set(paths.map(ensureManagedRecordPath))];
  const bucket = admin.storage().bucket();
  const bucketName = bucket.name;

  const uploads = await Promise.all(
    uniquePaths.map(async (path) => {
      const file = bucket.file(path);
      const [exists] = await file.exists();

      if (!exists) {
        throw new functions.https.HttpsError(
          "not-found",
          `Uploaded image not found for path ${path}.`
        );
      }

      const downloadToken = crypto.randomUUID();
      await file.setMetadata({
        metadata: {
          firebaseStorageDownloadTokens: downloadToken,
        },
      });

      return {
        path,
        downloadUrl: buildFirebaseDownloadUrl(bucketName, path, downloadToken),
      };
    })
  );

  return { uploads };
});

exports.deleteNavSafetyImages = functions.https.onCall(async (data, context) => {
  assertSignedIn(context);

  const inputs = Array.isArray(data?.pathsOrUrls) ? data.pathsOrUrls : [];
  if (inputs.length === 0) {
    return { deletedCount: 0 };
  }

  const uniquePaths = [...new Set(inputs.map(extractStoragePath))];
  const bucket = admin.storage().bucket();

  const results = await Promise.allSettled(
    uniquePaths.map((path) =>
      bucket.file(path).delete({ ignoreNotFound: true })
    )
  );

  const failures = results.filter((result) => result.status === "rejected");
  if (failures.length > 0) {
    failures.forEach((failure) => {
      console.error("deleteNavSafetyImages failure:", failure.reason);
    });

    throw new functions.https.HttpsError(
      "internal",
      `Failed to delete ${failures.length} image(s).`
    );
  }

  return { deletedCount: uniquePaths.length };
});
