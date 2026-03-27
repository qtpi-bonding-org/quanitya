import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/dao/log_entry_query_dao.dart';
import '../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/structures/row.dart';
import '../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_action_dialog.dart';
import '../../../design_system/widgets/quanitya_confirmation_dialog.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/quanitya_progress_bar.dart';
import '../../../logic/import/services/import_executor.dart';
import '../../../logic/llm/services/local_llm_service.dart';
import '../../../logic/ocr/services/ocr_service.dart';
import '../../../logic/ocr/services/template_extraction_schema_builder.dart';
import '../../../logic/templates/models/shared/template_aesthetics.dart';
import '../../../logic/templates/models/shared/tracker_template.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../templates/cubits/form/dynamic_template_cubit.dart';
import '../../templates/cubits/form/dynamic_template_state.dart';
import '../../templates/widgets/shared/template_preview.dart';
import '../cubits/detail/entry_detail_cubit.dart';
import '../cubits/import/import_cubit.dart';
import '../cubits/import/import_state.dart';
import 'import_review_content.dart';

/// Mode for the unified log entry sheet.
enum LogEntrySheetMode {
  /// New log entry creation.
  create,

  /// View an existing entry (settled state with edit toggle).
  view,

  /// Template designer preview (non-interactive).
  preview,
}

/// Unified log entry sheet that replaces separate new/view/edit pages.
///
/// Displays a [TemplatePreview] inside a [LooseInsertSheet] with mode-specific
/// action bars and settled/active field states.
class LogEntrySheet extends StatefulWidget {
  final LogEntrySheetMode mode;

  /// Template for create and preview modes.
  final TrackerTemplateModel? template;

  /// Aesthetics for create and preview modes.
  final TemplateAestheticsModel? aesthetics;

  /// Entry with context for view mode.
  final LogEntryWithContext? entryWithContext;

  const LogEntrySheet._({
    required this.mode,
    this.template,
    this.aesthetics,
    this.entryWithContext,
  });

  /// Show sheet in create mode for a given template ID.
  ///
  /// Loads the template via [TemplateWithAestheticsRepository] before opening.
  static Future<void> showCreate({
    required BuildContext context,
    required String templateId,
  }) async {
    final repo = GetIt.I<TemplateWithAestheticsRepository>();
    final data = await repo.findById(templateId);
    if (!context.mounted) return;
    if (data == null) {
      GetIt.I<IFeedbackService>().show(FeedbackMessage(
        message: context.l10n.errorTemplateNotFound,
        type: MessageType.error,
      ));
      return;
    }

    LooseInsertSheet.show(
      context: context,
      builder: (_) => LogEntrySheet._(
        mode: LogEntrySheetMode.create,
        template: data.template,
        aesthetics: data.aesthetics,
      ),
    );
  }

  /// Show sheet in view mode for an existing entry.
  static Future<void> showView({
    required BuildContext context,
    required LogEntryWithContext entryWithContext,
  }) {
    return LooseInsertSheet.show(
      context: context,
      title: entryWithContext.template.name,
      builder: (_) => LogEntrySheet._(
        mode: LogEntrySheetMode.view,
        entryWithContext: entryWithContext,
      ),
    );
  }

  /// Show sheet in preview mode for template design.
  static Future<void> showPreview({
    required BuildContext context,
    required TrackerTemplateModel template,
    TemplateAestheticsModel? aesthetics,
  }) {
    return LooseInsertSheet.show(
      context: context,
      title: template.name,
      builder: (_) => LogEntrySheet._(
        mode: LogEntrySheetMode.preview,
        template: template,
        aesthetics: aesthetics,
      ),
    );
  }

  @override
  State<LogEntrySheet> createState() => _LogEntrySheetState();
}

class _LogEntrySheetState extends State<LogEntrySheet> {
  // Shared services — survive across sheet opens, model stays loaded
  static final _sharedOcrService = OcrService();
  static final _sharedLlmService = LocalLlmService();

  late bool _isEditing;
  late Map<String, dynamic> _values;
  late Map<String, dynamic> _originalValues;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.mode == LogEntrySheetMode.create;

    if (widget.mode == LogEntrySheetMode.view && widget.entryWithContext != null) {
      _values = Map<String, dynamic>.from(
        widget.entryWithContext?.entry.data ?? {},
      );
    } else {
      _values = {};
    }
    _originalValues = Map<String, dynamic>.from(_values);
  }

  void _updateValues(Map<String, dynamic> newValues) {
    setState(() {
      _values = newValues;
    });
  }

  void _startEditing() {
    setState(() {
      _originalValues = Map<String, dynamic>.from(_values);
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _values = Map<String, dynamic>.from(_originalValues);
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.mode) {
      LogEntrySheetMode.create => _buildCreateMode(context),
      LogEntrySheetMode.view => _buildViewMode(context),
      LogEntrySheetMode.preview => _buildPreviewMode(context),
    };
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Create Mode
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildCreateMode(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GetIt.I<DynamicTemplateCubit>()
            ..loadTemplate(widget.template!),
        ),
        BlocProvider(
          create: (_) => ImportCubit(
            _sharedOcrService,
            _sharedLlmService,
            ImportExecutor(GetIt.I()),
          ),
        ),
      ],
      child: BlocListener<ImportCubit, ImportState>(
        listener: _handleImportState,
        child: BlocConsumer<DynamicTemplateCubit, DynamicTemplateState>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status ||
              prev.lastOperation != curr.lastOperation,
          buildWhen: (prev, curr) =>
              prev.template != curr.template ||
              prev.status != curr.status ||
              prev.fieldErrors != curr.fieldErrors,
          listener: (context, state) {
            if (state.lastOperation == DynamicTemplateOperation.submit &&
                state.isSuccess) {
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            if (state.template == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return BlocBuilder<ImportCubit, ImportState>(
              buildWhen: (prev, curr) =>
                  prev is ImportProcessing != (curr is ImportProcessing) ||
                  prev is ImportImporting != (curr is ImportImporting) ||
                  prev is ImportDownloading != (curr is ImportDownloading) ||
                  (prev is ImportDownloading &&
                      curr is ImportDownloading &&
                      prev.progress != curr.progress),
              builder: (context, importState) {
                final isImportBusy = importState is ImportProcessing ||
                    importState is ImportImporting ||
                    importState is ImportDownloading;

                return Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!kIsWeb)
                          Align(
                            alignment: Alignment.centerRight,
                            child: QuanityaIconButtonSizes.medium(
                              icon: Icons.camera_alt_outlined,
                              onPressed: isImportBusy
                                  ? null
                                  : () => _showSourcePicker(context),
                            ),
                          ),
                        Flexible(
                          child: TemplatePreview(
                            template: widget.template!,
                            aesthetics: widget.aesthetics,
                            initialValues: state.values,
                            fieldErrors: state.fieldErrors,
                            onValuesChanged: (values) {
                              for (final entry in values.entries) {
                                context
                                    .read<DynamicTemplateCubit>()
                                    .updateField(entry.key, entry.value);
                              }
                            },
                          ),
                        ),
                        VSpace.x2,
                        _buildCreateActions(context, state),
                      ],
                    ),
                    if (isImportBusy)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSmall),
                          ),
                          child: Center(
                            child: importState is ImportDownloading
                                ? Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSizes.space * 4,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          context.l10n.importModelDownloading,
                                          style: context.text.bodyMedium,
                                        ),
                                        VSpace.x2,
                                        QuanityaProgressBar(
                                          progress: importState.progress,
                                        ),
                                      ],
                                    ),
                                  )
                                : const CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCreateActions(
    BuildContext context,
    DynamicTemplateState state,
  ) {
    return QuanityaRow(
      alignment: CrossAxisAlignment.center,
      start: QuanityaTextButton(
        text: context.l10n.discardAction,
        isDestructive: true,
        onPressed: () => Navigator.of(context).pop(),
      ),
      end: QuanityaTextButton(
        text: context.l10n.actionSave,
        onPressed: state.isLoading
            ? null
            : () => context.read<DynamicTemplateCubit>().submit(),
      ),
    );
  }

  void _showSourcePicker(BuildContext context) {
    final importCubit = context.read<ImportCubit>();
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(context.l10n.importSourceCamera),
              onTap: () {
                Navigator.of(context).pop();
                importCubit.importFromImage(
                  source: ImageSource.camera,
                  template: widget.template!,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(context.l10n.importSourcePhotoLibrary),
              onTap: () {
                Navigator.of(context).pop();
                importCubit.importFromImage(
                  source: ImageSource.gallery,
                  template: widget.template!,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedback(String message, MessageType type) {
    GetIt.I<IFeedbackService>().show(
      FeedbackMessage(message: message, type: type),
    );
  }

  void _handleImportState(BuildContext context, ImportState importState) {
    switch (importState) {
      case ImportModelRequired(:final source, :final template):
        final importCubit = context.read<ImportCubit>();
        QuanityaConfirmationDialog.show(
          context: context,
          title: context.l10n.importModelDownloadTitle,
          message: context.l10n.importModelDownloadMessage,
          confirmText: context.l10n.importModelDownloadConfirm,
          onConfirm: () {
            importCubit.confirmDownloadAndImport(
              source: source,
              template: template,
            );
          },
        ).then((confirmed) {
          if (confirmed != true) {
            importCubit.reset();
          }
        });

      case ImportSingleResult(:final item):
        final cubit = context.read<DynamicTemplateCubit>();
        for (final entry in item.entries) {
          cubit.updateField(entry.key, entry.value);
        }
        _showFeedback(context.l10n.importValuesFilled, MessageType.success);
        context.read<ImportCubit>().reset();

      case ImportMultipleResults(:final items):
        _showImportReview(context, items);

      case ImportDone(:final count):
        _showFeedback(context.l10n.importEntriesImported(count), MessageType.success);
        Navigator.of(context).pop();

      case ImportError(:final message):
        _showFeedback(message, MessageType.error);
        context.read<ImportCubit>().reset();

      default:
        break;
    }
  }

  void _showImportReview(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    final extractionFields =
        TemplateExtractionSchemaBuilder.buildExtractionFields(
      widget.template!.fields,
    );

    ImportReviewState? reviewState;

    final importCubit = context.read<ImportCubit>();

    QuanityaActionDialog.show(
      context: context,
      title: context.l10n.importReviewTitle,
      confirmText: context.l10n.importReviewConfirm,
      child: ImportReviewContent(
        items: items,
        fields: extractionFields,
        onChanged: (state) => reviewState = state,
      ),
      onConfirm: () {
        if (reviewState != null) {
          importCubit.executeBulkImport(
            templateId: widget.template!.id,
            template: widget.template!,
            items: reviewState!.items,
            batchTimestamp: reviewState!.batchDate,
          );
        }
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // View Mode
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildViewMode(BuildContext context) {
    final ewc = widget.entryWithContext!;

    return BlocProvider(
      create: (_) => GetIt.I<EntryDetailCubit>()..initWithEntry(ewc),
      child: BlocConsumer<EntryDetailCubit, EntryDetailState>(
        listener: (context, state) {
          if (state.status == UiFlowStatus.success &&
              (state.lastOperation == EntryDetailOperation.update ||
                  state.lastOperation == EntryDetailOperation.delete)) {
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          final template = ewc.template;
          final aesthetics = ewc.aesthetics;

          final preview = TemplatePreview(
            template: template,
            aesthetics: aesthetics,
            initialValues: _values,
            onValuesChanged: _isEditing ? _updateValues : null,
          );

          final fieldContent = _isEditing
              ? preview
              : IgnorePointer(
                  ignoring: true,
                  child: AnimatedOpacity(
                    opacity: 0.85,
                    duration: const Duration(milliseconds: 200),
                    child: preview,
                  ),
                );

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: fieldContent),
              VSpace.x2,
              _buildViewActions(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildViewActions(BuildContext context, EntryDetailState state) {
    if (_isEditing) {
      return QuanityaRow(
        alignment: CrossAxisAlignment.center,
        start: QuanityaTextButton(
          text: context.l10n.actionDelete,
          isDestructive: true,
          onPressed: () => _confirmDelete(context),
        ),
        middle: Center(
          child: QuanityaTextButton(
            text: context.l10n.actionCancel,
            onPressed: _cancelEditing,
          ),
        ),
        end: QuanityaTextButton(
          text: context.l10n.actionSave,
          onPressed: state.isLoading ? null : () => _saveEntry(context),
        ),
      );
    }

    return QuanityaRow(
      alignment: CrossAxisAlignment.center,
      start: QuanityaTextButton(
        text: context.l10n.actionDelete,
        isDestructive: true,
        onPressed: () => _confirmDelete(context),
      ),
      end: QuanityaTextButton(
        text: context.l10n.actionEdit,
        onPressed: _startEditing,
      ),
    );
  }

  void _saveEntry(BuildContext context) {
    final entryWithContext = widget.entryWithContext;
    if (entryWithContext == null) return;
    final entry = entryWithContext.entry;
    final updatedEntry = entry.copyWith(
      data: _values,
      occurredAt: entry.occurredAt ?? DateTime.now(),
    );
    context.read<EntryDetailCubit>().updateEntry(updatedEntry);
  }

  void _confirmDelete(BuildContext context) {
    QuanityaConfirmationDialog.show(
      context: context,
      title: context.l10n.actionDelete,
      message: context.l10n.confirmDeleteEntry,
      confirmText: context.l10n.actionDelete,
      isDestructive: true,
      onConfirm: () => context.read<EntryDetailCubit>().deleteEntry(),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Preview Mode
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildPreviewMode(BuildContext context) {
    return AbsorbPointer(
      absorbing: true,
      child: AnimatedOpacity(
        opacity: 0.85,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: TemplatePreview(
                template: widget.template!,
                aesthetics: widget.aesthetics,
                  ),
            ),
            VSpace.x2,
            _buildPreviewActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewActions(BuildContext context) {
    return QuanityaRow(
      alignment: CrossAxisAlignment.center,
      end: QuanityaTextButton(
        text: context.l10n.actionSave,
        onPressed: null,
      ),
    );
  }
}
