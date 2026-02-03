import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../app_router.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../cubits/list/template_list_cubit.dart';
import '../cubits/list/template_list_state.dart';
import '../widgets/list/dashboard_header.dart';
import '../widgets/list/tracker_card.dart';

class TemplateListPage extends StatelessWidget {
  const TemplateListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    bool hasCubit = false;
    if (GetIt.I.isRegistered<TemplateListCubit>()) {
      try {
        // Probe if we can instantiate it (dependencies might be missing)
        GetIt.I.get<TemplateListCubit>();
        hasCubit = true;
      } catch (e) {
        debugPrint('Cubit probe failed: $e');
      }
    }

    if (!hasCubit) {
      // Fallback UI for preview when backend is dead
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              VSpace.x3,
              const DashboardHeader(),
              VSpace.x3,
              Expanded(
                child: GridView.count(
                  padding: AppPadding.page,
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSizes.space * 2,
                  mainAxisSpacing: AppSizes.space * 4,
                  childAspectRatio: 0.8,
                  children: [
                    TrackerCard(
                      title: 'Preview Tracker',
                      emoji: '👁️',
                      onEdit: () {},
                      onQuickAction: () {},
                    ),
                    TrackerCard(
                      title: 'Another One',
                      emoji: '🧪',
                      onEdit: () {},
                      onQuickAction: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton(
          onPressed: () => AppNavigation.toTemplateGenerator(context),
          backgroundColor: QuanityaPalette.primary.backgroundPrimary,
          foregroundColor: QuanityaPalette.primary.textPrimary,
          shape: const CircleBorder(),
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.all(AppSizes.space),
            child: Image.asset(
              'assets/quanitya.png',
              color: QuanityaPalette.primary.textPrimary,
            ),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => GetIt.I<TemplateListCubit>()..load(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              VSpace.x3,
              const DashboardHeader(),
              VSpace.x3,

              Expanded(
                child: BlocBuilder<TemplateListCubit, TemplateListState>(
                  builder: (context, state) {
                    if (state.templates.isEmpty) {
                      return Center(
                        child: Text(
                          'No templates yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: AppPadding.page,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSizes.space * 2,
                        mainAxisSpacing:
                            AppSizes.space * 4, // More vertical spacing
                        childAspectRatio: 0.8, // Taller cards
                      ),
                      itemCount: state.templates.length,
                      itemBuilder: (context, index) {
                        final item = state.templates[index];
                        return TrackerCard(
                          title: item.template.name,
                          icon: item.aesthetics.icon,
                          emoji: item.aesthetics.emoji,
                          template: item.template, // Pass template for default checking
                          onEdit: () {
                            AppNavigation.toTemplateGenerator(context, item);
                          },
                          onQuickAction: () => AppNavigation.toLogEntry(context, item.template.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton(
          onPressed: () => AppNavigation.toTemplateGenerator(context),
          backgroundColor: QuanityaPalette.primary.backgroundPrimary,
          foregroundColor: QuanityaPalette.primary.textPrimary,
          shape: const CircleBorder(),
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.all(AppSizes.space),
            child: Image.asset(
              'assets/quanitya.png',
              color: QuanityaPalette.primary.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
