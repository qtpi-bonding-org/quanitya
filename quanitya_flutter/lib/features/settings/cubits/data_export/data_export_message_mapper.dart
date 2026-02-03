import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import 'data_export_state.dart';

@injectable
class DataExportMessageMapper implements IStateMessageMapper<DataExportState> {
  @override
  MessageKey? map(DataExportState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        DataExportOperation.export => MessageKey.success('settings.export.success'),
      };
    }
    return null;
  }
}
