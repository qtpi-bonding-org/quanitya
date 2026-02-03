import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart'
    as quanitya_cloud_client;
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../data/db/app_database.dart';
import '../data/sync/powersync_service.dart';
import '../data/dao/tracker_template_dual_dao.dart';
import '../data/dao/template_aesthetics_dao.dart';
import '../data/dao/template_query_dao.dart';
import '../data/dao/dual_dao.dart';
import '../data/repositories/template_with_aesthetics_repository.dart';
import '../infrastructure/webhooks/webhook_repository.dart';

@module
abstract class AppModule {
  // Development server constants
  String get localhost {
    if (kIsWeb) return '127.0.0.1';
    return defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
  }

  @singleton
  http.Client get httpClient => http.Client();

  @singleton
  quanitya_cloud_client.Client get serverpodClient {
    var serverUrl = dotenv.env['SERVERPOD_URL'];

    if (serverUrl == null || serverUrl.isEmpty) {
      serverUrl = const String.fromEnvironment('SERVERPOD_URL');
    }

    if (serverUrl == null || serverUrl.isEmpty) {
      serverUrl = 'http://$localhost:8090/';
    }

    debugPrint('🔗 Serverpod Client connecting to: $serverUrl');

    final client = quanitya_cloud_client.Client(serverUrl)
      ..connectivityMonitor = FlutterConnectivityMonitor();

    return client;
  }

  @preResolve
  @singleton
  Future<AppDatabase> getDatabase(IPowerSyncService powerSync) async {
    debugPrint('AppModule: Initializing PowerSync...');
    await powerSync.initialize();
    debugPrint('AppModule: PowerSync initialized, returning driftDb');
    return powerSync.driftDb;
  }

  @lazySingleton
  DualDao<TrackerTemplate, EncryptedTemplate> trackerTemplateDualDao(
    TrackerTemplateDualDao dao,
  ) => dao;
}

@module
abstract class RepositoryModule {
  @lazySingleton
  TemplateWithAestheticsRepository templateWithAestheticsRepo(
    DualDao<TrackerTemplate, EncryptedTemplate> dualDao,
    TemplateAestheticsDao aestheticsDao,
    TemplateQueryDao queryDao,
    WebhookRepository webhookRepo,
  ) => TemplateWithAestheticsRepository(
    dualDao,
    aestheticsDao,
    queryDao,
    webhookRepo,
  );
}
