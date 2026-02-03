import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../templates/widgets/shared/template_preview.dart';
import '../../templates/cubits/form/dynamic_template_cubit.dart';
import '../../templates/cubits/form/dynamic_template_state.dart';

class LogEntryPage extends StatelessWidget {
  final String templateId;

  const LogEntryPage({super.key, required this.templateId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: GetIt.I<TemplateWithAestheticsRepository>().findById(templateId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final templateWithAesthetics = snapshot.data!;

        return BlocProvider(
          create: (_) => GetIt.I<DynamicTemplateCubit>()..loadTemplate(templateWithAesthetics.template),
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                templateWithAesthetics.template.name,
                style: context.text.headlineMedium,
              ),
              leading: QuanityaIconButton(
                icon: Icons.close,
                onPressed: () => context.pop(),
              ),
            ),
            body: BlocConsumer<DynamicTemplateCubit, DynamicTemplateState>(
              listener: (context, state) {
                if (state.lastOperation == DynamicTemplateOperation.submit && state.isSuccess) {
                  context.pop();
                }
              },
              builder: (context, state) {
                if (state.template == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                return TemplatePreview(
                  template: templateWithAesthetics.template,
                  aesthetics: templateWithAesthetics.aesthetics,
                  initialValues: state.values,
                  onValuesChanged: (values) {
                    // Update each field value in the cubit
                    for (final entry in values.entries) {
                      context.read<DynamicTemplateCubit>().updateField(entry.key, entry.value);
                    }
                  },
                  actions: [
                    TemplatePreviewAction.secondary(
                      label: context.l10n.actionCancel,
                      icon: Icons.close,
                      onPressed: () => context.pop(),
                    ),
                    TemplatePreviewAction.primary(
                      label: context.l10n.actionSave,
                      icon: Icons.save,
                      onPressed: () {
                        if (!state.isLoading) {
                          context.read<DynamicTemplateCubit>().submit();
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
