# Golf Scorecard ⛳

A beautiful, modern golf scoring application with comprehensive statistics tracking, player management, and dark mode support.

## 📱 Features

- **Score Tracking**: Track scores for multiple players across 9, 18, 27, or 36 holes
- **Player Management**: Add players with photos and manage player profiles
- **Statistics**: Comprehensive statistics including:
  - Best/Average/Worst scores
  - Performance by hole
  - Game history
  - Consistency tracking
- **Beautiful UI**: Modern Material 3 design with smooth animations
- **Dark Mode**: Gorgeous dark theme with emerald accents on slate backgrounds
- **Game History**: Browse and review all past games
- **Photo Support**: Add player photos from camera or gallery
- **Share Results**: Share scorecards with friends

## 🎨 Design Highlights

- **Modern Color Scheme**: Emerald green (#10B981) primary color
- **Dark Mode**: Professional slate-based dark theme (#0F172A)
- **Smooth Animations**: Fade, slide, and scale transitions
- **Gradient Backgrounds**: Beautiful gradients throughout
- **Material 3**: Latest Material Design principles
- **Responsive**: Adapts to different screen sizes

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (^3.9.2)
- iOS development: Xcode and CocoaPods
- Android development: Android Studio

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd minigolf_scorer
```

2. Install dependencies
```bash
flutter pub get
```

3. For iOS, install pods
```bash
cd ios && pod install && cd ..
```

4. Run the app
```bash
flutter run
```

## 📦 Dependencies

- **flutter_bloc**: State management
- **sqflite**: Local database storage
- **shared_preferences**: Settings persistence
- **image_picker**: Player photo capture
- **permission_handler**: Camera and photo permissions
- **share_plus**: Share scorecard functionality
- **intl**: Date formatting

## 🏗️ Architecture

The app follows Clean Architecture principles with:

- **Presentation Layer**: BLoC pattern for state management
- **Application Layer**: Business logic and services
- **Domain Layer**: Entities and models
- **Core Layer**: Themes, utilities, and widgets

## 📱 App Identifiers

- **Package Name**: `golfscorecard`
- **Display Name**: Golf Scorecard
- **Bundle ID**: `com.app.golfscorecard`

## 🎯 Screens

1. **Home**: View recent games and quick access to all features
2. **New Game**: Create and score a new game
3. **Players**: Manage player profiles
4. **Statistics**: View comprehensive player statistics
5. **Game History**: Browse all past games
6. **Settings**: Theme selection and app information

## 🌙 Theme Modes

- **Light Mode**: Clean, bright interface with emerald accents
- **Dark Mode**: Beautiful dark slate backgrounds with emerald highlights
- **System**: Automatically follows device settings

## 📄 License

Copyright © 2025 com.app. All rights reserved.

## 🛠️ Build Instructions

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 📸 Screenshots

(Add your app screenshots here)

## 🔄 Version History

- **v1.0.0**: Initial release with complete UI overhaul and dark mode

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

Built with ❤️ using Flutter
