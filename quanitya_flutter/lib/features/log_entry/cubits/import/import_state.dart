import 'package:freezed_annotation/freezed_annotation.dart';

part 'import_state.freezed.dart';

@freezed
abstract class ImportState with _$ImportState {
  const ImportState._();
  const factory ImportState.idle() = ImportIdle;
  const factory ImportState.picking() = ImportPicking;
  const factory ImportState.processing() = ImportProcessing;
  const factory ImportState.singleResult({
    required Map<String, dynamic> item,
  }) = ImportSingleResult;
  const factory ImportState.multipleResults({
    required List<Map<String, dynamic>> items,
  }) = ImportMultipleResults;
  const factory ImportState.importing() = ImportImporting;
  const factory ImportState.done({required int count}) = ImportDone;
  const factory ImportState.error({required String message}) = ImportError;
}
