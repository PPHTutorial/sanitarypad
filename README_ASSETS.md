# Assets and Icons Setup ✅

Assets and launcher icons have been successfully configured for FemCare+!

## ✅ What's Been Configured

### 1. **Assets Configuration**
- ✅ Assets directory structure set up (`assets/images/`, `assets/icons/`)
- ✅ Assets declared in `pubspec.yaml`
- ✅ Logo placeholder at `assets/images/logo.png`

### 2. **App Icons**
- ✅ `flutter_launcher_icons`` package installed
- ✅ Configuration file created (`flutter_launcher_icons.yaml`)
- ✅ Icons generated for all platforms:
  - Android (including adaptive icons)
  - iOS
  - Web
  - Windows
  - macOS
  - Linux

### 3. **Splash Screens**
- ✅ `flutter_native_splash` package installed
- ✅ Configuration file created (`flutter_native_splash.yaml`)
- ✅ Ready to generate splash screens

## 📋 Next Steps

### To Generate Splash Screens:
```bash
flutter pub run flutter_native_splash:create
```

### To Regenerate Icons (if you update the logo):
```bash
flutter pub run flutter_launcher_icons
```

### Or Use the Scripts:
**Windows:**
```bash
scripts\generate_assets.bat
```

**Linux/Mac:**
```bash
chmod +x scripts/generate_assets.sh
./scripts/generate_assets.sh
```

## 🎨 Customization

### Update Your Logo
1. Replace `assets/images/logo.png` with your logo (1024x1024px recommended)
2. Run the icon generation command
3. Clean and rebuild: `flutter clean && flutter run`

### Customize Colors
Edit the configuration files:
- **Icons**: `flutter_launcher_icons.yaml`
- **Splash**: `flutter_native_splash.yaml`

Current theme colors:
- Primary Pink: `#FF69B4`
- Light Pink Background: `#FFE1E6`
- Dark Mode Background: `#1A1A1A`

## 📚 Documentation

See `docs/ASSETS_SETUP.md` for detailed documentation on:
- Asset management
- Icon generation
- Splash screen configuration
- Troubleshooting

## ✨ Features

- ✅ Multi-platform icon support
- ✅ Android adaptive icons
- ✅ iOS icon generation
- ✅ Web favicon and PWA icons
- ✅ Windows and macOS icons
- ✅ Native splash screens
- ✅ Dark mode support (splash screens)
- ✅ Android 12+ material design splash screens

## 🚀 Quick Commands

```bash
# Generate everything
flutter pub get
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create

# Clean and rebuild
flutter clean
flutter run
```

---

**Note**: Make sure your logo is 1024x1024px PNG for best results. The logo should work well at small sizes and have good contrast.

