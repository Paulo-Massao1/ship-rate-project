class AppConstants {
  AppConstants._();

  static const appUrl = 'https://apps.apple.com/br/app/shiprate-pro/id6777518989';
  static const cspamUid = 'vvmd4t7NHgYEiRbE3aPPcyGscdq1';
  static const testEmails = ['gcbrgame@gmail.com', 'spaulomassao@gmail.com'];

  // Dev accounts excluded from every ranking (count and position).
  // UIDs are used directly so no runtime email->uid lookup is needed.
  static const List<String> excludedUids = [
    'bb4dHPgpo8duX4hqRdpHFXXWVpF2', // spaulomassao@gmail.com
    'gcmL4ngjAbblC2LwfDUzSbpPTTH2', // gcbrgame@gmail.com
  ];

  static const String andreiUid =
      'Z8UTPteGM1Y6H2rqsAmCiFtJrNC2'; // andreibrilhante@gmail.com

  // Ranking-only adjustments applied to the depth-record count of specific
  // accounts (uid -> delta). Does not affect overall totals.
  static const depthCountAdjustmentsByUid = <String, int>{
    andreiUid: -2,
  };

  // Firestore collections
  static const usersCollection = 'usuarios';
  static const shipsCollection = 'navios';
  static const ratingsSubcollection = 'avaliacoes';
  static const locationsCollection = 'locais';
  static const recordsSubcollection = 'registros';
  static const likesSubcollection = 'likes';
  static const cruzamentosCollection = 'cruzamentos';
  static const pilotStatsCollection = 'pilotStats';
}
