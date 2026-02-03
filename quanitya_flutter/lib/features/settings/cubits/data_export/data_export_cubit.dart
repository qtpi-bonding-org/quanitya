import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../../data/repositories/data_export_repository.dart';
import 'data_export_state.dart';

@injectable
class DataExportCubit extends QuanityaCubit<DataExportState> {
  final DataExportRepository _exportRepo;

  DataExportCubit(this._exportRepo) : super(const DataExportState());

  Future<void> exportData() async {
    await tryOperation(() async {
      final result = await _exportRepo.exportAllData();

      if (result == DataExportResult.success) {
        return state.copyWith(
          status: UiFlowStatus.success,
          lastOperation: DataExportOperation.export,
        );
      }

      // Cancelled - return to idle, no message
      return state.copyWith(status: UiFlowStatus.idle);
    }, emitLoading: true);
  }
}
