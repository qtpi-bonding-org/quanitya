import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'template_gallery_state.dart';

@injectable
class TemplateGalleryMessageMapper implements IStateMessageMapper<TemplateGalleryState> {
  @override
  MessageKey? map(TemplateGalleryState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        TemplateGalleryOperation.load => null,
        TemplateGalleryOperation.preview => null,
        TemplateGalleryOperation.import_ => MessageKey.success(L10nKeys.catalogTemplatesImported),
      };
    }
    return null;
  }
}
