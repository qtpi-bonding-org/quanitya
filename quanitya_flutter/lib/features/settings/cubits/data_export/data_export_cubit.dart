import 'package:injectable/injectable.dart';
import 'package:share_plus/share_plus.dart';
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
  ///
  /// Shows loading overlay only during data preparation (DB queries + JSON
  /// encoding). The overlay is dismissed before the share sheet opens because
  /// `Share.shareXFiles` can hang indefinitely on iOS until the share sheet
  /// is fully dismissed by the user.
  Future<void> exportData(Set<String> selectedTables) async {
    // Step 1: Prepare export file under loading overlay.
    XFile? file;
    await tryOperation(() async {
      file = await _exportRepo.prepareExportFile(selectedTables);
      return state.copyWith(status: UiFlowStatus.idle);
    }, emitLoading: true);

    // If preparation failed, tryOperation already emitted error state
    // and file will still be null.
    if (file == null) return;

    // Step 2: Open share sheet WITHOUT loading overlay.
    // Share.shareXFiles can block indefinitely on iOS.
    try {
      final result = await _exportRepo.shareExportFile(file!);

      if (result == DataExportResult.success) {
        analytics?.trackDataExported();
        emit(state.copyWith(
          status: UiFlowStatus.success,
          lastOperation: DataExportOperation.export,
        ));
      }
      // Cancelled/failed — stay idle, no message needed.
    } catch (e) {
      emit(createErrorState(e));
    }
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
