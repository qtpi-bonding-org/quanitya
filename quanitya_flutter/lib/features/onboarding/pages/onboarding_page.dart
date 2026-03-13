import 'package:flutter/material.dart';

import '../../../app_router.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/structures/column.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../support/extensions/context_extensions.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: AppPadding.page,
          child: Column(
            children: [
              // Hero section - logo and title (star of the show)
              Expanded(
                child: Center(
                  child: QuanityaColumn(
                    mainAlignment: MainAxisAlignment.center,
                    crossAlignment: CrossAxisAlignment.center,
                    spacing: VSpace.x4,
                    children: [
                      // Logo
                      SizedBox(
                        width: AppSizes.iconXLarge * 5,
                        height: AppSizes.iconXLarge * 5,
                        child: Image.asset(
                          'assets/quanitya.png',
                          color: context.colors.textPrimary,
                          excludeFromSemantics: true,
                        ),
                      ),
                      // Title - header style with letter spacing
                      Text(
                        context.l10n.onboardingTitle.split('').join(' '),
                        style: context.text.headlineMedium?.copyWith(
                          letterSpacing: AppSizes.space / 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              // Action buttons - pinned to bottom, close together
              QuanityaColumn(
                crossAlignment: CrossAxisAlignment.center,
                spacing: VSpace.x1,
                children: [
                  // Get Started - navigates to about page
                  QuanityaTextButton(
                    text: context.l10n.getStarted,
                    onPressed: () => AppNavigation.toAbout(context),
                  ),
                  // Connect Device - for users with existing account
                  QuanityaTextButton(
                    text: context.l10n.connectDevice,
                    onPressed: () => AppNavigation.toConnectDevice(context),
                  ),
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
