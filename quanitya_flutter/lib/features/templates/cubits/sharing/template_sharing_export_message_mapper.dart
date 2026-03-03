import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import 'template_sharing_export_state.dart';

@injectable
class TemplateSharingExportMessageMapper
    implements IStateMessageMapper<TemplateSharingExportState> {
  @override
  MessageKey? map(TemplateSharingExportState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        TemplateSharingExportOperation.export =>
          MessageKey.success('template.sharing.exported'),
        TemplateSharingExportOperation.loadPipelines => null,
      };
    }
    return null;
  }
}
