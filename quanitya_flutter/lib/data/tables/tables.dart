import 'package:drift/drift.dart';
import '../../features/app_operating_mode/models/app_operating_mode.dart';
import '../../logic/analytics/enums/analysis_output_mode.dart';
import '../../logic/analytics/models/analysis_enums.dart';

export 'analytics_inbox_entries.dart';
export 'error_box_entries.dart';
export 'notifications.dart';

/// TrackerTemplates table - stores user-defined form blueprints
/// Uses exact column specifications as defined in requirements
class TrackerTemplates extends Table {
  /// Primary key - UUID format string
  TextColumn get id => text()();

  /// Display name for the template
  TextColumn get name => text()();

  /// Serialized List of TemplateField as JSON string
  TextColumn get fieldsJson => text().named('fields_json')();

  /// Timestamp of last modification
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  /// Soft delete flag - when true, template is hidden but preserved
  BoolColumn get isArchived =>
      boolean().named('is_archived').withDefault(const Constant(false))();

  /// Hidden flag - when true, template requires authentication to view (like iOS Hidden Photos)
  /// Hidden templates and their entries are excluded from normal queries
  BoolColumn get isHidden =>
      boolean().named('is_hidden').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// LogEntries table - stores actual user data records
///
/// Supports three temporal states via two nullable timestamps:
/// - TODO: scheduledFor is future, occurredAt is null
/// - MISSED: scheduledFor is past, occurredAt is null
/// - LOGGED: occurredAt is not null (ad-hoc or completed todo)
///
/// Validation rules:
/// - At least one of scheduledFor/occurredAt must be non-null (enforced by CHECK)
/// - occurredAt cannot be in the future (enforced in model layer)
class LogEntries extends Table {
  /// Primary key - UUID format string (matches encrypted shadow table)
  TextColumn get id => text()();

  /// Foreign key reference to TrackerTemplate
  TextColumn get templateId => text().named('template_id')();

  /// When this entry is/was scheduled for (due date for todos)
  /// Null for ad-hoc logging without prior scheduling
  DateTimeColumn get scheduledFor =>
      dateTime().named('scheduled_for').nullable()();

  /// When this entry actually occurred/was completed
  /// Null for todos that haven't been done yet
  DateTimeColumn get occurredAt => dateTime().named('occurred_at').nullable()();

  /// Serialized Map of String to dynamic data payload as JSON string
  TextColumn get dataJson => text().named('data_json')();

  /// Timestamp of last modification (for E2EE sync conflict resolution)
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (scheduled_for IS NOT NULL OR occurred_at IS NOT NULL)',
  ];
}

/// EncryptedTemplates shadow table - PowerSync sync target for encrypted template data
/// Contains only essential columns for E2EE synchronization
class EncryptedTemplates extends Table {
  /// UUID only - matches TrackerTemplates.id
  TextColumn get id => text()();

  /// E2EE encrypted template data blob
  TextColumn get encryptedData => text().named('encrypted_data')();

  /// Timestamp only for sync ordering
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// EncryptedEntries shadow table - PowerSync sync target for encrypted entry data
/// Contains only essential columns for E2EE synchronization
class EncryptedEntries extends Table {
  /// UUID only - matches LogEntries.id
  TextColumn get id => text()();

  /// E2EE encrypted entry data blob
  TextColumn get encryptedData => text().named('encrypted_data')();

  /// Timestamp only for sync ordering
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Schedules table - stores "WHEN" to remind user to log
///
/// Links to TrackerTemplate (the "WHAT") and generates LogEntry todos.
/// One template can have multiple schedules (e.g., daily at 9am AND weekly summary).
class Schedules extends Table {
  /// Primary key - UUID format string
  TextColumn get id => text()();

  /// FK to TrackerTemplate - defines what to log
  TextColumn get templateId => text().named('template_id')();

  /// RRULE string (e.g., "FREQ=DAILY;BYHOUR=9")
  /// See: https://icalendar.org/iCalendar-RFC-5545/3-8-5-3-recurrence-rule.html
  TextColumn get recurrenceRule => text().named('recurrence_rule')();

  /// Minutes before due time to send notification (null = no reminder)
  IntColumn get reminderOffsetMinutes =>
      integer().named('reminder_offset_minutes').nullable()();

  /// Whether this schedule is active (can pause without deleting)
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  /// Last time entries were generated from this schedule (for incremental generation)
  DateTimeColumn get lastGeneratedAt =>
      dateTime().named('last_generated_at').nullable()();

  /// Timestamp of last modification
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// EncryptedSchedules shadow table - PowerSync sync target for encrypted schedule data
/// Contains only essential columns for E2EE synchronization
class EncryptedSchedules extends Table {
  /// UUID only - matches Schedules.id
  TextColumn get id => text()();

  /// E2EE encrypted schedule data blob
  TextColumn get encryptedData => text().named('encrypted_data')();

  /// Timestamp only for sync ordering
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// ApiKeys table - metadata for API keys (actual values in secure storage)
///
/// LOCAL-ONLY - never synced. Stores reference to flutter_secure_storage key.
/// Used for webhook authentication (Bearer tokens, API key headers).
class ApiKeys extends Table {
  /// Primary key - UUID format string
  TextColumn get id => text()();

  /// User-friendly name (e.g., "My OpenRouter Key", "Custom API")
  TextColumn get name => text()();

  /// Authentication type: 'bearer' | 'api_key_header'
  TextColumn get authType => text().named('auth_type')();

  /// Header name for api_key_header type (e.g., 'X-API-Key')
  /// Null for bearer type (uses 'Authorization: Bearer ...')
  TextColumn get headerName => text().named('header_name').nullable()();

  /// Key to lookup actual value in flutter_secure_storage
  /// Pattern: 'apikey_{uuid}'
  TextColumn get secureStorageKey => text().named('secure_storage_key')();

  /// Timestamp of last modification
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Webhooks table - triggers GET requests on log entry creation
///
/// LOCAL-ONLY - never synced. Per-template webhook configuration.
/// URLs must be HTTPS. No data sent, just a ping for automation triggers.
class Webhooks extends Table {
  /// Primary key - UUID format string
  TextColumn get id => text()();

  /// FK to TrackerTemplates - which template triggers this webhook
  TextColumn get templateId => text().named('template_id')();

  /// User-friendly name (e.g., "Daily Log Sync", "Mood Alert")
  TextColumn get name => text()();

  /// The endpoint URL to hit (must be https://)
  TextColumn get url => text()();

  /// FK to ApiKeys - optional authentication (null = no auth)
  TextColumn get apiKeyId => text().named('api_key_id').nullable()();

  /// Whether this webhook is active
  BoolColumn get isEnabled =>
      boolean().named('is_enabled').withDefault(const Constant(true))();

  /// Last time this webhook was triggered (for debugging)
  DateTimeColumn get lastTriggeredAt =>
      dateTime().named('last_triggered_at').nullable()();

  /// Timestamp of last modification
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// TemplateAesthetics table - stores visual styling for templates
///
/// NOT E2EE - contains only non-PII styling data (colors, fonts, icons).
/// Separated from TrackerTemplates to decouple content from presentation.
/// 1:1 relationship with TrackerTemplates via templateId FK.
class TemplateAesthetics extends Table {
  /// Primary key - UUID format string
  TextColumn get id => text()();

  /// FK to TrackerTemplate - defines which template this styling belongs to
  TextColumn get templateId => text().named('template_id')();

  /// Optional theme name for user identification (e.g., "Ocean Vibes", "Sunset Warm")
  TextColumn get themeName => text().named('theme_name').nullable()();

  /// Icon from flutter_iconpicker in format "packname:iconname"
  /// e.g., "material:fitness_center", "cupertino:heart_fill"
  /// Priority: icon → emoji → default
  TextColumn get icon => text().nullable()();

  /// Fallback emoji icon (e.g., "🏋️", "💊", "😊")
  /// Used when icon is null
  TextColumn get emoji => text().nullable()();

  /// Color palette as JSON: {"colors": ["#1976D2", ...], "neutrals": ["#212121", ...]}
  TextColumn get paletteJson => text().named('palette_json')();

  /// Font configuration as JSON: {"titleFontFamily": "Roboto", "titleWeight": 600, ...}
  TextColumn get fontConfigJson => text().named('font_config_json')();

  /// Color mappings by widget type as JSON: {"slider": {"activeColor": "color1", ...}, ...}
  TextColumn get colorMappingsJson => text().named('color_mappings_json')();

  /// Container geometry style for field styling (zen, soft, tech, console, etc.)
  /// Nullable - user must explicitly choose (no default).
  TextColumn get containerStyle => text().named('container_style').nullable()();

  /// Timestamp of last modification
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// AnalysisPipelines table - stores dynamic WASM-based analysis scripts
///
/// E2EE enabled - contains user-defined logic that may reveal patterns.
/// Replaces the legacy step-based pipeline with a script-based model.
class AnalysisPipelines extends Table {
  /// Primary key - UUID format string
  TextColumn get id => text()();

  /// User-friendly name for the analysis
  TextColumn get name => text()();

  /// Primary field ID this analysis is associated with
  TextColumn get fieldId => text().named('field_id')();

  /// The structural commitment of the output: scalar, vector, or matrix
  TextColumn get outputMode => textEnum<AnalysisOutputMode>().named('output_mode')();

  /// Language of the snippet (currently only 'js')
  TextColumn get snippetLanguage => textEnum<AnalysisSnippetLanguage>().named('snippet_language')();

  /// The code snippet (injected into Jinja template at runtime)
  TextColumn get snippet => text()();

  /// Brief explanation of the math logic used (generated by AI)
  TextColumn get reasoning => text().nullable()();

  /// Optional metadata (units, decimals, etc.)
  TextColumn get metadataJson =>
      text().named('metadata_json').nullable()();

  /// Timestamp of last modification
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// EncryptedAnalysisPipelines shadow table - PowerSync sync target for encrypted pipeline data
/// Contains only essential columns for E2EE synchronization
class EncryptedAnalysisPipelines extends Table {
  /// UUID only - matches AnalysisPipelines.id
  TextColumn get id => text()();

  /// E2EE encrypted pipeline data blob
  TextColumn get encryptedData => text().named('encrypted_data')();

  /// Timestamp only for sync ordering
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// AppOperatingSettings table - stores app operating mode configuration
///
/// LOCAL-ONLY - never synced. Single row table for app-wide settings.
/// Stores user's choice of local/self-hosted/cloud mode and connection status.
class AppOperatingSettings extends Table {
  /// Primary key - auto-increment (single row table)
  IntColumn get id => integer().autoIncrement()();

  /// Operating mode: 'local', 'selfHosted', 'cloud'
  TextColumn get mode => textEnum<AppOperatingMode>()();

  /// Self-hosted server URL (null for local/cloud modes)
  TextColumn get selfHostedUrl => text().named('self_hosted_url').nullable()();

  /// Whether currently connected to server (false for local mode)
  BoolColumn get isConnected =>
      boolean().named('is_connected').withDefault(const Constant(false))();

  /// Last time connection was tested (null if never tested)
  DateTimeColumn get lastConnectionTest =>
      dateTime().named('last_connection_test').nullable()();

  /// Whether analytics events are auto-sent on app startup (default: off)
  BoolColumn get analyticsAutoSend =>
      boolean().named('analytics_auto_send').withDefault(const Constant(false))();

  /// Timestamp of record creation
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  /// Timestamp of last modification
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();
}

/// OpenRouterModels table - cached model list from OpenRouter API
///
/// LOCAL-ONLY - never synced. Populated from two sources:
/// 1. tested_models.json (GitHub) on startup — sets tested: true
/// 2. Full OpenRouter API /models endpoint — sets pricing/context data
class OpenRouterModels extends Table {
  TextColumn get id => text()();
  IntColumn get contextLength =>
      integer().named('context_length').withDefault(const Constant(0))();
  TextColumn get promptPrice =>
      text().named('prompt_price').withDefault(const Constant('0'))();
  TextColumn get completionPrice =>
      text().named('completion_price').withDefault(const Constant('0'))();
  BoolColumn get tested =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// LlmProviderConfigs table - saved LLM provider configurations
///
/// LOCAL-ONLY - never synced. Users can save multiple configs.
/// Most recently used config is active on app restart.
class LlmProviderConfigs extends Table {
  TextColumn get id => text()();
  TextColumn get baseUrl => text().named('base_url')();
  TextColumn get modelId => text().named('model_id')();
  TextColumn get apiKeyId => text().named('api_key_id').nullable()();
  DateTimeColumn get lastUsedAt => dateTime().named('last_used_at')();

  @override
  Set<Column> get primaryKey => {id};
}
