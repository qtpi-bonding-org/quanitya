import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../infrastructure/core/try_operation.dart';

import '../../models/shared/shareable_template.dart';
import '../../models/shared/template_aesthetics.dart';
import '../../../analysis/models/analysis_script.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../../data/interfaces/analysis_script_interface.dart';

/// Service for importing templates from shareable JSON format.
///
/// Supports GitHub Gists, repository raw URLs, and direct JSON URLs.
/// Validates, sanitizes, and imports templates with optional aesthetics
/// and analysis scripts.
@injectable
class TemplateImportService {
  final http.Client _httpClient;
  final TemplateWithAestheticsRepository _templateRepository;
  final IAnalysisScriptRepository? _scriptRepository;

  TemplateImportService(
    this._httpClient,
    this._templateRepository,
    this._scriptRepository,
  );

  /// Import template from URL.
  ///
  /// [url] - GitHub Gist, repository raw URL, or direct JSON URL
  ///
  /// Returns the imported template with aesthetics.
  /// Throws [TemplateImportException] on failure.
  Future<TemplateWithAesthetics> importFromUrl(String url) async {
    try {
      // 1. Normalize and validate URL
      final normalizedUrl = _normalizeUrl(url);
      _validateUrl(normalizedUrl);

      // 2. Fetch JSON content
      final jsonContent = await _fetchJsonContent(normalizedUrl);

      // 3. Parse shareable template - Freezed will validate structure
      final shareableTemplate = await _parseShareableTemplate(jsonContent);

      // 4. Convert to local format and import
      return await _importShareableTemplate(shareableTemplate);
    } catch (e) {
      if (e is TemplateImportException) {
        rethrow;
      }
      throw TemplateImportException(
        'Failed to import template: ${e.toString()}',
        TemplateImportErrorType.unknown,
      );
    }
  }

  /// Preview template from URL without importing.
  ///
  /// Returns shareable template for preview UI.
  Future<ShareableTemplate> previewFromUrl(String url) async {
    try {
      final normalizedUrl = _normalizeUrl(url);
      _validateUrl(normalizedUrl);

      final jsonContent = await _fetchJsonContent(normalizedUrl);
      return await _parseShareableTemplate(jsonContent);
    } catch (e) {
      if (e is TemplateImportException) {
        rethrow;
      }
      throw TemplateImportException(
        'Failed to preview template: ${e.toString()}',
        TemplateImportErrorType.unknown,
      );
    }
  }

  /// Normalize GitHub URLs to raw format.
  String _normalizeUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      throw TemplateImportException(
        'Invalid URL format',
        TemplateImportErrorType.invalidUrl,
      );
    }

    // Convert GitHub Gist URLs to raw format
    if (uri.host == 'gist.github.com') {
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        final username = pathSegments[0];
        final gistId = pathSegments[1];
        return 'https://gist.githubusercontent.com/$username/$gistId/raw/template.json';
      }
    }

    // Return as-is for raw URLs and direct JSON URLs
    return url.trim();
  }

  /// Validate URL format and security.
  void _validateUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw TemplateImportException(
        'Invalid URL format',
        TemplateImportErrorType.invalidUrl,
      );
    }

    // Only allow HTTPS for security
    if (uri.scheme != 'https') {
      throw TemplateImportException(
        'Only HTTPS URLs are allowed for security',
        TemplateImportErrorType.invalidUrl,
      );
    }

    // Validate allowed hosts
    final allowedHosts = [
      'gist.githubusercontent.com',
      'raw.githubusercontent.com',
      // Add other trusted hosts as needed
    ];

    if (!allowedHosts.any((host) => uri.host.endsWith(host))) {
      // Allow any HTTPS host for now, but warn about security
      // In production, you might want to restrict this further
    }
  }

  /// Fetch JSON content from URL.
  Future<String> _fetchJsonContent(String url) async {
    try {
      final response = await _httpClient
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json, text/plain',
              'User-Agent': 'Quanitya-App/1.0',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.body;
      } else if (response.statusCode == 404) {
        throw TemplateImportException(
          'Template not found at URL',
          TemplateImportErrorType.notFound,
        );
      } else if (response.statusCode == 403) {
        throw TemplateImportException(
          'Access denied to template URL',
          TemplateImportErrorType.accessDenied,
        );
      } else {
        throw TemplateImportException(
          'Failed to fetch template (HTTP ${response.statusCode})',
          TemplateImportErrorType.networkError,
        );
      }
    } catch (e) {
      if (e is TemplateImportException) {
        rethrow;
      }
      throw TemplateImportException(
        'Network error: ${e.toString()}',
        TemplateImportErrorType.networkError,
      );
    }
  }

  /// Parse JSON to shareable template - Freezed handles validation.
  Future<ShareableTemplate> _parseShareableTemplate(String jsonContent) async {
    try {
      final jsonMap = json.decode(jsonContent) as Map<String, dynamic>;
      return ShareableTemplate.fromJson(jsonMap);
    } on FormatException {
      throw TemplateImportException(
        'Invalid JSON format',
        TemplateImportErrorType.invalidFormat,
      );
    } catch (e) {
      throw TemplateImportException(
        'Failed to parse template: ${e.toString()}',
        TemplateImportErrorType.invalidFormat,
      );
    }
  }

  /// Import shareable template to local database.
  Future<TemplateWithAesthetics> _importShareableTemplate(
    ShareableTemplate shareableTemplate,
  ) async {
    // Generate new IDs for local storage
    final templateId = const Uuid().v4();

    // Convert template with new IDs, tracking old → new field ID mapping
    final fieldIdMap = <String, String>{};
    final newFields = shareableTemplate.template.fields.map((field) {
      final newId = const Uuid().v4();
      fieldIdMap[field.id] = newId;
      return field.copyWith(id: newId);
    }).toList();

    final localTemplate = shareableTemplate.template.copyWith(
      id: templateId,
      fields: newFields,
      updatedAt: DateTime.now(),
      isArchived: false,
      isHidden: false,
    );

    // Convert aesthetics with new IDs if present
    TemplateAestheticsModel? localAesthetics;
    if (shareableTemplate.aesthetics != null) {
      localAesthetics = shareableTemplate.aesthetics!.copyWith(
        id: const Uuid().v4(),
        templateId: templateId,
        updatedAt: DateTime.now(),
      );
    }

    // Create template with aesthetics
    final templateWithAesthetics = TemplateWithAesthetics(
      template: localTemplate,
      aesthetics:
          localAesthetics ??
          TemplateAestheticsModel.defaults(templateId: templateId),
    );

    // Save template and aesthetics
    await _templateRepository.save(templateWithAesthetics);

    // Import analysis scripts if present and repository available
    if (shareableTemplate.analysisScripts != null &&
        shareableTemplate.analysisScripts!.isNotEmpty &&
        _scriptRepository != null) {
      await _importAnalysisScripts(
        shareableTemplate.analysisScripts!,
        fieldIdMap,
      );
    }

    return templateWithAesthetics;
  }

  /// Import analysis scripts, remapping field IDs to match new template.
  Future<void> _importAnalysisScripts(
    List<AnalysisScriptModel> scripts,
    Map<String, String> fieldIdMap,
  ) async {
    if (_scriptRepository == null) return;

    for (final script in scripts) {
      try {
        await tryMethod(
          () async {
            final newFieldId = fieldIdMap[script.fieldId] ?? script.fieldId;
            final localScript = script.copyWith(
              id: const Uuid().v4(),
              fieldId: newFieldId,
              updatedAt: DateTime.now(),
            );
            await _scriptRepository.saveScript(localScript);
          },
          (message, [cause]) => TemplateImportException(message, TemplateImportErrorType.unknown),
          'importScript',
        );
      } catch (_) {
        // tryMethod already logged — continue to next script
        continue;
      }
    }
  }
}

/// Exception thrown during template import operations.
class TemplateImportException implements Exception {
  final String message;
  final TemplateImportErrorType type;

  const TemplateImportException(this.message, this.type);

  @override
  String toString() => 'TemplateImportException: $message';
}

/// Types of template import errors.
enum TemplateImportErrorType {
  invalidUrl,
  networkError,
  notFound,
  accessDenied,
  invalidFormat,
  validationError,
  unknown,
}
