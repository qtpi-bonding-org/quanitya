import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../app_router.dart';
import '../../../../design_system/widgets/ui_flow_listener.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/widgets/quanitya_icon_button.dart';
import '../cubits/detail/template_detail_cubit.dart';
import '../cubits/detail/template_detail_state.dart';
import '../cubits/sharing/template_sharing_export_cubit.dart';
import '../../../../logic/templates/models/shared/shareable_template.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart';
import '../widgets/detail/recent_entries_section.dart';
import '../widgets/detail/schedule_status_section.dart';
import '../widgets/detail/template_info_section.dart';
import '../../../logic/schedules/models/schedule.dart';
import '../../schedules/widgets/edit_schedule_sheet.dart';
import '../../../../design_system/structures/column.dart';
import '../../../../design_system/structures/row.dart';
import '../../../../design_system/widgets/quanitya_confirmation_dialog.dart';

class TemplateEditorPage extends StatelessWidget {
  final String templateId;

  const TemplateEditorPage({super.key, required this.templateId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<TemplateDetailCubit>()..load(templateId),
      child: const TemplateDetailView(),
    );
  }
}

class TemplateDetailView extends StatelessWidget {
  const TemplateDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return UiFlowListener<TemplateDetailCubit, TemplateDetailState>(
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<TemplateDetailCubit, TemplateDetailState>(
            builder: (context, state) => Text(
              state.template?.template.name ?? '',
              style: context.text.headlineMedium, // 24px
            ),
          ),
          leading: QuanityaIconButton(
            icon: Icons.arrow_back,
            onPressed: () => AppNavigation.back(context),
          ),
          actions: [
            BlocBuilder<TemplateDetailCubit, TemplateDetailState>(
              builder: (context, state) {
                if (state.template == null) return const SizedBox.shrink();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QuanityaIconButton(
                      icon: Icons.share,
                      onPressed: () => _shareTemplate(context, state.template!),
                    ),
                    QuanityaIconButton(
                      icon: state.template!.template.isHidden ? Icons.visibility : Icons.visibility_off,
                      onPressed: () => context.read<TemplateDetailCubit>().toggleHidden(),
                    ),
                    QuanityaIconButton(
                      icon: Icons.edit,
                      onPressed: () => AppNavigation.toTemplateGenerator(context, state.template),
                    ),
                    QuanityaIconButton(
                      icon: Icons.delete_outline,
                      onPressed: () => _confirmDeleteTemplate(context, state.template!),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        floatingActionButton: BlocBuilder<TemplateDetailCubit, TemplateDetailState>(
          builder: (context, state) {
            if (state.template == null) return const SizedBox.shrink();
            return FloatingActionButton(
              onPressed: () => AppNavigation.toLogEntry(context, state.template!.template.id),
              tooltip: context.l10n.logEntryAction,
              child: const Icon(Icons.add),
            );
          },
        ),
        body: BlocBuilder<TemplateDetailCubit, TemplateDetailState>(
            builder: (context, state) {
                if (state.template == null) return const SizedBox.shrink();
                
                return SingleChildScrollView(
                    padding: AppPadding.page,
                    child: QuanityaColumn(
                        crossAlignment: CrossAxisAlignment.stretch,
                        spacing: VSpace.x3,
                        children: [
                            // Header with Emoji and Name
                            QuanityaRow(
                                spacing: HSpace.x3,
                                start: Text(
                                    state.template?.aesthetics.emoji ?? '📝',
                                    style: context.text.displaySmall,
                                ),
                                middle: Text(
                                    state.template?.template.name ?? '',
                                    style: context.text.headlineLarge, // 36px
                                ),
                            ),

                            TemplateInfoSection(template: state.template!),

                            RecentEntriesSection(
                                template: state.template!.template,
                                entries: state.recentEntries,
                            ),

                            ScheduleStatusSection(
                                schedules: state.schedules,
                                onAdd: () async {
                                    final templateId = state.template!.template.id;
                                    final templateName = state.template!.template.name;
                                    final defaultSchedule = ScheduleModel.daily(
                                        templateId: templateId,
                                        hour: 9,
                                    );
                                    final result = await EditScheduleSheet.show(
                                        context,
                                        schedule: defaultSchedule,
                                        templateName: templateName,
                                    );
                                    if (result != null && context.mounted) {
                                        context.read<TemplateDetailCubit>().saveSchedule(result);
                                    }
                                },
                                onScheduleTap: (schedule) async {
                                    final templateName = state.template!.template.name;
                                    final result = await EditScheduleSheet.show(
                                        context,
                                        schedule: schedule,
                                        templateName: templateName,
                                    );
                                    if (result != null && context.mounted) {
                                        context.read<TemplateDetailCubit>().saveSchedule(result);
                                    }
                                },
                            ),
                        ],
                    ),
                );
            },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTemplate(
    BuildContext context,
    TemplateWithAesthetics template,
  ) async {
    QuanityaConfirmationDialog.show(
      context: context,
      title: context.l10n.actionDelete,
      message: context.l10n.confirmDeleteTemplate,
      confirmText: context.l10n.actionDelete,
      isDestructive: true,
      onConfirm: () async {
        final repo = GetIt.instance<TemplateWithAestheticsRepository>();
        await repo.archive(template.template.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.templateDeleted)),
          );
          AppNavigation.back(context);
        }
      },
    );
  }

  void _shareTemplate(BuildContext context, TemplateWithAesthetics template) {
    final exportCubit = GetIt.instance<TemplateSharingExportCubit>();
    exportCubit.exportTemplate(
      templateWithAesthetics: template,
      author: AuthorCredit.create(name: 'Quanitya User'),
    );
  }
}