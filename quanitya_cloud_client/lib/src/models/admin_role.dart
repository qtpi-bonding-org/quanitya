/// Role-based access control for admin operations
/// 
/// Provides type-safe role definitions with permission checks.
/// Easy to extend with new roles in the future.
enum AdminRole {
  /// Full administrative access
  /// - Can send notifications
  /// - Can grant credits
  /// - Can manage API keys
  /// - Can view all statistics
  admin,
  
  /// Support team access
  /// - Cannot send notifications
  /// - Can grant credits (for refunds)
  /// - Cannot manage API keys
  /// - Can view statistics
  support;
  
  /// Check if this role can send notifications (broadcast or individual)
  bool canSendNotifications() => this == AdminRole.admin;
  
  /// Check if this role can grant credits to users
  bool canGrantCredits() => this == AdminRole.admin || this == AdminRole.support;
  
  /// Check if this role can create/revoke API keys
  bool canManageKeys() => this == AdminRole.admin;
  
  /// Check if this role can view statistics
  bool canViewStats() => true; // All roles can view stats
  
  /// Parse role from database string
  /// 
  /// Throws [ArgumentError] if the role string is invalid
  static AdminRole fromString(String value) {
    return AdminRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => throw ArgumentError('Invalid role: $value'),
    );
  }
  
  /// Convert role to database string
  String toDbString() => name;
  
  /// Get human-readable description of role
  String get description {
    switch (this) {
      case AdminRole.admin:
        return 'Full administrative access';
      case AdminRole.support:
        return 'Support team access (limited permissions)';
    }
  }
  
  /// Get list of permissions for this role
  List<String> get permissions {
    switch (this) {
      case AdminRole.admin:
        return [
          'Send notifications',
          'Grant credits',
          'Manage API keys',
          'View statistics',
        ];
      case AdminRole.support:
        return [
          'Grant credits',
          'View statistics',
        ];
    }
  }
}
