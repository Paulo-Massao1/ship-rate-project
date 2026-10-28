const TEST_EMAILS = [
  "gcbrgame@gmail.com",
  "spaulomassao@gmail.com",
  "shipratesuporte@gmail.com",
];
const TEST_UIDS = [
  "bb4dHPgpo8duX4hqRdpHFXXWVpF2",
  "gcmL4ngjAbblC2LwfDUzSbpPTTH2",
  "3Ta7Sfha0qM3peSTsR0qFbCd65g1",
  "3tXrdYuTfgQsQgzvqbluyh0u7Xz2",
];
const USER_COUNT_EXCLUDED_EMAILS = [
  ...TEST_EMAILS,
  "testerapptores@gmail.com",
];
const CSPAM_UID = "vvmd4t7NHgYEiRbE3aPPcyGscdq1";
const USER_COUNT_EXCLUDED_UIDS = [
  "bb4dHPgpo8duX4hqRdpHFXXWVpF2",
  "gcmL4ngjAbblC2LwfDUzSbpPTTH2",
  "3Ta7Sfha0qM3peSTsR0qFbCd65g1",
  "3tXrdYuTfgQsQgzvqbluyh0u7Xz2",
  "RckaridTpjOXQ37oY1tAXdQVoeE2",
  "upyJA8HoC9Y5LHv71654Mbt7w503",
  CSPAM_UID,
];
const CRUZAMENTOS_COLLECTION = "cruzamentos";
const RESTRICTED_MODULE_UIDS = [
  CSPAM_UID,
  "RckaridTpjOXQ37oY1tAXdQVoeE2",
  "upyJA8HoC9Y5LHv71654Mbt7w503",
  "3tXrdYuTfgQsQgzvqbluyh0u7Xz2",
];
const RESTRICTED_MODULE_EMAILS = [
  "plantao@nortepilot.com.br",
  "operacional@adjservicos.com.br",
  "jean@adjservicos.com.br",
  "testerapptores@gmail.com",
];
const RESTRICTED_MODULE_EMAIL_DOMAINS = ["@cspam.com.br"];

function isRestrictedModuleUser({ email = "", uid = "" } = {}) {
  const normalizedEmail = String(email || "").trim().toLowerCase();
  return RESTRICTED_MODULE_UIDS.includes(String(uid || "")) ||
    RESTRICTED_MODULE_EMAILS.includes(normalizedEmail) ||
    RESTRICTED_MODULE_EMAIL_DOMAINS.some((domain) =>
      normalizedEmail.endsWith(domain));
}

function isTestAccount({ email = "", uid = "" } = {}) {
  const normalizedEmail = String(email || "").trim().toLowerCase();
  return TEST_UIDS.includes(String(uid || "")) ||
    TEST_EMAILS.includes(normalizedEmail);
}

module.exports = {
  TEST_EMAILS,
  TEST_UIDS,
  USER_COUNT_EXCLUDED_EMAILS,
  USER_COUNT_EXCLUDED_UIDS,
  CSPAM_UID,
  CRUZAMENTOS_COLLECTION,
  RESTRICTED_MODULE_UIDS,
  RESTRICTED_MODULE_EMAILS,
  RESTRICTED_MODULE_EMAIL_DOMAINS,
  isRestrictedModuleUser,
  isTestAccount,
};
