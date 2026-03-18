import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:health/health.dart';
import 'package:injectable/injectable.dart';

import '../../../data/dao/template_query_dao.dart';
import '../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../infrastructure/core/try_operation.dart';
import '../../../infrastructure/crypto/interfaces/i_secure_storage.dart';
import '../../../infrastructure/platform/app_lifecycle_service.dart';
import '../../../logic/ingestion/exceptions/ingestion_exception.dart';
import '../../../logic/ingestion/services/data_ingestion_service.dart';
import '../../../logic/ingestion/adapters/flutter_data_source_adapter.dart';
import '../../../logic/templates/models/shared/template_aesthetics.dart';
import 'health_adapter_factory.dart';

/// Default health data types to sync.
const defaultHealthTypes = [
  HealthDataType.STEPS,
  HealthDataType.HEART_RATE,
  HealthDataType.BLOOD_OXYGEN,
  HealthDataType.BODY_TEMPERATURE,
  HealthDataType.WEIGHT,
];

/// Orchestrates health data sync from HealthKit/Health Connect through
/// the adapter pipeline into Quanitya's local storage.
///
/// Uses the `health` SDK to fetch data from the OS health store,
/// then pipes it through [HealthAdapterFactory] and [DataIngestionService]
/// for deduplication and persistence.
@lazySingleton
class HealthSyncService {
  static const _enabledKey = 'health_sync_enabled';
  static const _lifecycleKey = 'health_sync';

  final HealthAdapterFactory _adapterFactory;
  final DataIngestionService _ingestionService;
  final TemplateQueryDao _templateQueryDao;
  final TemplateWithAestheticsRepository _templateRepo;
  final ISecureStorage _storage;
  final AppLifecycleService _lifecycleService;

  final Health _health;

  HealthSyncService(
    this._adapterFactory,
    this._ingestionService,
    this._templateQueryDao,
    this._templateRepo,
    this._storage,
    this._lifecycleService,
  ) : _health = Health();

  @visibleForTesting
  HealthSyncService.forTesting(
    this._adapterFactory,
    this._ingestionService,
    this._templateQueryDao,
    this._templateRepo,
    this._storage,
    this._lifecycleService,
    this._health,
  );

  /// Whether the user has enabled automatic health sync on resume.
  Future<bool> isEnabled() async {
    final value = await _storage.getSecureData(_enabledKey);
    return value == 'true';
  }

  /// Persist the enabled flag and register/unregister the resume hook.
  Future<void> setEnabled(bool enabled) async {
    await _storage.storeSecureData(_enabledKey, enabled.toString());
    if (enabled) {
      _lifecycleService.registerOnResume(
        _lifecycleKey,
        () => syncIfEnabled(defaultHealthTypes),
      );
    } else {
      _lifecycleService.unregisterOnResume(_lifecycleKey);
    }
  }

  /// Register the resume hook if the user previously enabled health sync.
  ///
  /// Call once during bootstrap.
  Future<void> registerIfEnabled() async {
    if (await isEnabled()) {
      _lifecycleService.registerOnResume(
        _lifecycleKey,
        () => syncIfEnabled(defaultHealthTypes),
      );
    }
  }

  /// Sync only if enabled and permissions are granted. Silent no-op otherwise.
  Future<void> syncIfEnabled(List<HealthDataType> types) async {
    try {
      if (!await isEnabled()) return;
      if (!await hasPermissions(types)) return;
      await sync(types);
    } catch (e) {
      debugPrint('HealthSyncService: syncIfEnabled failed: $e');
    }
  }

  /// Check if health data is available on this platform.
  ///
  /// On iOS, always returns true (HealthKit is built-in).
  /// On Android, checks if Health Connect is installed.
  Future<bool> isAvailable() {
    return tryMethod(
      () => _health.isHealthConnectAvailable(),
      IngestionException.new,
      'isAvailable',
    );
  }

  /// Request OS-level health permissions for the given types.
  ///
  /// Returns true if permissions were granted (or on iOS, if the
  /// permission dialog was shown without errors).
  Future<bool> requestPermissions(List<HealthDataType> types) {
    return tryMethod(
      () => _health.requestAuthorization(
        types,
        permissions: List.filled(types.length, HealthDataAccess.READ),
      ),
      IngestionException.new,
      'requestPermissions',
    );
  }

  /// Check if permissions are already granted for the given types.
  ///
  /// Returns null on iOS for READ permissions (Apple doesn't disclose this).
  Future<bool> hasPermissions(List<HealthDataType> types) {
    return tryMethod(
      () async {
        final result = await _health.hasPermissions(
          types,
          permissions: List.filled(types.length, HealthDataAccess.READ),
        );
        // hasPermissions returns bool? — null means undetermined (iOS READ)
        return result ?? (Platform.isIOS ? true : false);
      },
      IngestionException.new,
      'hasPermissions',
    );
  }

  /// Fetch from OS health store, adapt, deduplicate, and persist.
  ///
  /// Returns the total number of newly imported entries across all types.
  Future<int> sync(List<HealthDataType> types, {DateTime? since}) {
    return tryMethod(
      () async {
        final start = since ?? DateTime.now().subtract(const Duration(days: 30));
        final end = DateTime.now();

        // Fetch from OS — the health SDK deduplicates internally
        final points = await _health.getHealthDataFromTypes(
          types: types,
          startTime: start,
          endTime: end,
        );

        if (points.isEmpty) return 0;

        // Group by HealthDataType
        final grouped = <HealthDataType, List<HealthDataPoint>>{};
        for (final point in points) {
          (grouped[point.type] ??= []).add(point);
        }

        var total = 0;
        for (final entry in grouped.entries) {
          // Use unmapped adapter for template creation/lookup
          final baseAdapter = _adapterFactory.create(entry.key);
          final templateId = await _ensureTemplate(baseAdapter);

          // Resolve field label → UUID mapping from the template
          final template = await _templateQueryDao.findById(templateId);
          final fieldMap = <String, String>{};
          if (template != null) {
            for (final f in template.fields) {
              fieldMap[f.label] = f.id;
            }
          }

          // Create adapter with field UUID mapping for correct data keys
          final adapter = _adapterFactory.create(
            entry.key,
            fieldLabelToId: fieldMap,
          );
          final count = await _ingestionService.syncFlutter(
            adapter: adapter,
            templateId: templateId,
            sourceData: entry.value,
          );
          total += count;
        }

        return total;
      },
      IngestionException.new,
      'sync',
    );
  }

  /// Find existing template by name or create from adapter.
  ///
  /// Find existing template by name or create from adapter.
  Future<String> _ensureTemplate(
    FlutterDataSourceAdapter<HealthDataPoint> adapter,
  ) async {
    final existing = await _templateQueryDao.findByName(adapter.displayName);
    if (existing != null) return existing.id;

    // Create new template from adapter
    final template = adapter.deriveTemplate();
    final aesthetics = TemplateAestheticsModel.defaults(
      templateId: template.id,
      icon: 'material:monitor_heart',
    );
    await _templateRepo.save(
      TemplateWithAesthetics(template: template, aesthetics: aesthetics),
    );
    return template.id;
  }
}
