import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../infrastructure/fonts/font_preloader_service.dart';
import '../../logic/templates/enums/ai/allowed_font.dart';
import '../../design_system/primitives/app_spacings.dart';
import '../../design_system/primitives/app_sizes.dart';
import '../../design_system/primitives/quanitya_palette.dart';
import '../../support/extensions/context_extensions.dart';

/// Test page to verify all fonts are loading correctly.
/// 
/// Shows each font from AllowedFont enum with sample text.
/// Useful for debugging font loading issues.
class FontTestPage extends StatefulWidget {
  const FontTestPage({super.key});

  @override
  State<FontTestPage> createState() => _FontTestPageState();
}

class _FontTestPageState extends State<FontTestPage> {
  final _fontPreloader = GetIt.I<FontPreloaderService>();
  final Map<String, bool> _fontAvailability = {};
  
  @override
  void initState() {
    super.initState();
    _checkFontAvailability();
  }
  
  Future<void> _checkFontAvailability() async {
    for (final font in AllowedFont.values) {
      final isAvailable = await _fontPreloader.isFontAvailable(font.googleFontName);
      if (mounted) {
        setState(() {
          _fontAvailability[font.googleFontName] = isAvailable;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Font Test', style: context.text.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _fontAvailability.clear();
              });
              _checkFontAvailability();
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: AppPadding.page,
        itemCount: AllowedFont.values.length,
        itemBuilder: (context, index) {
          final font = AllowedFont.values[index];
          final isAvailable = _fontAvailability[font.googleFontName];
          
          return Card(
            margin: EdgeInsets.only(bottom: AppSizes.space),
            child: Padding(
              padding: AppPadding.allDouble,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Font name and status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          font.googleFontName,
                          style: context.text.titleMedium?.copyWith(
                            color: QuanityaPalette.primary.textPrimary,
                          ),
                        ),
                      ),
                      if (isAvailable != null)
                        Icon(
                          isAvailable ? Icons.check_circle : Icons.error,
                          color: isAvailable 
                            ? QuanityaPalette.primary.successColor 
                            : QuanityaPalette.primary.errorColor,
                          size: AppSizes.iconMedium,
                        )
                      else
                        SizedBox(
                          width: AppSizes.iconSmall,
                          height: AppSizes.iconSmall,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: QuanityaPalette.primary.interactableColor,
                          ),
                        ),
                    ],
                  ),
                  
                  VSpace.x1,
                  
                  // Sample text in the font
                  Text(
                    'The quick brown fox jumps over the lazy dog. 1234567890',
                    style: _fontPreloader.getTextStyle(
                      font.googleFontName,
                      fontSize: 16,
                      color: QuanityaPalette.primary.textSecondary,
                    ),
                  ),
                  
                  VSpace.x05,
                  
                  // Bold sample
                  Text(
                    'Bold: The quick brown fox jumps over the lazy dog.',
                    style: _fontPreloader.getTextStyle(
                      font.googleFontName,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: QuanityaPalette.primary.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            const SnackBar(content: Text('Preloading fonts...')),
          );
          
          await _fontPreloader.preloadAllFonts();
          
          if (mounted) {
            final palette = QuanityaPalette.primary;
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  _fontPreloader.isPreloaded 
                    ? 'All fonts preloaded!' 
                    : 'Some fonts failed to preload',
                ),
                backgroundColor: _fontPreloader.isPreloaded 
                  ? palette.successColor 
                  : palette.errorColor,
              ),
            );
            
            // Refresh availability check
            _checkFontAvailability();
          }
        },
        icon: const Icon(Icons.download),
        label: const Text('Preload Fonts'),
      ),
    );
  }
}