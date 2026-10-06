const { getApps, initializeApp } = require("firebase-admin/app");
const { FieldValue, getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { getMessaging } = require("firebase-admin/messaging");
const { getStorage } = require("firebase-admin/storage");

const app = getApps()[0] || initializeApp();
const db = getFirestore(app);

// Compatibility facade for the existing functions while using the modular
// firebase-admin API required by current SDK releases.
const firestore = () => db;
firestore.FieldValue = FieldValue;

const admin = {
  auth: () => getAuth(app),
  firestore,
  messaging: () => getMessaging(app),
  storage: () => getStorage(app),
};

module.exports = { admin, db };
