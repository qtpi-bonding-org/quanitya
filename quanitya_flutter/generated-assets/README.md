# Zen Background Assets

These are generated PNG assets of the Quanitya zen paper background, designed for use in landing pages, marketing sites, and web applications.

## Files

- **zen_background_tile_240.png** (240x240px) - Small repeatable tile, optimized for file size
- **zen_background_tile_480.png** (480x480px) - 2x resolution repeatable tile for retina displays
- **zen_background_1920x1080.png** (1920x1080px) - Full HD background for hero sections

## Design Specs

- **Base Color**: #FAF7F0 (Washi White)
- **Dot Color**: #4D5B60 at 25% opacity (Blue-grey)
- **Dot Spacing**: 24px
- **Dot Radius**: 1.2px

## Usage

### CSS (Repeating Pattern)

```css
body {
  background-color: #FAF7F0;
  background-image: url('/assets/zen_backgrounds/zen_background_tile_240.png');
  background-repeat: repeat;
}

/* For retina displays */
@media (-webkit-min-device-pixel-ratio: 2), (min-resolution: 192dpi) {
  body {
    background-image: url('/assets/zen_backgrounds/zen_background_tile_480.png');
    background-size: 240px 240px;
  }
}
```

### Astro

1. Copy files to `public/assets/zen_backgrounds/`
2. Reference in your layout or component:

```astro
---
// src/layouts/Layout.astro
---
<style>
  body {
    background-color: #FAF7F0;
    background-image: url('/assets/zen_backgrounds/zen_background_tile_240.png');
    background-repeat: repeat;
  }
</style>
```

### React/Next.js

```jsx
<div style={{
  backgroundColor: '#FAF7F0',
  backgroundImage: 'url("/assets/zen_backgrounds/zen_background_tile_240.png")',
  backgroundRepeat: 'repeat',
}}>
  {/* Your content */}
</div>
```

### Tailwind CSS

Add to your `tailwind.config.js`:

```js
module.exports = {
  theme: {
    extend: {
      backgroundImage: {
        'zen-paper': "url('/assets/zen_backgrounds/zen_background_tile_240.png')",
      },
      backgroundColor: {
        'washi': '#FAF7F0',
      },
    },
  },
}
```

Then use in your components:

```jsx
<div className="bg-washi bg-zen-paper bg-repeat">
  {/* Your content */}
</div>
```

## Regenerating Assets

If you need to regenerate these assets (e.g., after changing colors or spacing):

```bash
cd quanitya
./scripts/generate_zen_background.sh
```

This will:
1. Run the Flutter golden tests
2. Generate new PNG files
3. Copy them to this directory

## Technical Details

The assets are generated using Flutter's golden testing system, which renders the actual `ZenPaperBackground` widget used in the Quanitya app. This ensures perfect consistency between the app and web assets.

The test file is located at: `quanitya_flutter/test/generate_zen_background_test.dart`
