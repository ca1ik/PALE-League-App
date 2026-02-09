import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomBrowserModule extends StatefulWidget {
  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;

  const CustomBrowserModule(
      {super.key, this.isFullScreen = false, required this.onToggleFullScreen});

  @override
  State<CustomBrowserModule> createState() => _CustomBrowserModuleState();
}

class _CustomBrowserModuleState extends State<CustomBrowserModule> {
  final _controller = WebviewController();
  final _textController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initWebview();
  }

  // --- STABİLİTE GÜNCELLEMESİ ---
  // didUpdateWidget ile yeniden çizme zorlamıyoruz, main.dart'taki yapı
  // webview'ı hayatta tutuyor. Sadece bildirim ve Javascript tetikliyoruz.
  @override
  void didUpdateWidget(CustomBrowserModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFullScreen != oldWidget.isFullScreen) {
      // Ekran boyutu değişti, webview'a haber verelim (isteğe bağlı)
      if (_isInitialized) {
        _controller.executeScript("window.dispatchEvent(new Event('resize'));");
      }
    }
  }

  Future<void> _initWebview() async {
    try {
      await _controller.initialize();
      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);

      // Web'den gelen mesajları dinle (F11 için)
      _controller.webMessage.listen((event) {
        if (event == 'toggle_fullscreen') {
          widget.onToggleFullScreen();
        }
      });

      _controller.loadingState.listen((state) {
        if (state == LoadingState.navigationCompleted) {
          _injectHaxballHacks();
          _injectKeyListener();
        }
      });

      await _controller.loadUrl('https://www.haxball.com');
      _textController.text = 'https://www.haxball.com';

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint("Webview Başlatma Hatası: $e");
    }
  }

  // F11 Tuşunu Dinleyen JS Kodu (Tarayıcı içindeyken)
  void _injectKeyListener() {
    const script = '''
      window.addEventListener('keydown', function(e) {
        if (e.key === 'F11') {
          e.preventDefault(); // Tarayıcının varsayılan tam ekranını engelle
          e.stopPropagation();
          window.chrome.webview.postMessage('toggle_fullscreen'); // Flutter'a sinyal yolla
        }
      });
    ''';
    _controller.executeScript(script);
  }

  // Siyah Barı Silen Javascript Kodu
  void _injectHaxballHacks() {
    const script = '''
      function removeHeader() {
        var headers = document.getElementsByClassName('header');
        if(headers.length > 0) { 
          headers[0].style.display = 'none'; 
        }
        var ads = document.getElementsByClassName('adsbygoogle');
        for(var i=0; i<ads.length; i++) { 
          ads[i].style.display='none'; 
        }
        // Oyunu tam ortaya odakla
        var game = document.getElementById('roomlink');
        if(game) game.focus();
      }
      // Garanti olsun diye birkaç kez çalıştır
      removeHeader();
      setTimeout(removeHeader, 500);
      setTimeout(removeHeader, 1500);
      setTimeout(removeHeader, 3000);
    ''';
    _controller.executeScript(script);
  }

  void _loadUrl() {
    String url = _textController.text;
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    _controller.loadUrl(url);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // ÜST BAR (Sadece Tam Ekran DEĞİLSE göster)
          if (!widget.isFullScreen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: const Color(0xFF1E1E24),
              child: Row(
                children: [
                  IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () {
                        _controller.reload();
                      }),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.black54,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none),
                          hintText: "URL Girin...",
                          hintStyle: const TextStyle(color: Colors.white30),
                          prefixIcon:
                              const Icon(Icons.link, color: Colors.cyanAccent)),
                      onSubmitted: (_) => _loadUrl(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _loadUrl,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent),
                    child: const Text("GİT",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),

          // TARAYICI ALANI
          Expanded(
            child: _isInitialized
                ? Webview(_controller)
                : const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }
}
