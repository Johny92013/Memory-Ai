import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/profile/data/profile_model.dart';

/// Dashboard-Daten für die Startseite (teilweise fehlertolerant).
class HomeDashboardData {
  const HomeDashboardData({
    this.profile,
    this.photoCount = 0,
    this.videoCount = 0,
    this.familyMemberCount,
    this.hasFamily = false,
    this.visitedLocationCount = 0,
    this.unreadMessageCount,
    this.chatAvailable = false,
    this.recentMemories = const [],
    this.statsFailed = false,
    this.familyFailed = false,
    this.memoriesFailed = false,
    this.locationsFailed = false,
  });

  final ProfileModel? profile;
  final int photoCount;
  final int videoCount;
  final int? familyMemberCount;
  final bool hasFamily;
  final int visitedLocationCount;
  final int? unreadMessageCount;
  final bool chatAvailable;
  final List<MediaItemModel> recentMemories;
  final bool statsFailed;
  final bool familyFailed;
  final bool memoriesFailed;
  final bool locationsFailed;

  bool get hasMedia => photoCount + videoCount > 0;

  String get memoriesSubtitle {
    if (statsFailed) return 'Nicht verfügbar';
    if (!hasMedia) return 'Noch keine Erinnerungen';
    if (videoCount > 0) {
      return '$photoCount Fotos, $videoCount Videos';
    }
    return '$photoCount Fotos';
  }

  String get familySubtitle {
    if (familyFailed) return 'Nicht verfügbar';
    if (!hasFamily) return 'Familie einrichten';
    final count = familyMemberCount ?? 0;
    return '$count Mitglied${count == 1 ? '' : 'er'}';
  }

  String get mapSubtitle {
    if (locationsFailed) return 'Nicht verfügbar';
    if (visitedLocationCount <= 0) return 'Noch keine Orte';
    return '$visitedLocationCount Orte bereist';
  }

  String get chatSubtitle {
    if (!chatAvailable) return 'Neue Nachrichten';
    final unread = unreadMessageCount;
    if (unread == null) return 'Neue Nachrichten';
    if (unread <= 0) return 'Keine neuen Nachrichten';
    return '$unread neue Nachricht${unread == 1 ? '' : 'en'}';
  }
}
