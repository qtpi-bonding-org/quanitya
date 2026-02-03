import 'package:flutter/material.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../logic/log_entries/models/log_entry.dart';
import '../../../../logic/templates/models/shared/tracker_template.dart';
import '../../../../design_system/structures/column.dart';
import '../../../../design_system/structures/row.dart';
import '../../../../design_system/structures/group.dart';

class LogEntryItem extends StatefulWidget {
  final LogEntryModel entry;
  final TrackerTemplateModel? template;

  const LogEntryItem({
    super.key,
    required this.entry,
    this.template,
  });

  @override
  State<LogEntryItem> createState() => _LogEntryItemState();
}

class _LogEntryItemState extends State<LogEntryItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Format timestamp: "Today, 10:45 AM" or "Dec 25, 10:45 AM"
    // Use displayTimestamp which handles nullable occurredAt/scheduledFor
    final date = widget.entry.displayTimestamp;
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final timeStr = "${isToday ? 'Today' : '${date.month}/${date.day}'}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

    return QuanityaGroup(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: QuanityaColumn(
        crossAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Timestamp + Expand Icon
          QuanityaRow(
            start: Text(
              timeStr,
              style: context.text.labelMedium, // 14px metadata
            ),
            end: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: context.colors.interactableColor, // Teal for tappable affordance
              size: AppSizes.iconSmall,
            ),
          ),
          
          // Data Content
          if (widget.template != null)
            ..._buildFields(context, widget.entry, widget.template!),
        ],
      ),
    );
  }

  List<Widget> _buildFields(BuildContext context, LogEntryModel entry, TrackerTemplateModel template) {
    if (entry.data.isEmpty) {
        return [Text(context.l10n.logEntryNoData, style: context.text.bodySmall)];
    }

    final fields = <Widget>[];

    // Simple display: Key - Value
    // In a real app, we would use the FieldDefinitions from the template to format this properly
    // (e.g. boolean as Checkbox, number with units, etc.)
    // For now, we iterate the data map.
    
    final data = entry.data;
    // Show summary (first 2 fields) if compacted, or all if expanded
    final keys = data.keys.toList();
    final countToShow = _isExpanded ? keys.length : (keys.length > 2 ? 2 : keys.length);

    for (var i = 0; i < countToShow; i++) {
      final key = keys[i];
      final value = data[key];
      // Find field name if possible
      final fieldDef = template.fields.firstWhere((f) => f.id == key, orElse: () => template.fields.first); // Fallback is slightly risky but okay for now
      final label = fieldDef.id == key ? fieldDef.label : key; // Try to use label

      fields.add(
        Padding(
          padding: EdgeInsets.only(left: AppSizes.space),
          child: QuanityaRow(
             spacing: HSpace.x1,
             alignment: CrossAxisAlignment.start,
             start: Text(
                "$label:",
                style: context.text.bodyLarge!.copyWith(color: context.colors.textSecondary), // 16px
             ),
             middle: Text(
                value.toString(),
                style: context.text.bodyLarge, // 16px
                maxLines: _isExpanded ? null : 1,
                overflow: _isExpanded ? null : TextOverflow.ellipsis,
             ),
          ),
        ),
      );
    }
    
    if (!_isExpanded && keys.length > 2) {
       fields.add(
         Padding(
           padding: EdgeInsets.only(left: AppSizes.space),
           child: Text(
             "... +${keys.length - 2} more", 
             style: context.text.labelMedium // 14px metadata
           ),
         )
       );
    }

    return fields;
  }
}
