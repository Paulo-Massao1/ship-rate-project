import 'package:firebase_auth/firebase_auth.dart';

import 'constants.dart';

class ModuleAccess {
  ModuleAccess._();

  // Accounts limited to the ship-rating and crossing modules. Blocked by uid
  // and by email so a change on either side still keeps them restricted.
  static const restrictedUids = <String>{
    AppConstants.cspamUid,
    'RckaridTpjOXQ37oY1tAXdQVoeE2', // operacional@adjservicos.com.br
    'upyJA8HoC9Y5LHv71654Mbt7w503', // jean@adjservicos.com.br
  };

  static const restrictedEmails = <String>{
    'plantao@nortepilot.com.br',
    'operacional@adjservicos.com.br',
    'jean@adjservicos.com.br',
    'testerapptores@gmail.com',
  };

  static const restrictedEmailDomains = <String>['@cspam.com.br'];

  static bool get isCurrentUserRestricted {
    final user = FirebaseAuth.instance.currentUser;
    return isRestrictedUser(email: user?.email, uid: user?.uid);
  }

  static bool get canAccessRestrictedModules => !isCurrentUserRestricted;

  static bool isRestrictedUser({String? email, String? uid}) {
    if (uid != null && restrictedUids.contains(uid)) return true;

    final normalizedEmail = email?.trim().toLowerCase() ?? '';
    if (normalizedEmail.isEmpty) return false;

    return restrictedEmails.contains(normalizedEmail) ||
        restrictedEmailDomains.any(
          (domain) => normalizedEmail.endsWith(domain),
        );
  }
}
