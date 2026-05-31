import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Typewriter text effect — types characters one by one.
/// Tap or press Space to skip to end.
class TypewriterText extends StatefulWidget {
  final String text;
  final double speed; // ms per character (default 30)
  final TextStyle? style;
  final VoidCallback? onComplete;
  final bool autoStart;

  const TypewriterText({
    super.key,
    required this.text,
    this.speed = 30,
    this.style,
    this.onComplete,
    this.autoStart = true,
  });

  @override
  State<TypewriterText> createState() => TypewriterTextState();
}

class TypewriterTextState extends State<TypewriterText> {
  int _index = 0;
  Timer? _timer;
  bool _complete = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) _start();
  }

  void _start() {
    if (widget.text.isEmpty) {
      _finish();
      return;
    }
    _timer = Timer.periodic(Duration(milliseconds: widget.speed.round()), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _index++;
        if (_index >= widget.text.length) {
          t.cancel();
          _finish();
        }
      });
    });
  }

  void _finish() {
    _complete = true;
    widget.onComplete?.call();
  }

  /// Skip to end instantly.
  void skip() {
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _index = widget.text.length;
      _complete = true;
    });
    widget.onComplete?.call();
  }

  bool get isComplete => _complete;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayed = widget.text.substring(0, _index);
    final defaultStyle = TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.6);

    return GestureDetector(
      onTap: _complete ? null : skip,
      child: Text.rich(TextSpan(children: [
        TextSpan(text: displayed, style: widget.style ?? defaultStyle),
        if (!_complete)
          WidgetSpan(child: _Cursor(style: widget.style ?? defaultStyle)),
      ])),
    );
  }
}

class _Cursor extends StatefulWidget {
  final TextStyle style;
  const _Cursor({required this.style});

  @override
  State<_Cursor> createState() => _CursorState();
}

class _CursorState extends State<_Cursor> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Text('█', style: widget.style.copyWith(color: AppColors.neonCyan)),
    );
  }
}
