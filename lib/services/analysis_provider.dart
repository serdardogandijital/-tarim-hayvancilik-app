enum AnalysisProvider { hosted, openAi, gemini }

class AnalysisCredential {
  const AnalysisCredential(this.provider, this.key);
  final AnalysisProvider provider;
  final String key;
}

class AnalysisProviderStore {
  // Legacy API keys remain in the phone's secure storage for data preservation.
  // The app never reads or requests them after moving analysis to its backend.
  static Future<AnalysisCredential> resolve() async =>
      const AnalysisCredential(AnalysisProvider.hosted, '');
}
