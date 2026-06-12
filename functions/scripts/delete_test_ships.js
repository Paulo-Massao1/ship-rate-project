const admin = require('firebase-admin');
const sa = require('../serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

async function deleteTestShips() {
  const naviosRef = db.collection('navios');
  const snapshot = await naviosRef.get();

  for (const doc of snapshot.docs) {
    const name = (doc.data().nome || '').toUpperCase();
    if (name.startsWith('TESTE') || name.startsWith('TEST')) {
      console.log(`Deleting ship: ${doc.data().nome} (${doc.id})`);

      // Delete avaliacoes subcollection and their likes
      const avaliacoes = await doc.ref.collection('avaliacoes').get();
      for (const aval of avaliacoes.docs) {
        const likes = await aval.ref.collection('likes').get();
        for (const like of likes.docs) {
          await like.ref.delete();
        }
        await aval.ref.delete();
      }

      // Delete the ship document
      await doc.ref.delete();
      console.log(`Deleted: ${doc.data().nome}`);
    }
  }
  console.log('Done.');
  process.exit(0);
}

deleteTestShips().catch(e => { console.error(e); process.exit(1); });
