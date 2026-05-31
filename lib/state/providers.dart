import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_notifier.dart';
import 'audio_notifier.dart';
import '../models/game_state.dart';
import '../models/audio_state.dart';

/// The single game state provider.
final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);

/// The audio settings provider (not persisted).
final audioProvider = NotifierProvider<AudioNotifier, AudioState>(AudioNotifier.new);

// themeProvider is defined in theme_provider.dart (avoids circular imports)
