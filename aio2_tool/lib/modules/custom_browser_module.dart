import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomBrowserModule extends StatefulWidget {
  final bool isFullScreen; // Main.dart'tan gelen bilgi
  const CustomBrowserModule({super.key, this.isFullScreen = false});

  @override
  State<CustomBrowserModule> createState() => _CustomBrowserModuleState();
}

class _CustomBrowserModuleState extends State<CustomBrowserModule> {
  final _controller = WebviewController();
  final _textController = TextEditingController();
  bool _isInitialized = false;
  Timer? _hackTimer;

  @override
  void initState() {
    super.initState();
    _initWebview();
  }

  // Tam ekran değişikliğinde WebView'i zorla yenile (Donmayı önler)
  @override
  void didUpdateWidget(CustomBrowserModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFullScreen != oldWidget.isFullScreen) {
      // Boyut değişimini algılaması için kısa bir gecikme
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _initWebview() async {
    try {
      await _controller.initialize();
      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);

      // Haxball yüklendiğinde üst barı silen kod
      _controller.loadingState.listen((state) {
        if (state == LoadingState.navigationCompleted) {
          _injectHaxballHacks();
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

  // Siyah Barı Silen Javascript Kodu
  void _injectHaxballHacks() {
    // Haxball'ın üstündeki 'header' class'lı div'i siler.
    const script = '''
      function removeHeader() {
        var headers = document.getElementsByClassName('header');
        if(headers.length > 0) {
          headers[0].style.display = 'none';
        }
        // Reklamları da temizle
        var ads = document.getElementsByClassName('adsbygoogle');
        for(var i=0; i<ads.length; i++) { ads[i].style.display='none'; }
      }
      // Yüklenme gecikmesi ihtimaline karşı tekrarla
      removeHeader();
      setInterval(removeHeader, 1000);
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
    _hackTimer?.cancel();
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
                        // Yenileyince hack'i tekrar çalıştır
                        Future.delayed(
                            const Duration(seconds: 1), _injectHaxballHacks);
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
