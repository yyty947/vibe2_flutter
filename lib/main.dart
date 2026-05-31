import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/game_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load all game JSON data before the app starts
  await GameData.init();

  // Lock orientation to landscape for terminal-style HUD layout
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Immersive sticky: hide system bars for full-screen terminal feel
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const ProviderScope(child: FrontendSurvivalApp()));
}
