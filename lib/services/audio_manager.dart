import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// SFX ID → asset filename mapping.
/// To swap formats (e.g. all .mp3 for Windows), only change this table.
const _sfxFiles = <String, String>{
  'click': 'click.ogg',
  'event': 'event.wav',
  'alert': 'alert.wav',
  'glitch': 'glitch.wav',
  'success': 'success.wav',
};

/// BGM ID → asset filename mapping.
const _bgmFiles = <String, String>{
  'title': 'title.mp3',
  'daily': 'daily.mp3',
  'tension': 'tension.mp3',
};

/// Centralized audio manager (TECH_ARCH §10).
/// All audio playback goes through this singleton.
///
/// Handles: BGM crossfade, SFX one-shot, mute/volume sync.
/// Graceful degradation: missing files are silently ignored.
class AudioManager {
  static final AudioManager _instance = AudioManager._();
  factory AudioManager() => _instance;
  AudioManager._() {
    _initContexts();
  }

  final _bgmPlayer = AudioPlayer();
  final _sfxPlayer = AudioPlayer();
  String? _currentBgmId;
  Timer? _crossfadeTimer;

  bool _muted = false;
  double _bgmVolume = 0.3;
  double _sfxVolume = 0.5;

  /// Configure audio contexts so SFX does not steal focus from BGM.
  void _initContexts() {
    final bgmCtx = AudioContext(
      android: AudioContextAndroid(
        audioMode: AndroidAudioMode.normal,
        audioFocus: AndroidAudioFocus.gain,
      ),
    );
    final sfxCtx = AudioContext(
      android: AudioContextAndroid(
        audioMode: AndroidAudioMode.normal,
        audioFocus: AndroidAudioFocus.none,
      ),
    );
    _bgmPlayer.setAudioContext(bgmCtx);
    _sfxPlayer.setAudioContext(sfxCtx);
  }

  /// Sync with AudioState from store.
  void sync({required bool muted, required double bgmVolume, required double sfxVolume}) {
    _muted = muted;
    _bgmVolume = bgmVolume;
    _sfxVolume = sfxVolume;
    _bgmPlayer.setVolume(muted ? 0 : bgmVolume);
  }

  /// Play a BGM track with crossfade (~1s).
  /// If the same track is already playing, does nothing.
  /// Pass null to stop BGM.
  Future<void> playBgm(String? bgmId) async {
    if (bgmId == _currentBgmId) return;

    _crossfadeTimer?.cancel();

    // Fade out current track
    if (_currentBgmId != null) {
      await _fadeOut();
      await _bgmPlayer.stop();
    }

    _currentBgmId = bgmId;
    if (bgmId == null) return;

    final filename = _bgmFiles[bgmId];
    if (filename == null) return;

    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(AssetSource('audio/bgm/$filename'));
      await _fadeIn();
    } catch (_) {
      // Audio file missing — game continues without audio
    }
  }

  /// Fade out over ~1 second.
  Future<void> _fadeOut() async {
    if (_muted) return;
    const steps = 20;
    final stepDuration = Duration(milliseconds: 50);
    for (int i = steps; i >= 0; i--) {
      _bgmPlayer.setVolume(_bgmVolume * i / steps);
      await Future.delayed(stepDuration);
    }
  }

  /// Fade in over ~1 second.
  Future<void> _fadeIn() async {
    if (_muted) return;
    const steps = 20;
    final stepDuration = Duration(milliseconds: 50);
    for (int i = 0; i <= steps; i++) {
      _bgmPlayer.setVolume(_bgmVolume * i / steps);
      await Future.delayed(stepDuration);
    }
  }

  /// Play a one-shot sound effect by ID (e.g. 'click', 'event').
  /// The actual filename is resolved via [_sfxFiles].
  Future<void> playSfx(String sfxId) async {
    if (_muted || _sfxVolume <= 0) return;
    final filename = _sfxFiles[sfxId];
    if (filename == null) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/sfx/$filename'),
          volume: _sfxVolume);
    } catch (_) {
      // Audio file missing — game continues without audio
    }
  }

  /// Stop all audio.
  Future<void> stopAll() async {
    _crossfadeTimer?.cancel();
    await _bgmPlayer.stop();
    await _sfxPlayer.stop();
    _currentBgmId = null;
  }

  void dispose() {
    _crossfadeTimer?.cancel();
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
  }
}
