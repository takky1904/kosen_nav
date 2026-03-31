# Rebranding Task: From "KOSEN NAV" to "KOSENAR"

## Context
- **New Name**: Kosenar (コセナール)
- **Origin**: KOSEN + Dominar (Spanish: to master / to control at will)
- **Objective**: Replace all occurrences of "KOSEN NAV" and "Kosen Nav" to avoid confusion with existing services and establish the new brand identity.

## Target Files & Replacement Rules

### 1. Documentation & UI Strings
- **Files**: `README.md`, `docs/*.md`, `lib/presentation/**/*.dart`
- **Rule**:
  - Replace "KOSEN NAV" (Uppercase) → "KOSENAR"
  - Replace "Kosen Nav" (Title Case) → "Kosenar"
  - Replace "高専ナビ" (Japanese) → "Kosenar" or "コセナール" (Context dependent)

### 2. App Metadata (Android/iOS)
- **Android**: `android/app/src/main/AndroidManifest.xml` (label)
- **iOS**: `ios/Runner/Info.plist` (CFBundleName, CFBundleDisplayName)
- **Flutter**: `pubspec.yaml` (name, description), `lib/main.dart` (MaterialApp title)

### 3. README.md Rewrite (Specific)
Update the top section of `README.md` with the new meaning:
- "KOSENAR は、高専生向けのタスク・成績管理アプリです。KOSEN + Dominar（スペイン語で熟達する、意のままに操る）を掛け合わせ、高専生活をマスターするという意味を込めています。"

## Step-by-Step Instructions

### Step 1: Global String Replacement
Replace all "KOSEN NAV" strings across the `@workspace`. 
*Careful*: If the project folder name or package name (e.g., `com.example.kosen_nav`) is changed, it may break imports. Only change the **Display Names** and **UI Strings** first.

### Step 2: Update App Title in Code
In `lib/main.dart`, update the `MaterialApp` title property:
```dart
title: 'Kosenar',
Step 3: Update Metadata
Update android:label in AndroidManifest.xml.

Update CFBundleDisplayName in Info.plist.

Step 4: Documentation Refresh
Update all markdown files to reflect the new vision. Ensure the "Phase" status in README.md remains accurate but under the new name.