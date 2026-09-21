import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BackgroundVideoWidget extends StatefulWidget {
  final Widget child;
  final bool isEnabled;
  final double overlayOpacity;

  const BackgroundVideoWidget({
    super.key,
    required this.child,
    this.isEnabled = true,
    this.overlayOpacity = 0.78,
  });

  @override
  State<BackgroundVideoWidget> createState() => _BackgroundVideoWidgetState();
}

class _BackgroundVideoWidgetState extends State<BackgroundVideoWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEnabled) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      final controller = VideoPlayerController.asset('assets/background-video.mp4');
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      await controller.play();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (_) {
      // Graceful fallback in environments where hardware video decoding is unavailable
    }
  }

  @override
  void didUpdateWidget(covariant BackgroundVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEnabled != oldWidget.isEnabled) {
      if (widget.isEnabled && _controller == null) {
        _initVideo();
      } else if (!widget.isEnabled && _controller != null) {
        _controller?.pause();
      } else if (widget.isEnabled && _controller != null) {
        _controller?.play();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isInitialized && _controller != null)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width > 0 ? _controller!.value.size.width : 16,
                height: _controller!.value.size.height > 0 ? _controller!.value.size.height : 9,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
        // Darkened glass tint to preserve pristine UI contrast
        Container(
          color: Colors.black.withValues(alpha: _isInitialized ? widget.overlayOpacity : 0.88),
        ),
        widget.child,
      ],
    );
  }
}
