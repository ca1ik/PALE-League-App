import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaleWebView extends StatefulWidget {
  final String url;
  const PaleWebView({super.key, required this.url});

  @override
  State<PaleWebView> createState() => _PaleWebViewState();
}

class _PaleWebViewState extends State<PaleWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            // Hata yönetimi
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white24),
          ),
          margin: const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: WebViewWidget(controller: _controller),
          ),
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          ),
      ],
    );
  }
}
