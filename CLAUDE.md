# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

```bash
flutter pub get                          # Install dependencies
flutter run                              # Run the app
flutter analyze                          # Lint / static analysis
flutter test                             # Run all tests
flutter test test/some_test.dart         # Run a single test file
flutter test --name "test name pattern"  # Run tests matching a name
flutter build apk                        # Android APK
flutter build appbundle                  # Android App Bundle (Play Store)
flutter build ios                        # iOS build
flutter clean                            # Clean build artifacts
```

## Architecture Overview

ZenRun is a fitness/wellness social app with chat, AI voice services, gamification, and shopping. It targets Android and iOS.

### Directory Layout

```
lib/
├── core/                  # Shared infrastructure used across features
│   ├── network/           # ApiHelper + DataState pattern
│   ├── PrefHelper/        # SharedPreferences wrapper (PrefHelpers)
│   ├── widgets/           # Costance.dart — colors, shadows, sizes, theme
│   ├── usecase/           # Abstract UseCase<T,P> base class
│   └── flushbar/          # Custom notification widget
├── src/                   # Feature modules
│   ├── api_models_repo/   # Singleton ApiService + all response models
│   ├── auth_pages/        # Login / registration
│   ├── home_pages/        # Dashboard, step counter, tasks
│   ├── chat_service/      # Messaging, posts, stories, calls
│   ├── profile_pages/     # User profiles, wallet, comments, likes
│   ├── shop_pages/        # Products, basket, orders
│   ├── social_pages/      # Social feed, follows
│   └── ai_pages/          # AI voice services
├── services/              # Singletons: SocketService, ProfileService (GetX services)
├── plugins/               # Self-contained feature plugins (BMI, Tanafos)
└── generated/             # Auto-generated asset references
```

### State Management

The app uses **Provider (ChangeNotifier)** as the primary state management solution and **GetX** for navigation and singleton services.

- All providers are registered at the top of `main.dart` via `MultiProvider`.
- Providers follow a thin repository pattern: they call `ApiService.instance` directly and hold `DataState<T>` results.
- `DataState<T>` is a sealed class with three variants: `DataSuccess<T>`, `DataFailed<T>`, `DataLoading<T>`. Always switch on it when consuming API results.

### Networking

- **HTTP base URL**: `https://zenrun.ir/API/`
- **Image storage**: `https://zenrun.ir/ImageStorage/`
- **AI backend**: `https://voiceapp-708846608306.us-central1.run.app/`
- **Upload service**: `https://zenrun.zenrun-uploader.workers.dev/`

`ApiHelper` (`lib/core/network/api_helper.dart`) is the low-level HTTP layer. Despite `makeGetRequest` naming, it sends HTTP POSTs with query parameters. It includes 3-retry logic with 2-second delays and Base64-encoded email tokens for auth.

`ApiService` (`lib/src/api_models_repo/api_service.dart`) is a singleton that wraps `ApiHelper` and returns typed `DataState<T>` objects.

> **Watch out**: `lib/src/chat_service/chat_controller/api_helper.dart` is a separate, chat-specific `ApiHelper` — distinct from the core one. Changes to the core helper do not affect chat networking and vice versa.

### Navigation

GetX navigation is used throughout. The root widget is `GetMaterialApp`. Named routes are declared in `lib/get_page.dart`. A global navigator key (`navKey`) is used for context-free navigation from services.

### Real-time (Socket.IO)

`SocketService` (`lib/services/socket_service.dart`) is a GetX service connecting to `http://217.182.171.221/` with bearer token auth. Key events: `new_message`, `new_group_message`, `message_sent`, `user_typing`.

### Local Storage

`PrefHelpers` is the SharedPreferences wrapper used for tokens, profile data, step counts, and settings. `GetStorage` is used in some places for persistent local state.

### Constants & Theming

`lib/core/widgets/Costance.dart` is the single source of truth for colors (`ColorsHelper`), shadows (`UiHelper`), responsive sizes, and Material theme (`ThemeHelper`). Use `Sizer` for responsive dimensions.

### Dates & Localization

The app uses the **Jalali (Shamsi) calendar** for dates shown to users (`shamsi_date` package) and Persian number formatting (`persian_number_utility`). When working on any date display or input, use these packages rather than Dart's `DateTime` directly. Locale strings live in `assets/locales/`.

### Background Services

The pedometer/step counter runs in a Flutter background service (`flutter_background_service`). FCM push notifications are handled via `firebase_messaging`.
