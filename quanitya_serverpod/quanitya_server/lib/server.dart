import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

import 'src/generated/endpoints.dart';
import 'src/generated/protocol.dart';
import 'src/web/routes/root.dart';
import 'src/middleware/request_logger.dart';
import 'src/services/email_service.dart';
import 'src/future_calls/monthly_backup_future_call.dart';

export 'src/services/email_service.dart';
export 'src/services/snapshot_pipeline.dart';
export 'src/future_calls/monthly_backup_future_call.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Add request logging middleware for debugging
  pod.server.addMiddleware(RequestLoggingMiddleware.create());

  // Initialize authentication services for the server.
  // Token managers will be used to validate and issue authentication keys,
  // and the identity providers will be the authentication options available for users.
  pod.initializeAuthServices(
    tokenManagerBuilders: [
      // Use JWT for authentication keys towards the server.
      JwtConfigFromPasswords(),
    ],
    identityProviderBuilders: [
      // Configure the email identity provider for email/password authentication.
      EmailIdpConfigFromPasswords(
        sendRegistrationVerificationCode: _sendRegistrationCode,
        sendPasswordResetVerificationCode: _sendPasswordResetCode,
      ),
    ],
  );

  // Setup a default page at the web root.
  pod.webServer.addRoute(RootRoute(), '/');
  pod.webServer.addRoute(RootRoute(), '/index.html');

  // Serve static files from web/static under /static/*.
  final root = Directory(Uri(path: 'web/static').toFilePath());
  pod.webServer.addRoute(StaticRoute.directory(root), '/static/*');

  // Register background tasks
  await _registerBackgroundTasks(pod);

  // Start the server.
  await pod.start();
}

void _sendRegistrationCode(
  Session session, {
  required String email,
  required UuidValue accountRequestId,
  required String verificationCode,
  required Transaction? transaction,
}) {
  final smtp = EmailService.instance();
  if (smtp != null) {
    smtp.sendEmail(email, 'Quanitya — Verification Code', 'Your verification code is: $verificationCode');
  }
  // Always log so self-hosters without SMTP can still read the code.
  session.log('[EmailIdp] Registration code ($email): $verificationCode');
}

void _sendPasswordResetCode(
  Session session, {
  required String email,
  required UuidValue passwordResetRequestId,
  required String verificationCode,
  required Transaction? transaction,
}) {
  final smtp = EmailService.instance();
  if (smtp != null) {
    smtp.sendEmail(email, 'Quanitya — Password Reset', 'Your password reset code is: $verificationCode');
  }
  // Always log so self-hosters without SMTP can still read the code.
  session.log('[EmailIdp] Password reset code ($email): $verificationCode');
}

/// Concrete future call for standalone community server.
///
/// Uses the legacy registration API since `type: module` does not generate
/// the typed future call dispatch.
class _CommunityMonthlyBackup extends MonthlyBackupFutureCall {
  @override
  Future<void> runMonthlyBackup(Session session, int iteration) async {
    // Self-schedule next run FIRST (crash-safe) using legacy API
    try {
      final now = DateTime.now();
      final nextMonth = DateTime(now.year, now.month + 1, 1, 2, 0, 0);
      final delay = nextMonth.difference(now);

      // ignore: deprecated_member_use
      await session.serverpod.futureCallWithDelay(
        MonthlyBackupFutureCall.callName,
        null,
        delay,
      );

      session.log(
          'Next monthly backup scheduled for: ${nextMonth.toIso8601String()}');
    } catch (e) {
      session.log('Failed to schedule next monthly backup: $e',
          level: LogLevel.warning);
    }

    await super.runMonthlyBackup(session, iteration);
  }
}

/// Register background tasks for the server
Future<void> _registerBackgroundTasks(Serverpod pod) async {
  // Register the future call with legacy API (required for type: module)
  pod.registerFutureCall(
      _CommunityMonthlyBackup(), MonthlyBackupFutureCall.callName);

  // Schedule first run on 1st of next month at 2 AM
  final now = DateTime.now();
  final nextFirstOfMonth = now.day == 1 && now.hour < 2
      ? DateTime(now.year, now.month, 1, 2, 0, 0)
      : DateTime(now.year, now.month + 1, 1, 2, 0, 0);
  final delay = nextFirstOfMonth.difference(now);

  // ignore: deprecated_member_use
  await pod.futureCallWithDelay(
    MonthlyBackupFutureCall.callName,
    null,
    delay,
  );
  print('Monthly backup scheduled for: ${nextFirstOfMonth.toIso8601String()}');
}
