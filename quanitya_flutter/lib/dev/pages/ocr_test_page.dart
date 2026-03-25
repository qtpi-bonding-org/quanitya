import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quanitya_flutter/logic/ingestion/adapters/ocr_data_source_adapter.dart';
import 'package:quanitya_flutter/logic/llm/services/local_llm_service.dart';
import 'package:quanitya_flutter/logic/ocr/models/extraction_field.dart';
import 'package:quanitya_flutter/logic/ocr/services/ocr_service.dart';
import 'package:quanitya_flutter/logic/ocr/services/template_extraction_schema_builder.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_field.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';

class OcrTestPage extends StatefulWidget {
  const OcrTestPage({super.key});

  @override
  State<OcrTestPage> createState() => _OcrTestPageState();
}

class _OcrTestPageState extends State<OcrTestPage> {
  // Test template with known field IDs
  final _testTemplate = TrackerTemplateModel(
    id: 'test-receipt',
    name: 'Test Receipt',
    fields: [
      const TemplateField(
        id: 'item-name',
        label: 'Item Name',
        type: FieldEnum.text,
      ),
      const TemplateField(
        id: 'price',
        label: 'Price',
        type: FieldEnum.float,
      ),
    ],
    updatedAt: DateTime.now(),
  );

  // Services — instantiated directly (no DI, dev page only)
  final _ocrService = OcrService();
  final _llmService = LocalLlmService();
  final _picker = ImagePicker();

  // Extraction schema built once in initState
  late final List<ExtractionField> _extractionFields;
  late final String _grammar;

  // Model state
  bool _modelLoading = false;
  bool _modelReady = false;
  String? _modelError;
  Duration? _modelLoadDuration;

  // OCR state
  String? _imagePath;
  String? _ocrText;
  Duration? _ocrDuration;

  // LLM state
  bool _llmRunning = false;
  bool _llmCancelled = false;
  String _llmOutput = '';
  Duration? _llmDuration;

  // Pipeline results
  List<Map<String, dynamic>>? _remappedItems;
  List<String>? _validationErrors;

  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint('=== OCR TEST PAGE: initState ===');

    // Build extraction schema from test template fields once
    _extractionFields = TemplateExtractionSchemaBuilder.buildExtractionFields(
      _testTemplate.fields,
    );
    _grammar = TemplateExtractionSchemaBuilder.buildGrammar(_extractionFields);

    debugPrint('=== OCR TEST PAGE: ${_extractionFields.length} extraction fields ===');
    debugPrint('=== OCR TEST PAGE: grammar built (${_grammar.length} chars) ===');

    _loadModel();
  }

  @override
  void dispose() {
    debugPrint('=== OCR TEST PAGE: dispose ===');
    _ocrService.dispose();
    _llmService.dispose();
    super.dispose();
  }

  Future<void> _loadModel() async {
    debugPrint('=== LLM: starting model load ===');
    setState(() {
      _modelLoading = true;
      _modelError = null;
    });

    final sw = Stopwatch()..start();
    try {
      await _llmService.loadModel();
      sw.stop();

      debugPrint('=== LLM: model loaded in ${sw.elapsedMilliseconds}ms ===');
      setState(() {
        _modelReady = true;
        _modelLoading = false;
        _modelLoadDuration = sw.elapsed;
      });
    } on StateError catch (e) {
      // Already loaded — treat as ready (can happen on hot restart)
      sw.stop();
      debugPrint('=== LLM: model already loaded: $e ===');
      setState(() {
        _modelReady = true;
        _modelLoading = false;
        _modelLoadDuration = sw.elapsed;
      });
    } catch (e, stack) {
      sw.stop();
      debugPrint('=== LLM LOAD FAILED: $e ===');
      debugPrint('$stack');
      setState(() {
        _modelError = e is TimeoutException
            ? e.message ?? 'Model load timed out'
            : 'Model load failed: $e';
        _modelLoading = false;
      });
    }
  }

  Future<void> _pickAndOcr(ImageSource source) async {
    debugPrint('=== OCR: picking image from $source ===');
    try {
      final image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() {
        _imagePath = image.path;
        _ocrText = null;
        _ocrDuration = null;
        _llmOutput = '';
        _llmDuration = null;
        _remappedItems = null;
        _validationErrors = null;
        _error = null;
      });

      final sw = Stopwatch()..start();
      final spatialText = await _ocrService.recognizeText(image.path);
      sw.stop();

      debugPrint('=== OCR: done in ${sw.elapsedMilliseconds}ms ===');
      debugPrint('=== OCR TEXT START ===');
      debugPrint(spatialText);
      debugPrint('=== OCR TEXT END ===');

      setState(() {
        _ocrText = spatialText;
        _ocrDuration = sw.elapsed;
      });

      // Auto-run LLM after OCR if model is ready
      if (_modelReady && spatialText.isNotEmpty) {
        debugPrint('=== OCR TEST PAGE: auto-running LLM after OCR ===');
        await _runLlm(spatialText);
      }
    } catch (e, stack) {
      debugPrint('=== OCR FAILED: $e ===');
      debugPrint('$stack');
      setState(() => _error = 'OCR failed: $e');
    }
  }

  void _cancelLlm() {
    if (_llmRunning) {
      debugPrint('=== LLM: cancellation requested ===');
      _llmCancelled = true;
    }
  }

  Future<void> _runLlm(String ocrText) async {
    if (!_llmService.isReady) {
      debugPrint('=== LLM: service not ready, skipping ===');
      return;
    }

    debugPrint('=== LLM: starting full extraction pipeline ===');
    _llmCancelled = false;

    setState(() {
      _llmRunning = true;
      _llmOutput = '';
      _llmDuration = null;
      _remappedItems = null;
      _validationErrors = null;
      _error = null;
    });

    try {
      // Step 1: Build prompt
      final prompt = TemplateExtractionSchemaBuilder.buildPrompt(
        ocrText: ocrText,
        fields: _extractionFields,
      );
      debugPrint('=== LLM PROMPT START ===');
      debugPrint(prompt);
      debugPrint('=== LLM PROMPT END ===');

      // Step 2: Generate with grammar constraint
      final sw = Stopwatch()..start();
      final rawOutput = await _llmService.generate(
        prompt: prompt,
        grammar: _grammar,
        isCancelled: () => _llmCancelled,
      );
      sw.stop();

      debugPrint('=== LLM: done in ${sw.elapsedMilliseconds}ms ===');
      debugPrint('=== LLM OUTPUT START ===');
      debugPrint(rawOutput);
      debugPrint('=== LLM OUTPUT END ===');

      if (!mounted) return;

      setState(() {
        _llmOutput = rawOutput;
        _llmDuration = sw.elapsed;
        _llmRunning = false;
      });

      // Step 3: Parse JSON
      List<Map<String, dynamic>> parsedItems;
      try {
        final decoded = jsonDecode(rawOutput);
        if (decoded is List) {
          parsedItems = decoded.cast<Map<String, dynamic>>();
        } else if (decoded is Map<String, dynamic>) {
          parsedItems = [decoded];
        } else {
          throw FormatException('Unexpected LLM output structure: ${decoded.runtimeType}');
        }
        debugPrint('=== LLM: parsed ${parsedItems.length} items from JSON ===');
      } catch (e) {
        debugPrint('=== LLM: JSON parse failed: $e ===');
        if (mounted) setState(() => _error = 'JSON parse failed: $e');
        return;
      }

      // Step 4: Remap labels to field IDs
      final remapped = TemplateExtractionSchemaBuilder.remapLabelsToIds(
        parsedItems,
        _extractionFields,
      );
      debugPrint('=== LLM: remapped ${remapped.length} items to field IDs ===');
      for (var i = 0; i < remapped.length; i++) {
        debugPrint('=== LLM: item[$i] = ${remapped[i]} ===');
      }

      // Step 5: Validate each item via OcrDataSourceAdapter
      final adapter = OcrDataSourceAdapter(_testTemplate, _extractionFields);
      final allErrors = <String>[];
      for (var i = 0; i < remapped.length; i++) {
        final errors = adapter.validate(remapped[i]);
        if (errors.isNotEmpty) {
          debugPrint('=== LLM: validation errors for item[$i]: $errors ===');
          allErrors.addAll(errors.map((e) => 'item[$i]: $e'));
        } else {
          debugPrint('=== LLM: item[$i] passed validation ===');
        }
      }

      if (mounted) {
        setState(() {
          _remappedItems = remapped;
          _validationErrors = allErrors.isEmpty ? null : allErrors;
        });
      }
    } on TimeoutException catch (e) {
      debugPrint('=== LLM TIMEOUT: $e ===');
      if (mounted) {
        setState(() {
          _error = e.message ?? 'LLM timed out';
          _llmRunning = false;
        });
      }
    } catch (e, stack) {
      debugPrint('=== LLM FAILED: $e ===');
      debugPrint('$stack');
      if (mounted) {
        setState(() {
          _error = 'LLM failed: $e';
          _llmRunning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('OCR + LLM Test'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Model status
          _buildModelStatus(),
          const SizedBox(height: 8),

          // Template info
          _buildTemplateInfo(),
          const SizedBox(height: 16),

          // Image picker buttons
          ElevatedButton.icon(
            onPressed: () => _pickAndOcr(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _pickAndOcr(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
          ),
          const SizedBox(height: 16),

          // Image preview
          if (_imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(_imagePath!), height: 200, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
          ],

          // OCR result
          if (_ocrText != null) ...[
            _sectionHeader('OCR Result', '${_ocrDuration?.inMilliseconds}ms'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                _ocrText!,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // LLM status + cancel button
          if (_llmRunning)
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _cancelLlm,
                    icon: const Icon(Icons.stop, color: Colors.red),
                    label: const Text(
                      'Stop inference',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // LLM raw output
          if (_llmOutput.isNotEmpty) ...[
            _sectionHeader(
              'LLM Raw Output',
              _llmDuration != null ? '${_llmDuration!.inMilliseconds}ms' : 'streaming...',
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                _llmOutput,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Remapped + validated items
          if (_remappedItems != null) ...[
            _sectionHeader(
              'Extracted Items (${_remappedItems!.length})',
              _validationErrors == null ? 'valid' : '${_validationErrors!.length} errors',
            ),
            const SizedBox(height: 4),
            ..._buildExtractedItems(_remappedItems!),
            const SizedBox(height: 16),
          ],

          // Validation errors
          if (_validationErrors != null && _validationErrors!.isNotEmpty) ...[
            _sectionHeader('Validation Errors', null),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _validationErrors!
                    .map((e) => Text(
                          e,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Re-run LLM button (retry without re-scanning)
          if (_ocrText != null && _modelReady && !_llmRunning)
            OutlinedButton.icon(
              onPressed: () => _runLlm(_ocrText!),
              icon: const Icon(Icons.refresh),
              label: const Text('Re-run LLM'),
            ),

          // Error
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModelStatus() {
    Color bgColor;
    String text;

    if (_modelLoading) {
      bgColor = Colors.orange.shade100;
      text = 'Loading model... (first time copies 469MB from assets)';
    } else if (_modelReady) {
      bgColor = Colors.green.shade100;
      text = 'Model ready (loaded in ${_modelLoadDuration?.inMilliseconds}ms)';
    } else if (_modelError != null) {
      bgColor = Colors.red.shade100;
      text = _modelError!;
    } else {
      bgColor = Colors.grey.shade100;
      text = 'Model not loaded';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (_modelLoading)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (_modelReady)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.check_circle, color: Colors.green, size: 16),
            ),
          if (_modelError != null)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.error, color: Colors.red, size: 16),
            ),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          if (_modelError != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _loadModel,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildTemplateInfo() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Template: ${_testTemplate.name}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            'Fields: ${_extractionFields.map((f) => '${f.label} (${f.type.name})').join(', ')}',
            style: TextStyle(fontSize: 11, color: Colors.purple.shade700),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String? subtitle) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildExtractedItems(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return [
        Text(
          'No items extracted.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ];
    }
    return items.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item $idx',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            ...item.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.key}: ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${e.value ?? "null"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: e.value == null ||
                                    (e.value is String && (e.value as String).isEmpty)
                                ? Colors.grey
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );
    }).toList();
  }
}
