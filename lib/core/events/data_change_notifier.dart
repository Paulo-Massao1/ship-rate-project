import 'package:flutter/foundation.dart';

/// Global revision counter that increments whenever app data changes
/// (new rating, edit, delete). Widgets can listen to this to refresh.
final dataRevision = ValueNotifier<int>(0);

/// Call this after any mutation (create/edit/delete rating, etc.)
/// so that listeners (e.g. DashboardWidget) know to reload.
void notifyDataChanged() {
  dataRevision.value++;
}
