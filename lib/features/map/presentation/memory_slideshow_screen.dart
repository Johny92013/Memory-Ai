import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/services/signed_url_service.dart';
import 'package:memory_ai/features/map/data/memory_album_session.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';

/// In-App-Slideshow (keine serverseitige Videodatei). Fullscreen ohne Bottom-Nav.
class MemorySlideshowScreen extends StatefulWidget {
  const MemorySlideshowScreen({super.key, required this.session});

  final SlideshowSession session;

  @override
  State<MemorySlideshowScreen> createState() => _MemorySlideshowScreenState();
}

class _MemorySlideshowScreenState extends State<MemorySlideshowScreen> {
  late List<MediaItemModel> _items;
  int _index = 0;
  bool _playing = true;
  Timer? _timer;
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.session.items);
    _armTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _armTimer() {
    _timer?.cancel();
    if (!_playing || _items.isEmpty) return;
    final item = _items[_index];
    final seconds = item.mediaType == 'video'
        ? (item.durationSeconds ?? widget.session.secondsPerImage).clamp(2, 60)
        : widget.session.secondsPerImage;
    _timer = Timer(Duration(seconds: seconds), _next);
  }

  void _next() {
    if (_items.isEmpty) return;
    setState(() {
      if (_index >= _items.length - 1) {
        _playing = false;
      } else {
        _index++;
      }
    });
    if (_playing) _armTimer();
  }

  void _prev() {
    if (_index <= 0) return;
    setState(() => _index--);
    _armTimer();
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _armTimer();
    } else {
      _timer?.cancel();
    }
  }

  void _skipBroken() {
    if (_items.length <= 1) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _items.removeAt(_index);
      if (_index >= _items.length) _index = _items.length - 1;
    });
    _armTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ),
      );
    }

    final item = _items[_index];
    final progress = (_index + 1) / _items.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: FutureBuilder<String?>(
                future: SignedUrlService.mediaGridUrl(item),
                builder: (context, snap) {
                  if (snap.hasError) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _skipBroken();
                    });
                    return const SizedBox.shrink();
                  }
                  final url = snap.data;
                  if (url == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    child: CachedNetworkImage(
                      key: ValueKey(item.id),
                      imageUrl: url,
                      fit: BoxFit.contain,
                      errorWidget: (_, _, _) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _skipBroken();
                        });
                        return const SizedBox.shrink();
                      },
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      color: AppColors.accentWarm,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_index + 1}/${_items.length}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (widget.session.showCaptions)
              Positioned(
                left: 16,
                right: 16,
                bottom: 88,
                child: Text(
                  [
                    if (item.takenAt != null)
                      _dateFormat.format(item.takenAt!.toLocal()),
                    if (item.locationName != null) item.locationName!,
                    if (widget.session.locationLabel != null)
                      widget.session.locationLabel!,
                  ].join(' · '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _prev,
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: _togglePlay,
                    icon: Icon(
                      _playing ? Icons.pause_circle : Icons.play_circle,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  IconButton(
                    onPressed: _next,
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
