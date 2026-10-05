import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_bloc_observer.dart';
import 'app/supabase_config.dart';
import 'app/tickle_app.dart';
import 'auth/data/supabase_auth_repository.dart';
import 'knock/knock_detector.dart';
import 'onboarding/data/intro_repository.dart';
import 'session/user_repositories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) Bloc.observer = const AppBlocObserver();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
  );

  final prefs = await SharedPreferences.getInstance();
  final supabase = await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  final client = supabase.client;
  runApp(
    TickleApp(
      auth: SupabaseAuthRepository(client),
      intro: IntroRepository(prefs),
      repositoriesFor: (user) => UserRepositories.supabase(client, prefs, user),
      detectorFor: (settings) =>
          KnockDetector(threshold: () => settings.sensitivity.threshold),
    ),
  );
}
