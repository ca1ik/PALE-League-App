import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

class PaleWebView extends StatefulWidget {
  final String url;
  const PaleWebView({super.key, required this.url});

  @override
  State<PaleWebView> createState() => _PaleWebViewState();
}

class _PaleWebViewState extends State<PaleWebView> {
  final _controller = WebviewController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    initWebview();
  }

  Future<void> initWebview() async {
    try {
      await _controller.initialize();
      await _controller.loadUrl(widget.url);
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint("WebView Hatası: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xFF101014),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: _isInitialized
              ? Webview(_controller)
              : const Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent)),
        ),
      ),
    );
  }
}
