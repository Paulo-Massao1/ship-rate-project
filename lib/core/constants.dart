class AppConstants {
  AppConstants._();

  static const appUrl = 'https://apps.apple.com/br/app/shiprate-pro/id6777518989';
  static const cspamUid = 'vvmd4t7NHgYEiRbE3aPPcyGscdq1';
  static const testEmails = ['gcbrgame@gmail.com', 'spaulomassao@gmail.com'];

  // Dev accounts excluded from every ranking (count and position).
  static const excludedFromRankings = [
    'spaulomassao@gmail.com',
    'gcbrgame@gmail.com',
  ];

  // Ranking-only adjustments applied to the depth-record count of specific
  // accounts (email -> delta). Does not affect overall totals.
  static const depthCountAdjustmentsByEmail = <String, int>{
    'andreibrilhante@gmail.com': -2,
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
