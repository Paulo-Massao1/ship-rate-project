const TEST_EMAILS = ["gcbrgame@gmail.com", "spaulomassao@gmail.com"];
const USER_COUNT_EXCLUDED_EMAILS = [
  ...TEST_EMAILS,
  "testerapptores@gmail.com",
];
const CSPAM_UID = "vvmd4t7NHgYEiRbE3aPPcyGscdq1";
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

module.exports = {
  TEST_EMAILS,
  USER_COUNT_EXCLUDED_EMAILS,
  CSPAM_UID,
  CRUZAMENTOS_COLLECTION,
  RESTRICTED_MODULE_UIDS,
  RESTRICTED_MODULE_EMAILS,
  RESTRICTED_MODULE_EMAIL_DOMAINS,
  isRestrictedModuleUser,
};
