#!/bin/bash

# Script to download required fonts for Codesapiens app

echo "🎨 Setting up fonts for Codesapiens app..."
echo ""

# Create fonts directory
mkdir -p fonts
cd fonts

# Function to download from Google Fonts
download_google_font() {
    local font_name=$1
    local font_url=$2

    echo "📥 Downloading $font_name..."

    # Download the font zip file
    curl -L "$font_url" -o "${font_name}.zip"

    # Unzip the fonts
    unzip -q "${font_name}.zip" -d "$font_name"

    # Remove the zip file
    rm "${font_name}.zip"

    echo "✅ $font_name downloaded"
}

# Download Lexend Mega
download_google_font "LexendMega" "https://fonts.google.com/download?family=Lexend%20Mega"

# Download Public Sans
download_google_font "PublicSans" "https://fonts.google.com/download?family=Public%20Sans"

# Download Inter
download_google_font "Inter" "https://fonts.google.com/download?family=Inter"

# Download Patrick Hand
download_google_font "PatrickHand" "https://fonts.google.com/download?family=Patrick%20Hand"

echo ""
echo "✨ Font setup complete!"
echo ""
echo "ℹ️  Note: You may need to manually copy the specific font files to the fonts/ directory"
echo "   Required files:"
echo "   - LexendMega-Bold.ttf, LexendMega-SemiBold.ttf, LexendMega-Regular.ttf"
echo "   - PublicSans-ExtraBold.ttf, PublicSans-Bold.ttf, PublicSans-SemiBold.ttf,"
echo "     PublicSans-Regular.ttf, PublicSans-Light.ttf"
echo "   - Inter-Bold.ttf, Inter-Medium.ttf"
echo "   - PatrickHand-Regular.ttf"
echo ""
echo "🚀 After copying the fonts, run: flutter pub get"
