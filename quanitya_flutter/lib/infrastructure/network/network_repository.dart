import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:http/http.dart' as http;
import 'package:quanitya_flutter/infrastructure/core/try_operation.dart';
import '../../features/app_syncing_mode/exceptions/app_syncing_exceptions.dart';

abstract class INetworkRepository {
  Future<bool> testConnection(String url);
}

@Injectable(as: INetworkRepository)
@lazySingleton
class NetworkRepository implements INetworkRepository {
  final http.Client _client;

  NetworkRepository(this._client);

  @override
  Future<bool> testConnection(String url) {
    return tryMethod(
      () async {
        final response = await _client
            .get(
              Uri.parse('$url/health'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 5));

        return response.statusCode == 200;
      },
      NetworkException.new,
      'testConnection',
    );
  }
}
