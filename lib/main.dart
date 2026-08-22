import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'backend/supabase/supabase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/nav/nav.dart';
import 'index.dart';

class AppHttpOverrides extends HttpOverrides {
  static const Map<String, String> _staticHostMap = {
    'irisxsklwelqakeloerg.supabase.co': '104.18.38.10',
  };

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionFactory = (Uri uri, String? proxyHost, int? proxyPort) async {
      final isSecure = uri.scheme == 'https' || uri.scheme == 'wss';

      Future<Socket> connect() async {
        // 1. Try default system DNS lookup
        try {
          final addresses = await InternetAddress.lookup(uri.host)
              .timeout(const Duration(milliseconds: 1500));
          if (addresses.isNotEmpty) {
            final rawSocket = await Socket.connect(addresses.first, uri.port);
            if (isSecure) {
              return await SecureSocket.secure(
                rawSocket,
                host: uri.host,
                context: context,
                onBadCertificate: (cert) => true,
              );
            }
            return rawSocket;
          }
        } catch (_) {
          // Fall through to fallback resolver
        }

        // 2. Static host map fallback (handles broken emulator DNS forwarding)
        final fallbackIp = _staticHostMap[uri.host];
        final hostTarget =
            fallbackIp != null ? InternetAddress(fallbackIp) : uri.host;
        final rawSocket = await Socket.connect(hostTarget, uri.port);
        if (isSecure) {
          return await SecureSocket.secure(
            rawSocket,
            host: uri.host,
            context: context,
            onBadCertificate: (cert) => true,
          );
        }
        return rawSocket;
      }

      return ConnectionTask.fromSocket(connect(), () {});
    };
    return client;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = AppHttpOverrides();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await initSupabase();

  await FlutterFlowTheme.initialize();

  final appState = FFAppState(); // Initialize FFAppState
  await appState.initializePersistedState();

  runApp(ChangeNotifierProvider(
    create: (context) => appState,
    child: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.path;
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    Future.delayed(
      Duration(milliseconds: 1000),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Broadcast Automator',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: false,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
