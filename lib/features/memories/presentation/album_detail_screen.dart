import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/map/data/memory_album_session.dart';
import 'package:memory_ai/features/map/presentation/album_viewer_screen.dart';
import 'package:memory_ai/features/memories/data/album_repository.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

/// Lädt ein persistiertes Album und öffnet den Vollbild-Viewer.
class AlbumDetailScreen extends StatefulWidget {
  const AlbumDetailScreen({super.key, required this.albumId});

  final String albumId;

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final _repo = AlbumRepository();
  MemoryAlbumSession? _session;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final album = await _repo.getAlbum(widget.albumId);
      if (!mounted) return;
      if (album == null) {
        setState(() {
          _loading = false;
          _error = 'Album nicht gefunden.';
        });
        return;
      }
      final session = await _repo.toSession(album);
      if (!mounted) return;
      setState(() {
        _session = session;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ErrorMapper.map(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppScaffold(
        showAppBar: false,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return AppScaffold(
        title: 'Album',
        body: ErrorState(message: _error!, onRetry: _load),
      );
    }
    final session = _session;
    if (session == null) {
      return AppScaffold(
        title: 'Album',
        body: Center(
          child: Text(
            'Kein Album geladen.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    // Vollbild ohne Bottom-Nav (Route /album/:id ist in Shell – Viewer selbst fullscreen).
    return AlbumViewerScreen(
      session: session,
      onClose: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
    );
  }
}
