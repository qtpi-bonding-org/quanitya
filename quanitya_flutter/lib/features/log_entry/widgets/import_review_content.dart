import 'package:flutter/material.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../logic/ocr/models/extraction_field.dart';

class ImportReviewContent extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final List<ExtractionField> fields;
  final ValueChanged<ImportReviewState> onChanged;

  const ImportReviewContent({
    super.key,
    required this.items,
    required this.fields,
    required this.onChanged,
  });

  @override
  State<ImportReviewContent> createState() => _ImportReviewContentState();
}

class ImportReviewState {
  final List<Map<String, dynamic>> items;
  final DateTime batchDate;
  const ImportReviewState({required this.items, required this.batchDate});
}

class _ImportReviewContentState extends State<ImportReviewContent> {
  late List<Map<String, dynamic>> _items;
  late DateTime _batchDate;
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _items = widget.items.map((m) => Map<String, dynamic>.of(m)).toList();
    _batchDate = DateTime.now();
    _notifyChanged();
  }

  void _notifyChanged() {
    widget.onChanged(ImportReviewState(items: _items, batchDate: _batchDate));
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
      if (_editingIndex == index) _editingIndex = null;
      if (_editingIndex != null && _editingIndex! > index) {
        _editingIndex = _editingIndex! - 1;
      }
    });
    _notifyChanged();
  }

  void _updateField(int itemIndex, String fieldId, dynamic value) {
    setState(() {
      _items[itemIndex] = Map<String, dynamic>.of(_items[itemIndex])
        ..[fieldId] = value;
    });
    _notifyChanged();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _batchDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _batchDate = picked);
      _notifyChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date chip
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.space,
              vertical: AppSizes.space * 0.5,
            ),
            decoration: BoxDecoration(
              color: QuanityaPalette.primary.interactableColor
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today,
                    size: 14,
                    color: QuanityaPalette.primary.interactableColor),
                HSpace.x05,
                Text(
                  _formatDate(_batchDate),
                  style: context.text.bodyMedium?.copyWith(
                    color: QuanityaPalette.primary.interactableColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        VSpace.x1,
        // Item count
        Text(
          '${_items.length} item${_items.length == 1 ? '' : 's'}',
          style: context.text.bodySmall?.copyWith(
            color: QuanityaPalette.primary.textSecondary,
          ),
        ),
        VSpace.x1,
        // Scrollable item cards
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _items.length,
            itemBuilder: (context, index) => _buildItemCard(index),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];
    final isEditing = _editingIndex == index;

    return Dismissible(
      key: ValueKey('import-item-$index-${item.hashCode}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: AppSizes.space * 2),
        color: QuanityaPalette.primary.destructiveColor.withValues(alpha: 0.1),
        child: Icon(Icons.delete_outline,
            color: QuanityaPalette.primary.destructiveColor),
      ),
      onDismissed: (_) => _deleteItem(index),
      child: GestureDetector(
        onTap: () => setState(() {
          _editingIndex = isEditing ? null : index;
        }),
        child: Container(
          margin: EdgeInsets.only(bottom: AppSizes.space * 0.5),
          padding: EdgeInsets.all(AppSizes.space),
          decoration: BoxDecoration(
            color: isEditing
                ? QuanityaPalette.primary.interactableColor
                    .withValues(alpha: 0.05)
                : context.colors.backgroundPrimary,
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            border: Border.all(
              color: isEditing
                  ? QuanityaPalette.primary.interactableColor
                  : QuanityaPalette.primary.textSecondary
                      .withValues(alpha: 0.2),
              width: isEditing ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final field in widget.fields)
                _buildField(index, field, item[field.fieldId], isEditing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    int itemIndex,
    ExtractionField field,
    dynamic value,
    bool isEditing,
  ) {
    if (isEditing) {
      return Padding(
        padding: EdgeInsets.only(bottom: AppSizes.space * 0.25),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                field.label,
                style: context.text.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: TextFormField(
                initialValue: value?.toString() ?? '',
                style: context.text.bodySmall,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSizes.space * 0.5,
                    vertical: AppSizes.space * 0.25,
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => _updateField(itemIndex, field.fieldId, v),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.space * 0.25),
      child: Row(
        children: [
          Text(
            '${field.label}: ',
            style:
                context.text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '',
              style: context.text.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
