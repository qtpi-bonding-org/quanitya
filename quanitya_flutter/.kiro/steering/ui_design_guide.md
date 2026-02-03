---
inclusion: always
---
# Quanitya UI Design Guide (Concise)

## Core Principle
**Manuscript over Application. Typography over Topography.**
No hardcoded pixel values. Use semantic tokens only.

## Spacing Tokens (ALWAYS use these)
```dart
VSpace.x025  // Optical correction (2px)
VSpace.x05   // Text glue (header + subtitle)
VSpace.x1    // Component breath (icon + label)
VSpace.x2    // Standard margin
VSpace.x3    // Narrative flow (list items)
HSpace.x05, HSpace.x1, HSpace.x2  // Horizontal equivalents
```

## Color Tokens (QuanityaPalette.primary)
```dart
palette.textPrimary       // Headers, data values
palette.textSecondary     // Body, metadata
palette.interactableColor // "Tap me" signal (teal)
palette.successColor      // Active states
palette.errorColor        // Errors
palette.backgroundPrimary // Surface
```

## Typography (context.text extension)
```dart
context.text.header   // Atkinson Hyperlegible Mono - anchors
context.text.body     // Noto Sans Mono - narrative
context.text.metadata // Noto Sans Mono Light - whispers
```

## Touch Targets
- Minimum 48px (`AppSizes.buttonHeight`)
- Use `QuanityaIconButton` for tappable icons
- Wrap small visuals in larger hit areas

## Anti-Patterns
- 🚫 `SizedBox(height: 10)` → Use `VSpace.x1`
- 🚫 `Theme.of(context).colorScheme.xxx` → Use `QuanityaPalette.primary.xxx`
- 🚫 `const EdgeInsets.all(8)` → Use `AppPadding.allSingle`
- 🚫 `BorderRadius.circular(12)` → Use `AppSizes.radiusSmall`
- 🚫 Raw `GestureDetector` on icons → Use `QuanityaIconButton`
