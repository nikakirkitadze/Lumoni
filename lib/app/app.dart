import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lumoni/app/router.dart';
import 'package:lumoni/design_system/design_system.dart';
import 'package:lumoni/features/auth/presentation/cubits/auth_cubit.dart';

/// Root widget for the Lumoni application.
///
/// Sets up the global [MultiBlocProvider] wrapping [AuthCubit], configures
/// the [MaterialApp.router] with the dark theme and GoRouter navigation,
/// and listens for incoming deep links (email sign-in).
class LumoniApp extends StatefulWidget {
  const LumoniApp({super.key});

  @override
  State<LumoniApp> createState() => _LumoniAppState();
}

class _LumoniAppState extends State<LumoniApp> {
  final _authCubit = AuthCubit()..checkAuthStatus();
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Handle link that launched the app (cold start).
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleLink(initialLink);
      }
    } catch (e) {
      debugPrint('[LumoniApp] Error getting initial link: $e');
    }

    // Handle links while app is running (warm start).
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleLink,
      onError: (e) {
        debugPrint('[LumoniApp] Error in link stream: $e');
      },
    );
  }

  void _handleLink(Uri uri) {
    debugPrint('[LumoniApp] Incoming deep link: $uri');
    _authCubit.handleIncomingLink(uri.toString());
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(
          value: _authCubit,
        ),
      ],
      child: MaterialApp.router(
        title: 'Lumoni',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: appRouter,
      ),
    );
  }
}
