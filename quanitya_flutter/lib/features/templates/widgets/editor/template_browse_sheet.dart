import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:get_it/get_it.dart';

import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../design_system/widgets/quanitya_text_field.dart';
import '../../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../logic/templates/services/sharing/template_import_service.dart';
import '../../../catalog/cubits/template_gallery_cubit.dart';
import '../../../catalog/widgets/template_gallery_widget.dart';
import '../../cubits/editor/template_editor_cubit.dart';

/// Combined browse sheet: URL import at top, community gallery below.
///
/// Both paths load the template into the editor cubit (in memory)
/// rather than saving directly to the database.
class TemplateBrowseSheet {
  TemplateBrowseSheet._();

  static Future<void> show(BuildContext context) {
    final editorCubit = context.read<TemplateEditorCubit>();

    return LooseInsertSheet.show(
      context: context,
      title: context.l10n.browseTemplatesTitle,
      builder: (sheetContext) => _BrowseContent(
        editorCubit: editorCubit,
        onDone: () => Navigator.pop(sheetContext),
      ),
    );
  }
}

class _BrowseContent extends StatefulWidget {
  final TemplateEditorCubit editorCubit;
  final VoidCallback onDone;

  const _BrowseContent({
    required this.editorCubit,
    required this.onDone,
  });

  @override
  State<_BrowseContent> createState() => _BrowseContentState();
}

class _BrowseContentState extends State<_BrowseContent> {
  final _urlController = TextEditingController();
  final _importService = GetIt.I<TemplateImportService>();
  bool _isLoadingUrl = false;
  String? _urlError;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // URL import section
          Padding(
            padding: AppPadding.allSingle,
            child: _buildUrlSection(context),
          ),

          Divider(
            color: context.colors.textSecondary.withValues(alpha: 0.15),
          ),

          // Gallery section
          Expanded(
            child: _buildGallerySection(context),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.importTemplateUrlSection,
          style: context.text.titleSmall?.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
        VSpace.x1,
        Row(
          children: [
            Expanded(
              child: QuanityaTextField(
                controller: _urlController,
                hintText: context.l10n.templateImportUrlHint,
                keyboardType: TextInputType.url,
                onSubmitted: (_) => _importFromUrl(context),
              ),
            ),
            HSpace.x1,
            QuanityaTextButton(
              text: context.l10n.importAction,
              onPressed: _isLoadingUrl ? null : () => _importFromUrl(context),
            ),
          ],
        ),
        if (_isLoadingUrl) ...[
          VSpace.x1,
          const Center(child: CircularProgressIndicator()),
        ],
        if (_urlError != null) ...[
          VSpace.x1,
          Text(
            _urlError!,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.errorColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGallerySection(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<TemplateGalleryCubit>()..loadCatalog(),
      child: BlocBuilder<TemplateGalleryCubit, TemplateGalleryState>(
        builder: (context, state) {
          if (state.status == UiFlowStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.catalog == null) {
            return Center(
              child: Text(
                context.l10n.noResultsFound,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            );
          }

          return TemplateGalleryWidget(
            onCardTap: (entry) => _loadFromGallery(context, entry.slug),
          );
        },
      ),
    );
  }

  Future<void> _importFromUrl(BuildContext context) async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isLoadingUrl = true;
      _urlError = null;
    });

    try {
      final shareable = await _importService.previewFromUrl(url);
      final local = _importService.convertShareableTemplate(shareable);
      widget.editorCubit.populateFromTemplate(local);
      widget.onDone();
    } catch (e) {
      if (mounted) {
        setState(() => _urlError = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingUrl = false);
      }
    }
  }

  Future<void> _loadFromGallery(BuildContext context, String slug) async {
    final galleryCubit = context.read<TemplateGalleryCubit>();

    try {
      await galleryCubit.fetchPreview(slug);
      final preview = galleryCubit.state.previewCache[slug];
      if (preview == null) return;

      final local = _importService.convertShareableTemplate(preview);
      widget.editorCubit.populateFromTemplate(local);
      widget.onDone();
    } catch (_) {
      // Gallery cubit handles its own error state
    }
  }
}
