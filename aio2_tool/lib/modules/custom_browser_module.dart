import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CustomBrowserModule extends StatefulWidget {
  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;

  const CustomBrowserModule(
      {super.key, this.isFullScreen = false, required this.onToggleFullScreen});

  @override
  State<CustomBrowserModule> createState() => _CustomBrowserModuleState();
}

class _CustomBrowserModuleState extends State<CustomBrowserModule> {
  late final WebViewController _controller;
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _textController.text = 'https://www.haxball.com';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
            _injectHaxballHacks();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("Webview Hatası: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.haxball.com'));
  }

  // Siyah Barı Silen Javascript Kodu
  void _injectHaxballHacks() {
    // F11 ve KeyListener mobilde gerekli değil veya farklı çalışır.
    // Sadece reklam/header temizliği yapıyoruz.
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
      }
      // Garanti olsun diye birkaç kez çalıştır
      removeHeader();
      setTimeout(removeHeader, 1000);
    ''';
    _controller.runJavaScript(script);
  }

  void _loadUrl() {
    String url = _textController.text;
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    _controller.loadRequest(Uri.parse(url));
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
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(
                      child:
                          CircularProgressIndicator(color: Colors.cyanAccent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
