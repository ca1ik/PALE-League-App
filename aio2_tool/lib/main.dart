import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'modules/standings_view.dart';
import 'services/database_service.dart';
import 'providers/music_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/ui_provider.dart';
import 'data/player_data.dart';
import 'ui/background.dart';
import 'ui/sidebar.dart';

import 'ui/chatbot.dart';
import 'ui/glass_box.dart';
import 'ui/spatial_sidebar.dart';
import 'ui/movable_window.dart';
import 'screens/settings_screen.dart';
import 'modules/wifi_module.dart';
import 'modules/optimization_module.dart';
import 'modules/charts_module.dart';
import 'modules/cleaning_module.dart';
import 'modules/system_tools.dart';
import 'modules/pale_webview.dart';
import 'modules/ai_photo_module.dart';
import 'modules/keyboard_module.dart';
import 'modules/turkey_map_module.dart';
import 'modules/palehax_players_view.dart';
import 'modules/challenge_hub.dart';
import 'modules/squad_builder_module.dart';

import 'modules/palehax_tierlist.dart';
import 'modules/palehax_ultimate.dart';
import 'modules/palehax_games.dart';
import 'modules/pale_webview.dart';
import 'modules/custom_browser_module.dart';
import 'modules/extras_module.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PlayerAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(PlayStyleAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(MatchStatAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(SeasonStatAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(StrategyAdapter());

    await Future.wait([
      Hive.openBox('natroff_memory'),
      Hive.openBox<StrategyModel>('palehax_strategies'),
      Hive.openBox<Player>('palehax_manager_db'),
      Hive.openBox<Player>('palehax_players_v9'),
      Hive.openBox<Player>('palehax_players'),
    ]);
  } catch (e) {
    debugPrint("Hive Hatası: $e");
  }

  // Window Manager yalnızca Windows/macOS için
  if (Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 850),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setBackgroundColor(Colors.transparent);
    });
  }

  runApp(MultiProvider(providers: [
    Provider<AppDatabase>(
        create: (context) => AppDatabase(),
        dispose: (context, db) => db.close()),
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => MusicProvider()),
    ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ChangeNotifierProvider(create: (_) => UIProvider()),
    ChangeNotifierProvider(create: (_) => UltimateTeamProvider()..startTimer()),
  ], child: const AioApp()));
}

class AioApp extends StatelessWidget {
  const AioApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final langProv = Provider.of<LanguageProvider>(context);
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Natroff AIO',
      locale: langProv.currentLocale,
      themeMode: themeProv.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light().copyWith(
          scaffoldBackgroundColor: Colors.grey[100],
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme)),
      darkTheme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)),
      home: const MainWindow(),
    );
  }
}

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});
  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  List<int> _history = [0];
  int _historyIndex = 0;
  bool _isFullScreenMode = false;
  bool _showHelpIcon = false;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_keyboardFocusNode);
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _navigateTo(int index) {
    if (_history[_historyIndex] == index) return;
    setState(() {
      if (_historyIndex < _history.length - 1) {
        _history = _history.sublist(0, _historyIndex + 1);
      }
      _history.add(index);
      _historyIndex++;
    });
  }

  void _goBack() {
    if (_historyIndex > 0) setState(() => _historyIndex--);
  }

  void _goForward() {
    if (_historyIndex < _history.length - 1) setState(() => _historyIndex++);
  }

  void _launchHaxBall() {
    if (Platform.isWindows) {
      // GetActiveWindow() sadece Windows'ta mevcut
      try {
        // final int myHwnd = GetActiveWindow();
        // HaxBallService.launchAndEmbed(myHwnd, 110, 40, 1170, 810);
      } catch (e) {
        debugPrint("HaxBall launch error: $e");
      }
    }
    setState(() {
      _showHelpIcon = true;
    });
  }

  // --- TUŞ DİNLEME VE EYLEM ---
  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f11) {
        _toggleFullScreen();
      }
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreenMode = !_isFullScreenMode;

      if (_isFullScreenMode) {
        windowManager.setFullScreen(true);
        _showHelpIcon = false;

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.speed, color: Colors.greenAccent),
              const SizedBox(width: 10),
              Text("Sınırsız FPS Moduna Geçildi!",
                  style: GoogleFonts.orbitron(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.black.withOpacity(0.8),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      } else {
        windowManager.setFullScreen(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final langProv = Provider.of<LanguageProvider>(context);
    final uiProv = Provider.of<UIProvider>(context);
    final database = Provider.of<AppDatabase>(context);
    final isDark = themeProv.isDark;
    int activeIdx = _history[_historyIndex];

    final List<Widget> pages = [
      /* 0 */ const SizedBox(), // ResolutionModule - Windows only
      /* 1 */ const CleaningModule(),
      /* 2 */ const DnsModule(),
      /* 3 */ const PowerModule(),
      /* 4 */ const KeyboardModule(),
      /* 5 */ const WifiModule(),
      /* 6 */ const SecurityModule(),
      /* 7 */ const OptimizationModule(),
      /* 8 */ const HistoryModule(),
      /* 9 */ const WebviewModule(url: "https://github.com/ca1ik"),
      /* 10 */ const AiPhotoModule(),
      /* 11 */ const ChartsModule(),
      /* 12 */ const TurkeyMapModule(),
      /* 13 */ const SettingsScreen(),
      /* 14  const PaleWebView( 
          url: "https://palehaxball.com/", key: ValueKey("ph_home")),*/
      /* 15 */ const PaleHaxPlayersView(),
      /* 16 */ const StandingsView(),
      /* 17 */ const ChallengeHub(),
      /* 18 */ const SquadBuilderModule(isTOTWMode: true),
      /* 19 */ TierListView(database: database),
      /* 20 */ UltimateTeamView(database: database),
      /* 21 */ const GamesHubView(),
      /* 22 */ CustomBrowserModule(
          isFullScreen: _isFullScreenMode,
          onToggleFullScreen:
              _toggleFullScreen // Tarayıcıdan gelen sinyali bağladık
          ),
    ];

    Widget activeModule;
    if (activeIdx >= 0 && activeIdx < pages.length) {
      activeModule = pages[activeIdx];
    } else {
      activeModule = pages[0];
    }

    return RawKeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKey: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(children: [
          if (!uiProv.isSpatialMode && isDark)
            const Positioned.fill(child: ParticleBackground()),
          if (!uiProv.isSpatialMode && !isDark)
            Positioned.fill(child: Container(color: Colors.grey[200])),

          // 2. KATMAN: ANA İÇERİK (STABİL YAPILDI)
          if (!uiProv.isSpatialMode)
            Column(children: [
              // ÜST BAR: Yükseklik animasyonu ile gizleniyor (Yok edilmiyor)
              AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isFullScreenMode ? 0 : 40,
                  child: SingleChildScrollView(
                      // Overflow hatasını önler
                      physics: const NeverScrollableScrollPhysics(),
                      child: Container(
                          height: 40,
                          color: isDark ? Colors.black26 : Colors.white,
                          child: Row(children: [
                            Expanded(
                                child: GestureDetector(
                                    onPanStart: (_) =>
                                        windowManager.startDragging(),
                                    child: Container(
                                        color: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Row(children: [
                                          IconButton(
                                              icon: Icon(
                                                  Icons
                                                      .arrow_back_ios_new_rounded,
                                                  size: 16,
                                                  color: _historyIndex > 0
                                                      ? (isDark
                                                          ? Colors.white
                                                          : Colors.black)
                                                      : Colors.grey
                                                          .withOpacity(0.3)),
                                              onPressed: _historyIndex > 0
                                                  ? _goBack
                                                  : null),
                                          IconButton(
                                              icon: Icon(
                                                  Icons
                                                      .arrow_forward_ios_rounded,
                                                  size: 16,
                                                  color: _historyIndex <
                                                          _history.length - 1
                                                      ? (isDark
                                                          ? Colors.white
                                                          : Colors.black)
                                                      : Colors.grey
                                                          .withOpacity(0.3)),
                                              onPressed: _historyIndex <
                                                      _history.length - 1
                                                  ? _goForward
                                                  : null),
                                          const SizedBox(width: 15),
                                          Text(langProv.translate('app_title'),
                                              style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontWeight: FontWeight.bold))
                                        ])))),
                            IconButton(
                                icon: Icon(Icons.settings,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    size: 20),
                                onPressed: () => _navigateTo(13)),
                            const WindowButtons()
                          ])))),

              // İÇERİK ALANI
              Expanded(
                  child: Row(children: [
                // SIDEBAR: Genişlik animasyonu ile gizleniyor (Yok edilmiyor)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _isFullScreenMode ? 0 : 110,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      // İçeriği sabit tutup sadece containerı daraltıyoruz
                      width: 110,
                      child: CustomSidebar(
                          selectedIndex: activeIdx,
                          onIndexChanged: (i) => _navigateTo(i),
                          onHaxBallClick: _launchHaxBall),
                    ),
                  ),
                ),

                // AKTİF MODÜL
                Expanded(
                    child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: _isFullScreenMode
                            ? EdgeInsets.zero
                            : const EdgeInsets.all(20),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E24).withOpacity(0.6)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(
                                _isFullScreenMode ? 0 : 20),
                            border: _isFullScreenMode
                                ? null
                                : Border.all(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.black12)),
                        child: activeModule))
              ]))
            ]),

          if (uiProv.isSpatialMode) ...[
            Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 40,
                child: GestureDetector(
                    onPanStart: (_) => windowManager.startDragging(),
                    child: Container(color: Colors.transparent))),
            MovableWindow(
                initialX: 20,
                initialY: 100,
                child: SpatialSidebar(
                    selectedIndex: activeIdx,
                    onIndexChanged: (i) => _navigateTo(i))),
            MovableWindow(
                initialX: 140,
                initialY: 80,
                child: GlassBox(
                    width: 900,
                    height: 650,
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: activeModule))),
            const Positioned(
                top: 10, right: 10, child: WindowButtons(isSpatial: true))
          ],

          // CHATBOT (Tam ekranda gizle)
          if (!_isFullScreenMode)
            uiProv.isSpatialMode
                ? MovableWindow(
                    initialX: 1000,
                    initialY: 600,
                    child: FloatingChatbot(
                        currentLang: langProv.currentLocale.languageCode,
                        onSystemControl: (c, v) => {}))
                : Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingChatbot(
                        currentLang: langProv.currentLocale.languageCode,
                        onSystemControl: (c, v) => {})),

          if (_showHelpIcon && !_isFullScreenMode)
            Positioned(
                top: 50,
                right: 20,
                child: Tooltip(
                    message: 'Tam Ekran Modu için "F11" tuşuna bas.',
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    child: ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                                colors: [Colors.red, Colors.green, Colors.blue])
                            .createShader(b),
                        child: const Icon(Icons.help_outline,
                            size: 40, color: Colors.white))))
        ]),
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  final bool isSpatial;
  const WindowButtons({super.key, this.isSpatial = false});
  @override
  Widget build(BuildContext context) {
    final Color iconColor = isSpatial ? Colors.white : Colors.grey;
    return Row(children: [
      _winBtn(Icons.minimize, () => windowManager.minimize(), iconColor),
      _winBtn(Icons.crop_square, () async {
        if (await windowManager.isMaximized())
          windowManager.unmaximize();
        else
          windowManager.maximize();
      }, iconColor),
      _winBtn(Icons.close, () => windowManager.close(), iconColor)
    ]);
  }

  Widget _winBtn(IconData icon, VoidCallback onTap, Color color) => InkWell(
      onTap: onTap,
      child: Container(
          width: 40,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: color)));
}

class WebviewModule extends StatelessWidget {
  final String url;
  const WebviewModule({super.key, required this.url});
  @override
  Widget build(BuildContext context) {
    return Center(
        child:
            Text("WebView: $url", style: const TextStyle(color: Colors.white)));
  }
}
