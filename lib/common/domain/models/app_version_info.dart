import 'package:equatable/equatable.dart';

/// Remote app version configuration.
class AppVersionInfo extends Equatable {
  const AppVersionInfo({
    required this.minimumVersionCode,
    required this.latestVersionCode,
    required this.forceUpdate,
    this.updateUrl,
    this.releaseNotes,
  });

  final int minimumVersionCode;
  final int latestVersionCode;
  final bool forceUpdate;
  final String? updateUrl;
  final String? releaseNotes;

  bool requiresUpdate(int currentVersionCode) {
    return currentVersionCode < minimumVersionCode || forceUpdate;
  }

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      minimumVersionCode: json['minimum_version_code'] as int? ?? 1,
      latestVersionCode: json['latest_version_code'] as int? ?? 1,
      forceUpdate: json['force_update'] as bool? ?? false,
      updateUrl: json['update_url'] as String?,
      releaseNotes: json['release_notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        minimumVersionCode,
        latestVersionCode,
        forceUpdate,
        updateUrl,
        releaseNotes,
      ];
}
