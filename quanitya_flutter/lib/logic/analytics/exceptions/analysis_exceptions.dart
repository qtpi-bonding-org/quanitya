/// Exception thrown when analysis operations fail.
class AnalysisException implements Exception {
  final String message;
  final Object? cause;
  
  const AnalysisException(this.message, [this.cause]);
  
  @override
  String toString() => 'AnalysisException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}