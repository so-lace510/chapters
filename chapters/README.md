# Chapters

A private journal for your wins, bad days and ordinary days. Each entry has a
title, a date, your writing and an optional photo or video, shown on a
scrollable timeline. Built with Flutter (Android + iOS) and Supabase, plus a
Python script that exports everything as a manuscript for your book.

## 1. Set up Supabase (5 minutes)
1. Create a project at supabase.com.
2. Open **SQL Editor**, paste the contents of `supabase/schema.sql`, and run it.
   This creates the `experiences` table, a private `experience-media` bucket and
   the security rules that keep each person's data to themselves.
3. Open **Project Settings → API** and copy the Project URL and the anon key
   into `lib/config.dart`.
4. Optional while testing: in **Authentication → Providers → Email**, turn off
   "Confirm email" so new accounts can sign in immediately.

## 2. Create the Flutter project and drop these files in
This zip contains the app code but not the Android/iOS folders, which Flutter
generates for you:

```bash
flutter create chapters
# copy this zip's lib/, pubspec.yaml, supabase/, tools/ over the new project
cd chapters
flutter pub get
```

## 3. Allow photos, camera and internet
**iOS**: add to `ios/Runner/Info.plist` inside `<dict>`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Choose photos and videos to attach to your experiences.</string>
<key>NSCameraUsageDescription</key>
<string>Take photos and videos for your experiences.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Record sound when you film a video.</string>
```
**Android**: add to `android/app/src/main/AndroidManifest.xml`, above `<application>`
(needed for release builds):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## 4. Run it
```bash
flutter run            # with a phone or emulator connected
flutter build apk      # Android install file
flutter build ipa      # iOS (needs a Mac and an Apple developer account)
```

## 5. Export your book (Python)
```bash
pip install -r tools/requirements.txt
export SUPABASE_URL=... SUPABASE_ANON_KEY=... CHAPTERS_EMAIL=... CHAPTERS_PASSWORD=...
python tools/export_book.py
```
This writes `manuscript.md`, grouped by month.
