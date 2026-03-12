import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

import 'src/generated/endpoints.dart';
import 'src/generated/protocol.dart';
import 'src/future_calls/monthly_archival_future_call.dart';
import 'src/web/routes/root.dart';
import 'src/middleware/request_logger.dart';
import 'src/services/email_service.dart';

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

/// Register background tasks for the server
Future<void> _registerBackgroundTasks(Serverpod pod) async {
  // Register monthly archival future call
  pod.registerFutureCall(MonthlyArchivalFutureCall(), 'monthlyArchival');
  
  // Initialize the monthly archival schedule on server startup
  // This will schedule the first execution and then it will self-reschedule
  final session = await pod.createSession(enableLogging: false);
  try {
    await MonthlyArchivalFutureCall().initializeSchedule(session, 0);
    session.log('Monthly archival schedule initialized');
  } catch (e) {
    session.log('Failed to initialize monthly archival schedule: $e', level: LogLevel.error);
  } finally {
    await session.close();
  }
}
