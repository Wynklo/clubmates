import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/clubmates_app.dart';
import 'data/firebase_setup.dart';
import 'data/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseSetup.initialize();
  await initializeSupabaseIfConfigured();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(const ClubmatesApp());
}
