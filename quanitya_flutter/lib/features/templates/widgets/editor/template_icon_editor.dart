import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_iconpicker/Helpers/icon_pack_manager.dart' as fip;
import 'package:flutter_iconpicker/Models/icon_pack.dart';
import 'package:flutter_iconpicker/Models/icon_picker_icon.dart';
import 'package:get_it/get_it.dart';

import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../design_system/widgets/quanitya_text_field.dart';
import '../../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../support/extensions/color_extensions.dart';
import '../../../../support/utils/icon_resolver.dart';
import '../../../../infrastructure/fonts/font_preloader_service.dart';
import '../../cubits/editor/template_editor_cubit.dart';
import '../../cubits/editor/template_editor_state.dart';

/// Widget for editing the template's quick-access icon.
///
/// Displays a preview bubble with the selected icon and template name.
/// Tapping opens a searchable icon grid in a LooseInsertSheet.
class TemplateIconEditor extends StatelessWidget {
  const TemplateIconEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
      buildWhen: (p, c) =>
          p.aesthetics != c.aesthetics || p.templateName != c.templateName,
      builder: (context, state) {
        final iconString = state.aesthetics?.icon;
        final iconData = IconResolver.resolve(iconString) ?? Icons.description;

        final accentHexStr = state.aesthetics?.palette.accents.firstOrNull;
        final accentColor = accentHexStr != null
            ? HexColorExtension(accentHexStr).toColor()
            : context.colors.primaryColor;

        final titleFont = state.aesthetics?.fontConfig.titleFontFamily;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.quickAccessIconLabel,
              style: context.text.titleMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            VSpace.x1,
            Text(
              context.l10n.quickAccessIconDescription,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            VSpace.x2,
            Center(
              child: Semantics(
                button: true,
                label: context.l10n.accessibilityChangeTemplateIcon,
                child: GestureDetector(
                  onTap: () => _showIconPicker(context, accentColor),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: AppSizes.iconXLarge,
                        height: AppSizes.iconXLarge,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor,
                            width: AppSizes.borderWidthThick,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          iconData,
                          size: AppSizes.iconLarge,
                          color: accentColor,
                        ),
                      ),
                      VSpace.x1,
                      Text(
                        state.templateName.isEmpty
                            ? context.l10n.templateNamePlaceholder
                            : state.templateName,
                        style: _getTitleStyle(titleFont, context).copyWith(
                          color: state.templateName.isEmpty
                              ? context.colors.textSecondary.withValues(alpha: 0.5)
                              : context.colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  TextStyle _getTitleStyle(String? fontName, BuildContext context) {
    final baseStyle = context.text.bodyLarge ?? const TextStyle();
    if (fontName == null || fontName.isEmpty) return baseStyle;
    final fontPreloader = GetIt.I<FontPreloaderService>();
    return fontPreloader.getTextStyle(fontName, fontSize: baseStyle.fontSize);
  }

  void _showIconPicker(BuildContext context, Color accentColor) {
    final cubit = context.read<TemplateEditorCubit>();

    LooseInsertSheet.show(
      context: context,
      title: context.l10n.pickIconTitle,
      builder: (sheetContext) => _IconPickerGrid(
        accentColor: accentColor,
        onIconSelected: (icon) {
          cubit.updateTemplateIcon('${icon.pack}:${icon.name}');
          Navigator.pop(sheetContext);
        },
      ),
    );
  }
}

/// Searchable grid of material icons using flutter_iconpicker's generated packs.
class _IconPickerGrid extends StatefulWidget {
  final Color accentColor;
  final ValueChanged<IconPickerIcon> onIconSelected;

  const _IconPickerGrid({
    required this.accentColor,
    required this.onIconSelected,
  });

  @override
  State<_IconPickerGrid> createState() => _IconPickerGridState();
}

class _IconPickerGridState extends State<_IconPickerGrid> {
  final _searchController = TextEditingController();
  late final Map<String, IconPickerIcon> _allIcons;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _allIcons = fip.IconPackManager.getIcons(IconPack.material);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, IconPickerIcon>> get _filteredIcons {
    final entries = _allIcons.entries.toList();
    if (_query.isEmpty) return entries;
    final q = _query.toLowerCase();
    return entries.where((e) => e.key.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final icons = _filteredIcons;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          Padding(
            padding: AppPadding.allSingle,
            child: QuanityaTextField(
              controller: _searchController,
              hintText: context.l10n.searchIconsHint,
              autofocus: false,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: icons.isEmpty
                ? Center(
                    child: Text(
                      context.l10n.noResultsFound,
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: AppPadding.allSingle,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: AppSizes.space,
                      crossAxisSpacing: AppSizes.space,
                    ),
                    itemCount: icons.length,
                    itemBuilder: (context, index) {
                      final entry = icons[index];
                      return Tooltip(
                        message: entry.key.replaceAll('_', ' '),
                        child: InkWell(
                          onTap: () => widget.onIconSelected(entry.value),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                          child: Center(
                            child: Icon(
                              entry.value.data,
                              size: AppSizes.iconMedium,
                              color: widget.accentColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
