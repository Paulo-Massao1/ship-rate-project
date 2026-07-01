const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const fs = require("fs");
const path = require("path");
const readline = require("readline");
const sa = require("../functions/serviceAccountKey.json");
initializeApp({ credential: cert(sa) });
const db = getFirestore();

const AUDIT_LOG_PATH = path.join(__dirname, "merge_audit_log.txt");
const auditLines = [];

function log(msg) {
  const line = `[${new Date().toISOString()}] ${msg}`;
  console.log(line);
  auditLines.push(line);
}

function saveAuditLog() {
  fs.writeFileSync(AUDIT_LOG_PATH, auditLines.join("\n") + "\n", "utf8");
  console.log(`\nAudit log saved to ${AUDIT_LOG_PATH}`);
}

const MAPA_CHAVES = {
  "Dispositivo de Embarque/Desembarque": "dispositivo",
  "Temperatura da Cabine": "temp_cabine",
  "Limpeza da Cabine": "limpeza_cabine",
  "Passadiço – Equipamentos": "passadico_equip",
  "Passadiço – Temperatura": "passadico_temp",
  "Comida": "comida",
  "Relacionamento com comandante/tripulação": "relacionamento",
};

function calcularMedias(avaliacoesDocs) {
  const soma = {};
  const contagem = {};

  avaliacoesDocs.forEach((doc) => {
    const data = doc.data();
    const itens = data.itens || {};

    Object.entries(itens).forEach(([chave, valor]) => {
      const keyPadrao = MAPA_CHAVES[chave];
      const nota = valor?.nota;

      if (keyPadrao && typeof nota === "number") {
        soma[keyPadrao] = (soma[keyPadrao] || 0) + nota;
        contagem[keyPadrao] = (contagem[keyPadrao] || 0) + 1;
      }
    });
  });

  const medias = {};
  Object.keys(soma).forEach((chave) => {
    medias[chave] = Number((soma[chave] / contagem[chave]).toFixed(2));
  });

  return medias;
}

// ── Step 1: Empty duplicates to delete ──
const STEP1_DELETES = [
  { id: "3j1tz0TradY8yUm7MBqe", name: "TUCUNARÉ" },
  { id: "4blpDgos3rCHh4Av71H4", name: "ALI M" },
  { id: "4rm2bbp7rXGKpmzaZH3d", name: "MERCOSUL FORTALEZA" },
  { id: "jOMiT5h3ZJsJf4j9Te9l", name: "LOGIN POLARIS" },
  { id: "ajRDO5dNg1Ud5aocLgNW", name: "VIVALDI" },
];

// ── Step 2: Merges (transfer ratings then delete source) ──
const STEP2_MERGES = [
  {
    label: "TELLUS",
    primaryId: "Xd4O4kMlKvhCltxIQPtl",
    sources: [{ id: "svRs41NMIYd6uFPZ1zM0", expectedRatings: 1 }],
  },
  {
    label: "LOG IN JACARANDA",
    primaryId: "0S2kcWKuxAh1lBdbOgk3",
    sources: [
      { id: "4wttGpdtKg72wpT71pLm", expectedRatings: 2 },
      { id: "fPpUeUKARIisXEf44BNy", expectedRatings: 1 },
    ],
  },
  {
    label: "LOGIN POLARIS (remaining)",
    primaryId: "AwdUQlkFDAxZulaYBO3n",
    sources: [{ id: "7erBhWIoBdALoV2XGTsa", expectedRatings: 0 }],
  },
  {
    label: "LOGIN EVOLUTION",
    primaryId: "C8RlqzLBsHa5cOKKqupf",
    sources: [{ id: "RPiwhbkPpC6R1lnfqToL", expectedRatings: 2 }],
  },
  {
    label: "ARCTOS/ARCTUS",
    primaryId: "F6HPgh1Lzud5Q7Ytj5K3",
    sources: [{ id: "L28XDgKjraMxQaVFvale", expectedRatings: 1 }],
  },
  {
    label: "ELANDRA STAR / LEANDRA STAR",
    primaryId: "LL5enHCIjZK7PWdObTbt",
    sources: [{ id: "iuW5zh9rWAy6Yi78Ojen", expectedRatings: 1 }],
  },
];

async function getRatingCount(shipId) {
  const snap = await db
    .collection("navios")
    .doc(shipId)
    .collection("avaliacoes")
    .get();
  return snap.size;
}

async function getRatingDocs(shipId) {
  return db
    .collection("navios")
    .doc(shipId)
    .collection("avaliacoes")
    .get();
}

// ── DRY RUN ──

async function dryRun() {
  log("========== DRY RUN ==========");
  log("");

  log("--- STEP 1: Delete empty exact duplicates ---");
  for (const item of STEP1_DELETES) {
    const count = await getRatingCount(item.id);
    const status = count === 0 ? "OK (0 ratings)" : `WARNING: has ${count} ratings!`;
    log(`  DELETE ${item.name} (${item.id}) — ${status}`);
    if (count !== 0) {
      log(`  *** ABORTING would be required: ${item.name} has ratings! ***`);
    }
  }
  log("");

  log("--- STEP 2: Transfer ratings and delete sources ---");
  for (const merge of STEP2_MERGES) {
    const primaryCount = await getRatingCount(merge.primaryId);
    log(`  [${merge.label}]`);
    log(`    PRIMARY: ${merge.primaryId} (${primaryCount} ratings)`);

    for (const src of merge.sources) {
      const srcCount = await getRatingCount(src.id);
      if (srcCount > 0) {
        log(
          `    SOURCE:  ${src.id} (${srcCount} ratings) → transfer to primary, then delete`
        );
      } else {
        log(`    SOURCE:  ${src.id} (0 ratings) → just delete`);
      }
    }
  }
  log("");

  log("--- STEP 3: Recalculate averages on primaries that received ratings ---");
  for (const merge of STEP2_MERGES) {
    const hasTransfer = merge.sources.some((s) => s.expectedRatings > 0);
    if (hasTransfer) {
      log(`  RECALCULATE: ${merge.label} (${merge.primaryId})`);
    }
  }
  log("");
  log("========== END DRY RUN ==========");
}

// ── EXECUTE ──

async function execute() {
  log("");
  log("========== EXECUTING ==========");
  log("");

  // ── STEP 1 ──
  log("--- STEP 1: Deleting empty exact duplicates ---");
  for (const item of STEP1_DELETES) {
    const count = await getRatingCount(item.id);
    if (count !== 0) {
      log(`  SKIPPED ${item.name} (${item.id}) — has ${count} ratings, refusing to delete`);
      continue;
    }
    await db.collection("navios").doc(item.id).delete();
    log(`  DELETED ${item.name} (${item.id})`);
  }
  log("");

  // ── STEP 2 ──
  log("--- STEP 2: Transferring ratings and deleting sources ---");
  for (const merge of STEP2_MERGES) {
    log(`  [${merge.label}]`);
    const primaryBefore = await getRatingCount(merge.primaryId);
    log(`    Primary ${merge.primaryId} has ${primaryBefore} ratings before merge`);

    for (const src of merge.sources) {
      const srcSnap = await getRatingDocs(src.id);
      const srcCount = srcSnap.size;
      log(`    Source ${src.id} has ${srcCount} ratings`);

      if (srcCount > 0) {
        // Transfer each rating in a transaction
        for (const ratingDoc of srcSnap.docs) {
          const ratingData = ratingDoc.data();
          const srcRef = ratingDoc.ref;
          const destRef = db
            .collection("navios")
            .doc(merge.primaryId)
            .collection("avaliacoes")
            .doc(ratingDoc.id);

          await db.runTransaction(async (tx) => {
            const srcCheck = await tx.get(srcRef);
            if (!srcCheck.exists) {
              log(`      Rating ${ratingDoc.id} already gone, skipping`);
              return;
            }
            tx.set(destRef, ratingData);
            tx.delete(srcRef);
          });
          log(`      Transferred rating ${ratingDoc.id} from ${src.id} → ${merge.primaryId}`);
        }
      }

      // Verify source has no ratings left before deleting
      const remainingCount = await getRatingCount(src.id);
      if (remainingCount > 0) {
        log(`    ERROR: Source ${src.id} still has ${remainingCount} ratings after transfer — NOT deleting`);
        continue;
      }
      await db.collection("navios").doc(src.id).delete();
      log(`    DELETED source ${src.id}`);
    }

    const primaryAfter = await getRatingCount(merge.primaryId);
    log(`    Primary ${merge.primaryId} now has ${primaryAfter} ratings (was ${primaryBefore})`);
    log("");
  }

  // ── STEP 3 ──
  log("--- STEP 3: Recalculating averages ---");
  const primariesToRecalc = STEP2_MERGES.filter((m) =>
    m.sources.some((s) => s.expectedRatings > 0)
  );

  for (const merge of primariesToRecalc) {
    const snap = await getRatingDocs(merge.primaryId);
    if (snap.empty) {
      log(`  ${merge.label}: No ratings found, clearing medias`);
      await db.collection("navios").doc(merge.primaryId).update({ medias: {} });
      continue;
    }

    const medias = calcularMedias(snap.docs);
    await db.collection("navios").doc(merge.primaryId).update({ medias });
    log(
      `  ${merge.label} (${merge.primaryId}): recalculated from ${snap.size} ratings → ${JSON.stringify(medias)}`
    );
  }

  log("");
  log("========== EXECUTION COMPLETE ==========");
}

// ── MAIN ──

async function main() {
  log("ShipRate — Merge Duplicate Ships");
  log(`Started at ${new Date().toISOString()}`);
  log("");

  await dryRun();

  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  const answer = await new Promise((resolve) => {
    rl.question(
      "\nDry run complete. Type YES to execute the merge: ",
      resolve
    );
  });
  rl.close();

  if (answer.trim() !== "YES") {
    log("Aborted by user.");
    saveAuditLog();
    process.exit(0);
  }

  await execute();
  saveAuditLog();
  process.exit(0);
}

main().catch((err) => {
  log(`FATAL ERROR: ${err.message}`);
  log(err.stack);
  saveAuditLog();
  process.exit(1);
});
