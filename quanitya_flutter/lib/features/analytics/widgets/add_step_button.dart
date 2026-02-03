import 'package:flutter/material.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/analytics/analytics.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../logic/analytics/models/matrix_vector_scalar/analysis_data_type.dart';

/// Add step button with grid-aligned connection line
/// 
/// Shows connection from previous step and provides button to add new operations.
/// Uses analytics grid system for perfect zen paper alignment.
class AddStepButton extends StatelessWidget {
  final AnalysisDataType currentTailType;
  final VoidCallback onPressed;
  
  const AddStepButton({
    super.key,
    required this.currentTailType,
    required this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: AppPadding.horizontalSingle,
      child: Column(
        children: [
          // Connection line from previous step
          if (currentTailType != AnalysisDataType.timeSeriesMatrix)
            AnalyticsConnectionLine(
              column: 0, // Default column
              fromRow: 0, // Default from row
              type: currentTailType,
            ),
          
          // Add button
          SizedBox(
            width: double.infinity,
            child: QuanityaTextButton(
              text: 'Add Step',
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}