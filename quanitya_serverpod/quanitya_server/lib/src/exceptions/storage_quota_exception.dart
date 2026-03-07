/// Thrown when a sync write would exceed the account's storage quota.
///
/// Only new inserts are gated — updates and deletes are always allowed.
class StorageQuotaExceededException implements Exception {
  final int accountId;

  const StorageQuotaExceededException({required this.accountId});

  String get message => 'Storage quota exceeded for account $accountId';

  @override
  String toString() => 'StorageQuotaExceededException: $message';
}
