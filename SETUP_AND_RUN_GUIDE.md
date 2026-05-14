# Flutter Setup & Android Emulator Execution Guide

## ⚠️ Current System Status

**Issue:** Flutter SDK is not installed or not in the system PATH  
**Impact:** Cannot run the app on Android emulator without Flutter installation

---

## 🔧 Step-by-Step Setup Instructions

### Step 1: Download Flutter SDK

1. Go to [https://flutter.dev/docs/get-started/install/windows](https://flutter.dev/docs/get-started/install/windows)
2. Download the latest Flutter SDK (or specific version v3.10.4+ recommended)
3. Extract to a permanent location (e.g., `C:\flutter` or `C:\src\flutter`)
4. **Do NOT extract to:** Program Files, OneDrive, Desktop, or paths with spaces

### Step 2: Add Flutter to System PATH

#### Method A: Using GUI
1. Press `Win + X` → Search for **Environment Variables**
2. Click **Edit the system environment variables**
3. Click **Environment Variables...** button
4. Under **System variables**, click **New**
5. Variable name: `FLUTTER_HOME`
6. Variable value: `C:\flutter` (or your install path)
7. Find **PATH** variable → Click **Edit**
8. Add new entry: `%FLUTTER_HOME%\bin`
9. Click **OK** → **OK** → **OK**
10. Restart PowerShell/Terminal

#### Method B: Using PowerShell (Admin)
```powershell
# Run as Administrator
$flutterPath = "C:\flutter"
[Environment]::SetEnvironmentVariable("FLUTTER_HOME", $flutterPath, "Machine")
$path = [Environment]::GetEnvironmentVariable("PATH", "Machine")
[Environment]::SetEnvironmentVariable("PATH", "$path;$flutterPath\bin", "Machine")
```

### Step 3: Verify Flutter Installation

```powershell
# Restart PowerShell and run:
flutter --version
flutter doctor -v
```

**Expected Output:**
```
Flutter 3.x.x • channel stable
Dart SDK version: 3.x.x
```

### Step 4: Resolve Flutter Doctor Issues

```powershell
# Run the diagnostic
flutter doctor -v
```

**Common Issues:**
- ❌ **Android SDK**: Download Android SDK if missing
- ❌ **Android toolchain**: Run `flutter doctor --android-licenses` and accept all licenses
- ❌ **Xcode**: (Mac only) Install from App Store
- ❌ **Connected devices**: Ensure emulator/device is running

### Step 5: Setup Android Emulator

#### Option A: Using Android Studio
1. Open Android Studio
2. Go to **AVD Manager** (Virtual Device Manager)
3. Click **Create Virtual Device**
4. Select **Pixel 5** or **Pixel 6** device
5. Select **API 34** (or latest)
6. Name it: `flutter_emulator`
7. Click **Create**

#### Option B: Using Command Line
```powershell
# List available system images
emulator -list-avds

# If no images, download one
$ANDROID_HOME\cmdline-tools\latest\bin\sdkmanager "system-images;android-34;default;x86_64"

# Create emulator
$ANDROID_HOME\cmdline-tools\latest\bin\avdmanager create avd -n flutter_emulator -k "system-images;android-34;default;x86_64"
```

### Step 6: Start the Android Emulator

```powershell
# Option 1: From Android Studio
# Open AVD Manager → Click Play button on emulator

# Option 2: From Command Line
emulator -avd flutter_emulator -no-audio -no-boot-anim

# Option 3: Using Flutter devices
flutter emulators
flutter emulators --launch flutter_emulator
```

Wait for emulator to fully boot (you'll see Android home screen).

### Step 7: Navigate to Project Directory

```powershell
cd "f:\Archive\Desktop_Old\My Data\My Projects\Flutter Projects\first_flutter_app"
```

### Step 8: Get Flutter Dependencies

```powershell
flutter pub get
```

This downloads all dependencies from pubspec.yaml.

### Step 9: Verify Setup

```powershell
flutter devices
```

**Expected Output:**
```
2 connected devices:

emulator-5554          • android • Android API 34 • emulator
```

### Step 10: Run the App on Emulator

```powershell
# Method 1: Auto-detect device
flutter run

# Method 2: Specify device
flutter run -d emulator-5554

# Method 3: Release build
flutter run --release

# Method 4: With verbose output (for debugging)
flutter run -v
```

**First run will take 3-5 minutes** (compiling Dart code, building APK).

---

## 📋 Troubleshooting

### Issue: "flutter: The term 'flutter' is not recognized"
**Solution:** 
- Restart PowerShell after adding to PATH
- Verify PATH: `$env:PATH`
- Reinstall Flutter if needed

### Issue: "Android SDK not found"
**Solution:**
```powershell
# Set ANDROID_HOME
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "C:\Android\Sdk", "Machine")

# Accept licenses
flutter doctor --android-licenses
```

### Issue: "No devices found"
**Solution:**
```powershell
# Start emulator explicitly
emulator -avd flutter_emulator

# Wait 30-60 seconds for boot
# Then run: flutter devices
```

### Issue: "Gradle build failed"
**Solution:**
```powershell
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Issue: "JAVA_HOME not set"
**Solution:**
```powershell
# If using Android Studio's Java:
[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Android\Android Studio\jbr", "Machine")

# Or explicit Java installation:
[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jdk-17", "Machine")
```

### Issue: Emulator very slow
**Solution:**
```powershell
# Use GPU acceleration (requires VM acceleration)
# In AVD: Show Advanced Options → GPU → "Automatic" or "On"

# Disable animations
# In Emulator: Settings → Display → Animation scale → 0.0x

# Use x86_64 or x86 architecture (faster than ARM)
```

---

## ✅ Final Verification Steps

Once app is running:

1. ✅ See **"Idly Express"** in AppBar
2. ✅ Dashboard loads with empty state or sample data
3. ✅ Navigation drawer works (swipe left or menu icon)
4. ✅ Can add new entry (FAB or menu)
5. ✅ Can view expenses, profits, reports
6. ✅ Refresh button works (network icon)
7. ✅ Dark/Light theme toggle works

---

## 🎯 Quick Start Command Chain

For a fresh setup:

```powershell
# 1. After PATH setup
flutter doctor -v

# 2. Start emulator in background
emulator -avd flutter_emulator -no-audio &

# 3. Wait ~60 seconds

# 4. Navigate to project
cd "f:\Archive\Desktop_Old\My Data\My Projects\Flutter Projects\first_flutter_app"

# 5. Get dependencies
flutter pub get

# 6. Verify device
flutter devices

# 7. Run app
flutter run
```

---

## 📱 Testing on Emulator

### Basic Navigation Tests
```powershell
# These work via keyboard/mouse in emulator:
- TAB: Navigate between buttons
- ENTER: Click button
- Back arrow: Navigate back
```

### Logs & Debugging
```powershell
# View app logs
flutter logs

# Restart app
flutter restart (in running session - press 'r')

# Full rebuild
flutter restart (press 'R')

# Stop app
flutter run (press 'q')
```

### Performance Monitoring
```powershell
# During flutter run, press:
# 'p' = Toggle performance overlay
# 'L' = Dump layer tree
# 'S' = Dump semantics
# 't' = Dump rendering tree
```

---

## 🔄 Development Workflow

```
1. Edit Dart files (lib/*.dart)
↓
2. Save file (auto-rebuild in running session)
↓
3. See changes in ~2 seconds (hot reload)
↓
4. If hot reload fails, press 'R' (full rebuild)
↓
5. Debug in emulator
```

---

## 📦 Building APK for Distribution

Once development is complete:

```powershell
# Debug APK (for testing)
flutter build apk

# Release APK (optimized, signed)
flutter build apk --release

# Split by ABI (smaller downloads)
flutter build apk --split-per-abi --release

# Output location: build/app/outputs/flutter-apk/
```

---

## 🚀 Production Deployment

### Pre-deployment Checklist
- [ ] Update `versionCode` and `versionName` in `pubspec.yaml`
- [ ] Update app icon in `assets/logo.png`
- [ ] Configure signing key for release builds
- [ ] Test on multiple devices/emulators
- [ ] Performance test (large datasets)
- [ ] Security review (Firebase rules, data validation)
- [ ] Privacy policy prepared

### Generate Release Build
```powershell
flutter build apk --release

# Or Bundle for Google Play
flutter build appbundle --release
```

---

## 📞 Support Resources

- **Flutter Docs:** https://flutter.dev/docs
- **Firebase Setup:** https://firebase.google.com/docs/flutter/setup
- **Android Emulator:** https://developer.android.com/studio/run/emulator
- **Common Issues:** https://flutter.dev/docs/testing/debugging

---

**Setup Time:** ~30-45 minutes (including downloads)  
**First Run:** 3-5 minutes (first build compilation)  
**Subsequent Runs:** 5-10 seconds (hot reload)
