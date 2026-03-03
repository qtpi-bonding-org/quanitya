import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../../logic/templates/services/sharing/template_import_service.dart';
import 'template_sharing_import_state.dart';

@injectable
class TemplateSharingImportCubit
    extends QuanityaCubit<TemplateSharingImportState> {
  final TemplateImportService _importService;

  TemplateSharingImportCubit(this._importService)
      : super(const TemplateSharingImportState());

  /// Preview a template from a URL without importing.
  Future<void> previewFromUrl(String url) async {
    await tryOperation(() async {
      final preview = await _importService.previewFromUrl(url);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: TemplateSharingImportOperation.preview,
        previewUrl: url,
        previewTemplate: preview,
      );
    }, emitLoading: true);
  }

  /// Confirm import of the previously previewed template.
  Future<void> confirmImport() async {
    final url = state.previewUrl;
    if (url == null) return;

    await tryOperation(() async {
      final imported = await _importService.importFromUrl(url);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: TemplateSharingImportOperation.confirmImport,
        importedTemplate: imported,
      );
    }, emitLoading: true);
  }

  /// Clear the current preview and reset to initial state.
  void clearPreview() {
    emit(const TemplateSharingImportState());
  }
}
