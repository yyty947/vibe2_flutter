import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import '../state/theme_provider.dart';
import '../models/log_entry.dart';
import '../theme/colors.dart';

/// Terminal log display (UI_DESIGN_SYSTEM §5.4).
class TerminalWidget extends ConsumerStatefulWidget {
  const TerminalWidget({super.key});

  @override
  ConsumerState<TerminalWidget> createState() => _TerminalWidgetState();
}

class _TerminalWidgetState extends ConsumerState<TerminalWidget> {
  final _scrollCtrl = ScrollController();

  Color _logColor(LogType type) {
    final c = ref.watch(themeProvider).colors;
    return switch (type) {
      LogType.commit => c.neonGreen,
      LogType.bugfix => c.neonCyan,
      LogType.warning => c.neonAmber,
      LogType.alert => c.neonRed,
      LogType.study => c.neonCyan,
      _ => c.textMuted,
    };
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(gameProvider.select((s) => s.logs));
    final theme = ref.watch(themeProvider);

    // Auto-scroll to bottom on new log entries
    _autoScroll();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: theme.colors.terminalBg,
      ),
      child: logs.isEmpty
          ? Center(child: Text('> _', style: TextStyle(fontSize: 10, color: AppColors.textDim)))
          : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              itemCount: logs.length,
              itemBuilder: (_, i) {
                final log = logs[i];
                return TweenAnimationBuilder<Offset>(
                  tween: Tween(begin: const Offset(0, 0.3), end: Offset.zero),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  builder: (context, offset, _) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      builder: (context, opacity, child) {
                        return Opacity(
                          opacity: opacity,
                          child: Transform.translate(
                            offset: Offset(0, offset.dy * 20),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text.rich(TextSpan(children: [
                          TextSpan(text: '[D${log.day.toString().padLeft(2, '0')}] ',
                              style: TextStyle(fontSize: 9, color: theme.colors.textDim)),
                          TextSpan(text: '[${log.type.label}] ',
                              style: TextStyle(fontSize: 9, color: _logColor(log.type))),
                          TextSpan(text: log.message,
                              style: TextStyle(fontSize: 9, color: theme.colors.textPrimary)),
                        ])),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
