# Rewards & Recognition System - Frontend

## Tech Stack
- **Flutter 3.41.0+** - UI Framework
- **Dart** - Programming Language
- **flutter_bloc** - State management
- **get_it** - Dependency injection
- **dartz** - Functional programming (Error handling)
- **http** - Network requests

## Setup

1. **Switch to the frontend branch**:
   ```bash
   git checkout frontend
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Enable Web support**:
   ```bash
   flutter config --enable-web
   ```

4. **Start the application**:
   ```bash
   # Run in Chrome (Web)
   flutter run -d chrome
   
   # Run in Linux (Desktop)
   flutter run -d linux
   ```

**Note:** Ensure you have the Flutter SDK installed and `flutter doctor` shows no issues.

## Project Structure

```
frontend/
├── lib/
│   ├── main.dart            # Application entry point
│   ├── app.dart             # Root widget & theme setup
│   ├── core/                # Shared logic & components
│   │   ├── constants/       # API endpoints & strings
│   │   ├── theme/           # Light & Dark mode config
│   │   └── widgets/         # Common UI components
│   └── features/            # 13 Modular features
│       ├── auth/            # Login & Auth logic
│       ├── recognitions/    # Appreciations & Feed
│       └── analytics/       # Dashboards & Insights
├── pubspec.yaml             # Dependencies & assets
└── ARCHITECTURE.md          # Detailed architecture docs
```

## Architecture Details

The project follows **Clean Architecture** principles. Each feature in `lib/features/` is divided into:
- **Data**: API datasources and JSON models.
- **Domain**: Business rules, entities, and use cases.
- **Presentation**: UI widgets, pages, and BLoC state management.

For a complete breakdown of all 13 features and layer responsibilities, see [ARCHITECTURE.md](./ARCHITECTURE.md).
