import 'package:firebase_auth/firebase_auth.dart';

import 'constants.dart';

class ModuleAccess {
  ModuleAccess._();

  static const restrictedUids = <String>{
    AppConstants.cspamUid,
  };

  static const restrictedEmails = <String>{
    'plantao@nortepilot.com.br',
    'operacional@adjservicos.com.br',
  };

  static const restrictedEmailDomains = <String>[
    '@cspam.com.br',
  ];

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
