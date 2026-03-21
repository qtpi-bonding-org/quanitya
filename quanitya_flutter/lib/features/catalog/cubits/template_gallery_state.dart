import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/catalog_data.dart';
import '../../../logic/templates/models/shared/shareable_template.dart';

part 'template_gallery_state.freezed.dart';

enum TemplateGalleryOperation { load, preview, import_ }

@freezed
class TemplateGalleryState
    with _$TemplateGalleryState, UiFlowStateMixin
    implements IUiFlowState {
  const TemplateGalleryState._();

  const factory TemplateGalleryState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    TemplateGalleryOperation? lastOperation,
    CatalogData? catalog,
    @Default(null) String? selectedCategory,
    @Default({}) Set<String> selectedSlugs,
    @Default({}) Map<String, ShareableTemplate> previewCache,
    @Default(0) int importedCount,
    @Default(0) int failedCount,
  }) = _TemplateGalleryState;
}
