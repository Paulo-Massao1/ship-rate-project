class AppConstants {
  AppConstants._();

  static const appUrl =
      'https://apps.apple.com/br/app/shiprate-pro/id6777518989';
  static const cspamUid = 'vvmd4t7NHgYEiRbE3aPPcyGscdq1';
  static const andreiUid =
      'Z8UTPteGM1Y6H2rqsAmCiFtJrNC2'; // andreibrilhante@gmail.com
  static const appReviewUid = '3Ta7Sfha0qM3peSTsR0qFbCd65g1';
  static const testEmails = [
    'gcbrgame@gmail.com',
    'spaulomassao@gmail.com',
    'shipratesuporte@gmail.com',
  ];

  // Authorized accounts that unlock every gated feature without a
  // subscription. UIDs avoid a runtime email lookup.
  static const List<String> devBypassUids = [
    'bb4dHPgpo8duX4hqRdpHFXXWVpF2', // spaulomassao@gmail.com
    'gcmL4ngjAbblC2LwfDUzSbpPTTH2', // gcbrgame@gmail.com
    andreiUid, // andreibrilhante@gmail.com
  ];

  // Dev, admin and CSPAM accounts excluded from every ranking (count and
  // position) and from the pilot total shown in "ShipRate em Números".
  // UIDs are used directly so no runtime email->uid lookup is needed.
  static const List<String> excludedUids = [
    'bb4dHPgpo8duX4hqRdpHFXXWVpF2', // spaulomassao@gmail.com (dev)
    'gcmL4ngjAbblC2LwfDUzSbpPTTH2', // gcbrgame@gmail.com (dev)
    'RckaridTpjOXQ37oY1tAXdQVoeE2', // operacional@adjservicos.com.br
    'upyJA8HoC9Y5LHv71654Mbt7w503', // jean@adjservicos.com.br
    'vvmd4t7NHgYEiRbE3aPPcyGscdq1', // logisticars@cspam.com.br
    appReviewUid, // shipratesuporte@gmail.com (App Review)
  ];

  // UIDs whose emails the getUserCount Cloud Function already removes. Keeping
  // this separate from dev bypass prevents App Review accounts from receiving
  // paid access and prevents the pilot total from being reduced twice.
  static const Set<String> userCountExcludedUidsByBackend = {
    'bb4dHPgpo8duX4hqRdpHFXXWVpF2', // spaulomassao@gmail.com
    'gcmL4ngjAbblC2LwfDUzSbpPTTH2', // gcbrgame@gmail.com
    appReviewUid, // shipratesuporte@gmail.com
  };

  // Excluded accounts that the backend still counts are subtracted client-side.
  static List<String> get excludedUidsCountedByBackend => excludedUids
      .where((uid) => !userCountExcludedUidsByBackend.contains(uid))
      .toList(growable: false);

  // Ranking-only adjustments applied to the depth-record count of specific
  // accounts (uid -> delta). Does not affect overall totals.
  static const depthCountAdjustmentsByUid = <String, int>{andreiUid: -2};

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
