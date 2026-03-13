import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../app_router.dart';
import '../../../../design_system/widgets/ui_flow_listener.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../design_system/widgets/quanitya_icon_button.dart';
import '../cubits/history/log_entry_history_cubit.dart';
import '../cubits/history/log_entry_history_state.dart';
import '../../../data/dao/log_entry_query_dao.dart';
import '../widgets/log_entry_list.dart';
import '../widgets/log_entry_sheet.dart';

class LoggedEntriesTemplatePage extends StatelessWidget {
  final String templateId;

  const LoggedEntriesTemplatePage({super.key, required this.templateId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<LogEntryHistoryCubit>()..load(templateId),
      child: const LogEntryHistoryView(),
    );
  }
}

class LogEntryHistoryView extends StatelessWidget {
  const LogEntryHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return UiFlowListener<LogEntryHistoryCubit, LogEntryHistoryState>(
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<LogEntryHistoryCubit, LogEntryHistoryState>(
             builder: (context, state) {
                // If template is loaded, show its name, otherwise generic title
                return Text(
                    state.template?.template.name ?? context.l10n.logHistoryTitle,
                    style: context.text.headlineMedium, // 24px
                );
             },
          ),
          leading: QuanityaIconButton(
            icon: Icons.arrow_back,
            onPressed: () => AppNavigation.back(context),
          ),
        ),
        body: BlocBuilder<LogEntryHistoryCubit, LogEntryHistoryState>(
          builder: (context, state) {
            return LogEntryList(
                entries: state.entries,
                template: state.template?.template,
                onRefresh: () => context.read<LogEntryHistoryCubit>().load(state.template?.template.id ?? ''),
                onEntryTap: state.template != null
                    ? (entry) => LogEntrySheet.showView(
                          context: context,
                          entryWithContext: LogEntryWithContext(
                            entry: entry,
                            template: state.template!.template,
                            aesthetics: state.template!.aesthetics,
                          ),
                        )
                    : null,
            );
          },
        ),
      ),
    );
  }
}
