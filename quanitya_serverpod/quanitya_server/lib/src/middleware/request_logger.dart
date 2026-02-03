import 'dart:convert';
import 'package:serverpod/serverpod.dart';

/// Lightweight request logging middleware for debugging and monitoring.
/// 
/// Logs essential information about each RPC request:
/// - Endpoint and method being called
/// - Parameter names (not values for security)
/// - Authentication status
/// - Request timing
/// - Response status
/// 
/// Designed to be lightweight and security-conscious - no sensitive data is logged.
class RequestLoggingMiddleware {
  /// List of sensitive parameter names that should never be logged
  static const _sensitiveParams = {
    'password',
    'token',
    'key',
    'secret',
    'auth',
    'credential',
    'signature',
    'hash',
    'salt',
    'pepper',
    'private',
    'encrypted',
    'blob',
  };

  /// List of endpoints that should have minimal logging (to reduce noise)
  static const _quietEndpoints = {
    'cloudHealth.getHealth',
    'greeting.hello',
  };

  /// Create the logging middleware
  static Middleware create() {
    return (Handler innerHandler) {
      return (Request request) async {
        final stopwatch = Stopwatch()..start();
        
        try {
          // Log request details for RPC calls
          await _logRequest(request);
          
          // Process the request
          final response = await innerHandler(request);
          
          stopwatch.stop();
          
          // Log response details
          await _logResponse(request, response, stopwatch.elapsed);
          
          return response;
        } catch (e) {
          stopwatch.stop();
          await _logError(request, e, stopwatch.elapsed);
          rethrow;
        }
      };
    };
  }

  /// Log incoming RPC request details
  static Future<void> _logRequest(Request request) async {
    // Only log RPC calls (POST requests to endpoint paths)
    if (request.method.name != 'POST') {
      return;
    }

    try {
      // Try to parse the RPC request body
      final body = await request.readAsString();
      if (body.isEmpty) return;

      final Map<String, dynamic> rpcData = jsonDecode(body);
      final String? method = rpcData['method'];
      final Map<String, dynamic>? params = rpcData['params'];

      if (method == null) return;

      // Skip quiet endpoints
      if (_quietEndpoints.contains(method)) {
        return;
      }

      // Build parameter summary
      final paramSummary = _buildParameterSummary(params ?? {});
      
      // Get client info
      final clientInfo = _getClientInfo(request);
      
      // Get auth info from headers
      final authInfo = _getAuthInfo(request);

      print('🔗 RPC Request: $method | Auth: $authInfo | Client: $clientInfo | Params: $paramSummary');
      
    } catch (e) {
      // If we can't parse the request, just log basic info
      final path = request.url.path;
      print('🔗 HTTP ${request.method.name} $path | Client: ${_getClientInfo(request)}');
    }
  }

  /// Log response details
  static Future<void> _logResponse(Request request, dynamic response, Duration duration) async {
    if (request.method.name != 'POST') return;

    final timingMs = duration.inMilliseconds;
    
    if (response is Response) {
      final status = response.statusCode;
      final statusEmoji = status >= 200 && status < 300 ? '✅' : 
                         status >= 400 && status < 500 ? '⚠️' : '❌';
      
      print('$statusEmoji RPC Response: $status | Duration: ${timingMs}ms');
    } else {
      print('✅ RPC Response: Success | Duration: ${timingMs}ms');
    }
  }

  /// Log error details
  static Future<void> _logError(Request request, dynamic error, Duration duration) async {
    if (request.method.name != 'POST') return;

    final timingMs = duration.inMilliseconds;
    final errorType = error.runtimeType.toString();
    final errorMessage = error.toString();
    
    // Truncate long error messages
    final shortError = errorMessage.length > 100 
        ? '${errorMessage.substring(0, 97)}...'
        : errorMessage;
    
    print('❌ RPC Error: $errorType - $shortError | Duration: ${timingMs}ms');
  }

  /// Build a summary of parameters showing names but not sensitive values
  static String _buildParameterSummary(Map<String, dynamic> params) {
    if (params.isEmpty) {
      return 'none';
    }

    final paramNames = <String>[];
    
    for (final entry in params.entries) {
      final paramName = entry.key;
      final paramValue = entry.value;
      
      if (_isSensitiveParam(paramName)) {
        paramNames.add('$paramName=[REDACTED]');
      } else if (paramValue == null) {
        paramNames.add('$paramName=null');
      } else if (paramValue is String && paramValue.isEmpty) {
        paramNames.add('$paramName=""');
      } else if (paramValue is List) {
        paramNames.add('$paramName=[${paramValue.length} items]');
      } else if (paramValue is Map) {
        paramNames.add('$paramName={${paramValue.length} keys}');
      } else {
        // For non-sensitive simple values, show type
        final typeName = paramValue.runtimeType.toString();
        paramNames.add('$paramName:$typeName');
      }
    }
    
    return paramNames.join(', ');
  }

  /// Check if a parameter name is considered sensitive
  static bool _isSensitiveParam(String paramName) {
    final lowerName = paramName.toLowerCase();
    return _sensitiveParams.any((sensitive) => lowerName.contains(sensitive));
  }

  /// Get authentication info from request headers
  static String _getAuthInfo(Request request) {
    final authHeaders = request.headers['authorization'];
    if (authHeaders != null && authHeaders.isNotEmpty) {
      final authHeader = authHeaders.first;
      if (authHeader.startsWith('Bearer ')) {
        final token = authHeader.substring(7);
        // Show first 8 chars of token for debugging
        final shortToken = token.length > 8 ? '${token.substring(0, 8)}...' : token;
        return 'Bearer $shortToken';
      } else {
        return 'Custom auth';
      }
    }
    
    // Check for custom auth headers
    final customAuthHeaders = request.headers['x-quanitya-device-pubkey'];
    if (customAuthHeaders != null && customAuthHeaders.isNotEmpty) {
      final customAuthHeader = customAuthHeaders.first;
      final shortKey = customAuthHeader.length > 16 
          ? '${customAuthHeader.substring(0, 16)}...'
          : customAuthHeader;
      return 'DeviceKey $shortKey';
    }
    
    return 'anonymous';
  }

  /// Get client information for logging
  static String _getClientInfo(Request request) {
    // Get user agent (first 50 chars to avoid log spam)
    final userAgentHeaders = request.headers['user-agent'];
    final userAgent = (userAgentHeaders != null && userAgentHeaders.isNotEmpty) 
        ? userAgentHeaders.first 
        : 'unknown';
    final shortUserAgent = userAgent.length > 50 
        ? '${userAgent.substring(0, 47)}...' 
        : userAgent;
    
    // Get client IP (masked for privacy)
    final clientIP = _getMaskedClientIP(request);
    
    return '$clientIP | $shortUserAgent';
  }

  /// Get masked client IP for privacy-conscious logging
  static String _getMaskedClientIP(Request request) {
    // Try to get real IP from headers (reverse proxy setup)
    final forwardedForHeaders = request.headers['x-forwarded-for'];
    final realIPHeaders = request.headers['x-real-ip'];
    
    String? clientIP;
    if (forwardedForHeaders != null && forwardedForHeaders.isNotEmpty) {
      // Take first IP from X-Forwarded-For chain
      final forwardedFor = forwardedForHeaders.first;
      clientIP = forwardedFor.split(',').first.trim();
    } else if (realIPHeaders != null && realIPHeaders.isNotEmpty) {
      clientIP = realIPHeaders.first;
    } else {
      // Try to get from connection info if available
      clientIP = 'unknown';
    }
    
    if (clientIP == 'unknown') {
      return 'unknown';
    }
    
    // Mask IP for privacy (show first 2 octets only)
    final parts = clientIP.split('.');
    if (parts.length == 4) {
      return '${parts[0]}.${parts[1]}.*.*';
    } else {
      // IPv6 or other format - just show first few chars
      return clientIP.length > 8 
          ? '${clientIP.substring(0, 8)}...'
          : clientIP;
    }
  }
}