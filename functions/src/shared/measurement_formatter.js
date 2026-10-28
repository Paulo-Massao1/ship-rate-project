function formatMeters(value, { decimalSeparator = ",", emptyValue = "N/A" } = {}) {
  const numericValue = typeof value === "number"
    ? value
    : Number(String(value ?? "").trim().replace(",", "."));

  if (!Number.isFinite(numericValue)) return emptyValue;

  let formatted = numericValue.toFixed(2);
  if (formatted === "-0.00") formatted = "0.00";
  if (formatted.endsWith("0")) formatted = formatted.slice(0, -1);

  return `${formatted.replace(".", decimalSeparator)}m`;
}

module.exports = { formatMeters };
