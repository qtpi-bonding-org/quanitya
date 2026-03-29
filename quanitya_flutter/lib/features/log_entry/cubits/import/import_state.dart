import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../logic/templates/models/shared/tracker_template.dart';

part 'import_state.freezed.dart';

@freezed
abstract class ImportState with _$ImportState {
  const ImportState._();
  const factory ImportState.idle() = ImportIdle;
  const factory ImportState.modelRequired({
    required ImageSource source,
    required TrackerTemplateModel template,
  }) = ImportModelRequired;
  const factory ImportState.downloading({required double progress}) =
      ImportDownloading;
  const factory ImportState.picking() = ImportPicking;
  const factory ImportState.processing() = ImportProcessing;
  const factory ImportState.singleResult({
    required Map<String, dynamic> item,
    DateTime? extractedDate,
  }) = ImportSingleResult;
  const factory ImportState.multipleResults({
    required List<Map<String, dynamic>> items,
    required List<DateTime?> extractedDates,
  }) = ImportMultipleResults;
  const factory ImportState.importing() = ImportImporting;
  const factory ImportState.done({required int count}) = ImportDone;
  const factory ImportState.error({required String message}) = ImportError;
}
