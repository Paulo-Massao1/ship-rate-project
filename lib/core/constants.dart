class AppConstants {
  AppConstants._();

  static const appUrl = 'https://apps.apple.com/br/app/shiprate-pro/id6777518989';
  static const cspamUid = 'vvmd4t7NHgYEiRbE3aPPcyGscdq1';
  static const testEmails = ['gcbrgame@gmail.com', 'spaulomassao@gmail.com'];

  // Dev accounts that unlock every gated feature without a subscription.
  // Matches [testEmails], by uid so no runtime email->uid lookup is needed.
  static const List<String> devBypassUids = [
    'bb4dHPgpo8duX4hqRdpHFXXWVpF2', // spaulomassao@gmail.com
    'gcmL4ngjAbblC2LwfDUzSbpPTTH2', // gcbrgame@gmail.com
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
  ];

  // Excluded accounts the getUserCount Cloud Function still counts: it only
  // drops [testEmails] server side, which are the [devBypassUids] accounts.
  // Only these have to be subtracted from the pilot total on the client.
  static List<String> get excludedUidsCountedByBackend => excludedUids
      .where((uid) => !devBypassUids.contains(uid))
      .toList(growable: false);

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
