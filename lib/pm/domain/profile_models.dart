import 'package:flutter/foundation.dart';

enum ProfileDigestFrequency { daily, weekly }

enum ProfileMethodology { hybrid, waterfall }

@immutable
class ProfileWorkspacePrefs {
  const ProfileWorkspacePrefs({
    this.organization = 'Enterprise Solutions Global',
    this.location = 'Madrid HQ',
    this.floorLabel = 'Floor 14',
  });

  final String organization;
  final String location;
  final String floorLabel;
}

@immutable
class ProfileOperationalPrefs {
  ProfileOperationalPrefs({
    this.timezoneKey = 'utc_plus_1',
    this.methodology = ProfileMethodology.hybrid,
    this.digest = ProfileDigestFrequency.daily,
    this.darkStudioTheme = false,
    this.workspace = const ProfileWorkspacePrefs(),
    DateTime? passwordLastUpdatedAt,
  }) : passwordLastUpdatedAt = passwordLastUpdatedAt ?? DateTime.now().subtract(const Duration(days: 42));

  final String timezoneKey;
  final ProfileMethodology methodology;
  final ProfileDigestFrequency digest;
  final bool darkStudioTheme;
  final ProfileWorkspacePrefs workspace;
  final DateTime passwordLastUpdatedAt;

  ProfileOperationalPrefs copyWith({
    String? timezoneKey,
    ProfileMethodology? methodology,
    ProfileDigestFrequency? digest,
    bool? darkStudioTheme,
  }) {
    return ProfileOperationalPrefs(
      timezoneKey: timezoneKey ?? this.timezoneKey,
      methodology: methodology ?? this.methodology,
      digest: digest ?? this.digest,
      darkStudioTheme: darkStudioTheme ?? this.darkStudioTheme,
      workspace: workspace,
      passwordLastUpdatedAt: passwordLastUpdatedAt,
    );
  }
}

/// Port to the profile preferences store.
abstract class ProfileRepository implements Listenable {
  ProfileOperationalPrefs get operationalPrefs;

  Future<void> saveOperationalPrefs(ProfileOperationalPrefs prefs);
}
