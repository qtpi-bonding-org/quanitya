import 'dart:io';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';

/// Minimal SMTP email service. Reads config from env vars.
/// If SMTP_HOST is not set, returns null (caller should fall back to logging).
class EmailService {
  static EmailService? _instance;

  final SmtpServer _smtp;
  final String _fromAddress;

  EmailService._(this._smtp, this._fromAddress);

  /// Returns null if SMTP env vars are not configured.
  static EmailService? instance() {
    if (_instance != null) return _instance;

    final host = Platform.environment['SMTP_HOST'];
    if (host == null || host.isEmpty) return null;

    final port = int.tryParse(Platform.environment['SMTP_PORT'] ?? '') ?? 587;
    final username = Platform.environment['SMTP_USERNAME'] ?? '';
    final password = Platform.environment['SMTP_PASSWORD'] ?? '';
    final from = Platform.environment['SMTP_FROM'] ?? 'noreply@$host';
    final ssl = Platform.environment['SMTP_SSL'] == 'true';

    _instance = EmailService._(
      SmtpServer(host, port: port, username: username, password: password, ssl: ssl),
      from,
    );
    return _instance;
  }

  Future<void> sendEmail(String to, String subject, String body) async {
    final message = mailer.Message()
      ..from = mailer.Address(_fromAddress)
      ..recipients.add(to)
      ..subject = subject
      ..text = body;

    await mailer.send(message, _smtp);
  }
}
