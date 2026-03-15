import 'package:powersync_sqlcipher/powersync.dart';

/// PowerSync schema - defines tables that sync to/from backend
///
/// Two categories:
/// 1. Encrypted tables (E2EE) - All user data synced as encrypted blobs
/// 2. Notifications - Server-to-client notifications (no E2EE)
///
/// Note: Client tables don't have account_id - PowerSync sync rules
/// handle multi-tenancy on the server side via authenticated JWT.
const powerSyncSchema = Schema([
  // ─────────────────────────────────────────────────────────────────────────
  // E2EE Tables - PII data encrypted client-side
  // Note: PowerSync auto-adds 'id' column, don't define it manually
  // ─────────────────────────────────────────────────────────────────────────
  Table('encrypted_templates', [
    Column.text('encrypted_data'),
    Column.text('updated_at'),
  ]),
  Table('encrypted_entries', [
    Column.text('encrypted_data'),
    Column.text('updated_at'),
  ]),
  Table('encrypted_analysis_scripts', [
    Column.text('encrypted_data'),
    Column.text('updated_at'),
  ]),
  Table('encrypted_schedules', [
    Column.text('encrypted_data'),
    Column.text('updated_at'),
  ]),
  Table('encrypted_template_aesthetics', [
    Column.text('encrypted_data'),
    Column.text('updated_at'),
  ]),

  // ─────────────────────────────────────────────────────────────────────────
  // Notifications - Server-to-client notifications (no E2EE)
  // ─────────────────────────────────────────────────────────────────────────
  Table('notifications', [
    Column.text('title'),
    Column.text('message'),
    Column.text('type'),
    Column.text('created_at'),
    Column.text('expires_at'),
    Column.text('action_url'),
    Column.text('action_label'),
    Column.text('marked_at'),
    Column.text('updated_at'),
  ]),
]);
