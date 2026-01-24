import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

const String _groqKey =
    "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";

class FloatingChatbot extends StatefulWidget {
  final String currentLang; // Main'den gelen dil bilgisi
  final Function(String command, dynamic value) onSystemControl;

  const FloatingChatbot({
    super.key,
    required this.onSystemControl,
    this.currentLang = "tr", // Varsayılan TR
  });

  @override
  State<FloatingChatbot> createState() => FloatingChatbotState();
}

class FloatingChatbotState extends State<FloatingChatbot>
    with TickerProviderStateMixin {
  bool _isOpen = false;
  bool _isHovering = false;
  final TextEditingController _c = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _rgbController;
  late AnimationController _starController;
  List<Map<String, dynamic>> _msgs = [];
  bool _loading = false;
  final _box = Hive.box('natroff_memory');

  @override
  void initState() {
    super.initState();
    _rgbController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
    _starController =
        AnimationController(vsync: this, duration: const Duration(seconds: 30))
          ..repeat();

    var saved = _box.get('chat_history');
    if (saved != null) {
      _msgs = List<Map<String, dynamic>>.from(jsonDecode(saved));
    } else {
      // Başlangıç mesajını dile göre ayarla
      String welcome = widget.currentLang == "tr"
          ? "🤖 Natroff Core hazır. Uygulamanı yönetmek için talimatlarını bekliyorum."
          : "🤖 Natroff Core is ready. Waiting for your instructions to manage your app.";
      _msgs.add({"text": welcome, "isUser": false});
    }
  }

  @override
  void dispose() {
    _rgbController.dispose();
    _starController.dispose();
    _c.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleGlobalKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.tab) {
      if (!_isOpen) setState(() => _isOpen = true);
      _focusNode.requestFocus();
    }
  }

  Future<void> _processCommand(String input) async {
    final t = input.toLowerCase().trim();
    String? localRes;

    setState(() {
      _msgs.add({"text": input, "isUser": true});
      _c.clear();
      _loading = true;
    });
    _scrollToBottom();

    // --- Yerel Komut İşleme (Çift Dil Destekli) ---
    if (t.contains("aydın") || t.contains("ışık") || t.contains("light")) {
      widget.onSystemControl("THEME", "light");
      localRes = widget.currentLang == "tr"
          ? "🌓 Aydınlık tema aktif edildi."
          : "🌓 Light theme activated.";
    } else if (t.contains("koyu") ||
        t.contains("siyah") ||
        t.contains("dark")) {
      widget.onSystemControl("THEME", "dark");
      localRes = widget.currentLang == "tr"
          ? "🌒 Karanlık moda geçildi."
          : "🌒 Switched to dark mode.";
    } else if (t.contains("temiz") || t.contains("clean")) {
      widget.onSystemControl("NAVIGATE", "cleaning");
      localRes = widget.currentLang == "tr"
          ? "🧹 Temizlik modülü açıldı."
          : "🧹 Cleaning module opened.";
    } else if (t.contains("ekran") ||
        t.contains("hz") ||
        t.contains("resolution")) {
      widget.onSystemControl("NAVIGATE", "resolution");
      localRes = widget.currentLang == "tr"
          ? "🖥️ Ekran ayarları modülü açıldı."
          : "🖥️ Resolution settings opened.";
    } else if (t.contains("hava") ||
        t.contains("harita") ||
        t.contains("weather") ||
        t.contains("map")) {
      widget.onSystemControl("NAVIGATE", "weather");
      localRes = widget.currentLang == "tr"
          ? "🌍 Türkiye haritası ve hava durumu açıldı."
          : "🌍 Turkey map and weather opened.";
    }

    String aiRes = localRes ?? await _getGroqResponse(input);

    if (mounted) {
      setState(() {
        _msgs.add({"text": aiRes, "isUser": false});
        _loading = false;
      });
      _box.put('chat_history', jsonEncode(_msgs));
      _scrollToBottom();
    }
  }

  Future<String> _getGroqResponse(String prompt) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    try {
      final res = await http.post(url,
          headers: {
            'Authorization': 'Bearer $_groqKey',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({
            "model": "llama-3.1-8b-instant",
            "messages": [
              {
                "role": "system",
                "content": "You are Natroff Core, built by Ca1ik. You are the AI assistant of Natroff AIO app. "
                    "The current UI language is ${widget.currentLang.toUpperCase()}. "
                    "IMPORTANT: Always reply in the same language the user uses to speak to you."
              },
              {"role": "user", "content": prompt}
            ]
          }));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes))['choices'][0]['message']
            ['content'];
      }
      return widget.currentLang == "tr" ? "Sistem meşgul." : "System busy.";
    } catch (e) {
      return "Error: $e";
    }
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleGlobalKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isOpen)
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 380,
                  height: 580,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0E).withOpacity(0.65),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.05))),
                  child: Stack(
                    children: [
                      Positioned.fill(
                          child: AnimatedBuilder(
                              animation: _starController,
                              builder: (context, _) => CustomPaint(
                                  painter:
                                      StarPainter(_starController.value)))),
                      Column(children: [
                        Container(
                            padding: const EdgeInsets.all(20),
                            child: Row(children: [
                              const Icon(Icons.hub_rounded,
                                  color: Colors.cyanAccent, size: 20),
                              const SizedBox(width: 10),
                              Text("NATROFF CORE",
                                  style: GoogleFonts.orbitron(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2)),
                              const Spacer(),
                              IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white38),
                                  onPressed: () =>
                                      setState(() => _isOpen = false)),
                            ])),
                        Expanded(
                            child: ListView.builder(
                                controller: _scroll,
                                padding: const EdgeInsets.all(20),
                                itemCount: _msgs.length,
                                itemBuilder: (context, index) {
                                  final m = _msgs[index];
                                  return Align(
                                      alignment: m['isUser']
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 6),
                                          padding: const EdgeInsets.all(15),
                                          decoration: BoxDecoration(
                                              color: m['isUser']
                                                  ? Colors.cyanAccent
                                                      .withOpacity(0.15)
                                                  : Colors.white
                                                      .withOpacity(0.07),
                                              borderRadius:
                                                  BorderRadius.circular(18)),
                                          child: Text(m['text'],
                                              style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  height: 1.5))));
                                })),
                        if (_loading)
                          const LinearProgressIndicator(
                              backgroundColor: Colors.transparent,
                              color: Colors.cyanAccent),
                        Padding(
                            padding: const EdgeInsets.all(20),
                            child: TextField(
                                controller: _c,
                                focusNode: _focusNode,
                                onSubmitted: (v) => _processCommand(v),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                    hintText: widget.currentLang == "tr"
                                        ? "Komut ver..."
                                        : "Type a command...",
                                    hintStyle: const TextStyle(
                                        color: Colors.white24, fontSize: 12),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.05),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: BorderSide.none),
                                    suffixIcon: IconButton(
                                        icon: const Icon(Icons.send_rounded,
                                            color: Colors.cyanAccent),
                                        onPressed: () =>
                                            _processCommand(_c.text))))),
                      ])
                    ],
                  ),
                ),
              ),
            ),
          MouseRegion(
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            child: GestureDetector(
              onTap: () {
                setState(() => _isOpen = !_isOpen);
                if (_isOpen) _focusNode.requestFocus();
              },
              child: AnimatedScale(
                scale: _isHovering ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 250),
                child: AnimatedBuilder(
                    animation: _rgbController,
                    builder: (context, child) {
                      return Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                  colors: const [
                                    Colors.cyanAccent,
                                    Colors.purpleAccent,
                                    Colors.blueAccent,
                                    Colors.cyanAccent
                                  ],
                                  transform: GradientRotation(
                                      _rgbController.value * 2 * math.pi)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.3),
                                    blurRadius: 15)
                              ]),
                          padding: const EdgeInsets.all(4),
                          child: Container(
                              decoration: const BoxDecoration(
                                  color: Color(0xFF0A0A0E),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.smart_toy_rounded,
                                  color: Colors.white, size: 38)));
                    }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// StarPainter sınıfı aynı kalıyor...
class StarPainter extends CustomPainter {
  final double progress;
  StarPainter(this.progress);
  @override
  void paint(Canvas canvas, ui.Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.12);
    final random = math.Random(123);
    for (int i = 0; i < 70; i++) {
      double x = random.nextDouble() * size.width;
      double y =
          (random.nextDouble() * size.height + (progress * size.height)) %
              size.height;
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 1.3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarPainter oldDelegate) => true;
}
