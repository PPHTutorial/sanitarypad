#!/bin/bash

# Script to generate app icons and splash screens for FemCare+
# Run this script after updating your logo or configuration files

echo "🎨 Generating app icons and splash screens for FemCare+..."
echo ""

# Check if logo exists
if [ ! -f "assets/images/logo.png" ]; then
    echo "❌ Error: Logo not found at assets/images/logo.png"
    echo "Please add your logo (1024x1024px PNG recommended) before running this script."
    exit 1
fi

echo "📦 Installing dependencies..."
flutter pub get

echo ""
echo "🖼️  Generating app icons..."
flutter pub run flutter_launcher_icons

echo ""
echo "🌅 Generating splash screens..."
flutter pub run flutter_native_splash:create

echo ""
echo "✅ Done! Icons and splash screens have been generated."
echo ""
echo "Next steps:"
echo "1. Clean your build: flutter clean"
echo "2. Rebuild your app: flutter run"
echo "3. Test on different platforms to verify icons and splash screens"

