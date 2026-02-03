import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:intl/intl.dart';

import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_fonts.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart' as btn;

/// Card displaying an error entry with complete technical details
/// 
/// Shows PII-free error information with expandable details and
/// actions to send or delete the error report.
class ErrorEntryCard extends StatefulWidget {
  final ErrorEntry error;
  final int occurrenceCount;
  final VoidCallback onSend;
  final VoidCallback onDelete;

  const ErrorEntryCard({
    super.key,
    required this.error,
    required this.occurrenceCount,
    required this.onSend,
    required this.onDelete,
  });

  @override
  State<ErrorEntryCard> createState() => _ErrorEntryCardState();
}

class _ErrorEntryCardState extends State<ErrorEntryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat.yMd().add_jm().format(widget.error.timestamp);
    final occurrenceText = widget.occurrenceCount > 1 
        ? '${widget.occurrenceCount} times'
        : 'Once';

    return Container(
      padding: AppPadding.allDouble,
      decoration: BoxDecoration(
        color: QuanityaPalette.primary.backgroundPrimary,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ErrorHeader(
              error: widget.error,
              formattedTime: formattedTime,
              occurrenceText: occurrenceText,
              isExpanded: _isExpanded,
              onToggleExpanded: () => setState(() => _isExpanded = !_isExpanded),
            ),
            if (_isExpanded) ...[
              VSpace.x3,
              _ErrorDetails(error: widget.error),
              VSpace.x3,
              _ActionButtons(
                onSend: widget.onSend,
                onDelete: widget.onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorHeader extends StatelessWidget {
  final ErrorEntry error;
  final String formattedTime;
  final String occurrenceText;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  const _ErrorHeader({
    required this.error,
    required this.formattedTime,
    required this.occurrenceText,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggleExpanded,
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.space * 0.5),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSizes.space * 0.75),
              decoration: BoxDecoration(
                color: context.colors.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Icon(
                Icons.error_outline,
                size: AppSizes.iconMedium,
                color: context.colors.errorColor,
              ),
            ),
            HSpace.x2,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${error.errorCode}: ${error.errorType}',
                    style: context.text.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  VSpace.x025,
                  Text(
                    'From ${error.source}',
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.interactableColor,
                    ),
                  ),
                  VSpace.x025,
                  Row(
                    children: [
                      Text(
                        formattedTime,
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                      Text(
                        ' • $occurrenceText',
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: AppSizes.iconMedium,
              color: context.colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorDetails extends StatelessWidget {
  final ErrorEntry error;

  const _ErrorDetails({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppPadding.allDouble,
      decoration: BoxDecoration(
        color: context.colors.textSecondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Error Type', error.errorType),
          _buildDetailRow('Error Code', error.errorCode),
          _buildDetailRow('Source Cubit', error.source),
          if (error.userMessage != null)
            _buildDetailRow('User Message', error.userMessage!),
          VSpace.x2,
          Row(
            children: [
              Text(
                'Stack Trace',
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              btn.QuanityaTextButton(
                text: 'Copy',
                onPressed: () => _copyToClipboard(context, error.stackTrace),
              ),
            ],
          ),
          VSpace.x1,
          Container(
            width: double.infinity,
            padding: AppPadding.allDouble,
            decoration: BoxDecoration(
              color: context.colors.backgroundPrimary,
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              border: Border.all(
                color: context.colors.textSecondary.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              error.stackTrace,
              style: context.text.bodySmall?.copyWith(
                fontFamily: QuanityaFonts.bodyFamily,
                color: context.colors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.space),
      child: Builder(
        builder: (context) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: context.text.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Stack trace copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onSend;
  final VoidCallback onDelete;

  const _ActionButtons({
    required this.onSend,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: btn.QuanityaTextButton(
            text: 'Delete',
            onPressed: onDelete,
          ),
        ),
        HSpace.x2,
        Expanded(
          child: QuanityaTextButton(
            text: 'Send Report',
            onPressed: onSend,
          ),
        ),
      ],
    );
  }
}