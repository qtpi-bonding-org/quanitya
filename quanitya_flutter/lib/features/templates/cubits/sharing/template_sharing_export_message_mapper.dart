import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'template_sharing_export_state.dart';

@injectable
class TemplateSharingExportMessageMapper
    implements IStateMessageMapper<TemplateSharingExportState> {
  @override
  MessageKey? map(TemplateSharingExportState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        TemplateSharingExportOperation.export =>
          MessageKey.success(L10nKeys.templateSharingExported),
        TemplateSharingExportOperation.loadPipelines => null,
      };
    }
    return null;
  }
}
