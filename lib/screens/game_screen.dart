import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ending_type.dart';
import '../state/providers.dart';
import '../state/theme_provider.dart';
import '../services/audio_manager.dart';
import '../services/save_service.dart';
import '../data/game_data.dart';
import '../widgets/top_bar.dart';
import '../widgets/sidebar.dart';
import '../widgets/editor.dart';
import '../widgets/terminal_widget.dart';
import '../models/game_state.dart';
import 'title_screen.dart';
import 'ending_screen.dart';
import 'video_intro_screen.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(gameProvider.select((s) => s.phase));
    final showIntroVideo = ref.watch(gameProvider.select((s) => s.showIntroVideo));

    if (showIntroVideo) {
      return const VideoIntroScreen();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: switch (phase) {
        GamePhase.title => const _TitleWrapper(),
        GamePhase.ending => const EndingScreen(),
        _ => const _GameLayout(),
      },
    );
  }
}

class _TitleWrapper extends ConsumerWidget {
  const _TitleWrapper();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: const TitleScreen(),
    );
  }
}

class _GameLayout extends ConsumerStatefulWidget {
  const _GameLayout();
  @override
  ConsumerState<_GameLayout> createState() => _GameLayoutState();
}

class _GameLayoutState extends ConsumerState<_GameLayout> {
  bool _terminalOpen = true;
  String? _sfxPlayedKey;
  String? _prevEventId; // track event changes for QTE auto-collapse

  void _tryAdvance(GameState s) {
    if (s.phase == GamePhase.event && s.currentEventId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ref.read(gameProvider).phase == GamePhase.event &&
            ref.read(gameProvider).currentEventId == null) {
          ref.read(gameProvider.notifier).triggerEvent();
        }
      });
    }
    if (s.phase == GamePhase.settlement) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ref.read(gameProvider).phase == GamePhase.settlement) {
          ref.read(gameProvider.notifier).runSettlement();
        }
      });
    }
    if (s.phase == GamePhase.opening && s.dayModifier == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ns = ref.read(gameProvider);
        if (ns.phase == GamePhase.opening && ns.dayModifier == null) {
          ref.read(gameProvider.notifier).assignDayModifier();
          ref.read(gameProvider.notifier).checkSuspicionPressure();
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ns = ref.read(gameProvider);
        if (ns.day > 0 && ns.phase == GamePhase.opening) {
          SaveService.save(ns);
        }
      });
    }
  }

  /// Play event/alert SFX when a popup first appears (once per unique popup).
  void _tryPlaySfx(GameState s) {
    String? sfxKey;
    String? sfxId;

    if (s.currentEventId != null) {
      sfxKey = 'event:${s.currentEventId}';
      final ev = GameData.events.where((e) => e.id == s.currentEventId).firstOrNull;
      sfxId = (ev != null && ev.highRisk) ? 'alert' : 'event';
    } else if (s.interruption != null) {
      sfxKey = 'intr:${s.interruption}';
      sfxId = 'alert';
    } else if (s.suspicionPressure != null) {
      sfxKey = 'press:${s.suspicionPressure}';
      sfxId = 'alert';
    }

    if (sfxKey != null && sfxKey != _sfxPlayedKey) {
      _sfxPlayedKey = sfxKey;
      AudioManager().playSfx(sfxId!);
    }
    if (sfxKey == null) {
      _sfxPlayedKey = null;
    }
  }

  /// Switch BGM based on game state: tension when critical, daily otherwise.
  void _syncBgm(GameState s) {
    final isDanger = s.energy <= 20 || s.kpi <= 20;
    AudioManager().playBgm(isDanger ? 'tension' : 'daily');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(gameProvider);
    _tryAdvance(s);
    _tryPlaySfx(s);
    _syncBgm(s);

    // Auto-collapse terminal when entering a QTE event
    final eventId = s.currentEventId;
    if (eventId != null && eventId != _prevEventId) {
      _prevEventId = eventId;
      final ev = GameData.events.where((e) => e.id == eventId).firstOrNull;
      if (ev?.qteConfig != null && _terminalOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _terminalOpen = false);
        });
      }
    }
    if (eventId == null) _prevEventId = null;

    final theme = ref.watch(themeProvider);

    return Material(
      type: MaterialType.transparency,
      child: Column(children: [
        const TopBar(),
        Expanded(child: Row(children: const [
          LeftDatePanel(),
          Expanded(child: Editor()),
          RightStatsPanel(),
        ])),
        AnimatedContainer(height: 1, duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut, color: theme.colors.dividerColor),
        _CollapsibleTerminal(
          open: _terminalOpen,
          onToggle: () => setState(() => _terminalOpen = !_terminalOpen),
        ),
      ]),
    );
  }
}

class _CollapsibleTerminal extends ConsumerWidget {
  final bool open;
  final VoidCallback onToggle;
  const _CollapsibleTerminal({required this.open, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(gameProvider.select((s) => s.logs));
    final theme = ref.watch(themeProvider);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: () {
          AudioManager().playSfx('click');
          onToggle();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          height: 22, color: theme.colors.terminalBg,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(children: [
            Icon(open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                size: 11, color: theme.colors.textMuted),
            const SizedBox(width: 5),
            Text('LOG // CH0',
                style: TextStyle(fontSize: 8, color: theme.colors.neonGreen.withAlpha(200), letterSpacing: 0.5)),
            const SizedBox(width: 8),
            Text('(${logs.length})',
                style: TextStyle(fontSize: 7, color: theme.colors.textMuted)),
            const Spacer(),
            Text(open ? '▼' : '▲',
                style: TextStyle(fontSize: 8, color: theme.colors.neonGreen.withAlpha(150))),
            const SizedBox(width: 4),
            Text('TERMINAL',
                style: TextStyle(fontSize: 8, color: theme.colors.neonGreen.withAlpha(150), letterSpacing: 1)),
          ]),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: open ? const SizedBox(height: 72, child: TerminalWidget()) : const SizedBox.shrink(),
      ),
    ]);
  }
}
