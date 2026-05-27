# Quick Start Guide

Get the CollegeSapien app running in 5 minutes!

## Prerequisites

Make sure you have Flutter installed:

```bash
flutter doctor
```

## Setup Steps

### 0. Navigate to the app directory

```bash
cd app
```

### 1. Download Fonts (Automated)

Run the font setup script:

```bash
./setup_fonts.sh
```

Then manually copy the required font files from the downloaded folders to the `fonts/` directory:

```bash
# Copy Lexend Mega fonts
cp fonts/LexendMega/static/LexendMega-Bold.ttf fonts/
cp fonts/LexendMega/static/LexendMega-SemiBold.ttf fonts/
cp fonts/LexendMega/static/LexendMega-Regular.ttf fonts/

# Copy Public Sans fonts
cp fonts/PublicSans/static/PublicSans-ExtraBold.ttf fonts/
cp fonts/PublicSans/static/PublicSans-Bold.ttf fonts/
cp fonts/PublicSans/static/PublicSans-SemiBold.ttf fonts/
cp fonts/PublicSans/static/PublicSans-Regular.ttf fonts/
cp fonts/PublicSans/static/PublicSans-Light.ttf fonts/

# Copy Inter fonts
cp fonts/Inter/static/Inter-Bold.ttf fonts/
cp fonts/Inter/static/Inter-Medium.ttf fonts/

# Copy Patrick Hand font
cp fonts/PatrickHand/PatrickHand-Regular.ttf fonts/
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
flutter run
```

## Troubleshooting

### "No such file or directory" errors for fonts

Make sure you've:

1. Run `./setup_fonts.sh`
2. Copied the font files to the `fonts/` directory
3. Run `flutter pub get`

### Asset errors

Make sure the `assets/images/` directory exists and contains all the downloaded images.

### Build errors

Try cleaning and rebuilding:

```bash
flutter clean
flutter pub get
flutter run
```

## Screen Sizes Tested

The app is fully responsive and has been designed to work on:

- ✅ Small phones (320px width)
- ✅ Medium phones (375px width)
- ✅ Large phones (414px width)
- ✅ Tablets (768px+ width)

## Next Steps

- Customize the attendance percentage in `lib/screens/home_screen.dart`
- Add more timetable entries
- Connect to a backend API
- Add navigation to other screens

## Support

For issues or questions, refer to the main README.md file.
