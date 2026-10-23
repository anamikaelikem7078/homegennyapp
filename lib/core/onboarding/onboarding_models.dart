/// What `GET /me/onboarding` tells the app to show next.
enum OnboardingNextStep {
  completeProfile('COMPLETE_PROFILE'),
  waitForRm('WAIT_FOR_RM'),
  verification('VERIFICATION'),
  ready('READY');

  const OnboardingNextStep(this.value);
  final String value;

  static OnboardingNextStep fromString(String? raw) => OnboardingNextStep.values.firstWhere(
        (s) => s.value == raw?.toUpperCase(),
        orElse: () => OnboardingNextStep.ready,
      );
}

class OnboardingRm {
  const OnboardingRm({required this.name, required this.phone});

  final String name;
  final String phone;

  static OnboardingRm? fromJson(dynamic json) {
    if (json is! Map) return null;
    final name = (json['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) return null;
    return OnboardingRm(name: name, phone: (json['phone'] as String?)?.trim() ?? '');
  }
}

/// `GET /me/onboarding` — also the tail of `POST /staff/profile/submit`.
class OnboardingStatus {
  const OnboardingStatus({
    required this.role,
    required this.profileComplete,
    required this.missing,
    required this.nextStep,
    this.pipelineStage,
    this.rm,
  });

  /// Used when there is nothing to gate (dummy mode, no session).
  static const ready = OnboardingStatus(
    role: '',
    profileComplete: true,
    missing: [],
    nextStep: OnboardingNextStep.ready,
  );

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) {
    final complete = json['profile_complete'] as bool? ?? true;
    return OnboardingStatus(
      role: json['role'] as String? ?? '',
      profileComplete: complete,
      missing: ((json['missing'] ?? json['profile_missing']) as List?)?.map((e) => e.toString()).toList() ??
          const [],
      nextStep: json['next_step'] == null
          ? (complete ? OnboardingNextStep.ready : OnboardingNextStep.completeProfile)
          : OnboardingNextStep.fromString(json['next_step'] as String?),
      pipelineStage: json['pipeline_stage'] as String?,
      rm: OnboardingRm.fromJson(json['rm']),
    );
  }

  final String role;
  final bool profileComplete;
  final List<String> missing;
  final OnboardingNextStep nextStep;
  final String? pipelineStage;
  final OnboardingRm? rm;

  bool get isLocked => !profileComplete;
}

/// One entry of `GET /meta/cities`.
class CityOption {
  const CityOption({required this.city, required this.areas});

  factory CityOption.fromJson(Map<String, dynamic> json) => CityOption(
        city: json['city'] as String? ?? '',
        areas: ((json['areas'] as List?) ?? const []).map((e) => e.toString()).toList(),
      );

  final String city;
  final List<String> areas;

  /// "Other" is allowed, but no RM is assigned automatically.
  bool get isOther => city.toLowerCase() == 'other';
}
