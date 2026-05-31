import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../state/providers.dart';
import '../theme/colors.dart';
import '../widgets/editor.dart' show GlassPanel;
import '../widgets/typewriter_text.dart';

class VideoIntroScreen extends ConsumerStatefulWidget {
  const VideoIntroScreen({super.key});

  @override
  ConsumerState<VideoIntroScreen> createState() => _VideoIntroScreenState();
}

class _VideoIntroScreenState extends ConsumerState<VideoIntroScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final VideoPlayerController _videoController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _videoReady = false;
  bool _isFadingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _videoController = VideoPlayerController.asset('assets/video/intro.mp4');
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.addListener(() => setState(() {}));

    _videoController.initialize().then((_) {
      if (!mounted) return;
      setState(() => _videoReady = true);
      _videoController.play();
      _fadeController.forward();
    }).catchError((_) {
      if (!mounted) return;
      ref.read(gameProvider.notifier).finishIntroVideo();
    });

    _videoController.addListener(_onVideoUpdate);
  }

  void _onVideoUpdate() {
    if (_videoController.value.isCompleted && !_isFadingOut) {
      _startFadeOut();
    }
  }

  void _skip() {
    if (_isFadingOut || !_videoReady) return;
    _videoController.pause();
    _startFadeOut();
  }

  void _startFadeOut() {
    _isFadingOut = true;
    _fadeController.reverse();
    _fadeController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) {
        ref.read(gameProvider.notifier).finishIntroVideo();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_videoReady) return;
    if (state == AppLifecycleState.paused) {
      _videoController.pause();
    } else if (state == AppLifecycleState.resumed) {
      _videoController.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController.removeListener(_onVideoUpdate);
    _videoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_videoReady) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    final videoSize = _videoController.value.size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _skip();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _skip,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Full-screen video, no black bars
              FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.center,
                child: SizedBox(
                  width: videoSize.width,
                  height: videoSize.height,
                  child: VideoPlayer(_videoController),
                ),
              ),

              // Bottom caption with frosted glass
              Positioned(
                left: 16, right: 16, bottom: 24,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: GlassPanel(
                    borderRadius: 12,
                    padding: const EdgeInsets.all(16),
                    bgColor: const Color(0x40FFFFFF),
                    border: Border.all(color: const Color(0x59FFFFFF), width: 1),
                    child: const TypewriterText(
                      text: '2026年，降本增效的阴影笼罩大厂。作为一名前端开发，你只有30天时间——在裁员风暴中，活下去。',
                      speed: 25,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              // "Tap to skip" hint
              Positioned(
                top: 16, right: 16,
                child: Opacity(
                  opacity: _fadeAnimation.value * 0.6,
                  child: const Text('点击跳过',
                    style: TextStyle(fontSize: 10, color: Colors.white70)),
                ),
              ),

              // Fade overlay: drives both fade-in and fade-out
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (_, child) => Container(
                      color: Colors.black.withValues(alpha: 1.0 - _fadeAnimation.value),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
