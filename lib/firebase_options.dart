// lib/firebase_options.dart
//
// SETUP REQUIRED:
// Replace this file with your actual Firebase configuration.
// Run: flutterfire configure
// This will auto-generate the correct options for your Firebase project.
//
// See README.md → Setup Instructions for full steps.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web platform not configured. Run flutterfire configure.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS not configured.');
      case TargetPlatform.windows:
        throw UnsupportedError('Windows not configured.');
      case TargetPlatform.linux:
        throw UnsupportedError('Linux not configured.');
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Fuchsia not configured.');
    }
  }

  // ── REPLACE THESE WITH YOUR ACTUAL VALUES ─────────────────────────────────
  // Run `flutterfire configure` to auto-populate.

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.aetherProject',
  );
}
