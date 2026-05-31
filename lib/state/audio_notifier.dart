import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audio_state.dart';

/// Manages audio settings. NOT persisted (resets on each app launch).
/// TECH_ARCH §10.3.
class AudioNotifier extends Notifier<AudioState> {
  @override
  AudioState build() => const AudioState();

  void toggleMute() {
    state = state.copyWith(muted: !state.muted);
  }

  void setBgmVolume(double volume) {
    state = state.copyWith(bgmVolume: volume.clamp(0.0, 1.0));
  }

  void setSfxVolume(double volume) {
    state = state.copyWith(sfxVolume: volume.clamp(0.0, 1.0));
  }

  void setCurrentBgm(String? bgm) {
    state = state.copyWith(currentBgm: bgm);
  }
}
