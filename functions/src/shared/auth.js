const { admin } = require("./firestore");

const auth = admin.auth();

module.exports = { auth };
