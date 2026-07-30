import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/core/auth/app_role.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:memory_ai/features/admin/presentation/admin_families_screen.dart';
import 'package:memory_ai/features/admin/presentation/admin_users_screen.dart';
import 'package:memory_ai/features/auth/presentation/forgot_password_screen.dart';
import 'package:memory_ai/features/auth/presentation/login_screen.dart';
import 'package:memory_ai/features/auth/presentation/register_screen.dart';
import 'package:memory_ai/features/auth/presentation/welcome_screen.dart';
import 'package:memory_ai/features/chat/presentation/chat_overview_screen.dart';
import 'package:memory_ai/features/profile/presentation/profile_groups_screen.dart';
import 'package:memory_ai/features/map/presentation/world_map_screen.dart';
import 'package:memory_ai/features/timeline/presentation/timeline_screen.dart';
import 'package:memory_ai/features/trips/presentation/create_trip_screen.dart';
import 'package:memory_ai/features/trips/presentation/edit_trip_screen.dart';
import 'package:memory_ai/features/trips/presentation/trip_detail_screen.dart';
import 'package:memory_ai/features/trips/presentation/trip_map_screen.dart';
import 'package:memory_ai/features/trips/presentation/trip_members_screen.dart';
import 'package:memory_ai/features/trips/presentation/trip_memories_screen.dart';
import 'package:memory_ai/features/trips/presentation/trip_suggestions_screen.dart';
import 'package:memory_ai/features/trips/presentation/trip_timeline_screen.dart';
import 'package:memory_ai/features/trips/presentation/trips_screen.dart';
import 'package:memory_ai/features/family/presentation/create_family_screen.dart';
import 'package:memory_ai/features/family/presentation/family_member_detail_screen.dart';
import 'package:memory_ai/features/family/presentation/family_members_screen.dart';
import 'package:memory_ai/features/family/presentation/family_overview_screen.dart';
import 'package:memory_ai/features/family/presentation/family_setup_screen.dart';
import 'package:memory_ai/features/family/presentation/invite_family_member_screen.dart';
import 'package:memory_ai/features/family/presentation/join_family_screen.dart';
import 'package:memory_ai/features/family_tree/presentation/add_family_tree_person_screen.dart';
import 'package:memory_ai/features/family_tree/presentation/assign_relationship_screen.dart';
import 'package:memory_ai/features/family_tree/presentation/edit_family_tree_person_screen.dart';
import 'package:memory_ai/features/family_tree/presentation/family_tree_person_detail_screen.dart';
import 'package:memory_ai/features/family_tree/presentation/family_tree_screen.dart';
import 'package:memory_ai/features/home/presentation/main_navigation_screen.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/presentation/assign_location_screen.dart';
import 'package:memory_ai/features/memories/presentation/album_detail_screen.dart';
import 'package:memory_ai/features/memories/presentation/media_detail_screen.dart';
import 'package:memory_ai/features/memories/presentation/media_gallery_screen.dart';
import 'package:memory_ai/features/memories/presentation/upload_photos_screen.dart';
import 'package:memory_ai/features/map/presentation/country_detail_screen.dart';
import 'package:memory_ai/features/map/presentation/location_gallery_screen.dart';
import 'package:memory_ai/features/map/presentation/location_memories_screen.dart';
import 'package:memory_ai/features/map/presentation/album_viewer_screen.dart';
import 'package:memory_ai/features/map/presentation/memory_slideshow_screen.dart';
import 'package:memory_ai/features/map/data/memory_album_session.dart';
import 'package:memory_ai/features/profile/data/profile_repository.dart';
import 'package:memory_ai/features/profile/presentation/complete_profile_screen.dart';
import 'package:memory_ai/features/profile/presentation/consent_info_screen.dart';
import 'package:memory_ai/features/people/presentation/face_reference_setup_screen.dart';
import 'package:memory_ai/features/profile/presentation/edit_profile_screen.dart';
import 'package:memory_ai/features/profile/presentation/profile_screen.dart';
import 'package:memory_ai/features/settings/presentation/account_screen.dart';
import 'package:memory_ai/features/settings/presentation/privacy_screen.dart';
import 'package:memory_ai/features/settings/presentation/settings_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lauscht auf Auth-Änderungen und löst Router-Refresh aus.
class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable() {
    _subscription = SupabaseService.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final AuthRefreshListenable authRefreshListenable = AuthRefreshListenable();

/// Globale App-Navigation mit Auth- und Onboarding-Guards.
final GoRouter appRouter = GoRouter(
  initialLocation: '/welcome',
  refreshListenable: authRefreshListenable,
  redirect: (context, state) async {
    final session = SupabaseService.client.auth.currentSession;
    final path = state.uri.path;
    final isAuthRoute =
        path == '/welcome' ||
        path == '/login' ||
        path == '/register' ||
        path == '/forgot-password';

    if (session == null) {
      return isAuthRoute ? null : '/welcome';
    }

    final user = SupabaseService.client.auth.currentUser;
    final isAppAdmin = AppRole.isAppAdmin(user);
    final isAdminRoute = path == '/admin' || path.startsWith('/admin/');

    if (isAdminRoute && !isAppAdmin) {
      return '/home';
    }

    // Eingeloggt: Auth-Seiten verlassen.
    if (isAuthRoute || path == '/') {
      // Weiter unten je nach Profil/Familie.
    }

    try {
      final profile = await ProfileRepository().getMyProfile();
      final profileComplete = profile?.profileCompleted == true;

      if (!profileComplete) {
        return path == '/complete-profile' ? null : '/complete-profile';
      }

      if (path == '/complete-profile' ||
          path == '/welcome' ||
          path == '/login' ||
          path == '/register' ||
          path == '/') {
        return '/home';
      }
    } catch (error) {
      debugPrint('Router-Redirect-Fehler: $error');
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/welcome'),
    GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (_, _) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/complete-profile',
      builder: (_, _) => const CompleteProfileScreen(),
    ),
    GoRoute(path: '/home', builder: (_, _) => const MainNavigationScreen()),
    GoRoute(path: '/trips', builder: (_, _) => const TripsScreen()),
    GoRoute(
      path: '/trips/suggestions',
      builder: (_, _) => const TripSuggestionsScreen(),
    ),
    GoRoute(path: '/trips/create', builder: (_, _) => const CreateTripScreen()),
    GoRoute(
      path: '/trips/:id',
      builder: (context, state) =>
          TripDetailScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/trips/:id/edit',
      builder: (context, state) =>
          EditTripScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/trips/:id/timeline',
      builder: (context, state) =>
          TripTimelineScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/trips/:id/map',
      builder: (context, state) =>
          TripMapScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/trips/:id/members',
      builder: (context, state) =>
          TripMembersScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/trips/:id/memories',
      builder: (context, state) =>
          TripMemoriesScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/timeline', builder: (_, _) => const TimelineScreen()),
    GoRoute(
      path: '/map',
      builder: (_, _) => const Scaffold(body: WorldMapScreen()),
    ),
    GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    GoRoute(
      path: '/profile/edit',
      builder: (_, _) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/profile/groups',
      builder: (_, _) => const ProfileGroupsScreen(),
    ),
    GoRoute(
      path: '/profile/consent/face',
      builder: (_, _) => const ConsentInfoScreen(),
    ),
    GoRoute(
      path: '/profile/face-references',
      builder: (_, _) => const FaceReferenceSetupScreen(),
    ),
    GoRoute(path: '/chat', builder: (_, _) => const ChatOverviewScreen()),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(
      path: '/settings/privacy',
      builder: (_, _) => const PrivacyScreen(),
    ),
    GoRoute(
      path: '/settings/account',
      builder: (_, _) => const AccountScreen(),
    ),
    GoRoute(path: '/family', builder: (_, _) => const FamilyOverviewScreen()),
    GoRoute(
      path: '/family/setup',
      builder: (_, _) => const FamilySetupScreen(),
    ),
    GoRoute(
      path: '/family/create',
      builder: (_, _) => const CreateFamilyScreen(),
    ),
    GoRoute(path: '/family/join', builder: (_, _) => const JoinFamilyScreen()),
    GoRoute(
      path: '/family/members',
      builder: (context, state) {
        final familyId = state.uri.queryParameters['familyId'] ?? '';
        return FamilyMembersScreen(familyId: familyId);
      },
    ),
    GoRoute(
      path: '/family/member/:id',
      builder: (context, state) => FamilyMemberDetailScreen(
        familyId: state.uri.queryParameters['familyId'] ?? '',
        userId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/family/invite',
      builder: (context, state) {
        final familyId = state.uri.queryParameters['familyId'] ?? '';
        return InviteFamilyMemberScreen(familyId: familyId);
      },
    ),
    GoRoute(
      path: '/family/:familyId/invite',
      name: 'familyInvite',
      builder: (context, state) {
        final familyId = state.pathParameters['familyId'] ?? '';
        return InviteFamilyMemberScreen(familyId: familyId);
      },
    ),
    GoRoute(
      path: '/family-tree',
      builder: (context, state) {
        final familyId = state.uri.queryParameters['familyId'] ?? '';
        return FamilyTreeScreen(familyId: familyId);
      },
    ),
    GoRoute(
      path: '/family-tree/person/add',
      builder: (context, state) {
        final familyId = state.uri.queryParameters['familyId'] ?? '';
        return AddFamilyTreePersonScreen(familyId: familyId);
      },
    ),
    GoRoute(
      path: '/family-tree/person/:id',
      builder: (context, state) => FamilyTreePersonDetailScreen(
        personId: state.pathParameters['id']!,
        familyId: state.uri.queryParameters['familyId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/family-tree/person/:id/edit',
      builder: (context, state) => EditFamilyTreePersonScreen(
        personId: state.pathParameters['id']!,
        familyId: state.uri.queryParameters['familyId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/family-tree/relationship/add',
      builder: (context, state) {
        final familyId = state.uri.queryParameters['familyId'] ?? '';
        return AssignRelationshipScreen(familyId: familyId);
      },
    ),
    GoRoute(
      path: '/memories/upload',
      builder: (context, state) {
        final familyId = state.uri.queryParameters['familyId'];
        final tripId = state.uri.queryParameters['tripId'];
        return UploadPhotosScreen(familyId: familyId, tripId: tripId);
      },
    ),
    GoRoute(
      path: '/media/gallery',
      builder: (_, _) => const MediaGalleryScreen(),
    ),
    GoRoute(
      path: '/album/:id',
      builder: (context, state) =>
          AlbumDetailScreen(albumId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/media/assign-location',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is! MediaItemModel) {
          return const Scaffold(
            body: Center(child: Text('Kein Foto ausgewählt.')),
          );
        }
        return AssignLocationScreen(mediaItem: extra);
      },
    ),
    GoRoute(
      path: '/media/:id',
      builder: (context, state) =>
          MediaDetailScreen(mediaId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/map/location',
      builder: (context, state) => LocationMemoriesScreen(
        locationId: state.uri.queryParameters['id'],
        countryName: state.uri.queryParameters['country'],
        cityName: state.uri.queryParameters['city'],
        coordinateKey: state.uri.queryParameters['coordinateKey'],
        locationLabel: state.uri.queryParameters['label'],
      ),
    ),
    GoRoute(
      path: '/map/location-gallery',
      builder: (context, state) => LocationGalleryScreen(
        coordinateKey: state.uri.queryParameters['coordinateKey'],
        countryName: state.uri.queryParameters['country'],
        cityName: state.uri.queryParameters['city'],
        locationLabel: state.uri.queryParameters['label'],
      ),
    ),
    GoRoute(
      path: '/map/album-viewer',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is! MemoryAlbumSession) {
          return const Scaffold(
            body: Center(child: Text('Kein Album geladen.')),
          );
        }
        return AlbumViewerScreen(session: extra);
      },
    ),
    GoRoute(
      path: '/map/slideshow',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is! SlideshowSession) {
          return const Scaffold(
            body: Center(child: Text('Keine Slideshow geladen.')),
          );
        }
        return MemorySlideshowScreen(session: extra);
      },
    ),
    GoRoute(
      path: '/map/country',
      builder: (context, state) => CountryDetailScreen(
        countryName: state.uri.queryParameters['name'] ?? '',
      ),
    ),
    GoRoute(path: '/admin', builder: (_, _) => const AdminDashboardScreen()),
    GoRoute(path: '/admin/users', builder: (_, _) => const AdminUsersScreen()),
    GoRoute(
      path: '/admin/families',
      builder: (_, _) => const AdminFamiliesScreen(),
    ),
  ],
);
