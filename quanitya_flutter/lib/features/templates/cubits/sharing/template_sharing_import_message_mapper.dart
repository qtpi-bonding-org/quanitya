import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'template_sharing_import_state.dart';

@injectable
class TemplateSharingImportMessageMapper
    implements IStateMessageMapper<TemplateSharingImportState> {
  @override
  MessageKey? map(TemplateSharingImportState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        TemplateSharingImportOperation.preview =>
          MessageKey.info(L10nKeys.templateSharingPreviewLoaded),
        TemplateSharingImportOperation.confirmImport =>
          MessageKey.success(L10nKeys.templateSharingImported),
        TemplateSharingImportOperation.clear => null,
      };
    }
    return null;
  }
}
