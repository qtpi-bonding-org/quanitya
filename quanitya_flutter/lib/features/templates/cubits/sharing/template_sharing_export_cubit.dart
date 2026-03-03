import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../../logic/templates/services/sharing/template_export_service.dart';
import '../../../../logic/templates/models/shared/shareable_template.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart';
import 'template_sharing_export_state.dart';

@injectable
class TemplateSharingExportCubit
    extends QuanityaCubit<TemplateSharingExportState> {
  final TemplateExportService _exportService;

  TemplateSharingExportCubit(this._exportService)
      : super(const TemplateSharingExportState());

  /// Load available analysis pipelines for a template field.
  Future<void> loadAvailablePipelines(String fieldId) async {
    await tryOperation(() async {
      final pipelines = await _exportService.getAvailablePipelines(fieldId);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: TemplateSharingExportOperation.loadPipelines,
        availablePipelines: pipelines,
      );
    }, emitLoading: true);
  }

  /// Export a template as shareable JSON and open share sheet.
  Future<void> exportTemplate({
    required TemplateWithAesthetics templateWithAesthetics,
    required AuthorCredit author,
    String? description,
    List<String>? pipelineIds,
  }) async {
    await tryOperation(() async {
      final jsonString = await _exportService.exportTemplate(
        templateWithAesthetics: templateWithAesthetics,
        author: author,
        description: description,
        includedPipelineIds: pipelineIds,
      );

      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      final filename =
          '${templateWithAesthetics.template.name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '_').toLowerCase()}_template.json';

      final result = await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: filename,
            mimeType: 'application/json',
          ),
        ],
        subject: 'Quanitya Template',
      );

      switch (result.status) {
        case ShareResultStatus.success:
          analytics?.trackTemplateExported();
          return state.copyWith(
            status: UiFlowStatus.success,
            lastOperation: TemplateSharingExportOperation.export,
            shareResult: TemplateShareResult.success,
            exportedJson: jsonString,
          );
        case ShareResultStatus.dismissed:
          return state.copyWith(
            status: UiFlowStatus.idle,
            shareResult: TemplateShareResult.dismissed,
          );
        case ShareResultStatus.unavailable:
          return state.copyWith(
            status: UiFlowStatus.idle,
            shareResult: TemplateShareResult.unavailable,
          );
      }
    }, emitLoading: true);
  }
}
