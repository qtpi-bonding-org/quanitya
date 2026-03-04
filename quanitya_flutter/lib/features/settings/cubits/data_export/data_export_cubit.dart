import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../../data/repositories/data_export_repository.dart';
import 'data_export_state.dart';

@injectable
class DataExportCubit extends QuanityaCubit<DataExportState> {
  final DataExportRepository _exportRepo;

  DataExportCubit(this._exportRepo) : super(const DataExportState());

  /// Returns all exportable table names for the selection dialog.
  List<String> getExportableTableNames() {
    return _exportRepo.getExportableTableNames();
  }

  /// Export selected tables as JSON via share sheet.
  Future<void> exportData(Set<String> selectedTables) async {
    await tryOperation(() async {
      final result = await _exportRepo.exportData(selectedTables);

      if (result == DataExportResult.success) {
        analytics?.trackDataExported();
        return state.copyWith(
          status: UiFlowStatus.success,
          lastOperation: DataExportOperation.export,
        );
      }

      // Cancelled - return to idle, no message
      return state.copyWith(status: UiFlowStatus.idle);
    }, emitLoading: true);
  }

  /// Pick an import file and return the table names found in it.
  ///
  /// Returns null if the user cancelled or an error occurred.
  Future<List<String>?> pickImportFile() async {
    try {
      return await _exportRepo.parseImportFile();
    } on ImportCancelledException {
      return null;
    } catch (e) {
      emit(createErrorState(e));
      return null;
    }
  }

  /// Import selected tables from the previously picked file.
  Future<void> importData(Set<String> selectedTables) async {
    await tryOperation(() async {
      await _exportRepo.importData(selectedTables);
      analytics?.trackDataImported();
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: DataExportOperation.importData,
      );
    }, emitLoading: true);
  }
}
