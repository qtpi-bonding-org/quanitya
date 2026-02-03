import 'package:flutter/material.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/primitives/zen_grid_constants.dart';
import '../../../design_system/widgets/zen_grid_positioned.dart';
import '../../../support/extensions/context_extensions.dart';

/// Operation parameter card showing operation name and configurable parameters
/// 
/// Uses zen grid units for sizing:
/// - Width: 5 grid units (capped)
/// - Height: 2 units base + 1 unit per parameter (expands by integer increments)
class OperationParameterCard extends StatelessWidget {
  final String operationName;
  final Map<String, dynamic> parameters;
  final int column;
  final int row;
  final int widthUnits;
  final ValueChanged<Map<String, dynamic>>? onParametersChanged;
  final VoidCallback? onRemove;
  
  const OperationParameterCard({
    super.key,
    required this.operationName,
    required this.parameters,
    required this.column,
    required this.row,
    this.widthUnits = 6, // 6 units wide (even number for perfect centering)
    this.onParametersChanged,
    this.onRemove,
  });
  
  /// Calculate height in grid units based on content
  /// Expands by integer increments: 2 base + 1 per parameter (no cap)
  int get heightUnits {
    // Base: 2 units for header
    // +1 unit per parameter (no cap - expands as needed)
    return 2 + parameters.length;
  }
  
  @override
  Widget build(BuildContext context) {
    final gridSpacing = ZenGridConstants.dotSpacing;
    final cardWidth = widthUnits * gridSpacing;
    final cardHeight = heightUnits * gridSpacing;
    
    return ZenGridPositioned(
      column: column,
      row: row,
      width: cardWidth,
      height: cardHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent, // Transparent like journal writing
          border: Border.all(
            color: QuanityaPalette.primary.textSecondary.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          child: Padding(
            padding: EdgeInsets.all(gridSpacing * 0.4), // ~10px padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with operation name and remove button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        operationName,
                        style: context.text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: QuanityaPalette.primary.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onRemove != null)
                      GestureDetector(
                        onTap: onRemove,
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: QuanityaPalette.primary.textSecondary,
                        ),
                      ),
                  ],
                ),
                
                SizedBox(height: gridSpacing * 0.2), // Small gap
                
                // Parameters - takes remaining space
                if (parameters.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'No parameters',
                        style: context.text.bodySmall?.copyWith(
                          color: QuanityaPalette.primary.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      children: parameters.entries.map((entry) => 
                        Padding(
                          padding: EdgeInsets.only(bottom: gridSpacing * 0.15),
                          child: _buildParameterRow(context, entry.key, entry.value, gridSpacing),
                        )
                      ).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildParameterRow(BuildContext context, String key, dynamic value, double gridSpacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          key,
          style: context.text.labelSmall?.copyWith(
            color: QuanityaPalette.primary.textSecondary,
          ),
        ),
        SizedBox(height: gridSpacing * 0.1),
        _buildParameterInput(context, key, value, gridSpacing),
      ],
    );
  }
  
  Widget _buildParameterInput(BuildContext context, String key, dynamic value, double gridSpacing) {
    if (value is int) {
      return _buildNumberInput(context, key, value, gridSpacing);
    } else if (value is String && _isDropdownParameter(key)) {
      return _buildDropdownInput(context, key, value, gridSpacing);
    } else {
      return _buildTextInput(context, key, value.toString(), gridSpacing);
    }
  }
  
  Widget _buildNumberInput(BuildContext context, String key, int value, double gridSpacing) {
    return Container(
      height: gridSpacing * 0.9, // ~22px
      padding: EdgeInsets.symmetric(horizontal: gridSpacing * 0.3),
      decoration: BoxDecoration(
        border: Border.all(
          color: QuanityaPalette.primary.textSecondary.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              value.toString(),
              style: context.text.bodySmall?.copyWith(
                color: QuanityaPalette.primary.textPrimary,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _updateParameter(key, value + 1),
                child: Icon(Icons.keyboard_arrow_up, size: 14, color: QuanityaPalette.primary.textSecondary),
              ),
              GestureDetector(
                onTap: () => _updateParameter(key, (value - 1).clamp(1, 999)),
                child: Icon(Icons.keyboard_arrow_down, size: 14, color: QuanityaPalette.primary.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDropdownInput(BuildContext context, String key, String value, double gridSpacing) {
    final options = _getDropdownOptions(key);
    
    return Container(
      height: gridSpacing * 0.9, // ~22px
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: gridSpacing * 0.3),
      decoration: BoxDecoration(
        border: Border.all(
          color: QuanityaPalette.primary.textSecondary.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : options.first,
          isDense: true,
          isExpanded: true,
          onChanged: (newValue) {
            if (newValue != null) {
              _updateParameter(key, newValue);
            }
          },
          style: context.text.bodySmall?.copyWith(
            color: QuanityaPalette.primary.textPrimary,
          ),
          items: options.map((option) {
            return DropdownMenuItem<String>(value: option, child: Text(option));
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildTextInput(BuildContext context, String key, String value, double gridSpacing) {
    return Container(
      height: gridSpacing * 0.9, // ~22px
      padding: EdgeInsets.symmetric(horizontal: gridSpacing * 0.3),
      decoration: BoxDecoration(
        border: Border.all(
          color: QuanityaPalette.primary.textSecondary.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: context.text.bodySmall?.copyWith(
            color: QuanityaPalette.primary.textPrimary,
          ),
        ),
      ),
    );
  }
  
  bool _isDropdownParameter(String key) {
    return key.toLowerCase().contains('type') || 
           key.toLowerCase().contains('method') ||
           key.toLowerCase().contains('mode');
  }
  
  List<String> _getDropdownOptions(String key) {
    final keyLower = key.toLowerCase();
    if (keyLower.contains('type')) {
      return ['Simple', 'Exponential', 'Weighted'];
    } else if (keyLower.contains('method')) {
      return ['Linear', 'Polynomial', 'Spline'];
    } else if (keyLower.contains('mode')) {
      return ['Forward', 'Backward', 'Centered'];
    }
    return ['Option 1', 'Option 2', 'Option 3'];
  }
  
  void _updateParameter(String key, dynamic value) {
    if (onParametersChanged != null) {
      final updatedParams = Map<String, dynamic>.from(parameters);
      updatedParams[key] = value;
      onParametersChanged!(updatedParams);
    }
  }
}