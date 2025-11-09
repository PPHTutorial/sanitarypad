# Assets Directory

This directory contains all static assets used in the FemCare+ application.

## Directory Structure

```
assets/
├── images/          # Image assets (logos, illustrations, etc.)
│   └── logo.png    # Main app logo (1024x1024 recommended)
├── icons/          # Icon assets
└── fonts/         # Custom fonts (if any)
```

## Asset Guidelines

### Images
- **Logo**: Should be 1024x1024px PNG with transparent background
- **Format**: PNG for images with transparency, JPG for photos
- **Optimization**: Compress images before adding to reduce app size

### Icons
- Use vector icons when possible
- Ensure icons are scalable and look good at different sizes

### Usage in Code

```dart
// Load an image asset
Image.asset('assets/images/logo.png')

// Load an icon asset
Image.asset('assets/icons/icon_name.png')
```

## Generating App Icons

Run the following command to generate app icons for all platforms:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

## Generating Splash Screens

Run the following command to generate native splash screens:

```bash
flutter pub get
flutter pub run flutter_native_splash:create
```

## Notes

- All assets must be declared in `pubspec.yaml`
- Asset paths are case-sensitive
- Use relative paths from the project root
- Keep asset sizes optimized for mobile performance

