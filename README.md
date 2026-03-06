# Lumoni - Premium Intelligence Platform

A beautifully crafted mobile application that empowers users to measure, track, and improve their cognitive and emotional intelligence through scientifically grounded IQ tests and EQ assessments.

## Overview

Lumoni provides a premium experience for intelligence testing and personal growth. The app features dynamic IQ tests with 200+ questions across five cognitive categories, comprehensive EQ assessments based on established emotional intelligence frameworks, personalized daily insights backed by neuroscience, and detailed progress tracking with visual analytics. Built with Flutter for cross-platform excellence and powered by Firebase for real-time data synchronization.

## Features

- **Dynamic IQ Tests** -- 30-question timed assessments drawn from a pool of 200+ questions spanning pattern recognition, logical reasoning, mathematical ability, verbal intelligence, and spatial reasoning. Questions are randomized per session with adaptive difficulty and recent-question exclusion to ensure every test is unique.

- **EQ Assessments** -- 40-statement evaluations measuring five dimensions of emotional intelligence: self-awareness, self-regulation, motivation, empathy, and social skills. Uses validated Likert-scale methodology with reverse-scored items for accuracy.

- **Personalized Insights** -- Daily curated facts about brain science, cognitive performance, emotional intelligence, productivity, and growth mindset. Delivered fresh each day to keep users engaged and informed.

- **Progress Tracking** -- Visual charts and statistics showing score history, category breakdowns, and improvement trends over time. Tracks highest IQ, average EQ, total tests completed, and per-category performance.

- **Premium Subscriptions** -- Freemium model with 3 free tests. Premium unlocks unlimited testing, detailed analytics, and advanced insights via monthly, yearly, or lifetime plans managed through RevenueCat.

## Architecture

### Modular Feature Architecture

```
lib/
+-- app/                          # App-level configuration
+-- core/                         # Shared infrastructure
|   +-- constants/                # App-wide constants and configuration
|   +-- di/                       # Dependency injection (GetIt)
|   +-- extensions/               # Dart extension methods
|   +-- models/                   # Shared data models
|   +-- services/                 # Platform services (Firebase, Auth, Storage)
|   +-- utils/                    # Score calculators, randomizers
|   +-- widgets/                  # Shared UI components
+-- design_system/                # Design tokens and reusable components
|   +-- colors/                   # Color palette (AppColors)
|   +-- typography/               # Text styles (AppTypography)
|   +-- theme/                    # Material theme configuration
|   +-- components/               # Glass cards, buttons, charts, nav bars
|   +-- animations/               # Page transitions, scale taps, counters
+-- features/                     # Feature modules (Clean Architecture)
    +-- auth/                     # Authentication (Google, Apple, Email)
    |   +-- data/                 # Datasources, models, repositories
    |   +-- domain/               # Entities, repository contracts, use cases
    |   +-- presentation/         # Cubits, pages, widgets
    +-- onboarding/               # First-launch onboarding flow
    +-- home/                     # Dashboard with stats, insights, actions
    +-- iq_test/                  # IQ test feature
    +-- eq_test/                  # EQ assessment feature
    +-- results/                  # Test results and detailed breakdowns
    +-- insights/                 # Daily insights feed
    +-- profile/                  # User profile and settings
    +-- paywall/                  # Subscription purchase flow
```

### Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State Management | flutter_bloc / Cubit |
| Dependency Injection | GetIt |
| Navigation | GoRouter |
| Backend | Firebase (Auth, Firestore, Cloud Functions) |
| Subscriptions | RevenueCat (purchases_flutter) |
| Local Storage | Hive |
| Analytics | Firebase Analytics |
| Crash Reporting | Firebase Crashlytics |
| Charts | fl_chart |
| Fonts | Google Fonts (Inter) |

### Design Patterns

- **Clean Architecture** -- Each feature module is split into data, domain, and presentation layers with clear dependency boundaries.
- **Repository Pattern** -- Data access is abstracted behind repository interfaces, allowing Firestore and local data sources to be swapped independently.
- **BLoC/Cubit Pattern** -- UI state is managed through Cubits emitting immutable state objects, ensuring testable and predictable state transitions.
- **Singleton Services** -- Core services (Firebase, Auth, Storage, Subscriptions) are registered as singletons via GetIt for consistent access.
- **Factory Constructors** -- Models use `fromFirestore`, `fromJson`, and `toFirestore`/`toJson` factories for clean serialization.

## Getting Started

### Prerequisites

- **Flutter SDK** -- latest stable channel (>= 3.11.0)
- **Dart SDK** -- included with Flutter (>= 3.11.0)
- **Xcode** -- latest stable (for iOS development, macOS only)
- **Android Studio** -- latest stable (for Android development)
- **Firebase CLI** -- `npm install -g firebase-tools`
- **Node.js** -- v18+ (for Cloud Functions and seed scripts)
- **CocoaPods** -- `sudo gem install cocoapods` (for iOS dependencies)

### Firebase Setup

1. **Create a Firebase project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Click "Add project" and name it (e.g., `lumoni-prod`)
   - Enable Google Analytics when prompted

2. **Enable Authentication providers**
   - Navigate to Authentication > Sign-in method
   - Enable **Email/Password**
   - Enable **Google** (download updated config files after)
   - Enable **Apple** (requires Apple Developer account configuration)

3. **Create Firestore database**
   - Navigate to Firestore Database > Create database
   - Choose "Start in production mode"
   - Select your preferred region (e.g., `us-central1`)

4. **Add iOS app**
   - In Project Settings > General, click "Add app" > iOS
   - Bundle ID: `com.lumoni.app` (or your chosen ID)
   - Download `GoogleService-Info.plist`
   - Place it in `ios/Runner/GoogleService-Info.plist`

5. **Add Android app**
   - Click "Add app" > Android
   - Package name: `com.lumoni.app` (or your chosen ID)
   - Download `google-services.json`
   - Place it in `android/app/google-services.json`
   - Add the SHA-1 fingerprint for Google Sign-In:
     ```bash
     cd android && ./gradlew signingReport
     ```

6. **Enable Analytics and Crashlytics**
   - Navigate to Analytics > Dashboard (auto-enabled with config files)
   - Navigate to Crashlytics > Get started
   - Follow the setup wizard for both platforms

7. **Deploy security rules**
   ```bash
   cd firebase
   firebase deploy --only firestore:rules
   ```

8. **Deploy Firestore indexes**
   ```bash
   cd firebase
   firebase deploy --only firestore:indexes
   ```

9. **Deploy Cloud Functions**
   ```bash
   cd firebase/functions
   npm install
   cd ..
   firebase deploy --only functions
   ```

10. **Seed initial data**
    ```bash
    cd scripts
    npm install firebase-admin
    node seed_firestore.js /path/to/your-service-account-key.json
    ```
    To download your service account key:
    - Firebase Console > Project Settings > Service accounts
    - Click "Generate new private key"
    - Save the JSON file securely (never commit it to version control)

### RevenueCat Setup

1. **Create a RevenueCat account**
   - Sign up at [RevenueCat](https://www.revenuecat.com/)

2. **Create a new project**
   - In the RevenueCat dashboard, create a project named "Lumoni"

3. **Configure iOS (App Store Connect)**
   - In App Store Connect, create a new subscription group (e.g., "Lumoni Premium")
   - Add subscription products:
     - `lumoni_premium_monthly` -- Monthly plan
     - `lumoni_premium_yearly` -- Yearly plan
     - `lumoni_premium_lifetime` -- Lifetime (non-consumable)
   - In RevenueCat, add your App Store Connect app
   - Enter the App-Specific Shared Secret (App Store Connect > App > In-App Purchases > Manage)

4. **Configure Android (Google Play Console)**
   - In Google Play Console, create subscriptions under your app:
     - `lumoni_premium_monthly` -- Monthly plan
     - `lumoni_premium_yearly` -- Yearly plan
     - `lumoni_premium_lifetime` -- Lifetime (one-time)
   - In RevenueCat, add your Google Play app
   - Upload the Google Play service account JSON key

5. **Add API keys to the app**
   - Copy the RevenueCat public API keys from the dashboard
   - Update `lib/core/constants/app_constants.dart`:
     ```dart
     static const String revenueCatApiKeyiOS = 'appl_YOUR_ACTUAL_KEY';
     static const String revenueCatApiKeyAndroid = 'goog_YOUR_ACTUAL_KEY';
     ```

6. **Create Offerings and Packages**
   - In RevenueCat > Offerings, create a "default" offering
   - Add packages for monthly, yearly, and lifetime
   - Link each package to the corresponding store product

7. **Configure Entitlements**
   - Create an entitlement named `premium`
   - Attach all three subscription products to this entitlement
   - Verify the entitlement ID matches `AppConstants.premiumEntitlementId`

### Running Locally

```bash
# Install Flutter dependencies
flutter pub get

# Generate code (Hive adapters, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# Run on iOS simulator
flutter run -d ios

# Run on Android emulator
flutter run -d android

# Run on a specific device
flutter devices          # List available devices
flutter run -d <device-id>
```

### Running Without Firebase (Development Mode)

The app includes graceful fallback mechanisms for development without a configured Firebase project:

- **Authentication** -- `AuthService` catches Firebase initialization errors and logs them without crashing. You can test UI flows by mocking the auth state.
- **Firestore** -- `FirestoreService` operations are wrapped in try/catch blocks that throw typed `FirestoreException` errors, allowing the UI layer to show appropriate fallback states.
- **Cloud Functions** -- The `generateIQTest` callable function is optional. The app's `IQTestCubit` can load questions from a local question bank (when implemented) as a fallback.
- **Subscriptions** -- `SubscriptionService` initialization is non-blocking. If RevenueCat fails to initialize, the app continues with free-tier defaults.

To run without Firebase:
1. Comment out `await getIt<FirebaseService>().initialize();` in `injection.dart`
2. Use mock data providers or the local question bank
3. The app will function with local storage only (no cloud sync)

### Firebase Emulator Suite

For local development with Firebase services:

```bash
# Start all emulators
cd firebase
firebase emulators:start

# Seed data into the emulator
cd ../scripts
FIRESTORE_EMULATOR_HOST="localhost:8080" node seed_firestore.js /path/to/key.json
```

The emulator UI is available at `http://localhost:4000`.

## IQ Test Randomization Algorithm

### 1. Question Pool Structure

The IQ question pool contains 200+ questions organized across two dimensions:

- **Category** (5 categories): Pattern Recognition, Logical Reasoning, Mathematical Ability, Verbal Intelligence, Spatial Reasoning
- **Difficulty** (5 levels): Very Easy (1), Easy (2), Medium (3), Hard (4), Very Hard (5)

This creates a 5x5 matrix of question buckets, with approximately 8 questions per bucket, ensuring sufficient variety for repeated testing.

### 2. Selection Algorithm

The selection process follows these steps:

```
1. LOAD user's recent test sessions (last 10 sessions)
2. EXTRACT all question IDs used in those sessions (up to 200 IDs)
3. ADJUST difficulty based on user's recent score average:
   - Average >= 130: difficulty + 2
   - Average >= 120: difficulty + 1
   - Average 90-119: no change
   - Average 80-89:  difficulty - 1
   - Average < 80:   difficulty - 2
4. FOR EACH of the 5 categories:
   a. Query questions at the adjusted difficulty level
   b. Exclude recently used question IDs
   c. If insufficient questions at primary difficulty,
      fall back to adjacent difficulty levels
   d. Select up to 6 questions per category
5. If total < 30, fill remaining slots from any category
6. SHUFFLE the final 30 questions randomly
7. RETURN the question set
```

### 3. Scoring Normalization

Raw test performance is converted to the IQ scale using these steps:

```
1. CALCULATE weighted raw score:
   - Each correct answer contributes: 0.5 + (difficulty * 0.25)
   - Difficulty 1 = 0.75 points, Difficulty 5 = 1.75 points
   - This rewards correct answers on harder questions

2. APPLY time adjustment:
   - Average time < 20s per question: up to +10% bonus
   - Average time > 45s per question: up to -5% penalty
   - Between 20-45s: no adjustment

3. COMPUTE raw fraction:
   - raw_fraction = weighted_score / max_possible_weighted_score
   - adjusted_fraction = raw_fraction * time_factor

4. CONVERT to IQ scale via z-score:
   - z_score = (adjusted_fraction - 0.50) / 0.18
   - iq_score = 100 + z_score * 15
   - A raw fraction of 0.50 maps to IQ 100 (population mean)
   - Standard deviation of 15 points per 0.18 raw fraction

5. CLAMP to valid range: [55, 145]
```

### 4. Adaptive Difficulty Logic

The system tracks the user's performance history and adjusts the base difficulty for subsequent tests:

| Recent Average IQ | Difficulty Adjustment |
|---|---|
| >= 130 (Exceptionally High) | +2 levels |
| 120-129 (High Above Average) | +1 level |
| 90-119 (Average to Above Average) | No change |
| 80-89 (Low Average) | -1 level |
| < 80 (Below Average) | -2 levels |

Difficulty adjustments are clamped between 1 and 5. The algorithm also uses a "spread" strategy: when querying questions at the adjusted difficulty, it includes adjacent difficulty levels to ensure variety and to prevent the test from feeling monotonous.

## Project Structure

```
lumoni/
+-- android/                      # Android platform project
+-- ios/                          # iOS platform project
+-- web/                          # Web platform project
+-- linux/                        # Linux platform project
+-- macos/                        # macOS platform project
+-- windows/                      # Windows platform project
+-- assets/
|   +-- images/                   # Static images
|   +-- icons/                    # Custom SVG/PNG icons
|   +-- animations/               # Lottie animation files
|   +-- fonts/                    # Inter font family
+-- lib/
|   +-- main.dart                 # App entry point
|   +-- app/                      # App configuration, routing
|   +-- core/
|   |   +-- constants/
|   |   |   +-- app_constants.dart  # All app-wide constants
|   |   +-- di/
|   |   |   +-- injection.dart      # GetIt service registration
|   |   +-- models/
|   |   |   +-- user_model.dart         # User profile + stats
|   |   |   +-- iq_question_model.dart  # IQ question structure
|   |   |   +-- eq_question_model.dart  # EQ statement structure
|   |   |   +-- test_session_model.dart # Test session tracking
|   |   +-- services/
|   |   |   +-- firebase_service.dart       # Firebase initialization
|   |   |   +-- firestore_service.dart      # Firestore CRUD operations
|   |   |   +-- auth_service.dart           # Authentication wrapper
|   |   |   +-- local_storage_service.dart  # Hive local storage
|   |   |   +-- subscription_service.dart   # RevenueCat integration
|   |   +-- utils/
|   |   |   +-- iq_score_calculator.dart    # IQ scoring algorithm
|   |   |   +-- eq_score_calculator.dart    # EQ scoring algorithm
|   |   |   +-- question_randomizer.dart    # Question selection logic
|   |   +-- widgets/               # Shared widgets
|   +-- design_system/
|   |   +-- design_system.dart     # Barrel export
|   |   +-- colors/
|   |   |   +-- app_colors.dart    # Color palette
|   |   +-- typography/
|   |   |   +-- app_typography.dart # Text styles
|   |   +-- theme/
|   |   |   +-- app_theme.dart     # ThemeData configuration
|   |   +-- spacing.dart           # Spacing constants
|   |   +-- components/
|   |   |   +-- glass_card.dart          # Glassmorphism card
|   |   |   +-- app_button.dart          # Styled button variants
|   |   |   +-- animated_progress_bar.dart
|   |   |   +-- bottom_nav_bar.dart
|   |   |   +-- score_chart.dart
|   |   |   +-- insight_card.dart
|   |   |   +-- stat_card.dart
|   |   +-- animations/
|   |       +-- fade_slide_transition.dart
|   |       +-- scale_tap.dart
|   |       +-- animated_counter.dart
|   |       +-- page_transitions.dart
|   +-- features/
|       +-- auth/
|       |   +-- presentation/
|       |       +-- cubits/
|       |       |   +-- auth_cubit.dart
|       |       |   +-- auth_state.dart
|       |       +-- pages/
|       |       +-- widgets/
|       |           +-- social_sign_in_button.dart
|       |           +-- auth_text_field.dart
|       +-- onboarding/
|       |   +-- presentation/
|       |       +-- cubits/
|       |       |   +-- onboarding_cubit.dart
|       |       +-- pages/
|       |       |   +-- onboarding_page.dart
|       |       +-- widgets/
|       |           +-- onboarding_illustration.dart
|       +-- home/
|       |   +-- data/
|       |   |   +-- repositories/
|       |   |       +-- home_repository.dart
|       |   +-- domain/
|       |   |   +-- entities/
|       |   |       +-- daily_insight.dart
|       |   +-- presentation/
|       |       +-- cubits/
|       |       |   +-- home_cubit.dart
|       |       |   +-- home_state.dart
|       |       +-- widgets/
|       |           +-- greeting_header.dart
|       |           +-- test_action_card.dart
|       |           +-- recent_score_card.dart
|       +-- iq_test/
|       |   +-- presentation/
|       |       +-- cubits/
|       |       |   +-- iq_test_cubit.dart
|       |       |   +-- iq_test_state.dart
|       |       +-- widgets/
|       |           +-- test_timer.dart
|       |           +-- test_progress_bar.dart
|       +-- eq_test/
|       |   +-- presentation/
|       |       +-- cubits/
|       |       |   +-- eq_test_cubit.dart
|       |       |   +-- eq_test_state.dart
|       |       +-- widgets/
|       |           +-- likert_scale.dart
|       +-- results/
|       +-- insights/
|       +-- profile/
|       +-- paywall/
+-- firebase/
|   +-- firebase.json              # Firebase project configuration
|   +-- firestore.rules            # Firestore security rules
|   +-- firestore.indexes.json     # Composite index definitions
|   +-- functions/
|       +-- package.json           # Cloud Functions dependencies
|       +-- index.js               # Cloud Functions implementation
+-- scripts/
|   +-- seed_firestore.js          # Database seeding script
+-- test/                          # Unit and widget tests
+-- pubspec.yaml                   # Flutter dependencies
+-- analysis_options.yaml          # Dart analysis configuration
```

## Data Models

### Firestore Collections

| Collection | Description | Key Fields |
|---|---|---|
| `users` | User profiles with aggregate stats | `email`, `displayName`, `isPremium`, `totalIQTests`, `totalEQTests`, `highestIQ`, `averageEQ`, `createdAt`, `lastTestAt` |
| `users/{uid}/daily_insights` | Per-user daily insight documents | `title`, `description`, `category`, `icon`, `date`, `createdAt` |
| `iq_questions` | IQ test question pool | `question`, `answers[]`, `correctAnswerIndex`, `difficulty` (1-5), `category`, `explanation`, `imageUrl` |
| `eq_questions` | EQ assessment statement pool | `statement`, `category`, `isReversed`, `weight` |
| `test_sessions` | Individual test session records | `userId`, `testType` (iq/eq), `startedAt`, `completedAt`, `score`, `categoryScores{}`, `questionIds[]`, `answers{}`, `timeSpentSeconds` |
| `results` | Detailed computed results | `sessionId`, `userId`, `testType`, `iqScore`/`overallScore`, `classification`, `categoryScores{}`, `accuracy`, `createdAt` |
| `subscriptions` | User subscription records | Managed by RevenueCat webhooks |

## Deployment

### iOS (App Store)

1. **Prepare the build**
   ```bash
   flutter build ios --release
   ```

2. **Open in Xcode**
   ```bash
   open ios/Runner.xcworkspace
   ```

3. **Configure signing**
   - Select your development team
   - Verify the bundle identifier matches Firebase and RevenueCat config
   - Ensure the `GoogleService-Info.plist` is included in the target

4. **Archive and upload**
   - Product > Archive
   - Distribute App > App Store Connect
   - Upload

5. **Submit for review in App Store Connect**
   - Add screenshots, description, and metadata
   - Submit for review

### Android (Google Play)

1. **Create a signing key** (first time only)
   ```bash
   keytool -genkey -v -keystore ~/lumoni-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias lumoni
   ```

2. **Configure signing in `android/app/build.gradle`**

3. **Build the app bundle**
   ```bash
   flutter build appbundle --release
   ```

4. **Upload to Google Play Console**
   - Create a new release in the Production track
   - Upload the `.aab` file from `build/app/outputs/bundle/release/`
   - Add release notes

5. **Submit for review**
   - Complete the store listing (screenshots, description, content rating)
   - Roll out the release

### Firebase Deployment

```bash
# Deploy everything
cd firebase
firebase deploy

# Deploy individual components
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only functions

# Deploy to a specific project
firebase deploy --project lumoni-prod
```
