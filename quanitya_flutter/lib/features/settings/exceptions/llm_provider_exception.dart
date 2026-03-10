class LlmProviderException implements Exception {
  final String message;
  final Object? cause;
  const LlmProviderException(this.message, [this.cause]);
}
