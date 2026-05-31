/// Audio state model (TECH_ARCH §10.3).
class AudioState {
  final bool muted;
  final double bgmVolume; // [0, 1], default 0.3
  final double sfxVolume; // [0, 1], default 0.5
  final String? currentBgm;

  const AudioState({
    this.muted = false,
    this.bgmVolume = 0.3,
    this.sfxVolume = 0.5,
    this.currentBgm,
  });

  AudioState copyWith({
    bool? muted,
    double? bgmVolume,
    double? sfxVolume,
    Object? currentBgm = _sentinel,
  }) {
    return AudioState(
      muted: muted ?? this.muted,
      bgmVolume: bgmVolume ?? this.bgmVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      currentBgm: identical(currentBgm, _sentinel) ? this.currentBgm : currentBgm as String?,
    );
  }

  static const _sentinel = Object();
}
