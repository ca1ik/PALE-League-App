import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:window_manager/window_manager.dart';

// --- PROVIDERS ---
import 'providers/music_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/ui_provider.dart';

// --- UI & EKRANLAR ---
import 'ui/background.dart';
import 'ui/sidebar.dart';
import 'ui/chatbot.dart';
import 'ui/glass_box.dart';
import 'ui/spatial_sidebar.dart';
import 'ui/movable_window.dart';
import 'screens/settings_screen.dart';

// --- MODÜLLER ---
import 'modules/wifi_module.dart';
import 'modules/optimization_module.dart';
import 'modules/charts_module.dart';
import 'modules/resolution_module.dart';
import 'modules/cleaning_module.dart';
import 'modules/system_tools.dart';
import 'modules/ai_photo_module.dart';
import 'modules/extras_module.dart';
import 'modules/keyboard_module.dart';
import 'modules/turkey_map_module.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
    await Hive.openBox('natroff_memory');
  } catch (e) {
    debugPrint("Hafıza Hatası: $e");
  }

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => UIProvider()),
      ],
      child: const AioApp(),
    ),
  );
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
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      home: const VideoIntroScreen(),
    );
  }
}

class VideoIntroScreen extends StatefulWidget {
  const VideoIntroScreen({super.key});
  @override
  State<VideoIntroScreen> createState() => _VideoIntroScreenState();
}

class _VideoIntroScreenState extends State<VideoIntroScreen> {
  late VideoPlayerController _controller;
  bool _isNavigated = false;
  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    _controller = VideoPlayerController.asset('assets/x.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setVolume(1.0);
      }).catchError((e) {
        _goToMain();
      });
    _controller.addListener(() {
      if (!_isNavigated &&
          _controller.value.position >= _controller.value.duration) {
        _goToMain();
      }
    });
    Future.delayed(const Duration(seconds: 5), _goToMain);
  }

  void _goToMain() {
    if (_isNavigated) return;
    _isNavigated = true;
    _controller.dispose();
    if (mounted)
      Get.offAll(() => const MainWindow(), transition: Transition.fadeIn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller))
                : const CircularProgressIndicator(color: Colors.white24)));
  }
}

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});
  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  // --- NAVİGASYON GEÇMİŞİ SİSTEMİ ---
  List<int> _history = [0]; // Başlangıçta sadece anasayfa (0) var
  int _historyIndex = 0; // Şu an geçmişin hangi sırasındayız

  // Sayfa Değiştirme Fonksiyonu (Geçmişe ekler)
  void _navigateTo(int index) {
    if (_history[_historyIndex] == index)
      return; // Aynı sayfadaysak işlem yapma

    setState(() {
      // Eğer geçmişin ortasındayken yeni bir yere gidersek, ilerideki geçmişi sil (Tarayıcı mantığı)
      if (_historyIndex < _history.length - 1) {
        _history = _history.sublist(0, _historyIndex + 1);
      }
      _history.add(index);
      _historyIndex++;
    });
  }

  // Geri Git
  void _goBack() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
      });
    }
  }

  // İleri Git
  void _goForward() {
    if (_historyIndex < _history.length - 1) {
      setState(() {
        _historyIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final langProv = Provider.of<LanguageProvider>(context);
    final uiProv = Provider.of<UIProvider>(context);
    final isDark = themeProv.isDark;

    // Aktif sayfa indexi geçmişten çekilir
    int activeIdx = _history[_historyIndex];

    // --- MODÜL LİSTESİ ---
    final List<Widget> pages = [
      const ResolutionModule(), // 0
      const CleaningModule(), // 1
      const DnsModule(), // 2
      const PowerModule(), // 3
      const KeyboardModule(), // 4
      const WifiModule(), // 5
      const SecurityModule(), // 6
      const OptimizationModule(), // 7
      const HistoryModule(), // 8
      const WebviewModule(url: "https://github.com/ca1ik"), // 9
      const AiPhotoModule(), // 10
      const ChartsModule(), // 11
      const TurkeyMapModule(), // 12
      const SettingsScreen(), // 13
      const WebviewModule(url: "https://palehaxball.com/"), // 14
    ];

    Widget activeModule = pages[activeIdx < pages.length ? activeIdx : 0];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if (!uiProv.isSpatialMode && isDark)
            const Positioned.fill(child: ParticleBackground()),
          if (!uiProv.isSpatialMode && !isDark)
            Positioned.fill(child: Container(color: Colors.grey[200])),
          if (!uiProv.isSpatialMode)
            Column(
              children: [
                // --- ÜST ÇUBUK (NAVİGASYONLU) ---
                Container(
                  height: 40, // Biraz yükselttik
                  color: isDark ? Colors.black26 : Colors.white,
                  child: Row(
                    children: [
                      // Sürükleme Alanı Başlangıcı
                      Expanded(
                        child: GestureDetector(
                          onPanStart: (_) => windowManager.startDragging(),
                          child: Container(
                            color: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                // --- GERİ BUTONU ---
                                IconButton(
                                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                                      size: 16,
                                      color: _historyIndex > 0
                                          ? (isDark
                                              ? Colors.white
                                              : Colors.black)
                                          : Colors.grey.withOpacity(0.3)),
                                  onPressed: _historyIndex > 0 ? _goBack : null,
                                  tooltip: "Geri",
                                ),
                                // --- İLERİ BUTONU ---
                                IconButton(
                                  icon: Icon(Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: _historyIndex < _history.length - 1
                                          ? (isDark
                                              ? Colors.white
                                              : Colors.black)
                                          : Colors.grey.withOpacity(0.3)),
                                  onPressed: _historyIndex < _history.length - 1
                                      ? _goForward
                                      : null,
                                  tooltip: "İleri",
                                ),

                                const SizedBox(width: 15),

                                // Başlık
                                Text(
                                  langProv.translate('app_title'),
                                  style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Hızlı Ayarlar
                      IconButton(
                        icon: Icon(Icons.settings,
                            color: isDark ? Colors.white70 : Colors.black54,
                            size: 20),
                        onPressed: () => _navigateTo(
                            13), // setState yerine navigateTo kullanıyoruz
                      ),
                      const WindowButtons(),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      // Sidebar'a navigateTo fonksiyonunu gönderiyoruz
                      CustomSidebar(
                          selectedIndex: activeIdx,
                          onIndexChanged: (i) => _navigateTo(i)),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E24).withOpacity(0.6)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    isDark ? Colors.white12 : Colors.black12),
                          ),
                          child: activeModule,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (uiProv.isSpatialMode) ...[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 40,
              child: GestureDetector(
                  onPanStart: (_) => windowManager.startDragging(),
                  child: Container(color: Colors.transparent)),
            ),
            MovableWindow(
              initialX: 20,
              initialY: 100,
              child: SpatialSidebar(
                  selectedIndex: activeIdx,
                  onIndexChanged: (i) => _navigateTo(i)),
            ),
            MovableWindow(
              initialX: 140,
              initialY: 80,
              child: GlassBox(
                width: 900,
                height: 650,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: activeModule),
              ),
            ),
            // Spatial Modda Navigasyon Kontrolleri (Ana Modülün Üzerine Eklenebilir veya ayrı bir bar yapılabilir)
            // Şimdilik pencere kontrolleri yeterli
            const Positioned(
                top: 10, right: 10, child: WindowButtons(isSpatial: true)),
          ],
          uiProv.isSpatialMode
              ? MovableWindow(
                  initialX: 1000,
                  initialY: 600,
                  child: FloatingChatbot(
                      currentLang: langProv.currentLocale.languageCode,
                      onSystemControl: (c, v) =>
                          _handleChatCommand(c, v, themeProv, uiProv)))
              : Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingChatbot(
                      currentLang: langProv.currentLocale.languageCode,
                      onSystemControl: (c, v) =>
                          _handleChatCommand(c, v, themeProv, uiProv))),
        ],
      ),
    );
  }

  void _handleChatCommand(
      String command, dynamic value, ThemeProvider theme, UIProvider ui) {
    if (command == "THEME")
      theme.setTheme(value.toString().toLowerCase() == "dark");
    if (command == "NAVIGATE") {
      int? t;
      switch (value) {
        case "resolution":
          t = 0;
          break;
        case "cleaning":
          t = 1;
          break;
        case "dns":
          t = 2;
          break;
        case "power":
          t = 3;
          break;
        case "keyboard":
          t = 4;
          break;
        case "wifi":
          t = 5;
          break;
        case "security":
          t = 6;
          break;
        case "optimization":
          t = 7;
          break;
        case "history":
          t = 8;
          break;
        case "about":
          t = 9;
          break;
        case "aiphoto":
          t = 10;
          break;
        case "charts":
          t = 11;
          break;
        case "weather":
          t = 12;
          break;
        case "settings":
          t = 13;
          break;
        case "palehax":
          t = 14;
          break;
      }
      if (t != null)
        _navigateTo(t!); // Chatbot da artık geçmiş sistemini kullanıyor
    }
  }
}

class WindowButtons extends StatelessWidget {
  final bool isSpatial;
  const WindowButtons({super.key, this.isSpatial = false});
  @override
  Widget build(BuildContext context) {
    final Color iconColor = isSpatial ? Colors.white : Colors.grey;
    return Row(
      children: [
        _winBtn(Icons.minimize, () => windowManager.minimize(), iconColor),
        _winBtn(Icons.crop_square, () async {
          if (await windowManager.isMaximized())
            windowManager.unmaximize();
          else
            windowManager.maximize();
        }, iconColor),
        _winBtn(Icons.close, () => windowManager.close(), iconColor),
      ],
    );
  }

  Widget _winBtn(IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
        onTap: onTap,
        child: Container(
            width: 40,
            height: 32,
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: color)));
  }
}
