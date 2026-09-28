import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/experience.dart';
import '../services/experience_service.dart';
import '../theme.dart';

/// Shows an entry's photo or video.
/// In the timeline ([playVideo] false) videos show a poster; in the detail
/// screen ([playVideo] true) they play.
class MediaView extends StatefulWidget {
  final Experience experience;
  final bool playVideo;
  final double? height;

  const MediaView({
    super.key,
    required this.experience,
    this.playVideo = false,
    this.height,
  });

  @override
  State<MediaView> createState() => _MediaViewState();
}

class _MediaViewState extends State<MediaView> {
  late final Future<String> _url;

  @override
  void initState() {
    super.initState();
    _url = ExperienceService.instance.signedUrl(widget.experience.mediaPath!);
  }

  Widget _box(Widget child) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: child,
      );

  Widget _placeholder({IconData? icon, String? label, bool loading = false}) {
    return _box(
      Container(
        height: widget.height ?? 220,
        width: double.infinity,
        color: const Color(0xFFE2E6E4),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 40, color: AppColors.muted),
                  if (label != null) ...[
                    const SizedBox(height: 6),
                    Text(label, style: const TextStyle(color: AppColors.muted)),
                  ],
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.experience;
    return FutureBuilder<String>(
      future: _url,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _placeholder(loading: true);
        }
        if (snap.hasError || !snap.hasData) {
          return _placeholder(
            icon: Icons.broken_image_outlined,
            label: 'Couldn\'t load this file',
          );
        }
        final url = snap.data!;

        if (e.isVideo) {
          return widget.playVideo
              ? _box(_VideoBox(url: url))
              : _placeholder(
                  icon: Icons.play_circle_fill_rounded,
                  label: 'Video',
                );
        }

        return _box(
          Image.network(
            url,
            width: double.infinity,
            height: widget.height,
            fit: widget.height == null ? BoxFit.fitWidth : BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : _placeholder(loading: true),
            errorBuilder: (_, __, ___) => _placeholder(
              icon: Icons.broken_image_outlined,
              label: 'Couldn\'t load this file',
            ),
          ),
        );
      },
    );
  }
}

class _VideoBox extends StatefulWidget {
  final String url;
  const _VideoBox({required this.url});

  @override
  State<_VideoBox> createState() => _VideoBoxState();
}

class _VideoBoxState extends State<_VideoBox> {
  late final VideoPlayerController _c;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _init();
  }

  Future<void> _init() async {
    try {
      await _c.initialize();
      await _c.setLooping(true);
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Container(
        height: 220,
        color: const Color(0xFFE2E6E4),
        alignment: Alignment.center,
        child: const Text('Couldn\'t play this video'),
      );
    }
    if (!_ready) {
      return Container(
        height: 220,
        color: const Color(0xFF1B2440),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Colors.white),
      );
    }
    return GestureDetector(
      onTap: () => _c.value.isPlaying ? _c.pause() : _c.play(),
      child: AspectRatio(
        aspectRatio: _c.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_c),
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _c,
              builder: (_, v, __) => AnimatedOpacity(
                opacity: v.isPlaying ? 0 : 1,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
