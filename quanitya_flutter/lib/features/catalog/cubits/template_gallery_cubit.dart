import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../models/catalog_data.dart';
import '../services/template_catalog_service.dart';
import '../../../logic/templates/models/shared/shareable_template.dart';
import '../../../logic/templates/services/sharing/template_import_service.dart';
import 'template_gallery_state.dart';

export 'template_gallery_state.dart';

/// Cubit for the template gallery page.
///
/// Manages catalog loading, category filtering, template selection,
/// preview fetching, and batch importing of community templates.
@injectable
class TemplateGalleryCubit extends QuanityaCubit<TemplateGalleryState> {
  final TemplateCatalogService _catalogService;
  final TemplateImportService _importService;

  TemplateGalleryCubit(this._catalogService, this._importService)
      : super(const TemplateGalleryState());

  /// Load the template catalog from the remote repository.
  Future<void> loadCatalog() => tryOperation(() async {
        final catalog = await _catalogService.fetchCatalog();
        return state.copyWith(
          status: UiFlowStatus.success,
          lastOperation: TemplateGalleryOperation.load,
          catalog: catalog,
        );
      }, emitLoading: true);

  /// Filter templates by category. Pass `null` to show all.
  void selectCategory(String? categoryId) {
    emit(state.copyWith(selectedCategory: categoryId));
  }

  /// Returns templates filtered by the currently selected category.
  List<CatalogEntry> get filteredTemplates {
    final templates = state.catalog?.templates ?? [];
    if (state.selectedCategory == null) return templates;
    return templates
        .where((t) => t.category == state.selectedCategory)
        .toList();
  }

  /// Toggle selection of a template by slug.
  void toggleSelection(String slug) {
    final updated = Set<String>.from(state.selectedSlugs);
    if (updated.contains(slug)) {
      updated.remove(slug);
    } else {
      updated.add(slug);
    }
    emit(state.copyWith(selectedSlugs: updated));
  }

  /// Whether a template is currently selected.
  bool isSelected(String slug) => state.selectedSlugs.contains(slug);

  /// Fetch and cache a template preview for detail display.
  Future<ShareableTemplate> fetchPreview(String slug) async {
    if (state.previewCache.containsKey(slug)) {
      return state.previewCache[slug]!;
    }
    final template = await _catalogService.fetchTemplate(slug);
    final updatedCache =
        Map<String, ShareableTemplate>.from(state.previewCache);
    updatedCache[slug] = template;
    emit(state.copyWith(previewCache: updatedCache));
    return template;
  }

  /// Import all currently selected templates.
  Future<void> importSelected() => tryOperation(() async {
        for (final slug in state.selectedSlugs) {
          final url = _catalogService.getTemplateUrl(slug);
          try {
            await _importService.importFromUrl(url);
          } catch (_) {
            // Skip individual failures, continue importing others.
            continue;
          }
        }
        return state.copyWith(
          status: UiFlowStatus.success,
          lastOperation: TemplateGalleryOperation.import_,
        );
      }, emitLoading: true);

  /// Number of currently selected templates.
  int get selectedCount => state.selectedSlugs.length;
}
