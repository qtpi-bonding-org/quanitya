import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../app_router.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_page_wrapper.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_empty_state.dart';
import '../../../design_system/widgets/ui_flow_listener.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../templates/widgets/shared/template_preview.dart';
import '../cubits/template_gallery_cubit.dart';
import '../models/catalog_data.dart';
import '../widgets/template_gallery_widget.dart';

/// Full-screen gallery page shown after onboarding.
///
/// Wraps [TemplateGalleryWidget] with a header, preview sheets, and a
/// sticky footer button that lets the user skip or import selected templates.
class TemplateGalleryPage extends StatelessWidget {
  const TemplateGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<TemplateGalleryCubit>()..loadCatalog(),
      child: const _GalleryPageBody(),
    );
  }
}

class _GalleryPageBody extends StatelessWidget {
  const _GalleryPageBody();

  @override
  Widget build(BuildContext context) {
    return QuanityaPageWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SimpleUiFlowListener<TemplateGalleryCubit, TemplateGalleryState>(
          child: BlocListener<TemplateGalleryCubit, TemplateGalleryState>(
            listenWhen: (prev, curr) =>
                curr.lastOperation == TemplateGalleryOperation.preview &&
                curr.status == UiFlowStatus.success &&
                curr.previewSlug != null &&
                prev.status != curr.status,
            listener: (context, state) {
              _openPreviewSheet(context, state);
            },
            child: BlocBuilder<TemplateGalleryCubit, TemplateGalleryState>(
              builder: (context, state) {
                return Column(
                  children: [
                    // Header
                    Padding(
                      padding: AppPadding.page,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VSpace.x2,
                          Text(
                            context.l10n.galleryTitle,
                            style: context.text.headlineSmall,
                          ),
                          VSpace.x05,
                          Text(
                            context.l10n.gallerySubtitle,
                            style: context.text.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                          VSpace.x2,
                        ],
                      ),
                    ),

                    // Body
                    Expanded(child: _buildBody(context, state)),

                    // Footer
                    _Footer(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TemplateGalleryState state) {
    if (state.status == UiFlowStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == UiFlowStatus.failure) {
      return Padding(
        padding: AppPadding.page,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const QuanityaEmptyState(),
            VSpace.x2,
            Text(
              context.l10n.galleryOffline,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: AppPadding.pageHorizontal,
      child: TemplateGalleryWidget(onCardTap: (entry) => _showPreview(context, entry)),
    );
  }

  void _showPreview(BuildContext context, CatalogEntry entry) {
    context.read<TemplateGalleryCubit>().fetchPreview(entry.slug);
  }

  void _openPreviewSheet(BuildContext context, TemplateGalleryState state) {
    final slug = state.previewSlug!;
    final shareable = state.previewCache[slug]!;
    final cubit = context.read<TemplateGalleryCubit>();
    final isSelected = cubit.isSelected(slug);

    // Find the entry name from the catalog
    final entry = state.catalog?.templates.firstWhere((t) => t.slug == slug);

    LooseInsertSheet.show(
      context: context,
      title: entry?.name ?? shareable.template.name,
      builder: (sheetContext) => TemplatePreview(
        template: shareable.template,
        aesthetics: shareable.aesthetics,
        actions: [
          if (isSelected)
            TemplatePreviewAction.secondary(
              label: context.l10n.galleryDeselect,
              icon: Icons.remove_circle_outline,
              onPressed: () {
                cubit.toggleSelection(slug);
                Navigator.of(sheetContext).pop();
              },
            )
          else
            TemplatePreviewAction.primary(
              label: context.l10n.gallerySelect,
              icon: Icons.add_circle_outline,
              onPressed: () {
                cubit.toggleSelection(slug);
                Navigator.of(sheetContext).pop();
              },
            ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplateGalleryCubit, TemplateGalleryState>(
      builder: (context, state) {
        final cubit = context.read<TemplateGalleryCubit>();
        final count = cubit.selectedCount;

        return Padding(
          padding: AppPadding.page,
          child: QuanityaTextButton(
            text: count == 0
                ? context.l10n.gallerySkip
                : context.l10n.galleryStartWith(count),
            onPressed: () async {
              if (count > 0) {
                await cubit.importSelected();
              }
              if (context.mounted) {
                AppNavigation.toHome(context);
              }
            },
          ),
        );
      },
    );
  }
}
