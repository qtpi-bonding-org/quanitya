/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import '../endpoints/archive_endpoint.dart' as _i2;
import '../endpoints/email_idp_endpoint.dart' as _i3;
import '../endpoints/jwt_refresh_endpoint.dart' as _i4;
import '../endpoints/powersync_endpoint.dart' as _i5;
import '../endpoints/sync_endpoint.dart' as _i6;
import '../greeting_endpoint.dart' as _i7;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i8;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i9;
import 'package:quanitya_server/src/generated/future_calls.dart' as _i10;
export 'future_calls.dart' show ServerpodFutureCallsGetter;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'archive': _i2.ArchiveEndpoint()
        ..initialize(
          server,
          'archive',
          'quanitya',
        ),
      'emailIdp': _i3.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          'quanitya',
        ),
      'jwtRefresh': _i4.JwtRefreshEndpoint()
        ..initialize(
          server,
          'jwtRefresh',
          'quanitya',
        ),
      'powerSync': _i5.PowerSyncEndpoint()
        ..initialize(
          server,
          'powerSync',
          'quanitya',
        ),
      'sync': _i6.SyncEndpoint()
        ..initialize(
          server,
          'sync',
          'quanitya',
        ),
      'greeting': _i7.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          'quanitya',
        ),
    };
    connectors['archive'] = _i1.EndpointConnector(
      name: 'archive',
      endpoint: endpoints['archive']!,
      methodConnectors: {
        'getArchivedMonth': _i1.MethodConnector(
          name: 'getArchivedMonth',
          params: {
            'year': _i1.ParameterDescription(
              name: 'year',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'month': _i1.ParameterDescription(
              name: 'month',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['archive'] as _i2.ArchiveEndpoint)
                  .getArchivedMonth(
                    session,
                    params['year'],
                    params['month'],
                  ),
        ),
        'getArchivedDateRange': _i1.MethodConnector(
          name: 'getArchivedDateRange',
          params: {
            'startYear': _i1.ParameterDescription(
              name: 'startYear',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'startMonth': _i1.ParameterDescription(
              name: 'startMonth',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'endYear': _i1.ParameterDescription(
              name: 'endYear',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'endMonth': _i1.ParameterDescription(
              name: 'endMonth',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['archive'] as _i2.ArchiveEndpoint)
                  .getArchivedDateRange(
                    session,
                    params['startYear'],
                    params['startMonth'],
                    params['endYear'],
                    params['endMonth'],
                  ),
        ),
        'getArchiveMetadata': _i1.MethodConnector(
          name: 'getArchiveMetadata',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['archive'] as _i2.ArchiveEndpoint)
                  .getArchiveMetadata(session),
        ),
        'searchArchivedEntries': _i1.MethodConnector(
          name: 'searchArchivedEntries',
          params: {
            'startDate': _i1.ParameterDescription(
              name: 'startDate',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
            'endDate': _i1.ParameterDescription(
              name: 'endDate',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['archive'] as _i2.ArchiveEndpoint)
                  .searchArchivedEntries(
                    session,
                    params['startDate'],
                    params['endDate'],
                  ),
        ),
        'runManualArchival': _i1.MethodConnector(
          name: 'runManualArchival',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['archive'] as _i2.ArchiveEndpoint)
                  .runManualArchival(session),
        ),
      },
    );
    connectors['emailIdp'] = _i1.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i3.EmailIdpEndpoint).login(
                session,
                email: params['email'],
                password: params['password'],
              ),
        ),
        'startRegistration': _i1.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i3.EmailIdpEndpoint)
                  .startRegistration(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyRegistrationCode': _i1.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _i1.ParameterDescription(
              name: 'accountRequestId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _i1.ParameterDescription(
              name: 'verificationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i3.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _i1.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _i1.ParameterDescription(
              name: 'registrationToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i3.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'startPasswordReset': _i1.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i3.EmailIdpEndpoint)
                  .startPasswordReset(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyPasswordResetCode': _i1.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _i1.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _i1.ParameterDescription(
              name: 'verificationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i3.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishPasswordReset': _i1.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _i1.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i3.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
        'hasAccount': _i1.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i3.EmailIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['jwtRefresh'] = _i1.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _i1.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _i1.ParameterDescription(
              name: 'refreshToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['jwtRefresh'] as _i4.JwtRefreshEndpoint)
                  .refreshAccessToken(
                    session,
                    refreshToken: params['refreshToken'],
                  ),
        ),
      },
    );
    connectors['powerSync'] = _i1.EndpointConnector(
      name: 'powerSync',
      endpoint: endpoints['powerSync']!,
      methodConnectors: {
        'getToken': _i1.MethodConnector(
          name: 'getToken',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['powerSync'] as _i5.PowerSyncEndpoint)
                  .getToken(session),
        ),
      },
    );
    connectors['sync'] = _i1.EndpointConnector(
      name: 'sync',
      endpoint: endpoints['sync']!,
      methodConnectors: {
        'upsertEncryptedTemplate': _i1.MethodConnector(
          name: 'upsertEncryptedTemplate',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'encryptedData': _i1.ParameterDescription(
              name: 'encryptedData',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sync'] as _i6.SyncEndpoint)
                  .upsertEncryptedTemplate(
                    session,
                    params['id'],
                    params['encryptedData'],
                  ),
        ),
        'deleteEncryptedTemplate': _i1.MethodConnector(
          name: 'deleteEncryptedTemplate',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sync'] as _i6.SyncEndpoint)
                  .deleteEncryptedTemplate(
                    session,
                    params['id'],
                  ),
        ),
        'upsertEncryptedEntry': _i1.MethodConnector(
          name: 'upsertEncryptedEntry',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'encryptedData': _i1.ParameterDescription(
              name: 'encryptedData',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sync'] as _i6.SyncEndpoint).upsertEncryptedEntry(
                    session,
                    params['id'],
                    params['encryptedData'],
                  ),
        ),
        'deleteEncryptedEntry': _i1.MethodConnector(
          name: 'deleteEncryptedEntry',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sync'] as _i6.SyncEndpoint).deleteEncryptedEntry(
                    session,
                    params['id'],
                  ),
        ),
        'upsertEncryptedSchedule': _i1.MethodConnector(
          name: 'upsertEncryptedSchedule',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'encryptedData': _i1.ParameterDescription(
              name: 'encryptedData',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sync'] as _i6.SyncEndpoint)
                  .upsertEncryptedSchedule(
                    session,
                    params['id'],
                    params['encryptedData'],
                  ),
        ),
        'deleteEncryptedSchedule': _i1.MethodConnector(
          name: 'deleteEncryptedSchedule',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sync'] as _i6.SyncEndpoint)
                  .deleteEncryptedSchedule(
                    session,
                    params['id'],
                  ),
        ),
        'upsertTemplateAesthetics': _i1.MethodConnector(
          name: 'upsertTemplateAesthetics',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'templateId': _i1.ParameterDescription(
              name: 'templateId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'themeName': _i1.ParameterDescription(
              name: 'themeName',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'icon': _i1.ParameterDescription(
              name: 'icon',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'emoji': _i1.ParameterDescription(
              name: 'emoji',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'paletteJson': _i1.ParameterDescription(
              name: 'paletteJson',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'fontConfigJson': _i1.ParameterDescription(
              name: 'fontConfigJson',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'colorMappingsJson': _i1.ParameterDescription(
              name: 'colorMappingsJson',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'updatedAt': _i1.ParameterDescription(
              name: 'updatedAt',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sync'] as _i6.SyncEndpoint)
                  .upsertTemplateAesthetics(
                    session,
                    params['id'],
                    params['templateId'],
                    params['themeName'],
                    params['icon'],
                    params['emoji'],
                    params['paletteJson'],
                    params['fontConfigJson'],
                    params['colorMappingsJson'],
                    params['updatedAt'],
                  ),
        ),
        'deleteTemplateAesthetics': _i1.MethodConnector(
          name: 'deleteTemplateAesthetics',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sync'] as _i6.SyncEndpoint)
                  .deleteTemplateAesthetics(
                    session,
                    params['id'],
                  ),
        ),
        'upsertEncryptedAnalysisScript': _i1.MethodConnector(
          name: 'upsertEncryptedAnalysisScript',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'encryptedData': _i1.ParameterDescription(
              name: 'encryptedData',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sync'] as _i6.SyncEndpoint)
                  .upsertEncryptedAnalysisScript(
                    session,
                    params['id'],
                    params['encryptedData'],
                  ),
        ),
        'deleteEncryptedAnalysisScript': _i1.MethodConnector(
          name: 'deleteEncryptedAnalysisScript',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sync'] as _i6.SyncEndpoint)
                  .deleteEncryptedAnalysisScript(
                    session,
                    params['id'],
                  ),
        ),
        'getStorageUsage': _i1.MethodConnector(
          name: 'getStorageUsage',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sync'] as _i6.SyncEndpoint)
                  .getStorageUsage(session),
        ),
      },
    );
    connectors['greeting'] = _i1.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _i1.MethodConnector(
          name: 'hello',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['greeting'] as _i7.GreetingEndpoint).hello(
                session,
                params['name'],
              ),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _i8.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _i9.Endpoints()
      ..initializeEndpoints(server);
  }

  @override
  _i1.FutureCallDispatch? get futureCalls {
    return _i10.FutureCalls();
  }
}
