import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_survival/state/providers.dart';

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('AudioNotifier', () {
    test('initial state has muted=false, bgm=0.3, sfx=0.5', () {
      final c = _container();
      final s = c.read(audioProvider);
      expect(s.muted, false);
      expect(s.bgmVolume, 0.3);
      expect(s.sfxVolume, 0.5);
      expect(s.currentBgm, isNull);
    });

    test('toggleMute flips muted', () {
      final c = _container();
      c.read(audioProvider.notifier).toggleMute();
      expect(c.read(audioProvider).muted, true);
      c.read(audioProvider.notifier).toggleMute();
      expect(c.read(audioProvider).muted, false);
    });

    test('setBgmVolume clamps to [0, 1]', () {
      final c = _container();
      c.read(audioProvider.notifier).setBgmVolume(0.8);
      expect(c.read(audioProvider).bgmVolume, 0.8);
      c.read(audioProvider.notifier).setBgmVolume(2.5);
      expect(c.read(audioProvider).bgmVolume, 1.0);
      c.read(audioProvider.notifier).setBgmVolume(-0.5);
      expect(c.read(audioProvider).bgmVolume, 0.0);
    });

    test('setSfxVolume clamps to [0, 1]', () {
      final c = _container();
      c.read(audioProvider.notifier).setSfxVolume(1.5);
      expect(c.read(audioProvider).sfxVolume, 1.0);
    });

    test('setCurrentBgm sets bgm id', () {
      final c = _container();
      c.read(audioProvider.notifier).setCurrentBgm('daily');
      expect(c.read(audioProvider).currentBgm, 'daily');
      c.read(audioProvider.notifier).setCurrentBgm(null);
      expect(c.read(audioProvider).currentBgm, isNull);
    });
  });
}
