import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase reads google-services.json (Android) and GoogleService-Info.plist
/// (iOS). Both are kept out of git, so a checkout without them still runs and
/// only the debug developer login is offered.
abstract final class FirebaseSetup {
  static bool ready = false;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      ready = true;
    } catch (error) {
      debugPrint('Firebase is not configured: $error');
    }
  }
}
