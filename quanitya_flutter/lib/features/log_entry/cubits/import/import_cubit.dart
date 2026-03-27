import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import '../../../../infrastructure/config/debug_log.dart';

import '../../../../logic/import/services/import_executor.dart';

const _tag = 'features/log_entry/cubits/import/import_cubit';
import '../../../../logic/import/services/timestamp_resolver.dart';
import '../../../../logic/llm/services/local_llm_service.dart';
import '../../../../logic/ocr/services/ocr_service.dart';
import '../../../../logic/ocr/services/template_extraction_schema_builder.dart';
import '../../../../logic/templates/models/shared/tracker_template.dart';
import 'import_state.dart';

@injectable
class ImportCubit extends Cubit<ImportState> {
  final OcrService _ocrService;
  final LocalLlmService _llmService;
  final ImportExecutor _importExecutor;
  final ImagePicker _picker;

  ImportCubit(
    this._ocrService,
    this._llmService,
    this._importExecutor,
  )   : _picker = ImagePicker(),
        super(const ImportState.idle());

  Future<void> importFromImage({
    required ImageSource source,
    required TrackerTemplateModel template,
  }) async {
    try {
      emit(const ImportState.picking());
      final image = await _picker.pickImage(source: source);
      if (image == null) {
        emit(const ImportState.idle());
        return;
      }

      emit(const ImportState.processing());
      final extractionFields =
          TemplateExtractionSchemaBuilder.buildExtractionFields(template.fields);
      if (extractionFields.isEmpty) {
        emit(const ImportState.error(message: 'No extractable fields in template'));
        return;
      }

      final grammar = TemplateExtractionSchemaBuilder.buildGrammar(extractionFields);
      final ocrText = await _ocrService.recognizeText(image.path);
      if (ocrText.trim().isEmpty) {
        emit(const ImportState.error(message: 'No text detected in image'));
        return;
      }

      final prompt = TemplateExtractionSchemaBuilder.buildPrompt(
        ocrText: ocrText,
        fields: extractionFields,
      );

      if (!_llmService.isReady) {
        await _llmService.loadModel();
      }

      final rawOutput = await _llmService.generate(
        prompt: prompt,
        grammar: grammar,
      );

      final decoded = jsonDecode(rawOutput);
      List<Map<String, dynamic>> parsedItems;
      if (decoded is List) {
        parsedItems = decoded.cast<Map<String, dynamic>>();
      } else if (decoded is Map<String, dynamic>) {
        parsedItems = [decoded];
      } else {
        emit(const ImportState.error(message: 'Unexpected LLM output format'));
        return;
      }

      final remapped = TemplateExtractionSchemaBuilder.remapLabelsToIds(
        parsedItems,
        extractionFields,
      );

      final nonEmpty = remapped.where((item) {
        return item.values.any((v) =>
            v != null && (v is! String || v.trim().isNotEmpty));
      }).toList();

      if (nonEmpty.isEmpty) {
        emit(const ImportState.error(message: 'No items extracted from image'));
        return;
      }

      Log.d(_tag,'=== ImportCubit: extracted ${nonEmpty.length} items ===');
      if (nonEmpty.length == 1) {
        emit(ImportState.singleResult(item: nonEmpty.first));
      } else {
        emit(ImportState.multipleResults(items: nonEmpty));
      }
    } catch (e) {
      Log.d(_tag,'=== ImportCubit: error: $e ===');
      emit(ImportState.error(message: 'Import failed: $e'));
    }
  }

  Future<void> executeBulkImport({
    required String templateId,
    required TrackerTemplateModel template,
    required List<Map<String, dynamic>> items,
    required DateTime batchTimestamp,
  }) async {
    try {
      emit(const ImportState.importing());

      final extractionFields =
          TemplateExtractionSchemaBuilder.buildExtractionFields(template.fields);

      final resolved = TimestampResolver.resolve(
        items: items,
        batchTimestamp: batchTimestamp,
      );

      final count = await _importExecutor.execute(
        templateId: templateId,
        template: template,
        items: resolved,
        extractionFields: extractionFields,
      );

      emit(ImportState.done(count: count));
    } catch (e) {
      Log.d(_tag,'=== ImportCubit: bulk import error: $e ===');
      emit(ImportState.error(message: 'Import failed: $e'));
    }
  }

  void reset() => emit(const ImportState.idle());
}
