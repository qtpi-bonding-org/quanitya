import 'package:flutter/material.dart';
import 'package:flutter_adaptable_group/flutter_adaptable_group.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design_system/primitives/app_spacings.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/widgets/quanitya/general/pen_circled_chip.dart';
import '../cubits/template_gallery_cubit.dart';
import '../models/catalog_data.dart';
import 'gallery_card.dart';

/// Reusable template gallery widget with category filtering and a responsive grid.
///
/// Shows a horizontal chip row for category selection (including "All")
/// and a scrollable grid of [GalleryCard] widgets below.
class TemplateGalleryWidget extends StatelessWidget {
  /// Called when a gallery card is tapped.
  final ValueChanged<CatalogEntry> onCardTap;

  const TemplateGalleryWidget({
    super.key,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplateGalleryCubit, TemplateGalleryState>(
      builder: (context, state) {
        final cubit = context.read<TemplateGalleryCubit>();
        final categories = state.catalog?.categories ?? [];
        final templates = cubit.filteredTemplates;

        return Column(
          children: [
            // 1. Category chip row (horizontal scroll)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  PenCircledChip(
                    label: context.l10n.catalogFilterAll,
                    isSelected: state.selectedCategory == null,
                    onTap: () => cubit.selectCategory(null),
                  ),
                  for (final category in categories) ...[
                    HSpace.x05,
                    PenCircledChip(
                      label: category.name,
                      isSelected: state.selectedCategory == category.id,
                      onTap: () => cubit.selectCategory(category.id),
                    ),
                  ],
                ],
              ),
            ),

            VSpace.x2,

            // 2. Template grid (scrollable)
            Expanded(
              child: SingleChildScrollView(
                child: LayoutGroup.grid(
                  minItemWidth: 20,
                  children: [
                    for (final entry in templates)
                      GalleryCard(
                        emoji: entry.emoji,
                        name: entry.name,
                        isSelected: cubit.isSelected(entry.slug),
                        onTap: () => onCardTap(entry),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
