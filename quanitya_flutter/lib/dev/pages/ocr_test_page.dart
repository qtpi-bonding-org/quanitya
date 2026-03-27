import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../infrastructure/config/debug_log.dart';
import 'package:quanitya_flutter/dev/models/ocr_table_model.dart';
import 'package:quanitya_flutter/logic/ingestion/adapters/import_data_source_adapter.dart';
import 'package:quanitya_flutter/logic/llm/services/local_llm_service.dart';
import 'package:quanitya_flutter/logic/ocr/models/extraction_field.dart';
import 'package:quanitya_flutter/logic/ocr/services/ocr_service.dart';
import 'package:quanitya_flutter/logic/ocr/services/template_extraction_schema_builder.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_field.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';

const _tag = 'dev/pages/ocr_test_page';

class OcrTestPage extends StatefulWidget {
  const OcrTestPage({super.key});

  @override
  State<OcrTestPage> createState() => _OcrTestPageState();
}

class _OcrTestPageState extends State<OcrTestPage> {
  // Test template
  final _testTemplate = TrackerTemplateModel(
    id: 'test-receipt',
    name: 'Test Receipt',
    fields: [
      const TemplateField(id: 'item-name', label: 'Item Name', type: FieldEnum.text),
      const TemplateField(id: 'price', label: 'Price', type: FieldEnum.float),
    ],
    updatedAt: DateTime.now(),
  );

  // Services — LLM service is static to survive hot restarts
  // (Metal buffers can't be double-allocated)
  static final _llmService = LocalLlmService();
  final _ocrService = OcrService();
  final _picker = ImagePicker();

  // Extraction schema
  late final List<ExtractionField> _extractionFields;
  late final String _grammar;

  // Model state
  bool _modelLoading = false;
  bool _modelReady = false;
  String? _modelError;
  Duration? _modelLoadDuration;

  // OCR state
  String? _imagePath;
  Duration? _ocrDuration;

  // Table state
  OcrTableModel? _table;
  int? _editingRow;
  int? _editingCol;
  final _editController = TextEditingController();

  // LLM state
  bool _llmRunning = false;
  bool _llmCancelled = false;
  String _llmOutput = '';
  Duration? _llmDuration;

  // Results
  List<Map<String, dynamic>>? _remappedItems;
  List<String>? _validationErrors;
  String? _error;

  @override
  void initState() {
    super.initState();
    _extractionFields = TemplateExtractionSchemaBuilder.buildExtractionFields(
      _testTemplate.fields,
    );
    _grammar = TemplateExtractionSchemaBuilder.buildGrammar(_extractionFields);
    _loadModel();
  }

  @override
  void dispose() {
    _editController.dispose();
    _ocrService.dispose();
    // Don't dispose _llmService — it's static, survives hot restarts
    super.dispose();
  }

  Future<void> _loadModel() async {
    // Already loaded (survives hot restart via static)
    if (_llmService.isReady) {
      setState(() { _modelReady = true; _modelLoading = false; });
      return;
    }
    setState(() { _modelLoading = true; _modelError = null; });
    final sw = Stopwatch()..start();
    try {
      await _llmService.loadModel();
      sw.stop();
      setState(() { _modelReady = true; _modelLoading = false; _modelLoadDuration = sw.elapsed; });
    } catch (e) {
      sw.stop();
      setState(() {
        _modelError = e is TimeoutException ? (e.message ?? 'Timed out') : 'Load failed: $e';
        _modelLoading = false;
      });
    }
  }

  Future<void> _pickAndOcr(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() {
        _imagePath = image.path;
        _table = null;
        _ocrDuration = null;
        _llmOutput = '';
        _llmDuration = null;
        _remappedItems = null;
        _validationErrors = null;
        _error = null;
        _editingRow = null;
        _editingCol = null;
      });

      final sw = Stopwatch()..start();
      final text = await _ocrService.recognizeText(image.path);
      sw.stop();

      Log.d(_tag, '=== OCR: done in ${sw.elapsedMilliseconds}ms ===');
      Log.d(_tag, text);

      setState(() {
        _table = OcrTableModel.fromOcrText(text);
        _ocrDuration = sw.elapsed;
      });
    } catch (e) {
      setState(() => _error = 'OCR failed: $e');
    }
  }

  void _startEditing(int row, int col) {
    setState(() {
      _editingRow = row;
      _editingCol = col;
      _editController.text = _table!.getCell(row, col);
    });
  }

  void _finishEditing() {
    if (_editingRow != null && _editingCol != null && _table != null) {
      _table!.updateCell(_editingRow!, _editingCol!, _editController.text);
    }
    setState(() { _editingRow = null; _editingCol = null; });
  }

  void _deleteRow(int index) {
    _finishEditing();
    setState(() => _table!.deleteRow(index));
  }

  void _deleteColumn(int index) {
    _finishEditing();
    setState(() => _table!.deleteColumn(index));
  }

  Future<void> _extract() async {
    _finishEditing();
    final text = _table?.toText();
    Log.d(_tag, '=== TABLE toText() START ===');
    Log.d(_tag, text ?? '');
    Log.d(_tag, '=== TABLE toText() END (${text?.length} chars) ===');
    if (text == null || text.isEmpty) {
      setState(() => _error = 'No data to extract');
      return;
    }
    await _runLlm(text);
  }

  void _cancelLlm() {
    if (_llmRunning) _llmCancelled = true;
  }

  Future<void> _runLlm(String ocrText) async {
    if (!_llmService.isReady) return;
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
      final prompt = TemplateExtractionSchemaBuilder.buildPrompt(
        ocrText: ocrText,
        fields: _extractionFields,
      );
      Log.d(_tag, '=== LLM PROMPT ===\n$prompt');

      final sw = Stopwatch()..start();
      final rawOutput = await _llmService.generate(
        prompt: prompt,
        grammar: _grammar,
        isCancelled: () => _llmCancelled,
      );
      sw.stop();

      Log.d(_tag, '=== LLM OUTPUT (${sw.elapsedMilliseconds}ms) ===\n$rawOutput');

      if (!mounted) return;
      setState(() { _llmOutput = rawOutput; _llmDuration = sw.elapsed; _llmRunning = false; });

      // Parse
      List<Map<String, dynamic>> parsedItems;
      try {
        final decoded = jsonDecode(rawOutput);
        parsedItems = decoded is List
            ? decoded.cast<Map<String, dynamic>>()
            : [decoded as Map<String, dynamic>];
      } catch (e) {
        if (mounted) setState(() => _error = 'JSON parse failed: $e');
        return;
      }

      // Remap
      final remapped = TemplateExtractionSchemaBuilder.remapLabelsToIds(parsedItems, _extractionFields);

      // Validate
      final adapter = ImportDataSourceAdapter(_testTemplate, _extractionFields);
      final allErrors = <String>[];
      for (var i = 0; i < remapped.length; i++) {
        final errors = adapter.validate(remapped[i]);
        if (errors.isNotEmpty) allErrors.addAll(errors.map((e) => 'item[$i]: $e'));
      }

      if (mounted) {
        setState(() {
          _remappedItems = remapped;
          _validationErrors = allErrors.isEmpty ? null : allErrors;
        });
      }
    } on TimeoutException catch (e) {
      if (mounted) setState(() { _error = e.message ?? 'Timed out'; _llmRunning = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'LLM failed: $e'; _llmRunning = false; });
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
      body: GestureDetector(
        onTap: () {
          // Finish editing when tapping outside
          if (_editingRow != null) _finishEditing();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildModelStatus(),
            const SizedBox(height: 8),
            _buildTemplateInfo(),
            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickAndOcr(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickAndOcr(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
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

            // Table editor
            if (_table != null && !_table!.isEmpty) ...[
              _sectionHeader('OCR Table', '${_ocrDuration?.inMilliseconds}ms — ${_table!.rowCount} rows x ${_table!.columnCount} cols'),
              const SizedBox(height: 4),
              _buildTable(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_modelReady && !_llmRunning) ? _extract : null,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Extract with LLM'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // LLM running
            if (_llmRunning)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _cancelLlm,
                      icon: const Icon(Icons.stop, color: Colors.red, size: 16),
                      label: const Text('Stop', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),

            // LLM output
            if (_llmOutput.isNotEmpty) ...[
              _sectionHeader('LLM Output', '${_llmDuration?.inMilliseconds ?? "?"}ms'),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                child: SelectableText(_llmOutput, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
              ),
              const SizedBox(height: 16),
            ],

            // Extracted items
            if (_remappedItems != null) ...[
              _sectionHeader(
                'Extracted (${_remappedItems!.length})',
                _validationErrors == null ? 'all valid' : '${_validationErrors!.length} errors',
              ),
              const SizedBox(height: 4),
              ..._remappedItems!.asMap().entries.map((e) => _buildItemCard(e.key, e.value)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _llmOutput = '';
                  _llmDuration = null;
                  _remappedItems = null;
                  _validationErrors = null;
                }),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Back to table'),
              ),
              const SizedBox(height: 16),
            ],

            // Validation errors
            if (_validationErrors != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _validationErrors!
                      .map((e) => Text(e, style: TextStyle(fontSize: 11, color: Colors.orange.shade800)))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Error
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                child: SelectableText(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  // ── Table Widget ──────────────────────────────────────────────────────

  Widget _buildTable() {
    final table = _table!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column delete header row
          Row(
            children: [
              const SizedBox(width: 32), // spacer for row delete buttons
              for (var col = 0; col < table.columnCount; col++)
                SizedBox(
                  width: 120,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _deleteColumn(col),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close, size: 12, color: Colors.red.shade400),
                            const SizedBox(width: 2),
                            Text('Col ${col + 1}', style: TextStyle(fontSize: 10, color: Colors.red.shade400)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Data rows
          for (var row = 0; row < table.rowCount; row++)
            Row(
              children: [
                // Row delete button
                GestureDetector(
                  onTap: () => _deleteRow(row),
                  child: Container(
                    width: 28,
                    height: 36,
                    alignment: Alignment.center,
                    child: Icon(Icons.close, size: 14, color: Colors.red.shade400),
                  ),
                ),
                const SizedBox(width: 4),
                // Cells
                for (var col = 0; col < table.columnCount; col++)
                  _buildCell(row, col),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCell(int row, int col) {
    final isEditing = _editingRow == row && _editingCol == col;
    final value = _table!.getCell(row, col);

    return GestureDetector(
      onTap: () => _startEditing(row, col),
      child: Container(
        width: 120,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: isEditing ? Colors.deepPurple : Colors.grey.shade300,
            width: isEditing ? 2 : 0.5,
          ),
          color: value.trim().isEmpty ? Colors.grey.shade50 : Colors.white,
        ),
        alignment: Alignment.centerLeft,
        child: isEditing
            ? TextField(
                controller: _editController,
                autofocus: true,
                style: const TextStyle(fontSize: 11),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _finishEditing(),
              )
            : Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  color: value.trim().isEmpty ? Colors.grey.shade400 : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }

  // ── Result Card ───────────────────────────────────────────────────────

  Widget _buildItemCard(int index, Map<String, dynamic> item) {
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
          Text('Item $index', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ...item.entries.map((e) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(
                  '${e.key}: ${e.value ?? "null"}',
                  style: const TextStyle(fontSize: 12),
                ),
              )),
        ],
      ),
    );
  }

  // ── Shared Widgets ────────────────────────────────────────────────────

  Widget _buildModelStatus() {
    Color bg;
    String text;
    if (_modelLoading) {
      bg = Colors.orange.shade100;
      text = 'Loading model...';
    } else if (_modelReady) {
      bg = Colors.green.shade100;
      text = 'Model ready (${_modelLoadDuration?.inMilliseconds}ms)';
    } else if (_modelError != null) {
      bg = Colors.red.shade100;
      text = _modelError!;
    } else {
      bg = Colors.grey.shade100;
      text = 'Model not loaded';
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          if (_modelLoading)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          if (_modelReady)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.check_circle, color: Colors.green.shade700, size: 14),
            ),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
          if (_modelError != null)
            IconButton(icon: const Icon(Icons.refresh, size: 16), onPressed: _loadModel, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ],
      ),
    );
  }

  Widget _buildTemplateInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(6)),
      child: Text(
        '${_testTemplate.name}: ${_extractionFields.map((f) => f.label).join(', ')}',
        style: TextStyle(fontSize: 11, color: Colors.purple.shade700),
      ),
    );
  }

  Widget _sectionHeader(String title, String? subtitle) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ],
    );
  }
}
