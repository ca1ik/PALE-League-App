import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Win32 import only on Windows
import 'package:win32/win32.dart'
    if (dart.library.html) 'package:flutter/material.dart'; // Dummy import for web/mobile

// Veri Modelleri
class ResolutionOption {
  final int width, height, hz;
  ResolutionOption(this.width, this.height, this.hz);
  @override
  String toString() => "$width x $height";
  Map<String, dynamic> toJson() => {'width': width, 'height': height, 'hz': hz};
  factory ResolutionOption.fromJson(Map<String, dynamic> json) =>
      ResolutionOption(json['width'], json['height'], json['hz']);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolutionOption &&
          width == other.width &&
          height == other.height &&
          hz == other.hz;
  @override
  int get hashCode => Object.hash(width, height, hz);
}

class Preset {
  final String name;
  final ResolutionOption modeA; // Masaüstü
  final ResolutionOption modeB; // Oyun
  final int hz;
  Preset(
      {required this.name,
      required this.modeA,
      required this.modeB,
      required this.hz});
  Map<String, dynamic> toJson() => {
        'name': name,
        'modeA': modeA.toJson(),
        'modeB': modeB.toJson(),
        'hz': hz
      };
  factory Preset.fromJson(Map<String, dynamic> j) => Preset(
      name: j['name'],
      modeA: ResolutionOption.fromJson(j['modeA']),
      modeB: ResolutionOption.fromJson(j['modeB']),
      hz: j['hz']);
}

class ResolutionModule extends StatefulWidget {
  const ResolutionModule({super.key});
  @override
  State<ResolutionModule> createState() => _ResolutionModuleState();
}

class _ResolutionModuleState extends State<ResolutionModule> {
  List<int> _supportedHz = [];
  int? _selectedHz;
  List<ResolutionOption> _currentResolutions = [];

  // Seçimler
  ResolutionOption? _selectedModeA; // Masaüstü
  ResolutionOption? _selectedModeB; // Oyun

  List<Preset> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await Future.delayed(Duration.zero);
    final hzList = _getSupportedRefreshRates();
    _loadFavorites();
    if (mounted) {
      setState(() {
        _supportedHz = hzList;
        if (hzList.isNotEmpty) {
          _selectedHz = hzList.first;
          _updateResolutionsForHz(_selectedHz!);
        }
        _isLoading = false;
      });
    }
  }

  // Windows API
  List<int> _getSupportedRefreshRates() {
    Set<int> rates = {};
    final devMode = calloc<DEVMODE>();
    devMode.ref.dmSize = sizeOf<DEVMODE>();
    int i = 0;
    while (EnumDisplaySettings(nullptr, i, devMode) != 0) {
      rates.add(devMode.ref.dmDisplayFrequency);
      i++;
    }
    free(devMode);
    return rates.toList()..sort((a, b) => b.compareTo(a));
  }

  void _updateResolutionsForHz(int hz) {
    List<ResolutionOption> resolutions = [];
    final devMode = calloc<DEVMODE>();
    devMode.ref.dmSize = sizeOf<DEVMODE>();
    int i = 0;
    while (EnumDisplaySettings(nullptr, i, devMode) != 0) {
      if (devMode.ref.dmDisplayFrequency == hz) {
        final res = ResolutionOption(devMode.ref.dmPelsWidth,
            devMode.ref.dmPelsHeight, devMode.ref.dmDisplayFrequency);
        if (!resolutions
            .any((r) => r.width == res.width && r.height == res.height)) {
          resolutions.add(res);
        }
      }
      i++;
    }
    free(devMode);
    resolutions.sort((a, b) => b.width.compareTo(a.width)); // Büyükten küçüğe
    setState(() {
      _currentResolutions = resolutions;
      if (resolutions.isNotEmpty) {
        if (_selectedModeA == null) _selectedModeA = resolutions.first;
        if (_selectedModeB == null)
          _selectedModeB =
              resolutions.length > 1 ? resolutions[1] : resolutions.last;
      }
    });
  }

  void _changeRes(ResolutionOption target) {
    final devMode = calloc<DEVMODE>();
    devMode.ref.dmSize = sizeOf<DEVMODE>();
    EnumDisplaySettings(nullptr, ENUM_CURRENT_SETTINGS, devMode);
    devMode.ref.dmPelsWidth = target.width;
    devMode.ref.dmPelsHeight = target.height;
    devMode.ref.dmDisplayFrequency = target.hz;
    devMode.ref.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT | DM_DISPLAYFREQUENCY;
    ChangeDisplaySettings(devMode, 0);
    free(devMode);
  }

  // Toggle Logic (Bi ona bi buna)
  void _togglePreset(Preset p) {
    // Şu anki çözünürlüğü bul
    final devMode = calloc<DEVMODE>();
    devMode.ref.dmSize = sizeOf<DEVMODE>();
    EnumDisplaySettings(nullptr, ENUM_CURRENT_SETTINGS, devMode);
    int currentW = devMode.ref.dmPelsWidth;
    int currentH = devMode.ref.dmPelsHeight;
    free(devMode);

    // Eğer şu an ModeA ise ModeB'ye geç, değilse ModeA'ya geç
    if (currentW == p.modeA.width && currentH == p.modeA.height) {
      _changeRes(p.modeB);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Oyun Moduna Geçildi: ${p.modeB}"),
          backgroundColor: Colors.purple));
    } else {
      _changeRes(p.modeA);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Masaüstü Moduna Geçildi: ${p.modeA}"),
          backgroundColor: Colors.blue));
    }
  }

  // Favori İşlemleri
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString('fav_presets');
    if (saved != null) {
      final List decoded = jsonDecode(saved);
      setState(
          () => _favorites = decoded.map((e) => Preset.fromJson(e)).toList());
    }
  }

  Future<void> _saveFavorite() async {
    if (_selectedModeA == null || _selectedModeB == null || _selectedHz == null)
      return;

    // İsim İste
    final controller = TextEditingController();
    await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Favori Ekle"),
              content: TextField(
                  controller: controller,
                  decoration:
                      const InputDecoration(hintText: "Örn: CS2 Ayarı")),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("İptal")),
                FilledButton(
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        setState(() {
                          _favorites.add(Preset(
                              name: controller.text,
                              modeA: _selectedModeA!,
                              modeB: _selectedModeB!,
                              hz: _selectedHz!));
                        });
                        _saveToDisk();
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text("Kaydet"))
              ],
            ));
  }

  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_favorites.map((e) => e.toJson()).toList());
    prefs.setString('fav_presets', data);
  }

  void _deleteFav(int index) {
    setState(() => _favorites.removeAt(index));
    _saveToDisk();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Çözünürlük Geçişi",
                style: GoogleFonts.poppins(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            IconButton(
                onPressed: _saveFavorite,
                icon: const Icon(Icons.star_border,
                    size: 30, color: Colors.amber),
                tooltip: "Ayarları Favorilere Ekle")
          ],
        ),
        const SizedBox(height: 20),

        // Ayar Seçim Alanı
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.black12, borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              // HZ
              DropdownButton<int>(
                  value: _selectedHz,
                  isExpanded: true,
                  items: _supportedHz
                      .map((hz) =>
                          DropdownMenuItem(value: hz, child: Text("$hz Hz")))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedHz = v);
                      _updateResolutionsForHz(v);
                    }
                  }),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Mod A (Masaüstü)",
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        DropdownButton<ResolutionOption>(
                          value: _selectedModeA,
                          isExpanded: true,
                          items: _currentResolutions
                              .map((r) => DropdownMenuItem(
                                  value: r, child: Text(r.toString())))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedModeA = v),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.swap_horiz, size: 30)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Mod B (Oyun)",
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        DropdownButton<ResolutionOption>(
                          value: _selectedModeB,
                          isExpanded: true,
                          items: _currentResolutions
                              .map((r) => DropdownMenuItem(
                                  value: r, child: Text(r.toString())))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedModeB = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),
        const Divider(),
        const SizedBox(height: 10),
        Align(
            alignment: Alignment.centerLeft,
            child: Text("Favorilerim",
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold))),
        const SizedBox(height: 10),

        // Favori Kartları
        if (_favorites.isEmpty)
          const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                  "Henüz favori eklemediniz. Yukarıdaki yıldız ikonuna tıklayın.",
                  style: TextStyle(color: Colors.grey))),

        Wrap(
          spacing: 15,
          runSpacing: 15,
          children: _favorites.asMap().entries.map((entry) {
            final idx = entry.key;
            final fav = entry.value;
            return InkWell(
              onTap: () => _togglePreset(fav),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF25252D), Color(0xFF1E1E24)]),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2), blurRadius: 5)
                    ]),
                child: Column(
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(fav.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          GestureDetector(
                              onTap: () => _deleteFav(idx),
                              child: const Icon(Icons.close,
                                  color: Colors.grey, size: 16))
                        ]),
                    const Divider(color: Colors.white10),
                    Text("${fav.hz} Hz",
                        style: const TextStyle(color: Colors.cyanAccent)),
                    Text(
                        "${fav.modeA.width}x${fav.modeA.height}  ↔  ${fav.modeB.width}x${fav.modeB.height}",
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white70)),
                    const SizedBox(height: 5),
                    const Text("TIKLA & GEÇİŞ YAP",
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent))
                  ],
                ),
              ),
            );
          }).toList(),
        )
      ],
    );
  }
}
