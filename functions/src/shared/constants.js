const TEST_EMAILS = ["gcbrgame@gmail.com", "spaulomassao@gmail.com"];
const CSPAM_UID = "vvmd4t7NHgYEiRbE3aPPcyGscdq1";
const CRUZAMENTOS_COLLECTION = "cruzamentos";
const RESTRICTED_MODULE_EMAILS = [
  "plantao@nortepilot.com.br",
  "operacional@adjservicos.com.br",
];
const RESTRICTED_MODULE_EMAIL_DOMAINS = ["@cspam.com.br"];

function isRestrictedModuleUser({ email = "", uid = "" } = {}) {
  const normalizedEmail = String(email || "").trim().toLowerCase();
  return uid === CSPAM_UID ||
    RESTRICTED_MODULE_EMAILS.includes(normalizedEmail) ||
    RESTRICTED_MODULE_EMAIL_DOMAINS.some((domain) =>
      normalizedEmail.endsWith(domain));
}

module.exports = {
  TEST_EMAILS,
  CSPAM_UID,
  CRUZAMENTOS_COLLECTION,
  RESTRICTED_MODULE_EMAILS,
  RESTRICTED_MODULE_EMAIL_DOMAINS,
  isRestrictedModuleUser,
};
