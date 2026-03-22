import 'package:flutter/material.dart';
import '../../primitives/app_spacings.dart';
import '../../primitives/app_sizes.dart';
import '../../primitives/quanitya_palette.dart';
import '../../structures/row.dart';
import '../../widgets/quanitya_text_field.dart';
import '../../../support/extensions/context_extensions.dart';

/// Reusable AI prompt widget that provides a consistent interface for AI-powered features.
///
/// This widget encapsulates the common AI prompt pattern:
/// - Header with AI icon and customizable title
/// - Text input field with hint text and loading states
/// - Send button that triggers generation
/// - Optional additional fields (like field selectors)
/// - Automatic prompt clearing after successful generation
///
/// Used across multiple AI features (template generation, analysis suggestions, etc.)
class AiPromptWidget extends StatefulWidget {
  /// The title displayed in the header (e.g., "AI GENERATOR", "AI SUGGESTIONS")
  final String title;
  
  /// Hint text shown in the input field
  final String hintText;
  
  /// Whether the AI generation is currently in progress
  final bool isLoading;
  
  /// Callback triggered when user submits a prompt
  final ValueChanged<String> onGenerate;
  
  /// Optional additional fields to display above the prompt input
  /// (e.g., field selector for analytics, configuration options)
  final Widget? additionalFields;
  
  /// Maximum number of lines for the text input
  final int maxLines;
  
  /// Minimum number of lines for the text input
  final int minLines;
  
  const AiPromptWidget({
    super.key,
    required this.title,
    required this.hintText,
    required this.isLoading,
    required this.onGenerate,
    this.additionalFields,
    this.maxLines = 2,
    this.minLines = 1,
  });

  @override
  State<AiPromptWidget> createState() => _AiPromptWidgetState();
}

class _AiPromptWidgetState extends State<AiPromptWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: AI Icon + Title
        QuanityaRow(
          spacing: HSpace.x1,
          alignment: CrossAxisAlignment.center,
          start: ExcludeSemantics(
            child: Icon(
              Icons.auto_awesome,
              color: palette.interactableColor,
              size: AppSizes.iconMedium,
            ),
          ),
          middle: Text(
            widget.title,
            style: context.text.titleMedium?.copyWith(
              color: palette.interactableColor,
            ),
          ),
        ),
        VSpace.x1,
        
        // Additional fields (field selector for analytics, etc.)
        if (widget.additionalFields != null) ...[
          widget.additionalFields!,
          VSpace.x2,
        ],
        
        // Prompt Input Field
        QuanityaTextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          enabled: !widget.isLoading,
          hintText: widget.hintText,
          textInputAction: TextInputAction.send,
          onChanged: (_) => setState(() {}), // Rebuild to update send button state
          onSubmitted: (_) => _handleGenerate(),
          suffixIcon: widget.isLoading
              ? Semantics(
                  label: context.l10n.accessibilityGenerating,
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.space),
                    child: SizedBox(
                      width: AppSizes.iconSmall,
                      height: AppSizes.iconSmall,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.interactableColor,
                      ),
                    ),
                  ),
                )
              : IconButton(
                  tooltip: context.l10n.aiPromptSend,
                  icon: Icon(
                    Icons.send_rounded,
                    color: _controller.text.trim().isEmpty
                        ? palette.textSecondary
                        : palette.interactableColor,
                  ),
                  onPressed: _controller.text.trim().isEmpty
                      ? null
                      : _handleGenerate,
                ),
        ),
      ],
    );
  }

  /// Handle prompt generation - validates input and triggers callback
  void _handleGenerate() {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty || widget.isLoading) return;

    // Unfocus to dismiss keyboard
    _focusNode.unfocus();
    
    // Trigger generation callback
    widget.onGenerate(prompt);
    
    // Clear the input field for next use
    _controller.clear();
  }
}