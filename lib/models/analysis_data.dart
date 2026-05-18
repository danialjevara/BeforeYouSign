enum AnalysisPreference {
  gemmaOnly,
  allowLimitedFallback,
}

class AnalysisData {
  const AnalysisData({
    required this.ocrText,
    required this.userContext,
    this.preference = AnalysisPreference.gemmaOnly,
  });

  final String ocrText;
  final String userContext;
  final AnalysisPreference preference;

  bool get allowLimitedFallback =>
      preference == AnalysisPreference.allowLimitedFallback;

  AnalysisData copyWith({
    String? ocrText,
    String? userContext,
    AnalysisPreference? preference,
  }) {
    return AnalysisData(
      ocrText: ocrText ?? this.ocrText,
      userContext: userContext ?? this.userContext,
      preference: preference ?? this.preference,
    );
  }
}
