import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:quanitya_flutter/design_system/primitives/quanitya_date_format.dart';

import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/primitives/quanitya_fonts.dart';
import '../../../design_system/widgets/quanitya/general/notebook_fold.dart';
import '../../../design_system/widgets/quanitya/general/post_it_toast.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart' as btn;

/// Card displaying an error entry with complete technical details
///
/// Shows PII-free error information with expandable details and
/// actions to send or delete the error report.
class ErrorEntryCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final formattedTime = QuanityaDateFormat.timestamp(error.timestamp);
    final occurrenceText = occurrenceCount > 1
        ? context.l10n.errorOccurrenceTimes(occurrenceCount)
        : context.l10n.errorOccurrenceOnce;

    return Padding(
      padding: AppPadding.allDouble,
      child: NotebookFold(
        header: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: AppSizes.iconMedium,
              color: context.colors.errorColor,
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
                    context.l10n.errorFromSource(error.source),
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
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VSpace.x3,
            _ErrorDetails(error: error),
            VSpace.x3,
            _ActionButtons(
              onSend: onSend,
              onDelete: onDelete,
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
    return Padding(
      padding: AppPadding.allDouble,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(context.l10n.errorDetailErrorType, error.errorType),
          _buildDetailRow(context.l10n.errorDetailErrorCode, error.errorCode),
          _buildDetailRow(context.l10n.errorDetailSourceCubit, error.source),
          if (error.userMessage != null)
            _buildDetailRow(context.l10n.errorDetailUserMessage, error.userMessage!),
          VSpace.x2,
          Row(
            children: [
              Text(
                context.l10n.errorDetailStackTrace,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              btn.QuanityaTextButton(
                text: context.l10n.actionCopy,
                onPressed: () => _copyToClipboard(context, error.stackTrace),
              ),
            ],
          ),
          VSpace.x1,
          Text(
            error.stackTrace,
            style: context.text.bodySmall?.copyWith(
              fontFamily: QuanityaFonts.bodyFamily,
              color: context.colors.textPrimary,
              height: 1.4,
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
    PostItToast.show(context,
        message: context.l10n.stackTraceCopied,
        type: PostItType.success);
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
            text: context.l10n.actionDelete,
            onPressed: onDelete,
          ),
        ),
        HSpace.x2,
        Expanded(
          child: QuanityaTextButton(
            text: context.l10n.actionSendReport,
            onPressed: onSend,
          ),
        ),
      ],
    );
  }
}
