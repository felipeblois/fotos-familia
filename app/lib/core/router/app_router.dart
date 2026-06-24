import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/about_screen.dart';
import '../../features/access_limited/access_limited_screen.dart';
import '../../features/admin/admin_screen.dart';
import '../../features/consent/consent_screen.dart';
import '../../features/gallery/gallery_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/photo_viewer/photo_viewer_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../config/app_config.dart';
import '../models/photo_model.dart';
import '../providers/consent_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final consentState = ref.watch(consentProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      if (AppConfig.bypassConsent) {
        if (state.uri.toString() == '/consent') {
          return '/home';
        }
        return null;
      }

      final location = state.uri.toString();
      final isSplash = location == '/';
      final isConsentRoute = location == '/consent';
      final isAboutRoute = location == '/about';
      final isAccessLimitedRoute = location == '/access-limited';

      if (consentState.isLoading) {
        return null;
      }

      final hasConsented = consentState.value ?? false;

      if (
          !hasConsented &&
          !isSplash &&
          !isConsentRoute &&
          !isAboutRoute &&
          !isAccessLimitedRoute) {
        return '/consent';
      }

      if (hasConsented && isConsentRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/consent',
        name: 'consent',
        builder: (context, state) => const ConsentScreen(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/access-limited',
        name: 'access-limited',
        builder: (context, state) => const AccessLimitedScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/gallery',
        name: 'gallery',
        builder: (context, state) => const GalleryScreen(),
      ),
      GoRoute(
        path: '/photo/:id',
        name: 'photo',
        builder: (context, state) {
          final photo = state.extra as PhotoItem?;
          return PhotoViewerScreen(
            photoId: state.pathParameters['id']!,
            photo: photo,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Pagina nao encontrada: ${state.uri}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    ),
  );
});
