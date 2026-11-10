import 'package:flutter/foundation.dart';
import 'package:mdeps_flutter/pm/domain/profile_models.dart';

/// In-memory replacement of the DataStore `DataStoreProfileRepository`.
class InMemoryProfileRepository extends ChangeNotifier implements ProfileRepository {
  ProfileOperationalPrefs _prefs = ProfileOperationalPrefs();

  @override
  ProfileOperationalPrefs get operationalPrefs => _prefs;

  @override
  Future<void> saveOperationalPrefs(ProfileOperationalPrefs prefs) async {
    _prefs = prefs;
    notifyListeners();
  }
}
