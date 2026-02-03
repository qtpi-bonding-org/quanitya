import 'package:flutter/material.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../logic/analytics/enums/calculation.dart';
import '../../../logic/analytics/models/matrix_vector_scalar/analysis_data_type.dart';
import '../../../logic/analytics/models/matrix_vector_scalar/operation_registry.dart';
import 'simple_type_badge.dart';

/// Simple operation selector showing compatible operations for input type
/// 
/// Displays operations grouped by category with type badges showing output types.
/// Only shows operations that are compatible with the current pipeline tail type.
class SimpleOperationSelector extends StatelessWidget {
  final AnalysisDataType inputType;
  final Function(Calculation) onOperationSelected;
  
  const SimpleOperationSelector({
    super.key,
    required this.inputType,
    required this.onOperationSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    final validOperations = _getValidOperations(inputType);
    
    if (validOperations.isEmpty) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: QuanityaPalette.primary.successColor,
              size: 48,
            ),
            VSpace.x2,
            Text(
              'Pipeline Complete!',
              style: context.text.titleMedium?.copyWith(
                color: QuanityaPalette.primary.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            VSpace.x1,
            Text(
              'No more operations available for ${inputType.name}',
              style: context.text.bodyMedium?.copyWith(
                color: QuanityaPalette.primary.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Enhanced header showing operation count
          Padding(
            padding: AppPadding.allSingle,
            child: Row(
              children: [
                Text('Add operation for: ', style: context.text.bodyMedium),
                SimpleTypeBadge(type: inputType, isValid: true),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: HSpace.x1.width, vertical: VSpace.x025.height),
                  decoration: BoxDecoration(
                    color: QuanityaPalette.primary.interactableColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  child: Text(
                    '${validOperations.length} available',
                    style: context.text.labelSmall?.copyWith(
                      color: QuanityaPalette.primary.interactableColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Group operations by category
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: _buildGroupedOperations(context, validOperations),
            ),
          ),
        ],
      ),
    );
  }
  
  List<MapEntry<Calculation, dynamic>> _getValidOperations(AnalysisDataType inputType) {
    return OperationRegistry.instance.getOperationsForInputType(inputType);
  }

  List<Widget> _buildGroupedOperations(BuildContext context, List<MapEntry<Calculation, dynamic>> operations) {
    // Group by category
    final grouped = <String, List<MapEntry<Calculation, dynamic>>>{};
    for (final op in operations) {
      final category = op.value.category;
      grouped.putIfAbsent(category, () => []).add(op);
    }
    
    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      // Category header
      widgets.add(
        Padding(
          padding: EdgeInsets.fromLTRB(AppSizes.space * 2, AppPadding.allSingle.top, AppSizes.space * 2, VSpace.x025.height),
          child: Row(
            children: [
              Text(
                entry.key,
                style: context.text.labelMedium?.copyWith(
                  color: QuanityaPalette.primary.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              HSpace.x1,
              Container(
                padding: EdgeInsets.symmetric(horizontal: HSpace.x025.width * 1.5, vertical: VSpace.x025.height * 0.5),
                decoration: BoxDecoration(
                  color: QuanityaPalette.primary.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Text(
                  '${entry.value.length}',
                  style: context.text.labelSmall?.copyWith(
                    color: QuanityaPalette.primary.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      
      // Operations in category
      for (final op in entry.value) {
        widgets.add(
          ListTile(
            title: Text(
              op.value.label,
              style: context.text.bodyMedium?.copyWith(
                color: QuanityaPalette.primary.textPrimary,
              ),
            ),
            subtitle: Text(
              op.value.description,
              style: context.text.bodySmall?.copyWith(
                color: QuanityaPalette.primary.textSecondary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (op.value.inputCount > 1)
                  Container(
                    margin: EdgeInsets.only(right: HSpace.x1.width),
                    padding: EdgeInsets.symmetric(horizontal: HSpace.x025.width * 1.5, vertical: VSpace.x025.height * 0.5),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${op.value.inputCount} inputs',
                      style: context.text.labelSmall?.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                if (op.value.requiredParams.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(right: HSpace.x1.width),
                    padding: EdgeInsets.symmetric(horizontal: HSpace.x025.width * 1.5, vertical: VSpace.x025.height * 0.5),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${op.value.requiredParams.length} params',
                      style: context.text.labelSmall?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                SimpleTypeBadge(type: op.value.outputType, isValid: true),
              ],
            ),
            onTap: () => onOperationSelected(op.key),
          ),
        );
      }
      
      // Add spacing between categories
      if (entry != grouped.entries.last) {
        widgets.add(VSpace.x1);
      }
    }
    
    return widgets;
  }
}