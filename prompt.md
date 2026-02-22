Create a Dart script to backup all Firestore data:

File: lib/scripts/backup_firestore.dart

Requirements:
1. Read ALL documents from 'navios' collection
2. For each ship, read ALL documents from its 'avaliacoes' subcollection
3. Save everything to a JSON file: backup_YYYYMMDD_HHMMSS.json
4. Include document IDs in the backup
5. Print summary: total ships, total ratings, file path

Structure:
{
  "timestamp": "2024-02-20T10:30:00",
  "ships": [
    {
      "id": "doc_id",
      "data": { "nome": "...", "imo": "...", ... },
      "avaliacoes": [
        { "id": "rating_id", "data": { ... } }
      ]
    }
  ]
}

This is READ-ONLY, does not modify any data.
Make it runnable with: dart run lib/scripts/backup_firestore.dart