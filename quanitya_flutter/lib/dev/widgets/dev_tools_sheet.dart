import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart' as cubit_ui_flow;

import '../../app_router.dart';
import '../../data/interfaces/analysis_pipeline_interface.dart';
import '../../design_system/primitives/app_sizes.dart';
import '../../design_system/primitives/app_spacings.dart';
import '../../design_system/primitives/quanitya_palette.dart';
import '../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../design_system/widgets/quanitya_confirmation_dialog.dart';
import '../../infrastructure/crypto/crypto_key_repository.dart';
import '../../logic/analytics/enums/analysis_output_mode.dart';
import '../../logic/analytics/models/analysis_enums.dart';
import '../../logic/analytics/models/analysis_pipeline.dart';
import '../../support/extensions/context_extensions.dart';
import '../../features/app_operating_mode/cubits/app_operating_cubit.dart';
import '../../infrastructure/auth/auth_service.dart';
import '../../infrastructure/notifications/notification_service.dart';
import '../services/dev_seeder_service.dart';

/// Shows a bottom sheet with dev tools
void showDevToolsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.backgroundPrimary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSizes.radiusLarge),
      ),
    ),
    builder: (ctx) => const DevToolsSheet(),
  );
}

/// Dev tools bottom sheet content
class DevToolsSheet extends StatelessWidget {
  const DevToolsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: AppPadding.page,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Handle bar
            Center(
              child: Container(
                width: AppSizes.space * 5,
                height: AppSizes.space * 0.5,
                decoration: BoxDecoration(
                  color: context.colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
              ),
            ),
            VSpace.x3,

            // Title
            Text(
              context.l10n.devToolsTitle,
              style: context.text.titleLarge?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            VSpace.x3,

            // Seed fake data
            _DevToolRow(
              label: context.l10n.devSeedFakeData,
              child: _DevSeedButton(),
            ),
            VSpace.x2,

            // Seed test analysis pipelines
            _DevToolRow(
              label: 'Seed Test JS Analysis',
              child: _DevSeedAnalysisButton(),
            ),
            VSpace.x2,

            // Clear all data
            _DevToolRow(
              label: context.l10n.devClearAllData,
              child: _DevClearButton(),
            ),
            VSpace.x2,

            // Wipe crypto keys
            _DevToolRow(
              label: context.l10n.devWipeCryptoKeys,
              child: _DevWipeKeysButton(),
            ),
            VSpace.x2,

            // Connect to cloud
            _DevToolRow(
              label: context.l10n.devConnectToCloud,
              child: _DevConnectCloudButton(),
            ),
            VSpace.x2,

            // Create account
            _DevToolRow(
              label: context.l10n.devCreateAccount,
              child: _DevCreateAccountButton(),
            ),
            VSpace.x2,

            // Register account
            _DevToolRow(
              label: context.l10n.devRegisterAccount,
              child: _DevRegisterAccountButton(),
            ),
            VSpace.x2,

            // Test local notification
            _DevToolRow(
              label: 'Test Notification',
              child: _DevTestNotificationButton(),
            ),
            VSpace.x2,

            // Navigation shortcuts
            const Divider(),
            VSpace.x2,
            Text(
              'NAVIGATION',
              style: context.text.titleMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            VSpace.x2,
            Wrap(
              spacing: AppSizes.space,
              runSpacing: AppSizes.space,
              children: [
                _NavChip(label: 'Onboarding', route: AppRoutes.onboarding),
                _NavChip(label: 'About', route: AppRoutes.about),
                _NavChip(label: 'Settings', route: AppRoutes.settings),
                _NavChip(label: 'Template Editor', route: AppRoutes.templateEditor),
                _NavChip(label: 'Visualization', route: AppRoutes.visualization),
                _NavChip(label: 'Pipeline Builder', route: AppRoutes.pipelineBuilder),
              ],
            ),
            VSpace.x4,
          ],
          ),
        ),
      ),
    );
  }
}

class _DevToolRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _DevToolRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: context.text.bodyLarge?.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _NavChip extends StatelessWidget {
  final String label;
  final String route;

  const _NavChip({required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        Navigator.pop(context);
        _navigateToRoute(context, route);
      },
    );
  }

  void _navigateToRoute(BuildContext context, String route) {
    switch (route) {
      case AppRoutes.onboarding:
        context.go(route); // Use go for onboarding to reset stack
      case AppRoutes.about:
        AppNavigation.toAbout(context);
      case AppRoutes.settings:
        AppNavigation.toSettings(context);
      case AppRoutes.templateEditor:
        AppNavigation.toTemplateGenerator(context);
      case AppRoutes.visualization:
        AppNavigation.toVisualization(context);
      case AppRoutes.pipelineBuilder:
        AppNavigation.toAnalysisBuilder(context);
      default:
        context.go(route);
    }
  }
}

class _DevSeedButton extends StatefulWidget {
  @override
  State<_DevSeedButton> createState() => _DevSeedButtonState();
}

class _DevSeedButtonState extends State<_DevSeedButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: AppSizes.iconMedium,
        height: AppSizes.iconMedium,
        child: CircularProgressIndicator(strokeWidth: AppSizes.borderWidthThick),
      );
    }

    final l10n = context.l10n;
    return QuanityaTextButton(
      text: l10n.devSeed,
      onPressed: () async {
        setState(() => _isLoading = true);
        try {
          final seeder = GetIt.instance<DevSeederService>();
          await seeder.clearAndSeed();
          if (mounted) {
            final feedbackService = GetIt.instance<cubit_ui_flow.IFeedbackService>();
            feedbackService.show(
              cubit_ui_flow.FeedbackMessage(
                message: l10n.devSeeded,
                type: cubit_ui_flow.MessageType.success,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }
}

class _DevClearButton extends StatefulWidget {
  @override
  State<_DevClearButton> createState() => _DevClearButtonState();
}

class _DevClearButtonState extends State<_DevClearButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: AppSizes.iconMedium,
        height: AppSizes.iconMedium,
        child: CircularProgressIndicator(strokeWidth: AppSizes.borderWidthThick),
      );
    }

    final l10n = context.l10n;
    return QuanityaTextButton(
      text: l10n.devClear,
      isDestructive: true,
      onPressed: () async {
        setState(() => _isLoading = true);
        try {
          final seeder = GetIt.instance<DevSeederService>();
          await seeder.clearAll();
          if (mounted) {
            final feedbackService = GetIt.instance<cubit_ui_flow.IFeedbackService>();
            feedbackService.show(
              cubit_ui_flow.FeedbackMessage(
                message: l10n.devCleared,
                type: cubit_ui_flow.MessageType.success,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }
}

class _DevWipeKeysButton extends StatefulWidget {
  @override
  State<_DevWipeKeysButton> createState() => _DevWipeKeysButtonState();
}

class _DevWipeKeysButtonState extends State<_DevWipeKeysButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: AppSizes.iconMedium,
        height: AppSizes.iconMedium,
        child: CircularProgressIndicator(strokeWidth: AppSizes.borderWidthThick),
      );
    }

    final l10n = context.l10n;
    return QuanityaTextButton(
      text: l10n.devWipe,
      isDestructive: true,
      onPressed: () async {
        final navigator = Navigator.of(context);
        final goRouter = GoRouter.of(context);
        
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (c) => QuanityaConfirmationDialog(
            title: l10n.devWipeKeysTitle,
            message: l10n.devWipeKeysMessage,
            onConfirm: () {},
            isDestructive: true,
            confirmText: l10n.devWipeKeysConfirm,
          ),
        );

        if (confirmed != true || !mounted) return;
        
        setState(() => _isLoading = true);
        try {
          final keyRepo = GetIt.instance<ICryptoKeyRepository>();
          await keyRepo.clearKeys();
          AppRouter.resetKeyCheck();
          if (mounted) {
            navigator.pop();
            goRouter.goNamed(RouteNames.onboarding);
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }
}
class _DevConnectCloudButton extends StatefulWidget {
  @override
  State<_DevConnectCloudButton> createState() => _DevConnectCloudButtonState();
}

class _DevConnectCloudButtonState extends State<_DevConnectCloudButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: AppSizes.iconMedium,
        height: AppSizes.iconMedium,
        child: CircularProgressIndicator(strokeWidth: AppSizes.borderWidthThick),
      );
    }

    final l10n = context.l10n;
    return QuanityaTextButton(
      text: l10n.devConnect,
      onPressed: () async {
        setState(() => _isLoading = true);
        try {
          final appOperatingCubit = GetIt.instance<AppOperatingCubit>();
          await appOperatingCubit.switchToCloud();
          
          // Let the cubit's UI flow system handle success/error messages
          // Don't manually show success - the AppOperatingMessageMapper will handle it
        } catch (e) {
          // The cubit already emits failure state, so UI flow will show error
          // No need for manual error handling here
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }
}
class _DevCreateAccountButton extends StatefulWidget {
  @override
  State<_DevCreateAccountButton> createState() => _DevCreateAccountButtonState();
}

class _DevCreateAccountButtonState extends State<_DevCreateAccountButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: AppSizes.iconMedium,
        height: AppSizes.iconMedium,
        child: CircularProgressIndicator(strokeWidth: AppSizes.borderWidthThick),
      );
    }

    final l10n = context.l10n;
    return QuanityaTextButton(
      text: l10n.devCreate,
      onPressed: () async {
        setState(() => _isLoading = true);
        try {
          print('🔐 Starting account creation...');
          
          final authService = GetIt.instance<AuthService>();
          final result = await authService.createAccount(
            deviceLabel: 'Dev Test Device',
          );
          
          print('🔐 Account creation result: ${result.toString()}');
          
          if (mounted) {
            final feedbackService = GetIt.instance<cubit_ui_flow.IFeedbackService>();
            feedbackService.show(
              cubit_ui_flow.FeedbackMessage(
                message: l10n.devAccountCreated,
                type: cubit_ui_flow.MessageType.success,
              ),
            );
          }
        } catch (e, stackTrace) {
          print('🔐 Account creation failed with error: $e');
          print('🔐 Stack trace: $stackTrace');
          print('🔐 Error type: ${e.runtimeType}');
          
          if (mounted) {
            final feedbackService = GetIt.instance<cubit_ui_flow.IFeedbackService>();
            feedbackService.show(
              cubit_ui_flow.FeedbackMessage(
                message: '${l10n.devAccountCreationFailed}: $e',
                type: cubit_ui_flow.MessageType.error,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }
}
class _DevRegisterAccountButton extends StatefulWidget {
  @override
  State<_DevRegisterAccountButton> createState() => _DevRegisterAccountButtonState();
}

class _DevRegisterAccountButtonState extends State<_DevRegisterAccountButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: AppSizes.iconMedium,
        height: AppSizes.iconMedium,
        child: CircularProgressIndicator(strokeWidth: AppSizes.borderWidthThick),
      );
    }

    final l10n = context.l10n;
    return QuanityaTextButton(
      text: l10n.devRegister,
      onPressed: () async {
        setState(() => _isLoading = true);
        try {
          print('🔐 Starting account registration with server...');
          
          final authService = GetIt.instance<AuthService>();
          await authService.registerAccountWithServer(
            deviceLabel: 'Dev Test Device',
          );
          
          print('🔐 Account registration completed successfully');
          
          if (mounted) {
            final feedbackService = GetIt.instance<cubit_ui_flow.IFeedbackService>();
            feedbackService.show(
              cubit_ui_flow.FeedbackMessage(
                message: l10n.devAccountRegistered,
                type: cubit_ui_flow.MessageType.success,
              ),
            );
          }
        } catch (e, stackTrace) {
          print('🔐 Account registration failed with error: $e');
          print('🔐 Stack trace: $stackTrace');
          print('🔐 Error type: ${e.runtimeType}');
          
          if (mounted) {
            final feedbackService = GetIt.instance<cubit_ui_flow.IFeedbackService>();
            feedbackService.show(
              cubit_ui_flow.FeedbackMessage(
                message: '${l10n.devAccountRegistrationFailed}: $e',
                type: cubit_ui_flow.MessageType.error,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }
}

class _DevSeedAnalysisButton extends StatefulWidget {
  @override
  State<_DevSeedAnalysisButton> createState() => _DevSeedAnalysisButtonState();
}

class _DevSeedAnalysisButtonState extends State<_DevSeedAnalysisButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: AppSizes.iconMedium,
        height: AppSizes.iconMedium,
        child: CircularProgressIndicator(strokeWidth: AppSizes.borderWidthThick),
      );
    }

    return QuanityaTextButton(
      text: 'Seed',
      onPressed: () async {
        setState(() => _isLoading = true);
        try {
          await _seedTestAnalysisPipelines();
          
          if (mounted) {
            final feedbackService = GetIt.instance<cubit_ui_flow.IFeedbackService>();
            feedbackService.show(
              cubit_ui_flow.FeedbackMessage(
                message: 'Seeded 3 test JS analysis pipelines',
                type: cubit_ui_flow.MessageType.success,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            final feedbackService = GetIt.instance<cubit_ui_flow.IFeedbackService>();
            feedbackService.show(
              cubit_ui_flow.FeedbackMessage(
                message: 'Failed to seed analysis: $e',
                type: cubit_ui_flow.MessageType.error,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _seedTestAnalysisPipelines() async {
    final repo = GetIt.instance.get<IAnalysisPipelineRepository>();
    
    final now = DateTime.now();
    
    // 1. SCALAR: Calculate mean and standard deviation
    final scalarPipeline = AnalysisPipelineModel(
      id: 'test-scalar-stats',
      name: 'Mood Statistics (Scalar)',
      fieldId: 'test-template:mood_score',
      outputMode: AnalysisOutputMode.scalar,
      snippetLanguage: AnalysisSnippetLanguage.js,
      snippet: '''
// Calculate multiple statistics
return [
  { label: 'Mean', value: ss.mean(data.values), unit: 'points' },
  { label: 'Std Dev', value: ss.standardDeviation(data.values), unit: 'points' },
  { label: 'Min', value: ss.min(data.values), unit: 'points' },
  { label: 'Max', value: ss.max(data.values), unit: 'points' }
];
      ''',
      reasoning: 'Test scalar output with multiple statistics',
      updatedAt: now,
    );
    
    // 2. VECTOR: Calculate 3-day moving average
    final vectorPipeline = AnalysisPipelineModel(
      id: 'test-vector-ma',
      name: '3-Day Moving Average (Vector)',
      fieldId: 'test-template:mood_score',
      outputMode: AnalysisOutputMode.vector,
      snippetLanguage: AnalysisSnippetLanguage.js,
      snippet: '''
// Calculate 3-day moving average
const windowSize = 3;
const movingAvg = [];

for (let i = windowSize - 1; i < data.values.length; i++) {
  const window = data.values.slice(i - windowSize + 1, i + 1);
  movingAvg.push(ss.mean(window));
}

return {
  label: '3-Day MA',
  values: movingAvg
};
      ''',
      reasoning: 'Test vector output with moving average',
      updatedAt: now,
    );
    
    // 3. MATRIX: Smooth time series with 3-point averaging
    final matrixPipeline = AnalysisPipelineModel(
      id: 'test-matrix-smooth',
      name: 'Smoothed Time Series (Matrix)',
      fieldId: 'test-template:mood_score',
      outputMode: AnalysisOutputMode.matrix,
      snippetLanguage: AnalysisSnippetLanguage.js,
      snippet: '''
// Apply 3-point smoothing
const smoothed = data.values.map((v, i) => {
  if (i === 0 || i === data.values.length - 1) {
    return v; // Keep endpoints unchanged
  }
  // Average with neighbors
  return (data.values[i-1] + v + data.values[i+1]) / 3;
});

return {
  values: smoothed
};
      ''',
      reasoning: 'Test matrix output with smoothing',
      updatedAt: now,
    );
    
    // Save all pipelines
    await repo.savePipeline(scalarPipeline);
    await repo.savePipeline(vectorPipeline);
    await repo.savePipeline(matrixPipeline);
  }
}

class _DevTestNotificationButton extends StatefulWidget {
  @override
  State<_DevTestNotificationButton> createState() => _DevTestNotificationButtonState();
}

class _DevTestNotificationButtonState extends State<_DevTestNotificationButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: AppSizes.iconMedium,
        height: AppSizes.iconMedium,
        child: CircularProgressIndicator(strokeWidth: AppSizes.borderWidthThick),
      );
    }

    return QuanityaTextButton(
      text: 'Send',
      onPressed: () async {
        setState(() => _isLoading = true);
        try {
          final notificationService = GetIt.instance<NotificationService>();
          await notificationService.showNow(
            id: 9999,
            title: 'Quanitya Test',
            body: 'This is a test notification from dev tools',
          );
          if (mounted) {
            final feedbackService = GetIt.instance<cubit_ui_flow.IFeedbackService>();
            feedbackService.show(
              cubit_ui_flow.FeedbackMessage(
                message: 'Notification sent',
                type: cubit_ui_flow.MessageType.success,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            final feedbackService = GetIt.instance<cubit_ui_flow.IFeedbackService>();
            feedbackService.show(
              cubit_ui_flow.FeedbackMessage(
                message: 'Failed: $e',
                type: cubit_ui_flow.MessageType.error,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }
}
