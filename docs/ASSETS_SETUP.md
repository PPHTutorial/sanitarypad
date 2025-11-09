# Assets and Launcher Icons Setup Guide

This guide explains how to configure and generate app icons and splash screens for FemCare+.

## Prerequisites

1. A logo image (1024x1024px PNG recommended)
2. The logo should be placed in `assets/images/logo.png`

## Configuration Files

### 1. `pubspec.yaml`
- Assets are declared in the `flutter.assets` section
- `flutter_launcher_icons` and `flutter_native_splash` are in `dev_dependencies`

### 2. `flutter_launcher_icons.yaml`
- Configures app icon generation for all platforms
- Supports adaptive icons for Android
- Generates icons for iOS, Android, Web, Windows, macOS, and Linux

### 3. `flutter_native_splash.yaml`
- Configures native splash screen generation
- Supports Android 12+ material design splash screens
- Configures iOS, Web splash screens

## Setup Steps

### Step 1: Prepare Your Logo

1. Create a 1024x1024px PNG image
2. Use a transparent background (recommended)
3. Place it in `assets/images/logo.png`
4. Ensure the logo is centered and looks good at small sizes

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Generate App Icons

```bash
flutter pub run flutter_launcher_icons
```

This will:
- Generate icons for all platforms
- Create adaptive icons for Android
- Update platform-specific configuration files

### Step 4: Generate Splash Screens

```bash
flutter pub run flutter_native_splash:create
```

This will:
- Generate native splash screens for all platforms
- Configure Android 12+ material design splash screens
- Set up iOS launch screens

## Customization

### Changing App Icon

1. Replace `assets/images/logo.png` with your new logo
2. Update `flutter_launcher_icons.yaml` if needed
3. Run `flutter pub run flutter_launcher_icons`

### Changing Splash Screen

1. Update `flutter_native_splash.yaml`:
   - Change `color` for background color
   - Change `image` for splash image
   - Adjust `android_12` settings for Android 12+
2. Run `flutter pub run flutter_native_splash:create`

### Removing Splash Screen

```bash
flutter pub run flutter_native_splash:remove
```

## Platform-Specific Notes

### Android
- Adaptive icons require foreground and background
- Minimum SDK 21 for adaptive icons
- Icon sizes: 48dp (mdpi) to 192dp (xxxhdpi)

### iOS
- Requires multiple icon sizes (20pt to 1024pt)
- Supports @2x and @3x variants
- Icon should not have alpha channel for iOS

### Web
- Generates favicon and app icons
- Supports PWA manifest icons

### Windows
- Generates .ico file
- Default size: 48x48

### macOS
- Generates .icns file
- Multiple sizes for different contexts

## Troubleshooting

### Icons Not Appearing
1. Clean build: `flutter clean`
2. Regenerate icons: `flutter pub run flutter_launcher_icons`
3. Rebuild app: `flutter run`

### Splash Screen Not Showing
1. Clean build: `flutter clean`
2. Regenerate splash: `flutter pub run flutter_native_splash:create`
3. Rebuild app: `flutter run`

### Android Adaptive Icon Issues
- Ensure `adaptive_icon_foreground` and `adaptive_icon_background` are set
- Foreground image should be centered
- Background color should complement the foreground

## Color Scheme

Current theme colors:
- **Primary Pink**: `#FF69B4`
- **Light Pink Background**: `#FFE1E6`
- **Dark Mode Background**: `#1A1A1A`

Update these in the configuration files to match your brand colors.

## Best Practices

1. **Logo Design**:
   - Keep it simple and recognizable at small sizes
   - Test on different backgrounds
   - Ensure good contrast

2. **Splash Screen**:
   - Keep loading time minimal
   - Use brand colors
   - Consider dark mode support

3. **Asset Optimization**:
   - Compress images before adding
   - Use appropriate formats (PNG for transparency, JPG for photos)
   - Keep file sizes small

4. **Testing**:
   - Test icons on actual devices
   - Check different screen densities
   - Verify splash screens on all platforms

## Additional Resources

- [flutter_launcher_icons Documentation](https://pub.dev/packages/flutter_launcher_icons)
- [flutter_native_splash Documentation](https://pub.dev/packages/flutter_native_splash)
- [Android Adaptive Icons Guide](https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive)
- [iOS App Icon Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons)

