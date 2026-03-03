import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import 'template_sharing_import_state.dart';

@injectable
class TemplateSharingImportMessageMapper
    implements IStateMessageMapper<TemplateSharingImportState> {
  @override
  MessageKey? map(TemplateSharingImportState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        TemplateSharingImportOperation.preview =>
          MessageKey.info('template.sharing.preview_loaded'),
        TemplateSharingImportOperation.confirmImport =>
          MessageKey.success('template.sharing.imported'),
        TemplateSharingImportOperation.clear => null,
      };
    }
    return null;
  }
}
