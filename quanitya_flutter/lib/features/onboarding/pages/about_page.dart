import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../app_router.dart';
import '../../../app/bootstrap.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/structures/column.dart';
import '../../../design_system/widgets/device_name_display.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../infrastructure/device/device_info_service.dart';
import '../../../infrastructure/feedback/base_state_message_mapper.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/widgets/quanitya_empty_state.dart';
import '../cubits/onboarding_cubit.dart';
import '../cubits/onboarding_state.dart';
import '../services/onboarding_message_mapper.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OnboardingCubit>(),
      child: const _AboutView(),
    );
  }
}

class _AboutView extends StatelessWidget {
  const _AboutView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: UiFlowStateListener<OnboardingCubit, OnboardingState>(
        mapper: BaseStateMessageMapper<OnboardingState>(
          exceptionMapper: getIt<IExceptionKeyMapper>(),
          domainMapper: getIt<OnboardingMessageMapper>(),
        ),
        uiService: getIt<IUiFlowService>(),
        child: BlocConsumer<OnboardingCubit, OnboardingState>(
          listenWhen: (prev, curr) => !prev.hasAccount && curr.hasAccount,
          listener: (context, state) {
            AppNavigation.toRecoveryKeyBackup(
              context,
              context.read<OnboardingCubit>(),
            );
          },
          builder: (context, state) {
            // Show loading screen while generating keys
            if (state.isLoading) {
              return _KeyGenerationLoadingView();
            }

            return SingleChildScrollView(
              padding: AppPadding.pageHorizontal,
              child: Padding(
                padding: AppPadding.verticalDouble,
                child: QuanityaColumn(
                  crossAlignment: CrossAxisAlignment.start,
                  spacing: VSpace.x4,
                  children: [
                    _HeaderSection(),
                    _NameExplanationSection(),
                    _FeaturesSection(),
                    const _FooterSection(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Loading screen shown while generating cryptographic keys
class _KeyGenerationLoadingView extends StatefulWidget {
  @override
  State<_KeyGenerationLoadingView> createState() => _KeyGenerationLoadingViewState();
}

class _KeyGenerationLoadingViewState extends State<_KeyGenerationLoadingView> {
  int _dotCount = 0;
  late final Timer _timer;
  String _deviceName = '';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() {
        _dotCount = (_dotCount + 1) % 4;
      });
    });
    _loadDeviceName();
  }

  Future<void> _loadDeviceName() async {
    final name = await getIt<DeviceInfoService>().getDeviceName();
    if (mounted) {
      setState(() => _deviceName = name);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _dotCount;
    // Pad to keep text from jumping
    final paddedDots = dots.padRight(3);
    
    return Center(
      child: Padding(
        padding: AppPadding.page,
        child: QuanityaColumn(
          mainAlignment: MainAxisAlignment.center,
          crossAlignment: CrossAxisAlignment.center,
          spacing: VSpace.x3,
          children: [
            // Key icon - the anchor
            Icon(
              Icons.key_rounded,
              size: AppSizes.iconXLarge * 2.5,
              color: context.colors.textPrimary,
            ),
            VSpace.x4,
            // Title with animated dots - header role
            Text(
              '${context.l10n.generatingKeysTitle}$paddedDots',
              style: context.text.headlineSmall,
              textAlign: TextAlign.center,
            ),
            // Description - body role, secondary color
            Text(
              context.l10n.generatingKeysDescription,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            VSpace.x4,
            // Device name display
            DeviceNameDisplay(
              label: context.l10n.pairingDeviceNameLabel,
              deviceName: _deviceName,
            ),
            VSpace.x2,
            // Time hint - metadata role, whisper
            Text(
              context.l10n.generatingKeysHint,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Title + subtitle + pronunciation
class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final secondaryText = context.colors.textSecondary;
    final bodyStyle = context.text.bodyMedium?.copyWith(color: secondaryText);
    final boldStyle = bodyStyle?.copyWith(fontWeight: FontWeight.bold);

    return QuanityaColumn(
      spacing: VSpace.x2,
      children: [
        Text(context.l10n.aboutTitle, style: context.text.headlineLarge),
        Text(
          context.l10n.aboutSubtitle(
            context.l10n.aboutQuaTitle,
            context.l10n.aboutAnityaTitle,
          ),
          style: bodyStyle,
        ),
        Text(
          context.l10n.aboutPronunciation,
          style: bodyStyle?.copyWith(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

/// Qua and Anitya definitions
class _NameExplanationSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return QuanityaColumn(
      spacing: VSpace.x3,
      children: [
        Text(context.l10n.aboutPhilosophyTitle, style: context.text.headlineMedium),
        _DefinitionItem(
          title: context.l10n.aboutQuaTitle,
          subtitle: context.l10n.aboutQuaSubtitle,
          description: context.l10n.aboutQuaDescription,
        ),
        _DefinitionItem(
          title: context.l10n.aboutAnityaTitle,
          subtitle: context.l10n.aboutAnityaSubtitle,
          description: context.l10n.aboutAnityaDescription,
        ),
      ],
    );
  }
}

class _DefinitionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;

  const _DefinitionItem({
    required this.title,
    required this.subtitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final bodyStyle = context.text.bodyMedium?.copyWith(
      color: context.colors.textSecondary,
    );

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: context.colors.textSecondary.withValues(alpha: 0.3),
            width: AppSizes.borderWidthThick,
          ),
        ),
      ),
      padding: AppPadding.horizontalDouble,
      child: QuanityaColumn(
        spacing: VSpace.x1,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(title, style: context.text.headlineSmall),
              HSpace.x1,
              Text(
                subtitle,
                style: bodyStyle?.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(description, style: bodyStyle),
        ],
      ),
    );
  }
}

/// Privacy, Anonymous, Local-first, Open Source features
class _FeaturesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return QuanityaColumn(
      spacing: VSpace.x3,
      children: [
        _FeatureItem(
          title: context.l10n.aboutPrivacyTitle,
          description: context.l10n.aboutPrivacyDescription,
          icon: Icons.security,
        ),
        _FeatureItem(
          title: context.l10n.aboutAnonymousTitle,
          description: context.l10n.aboutAnonymousDescription,
          icon: Icons.person_off,
        ),
        _FeatureItem(
          title: context.l10n.aboutLocalTitle,
          description: context.l10n.aboutLocalDescription,
          icon: Icons.wifi_off,
        ),
        _FeatureItem(
          title: context.l10n.aboutSourceTitle,
          description: context.l10n.aboutSourceDescription,
          icon: Icons.code,
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _FeatureItem({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bodyStyle = context.text.bodyMedium?.copyWith(
      color: context.colors.textSecondary,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: QuanityaColumn(
            spacing: VSpace.x05,
            children: [
              Text(title, style: context.text.headlineSmall),
              Text(description, style: bodyStyle),
            ],
          ),
        ),
        HSpace.x2,
        Icon(icon, size: AppSizes.iconMedium, color: context.colors.textPrimary),
      ],
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.verticalQuadruple,
      child: QuanityaColumn(
        spacing: VSpace.x4,
        children: [
          const QuanityaEmptyState(),
          QuanityaTextButton(
            text: context.l10n.createAccount,
            onPressed: () async => await context.read<OnboardingCubit>().createAccount(),
          ),
        ],
      ),
    );
  }
}
