import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:http/http.dart' as http;
import 'package:quanitya_flutter/infrastructure/core/try_operation.dart';
import '../exceptions/app_syncing_exceptions.dart';

abstract class INetworkService {
  Future<bool> testConnection(String url);
}

@Injectable(as: INetworkService)
@lazySingleton
class NetworkService implements INetworkService {
  final http.Client _client;

  NetworkService(this._client);

  @override
  Future<bool> testConnection(String url) {
    return tryMethod(
      () async {
        debugPrint('Testing connection to: $url/health');

        final response = await _client
            .get(
              Uri.parse('$url/health'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 5));

        debugPrint('Cloud response status: ${response.statusCode}');
        debugPrint('Cloud response headers: ${response.headers}');
        debugPrint('Cloud response body: ${response.body}');

        final isConnected = response.statusCode == 200;
        debugPrint(
          'Connection result: ${isConnected ? "SUCCESS" : "FAILED"}',
        );

        return isConnected;
      },
      NetworkException.new,
      'testConnection',
    );
  }
}
