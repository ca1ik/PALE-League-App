import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_windows/webview_windows.dart';

class WebviewModule extends StatefulWidget {
  final String url;
  const WebviewModule({super.key, required this.url});
  @override
  State<WebviewModule> createState() => _WebviewModuleState();
}

class _WebviewModuleState extends State<WebviewModule> {
  final _ctrl = WebviewController();
  bool _ready = false;
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _ctrl.initialize();
      await _ctrl.loadUrl(widget.url);
      if (mounted) setState(() => _ready = true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return _ready
        ? Webview(_ctrl)
        : const Center(child: CircularProgressIndicator());
  }
}

class HistoryModule extends StatelessWidget {
  const HistoryModule({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text("Henüz kayıt bulunamadı.",
            style: GoogleFonts.poppins(color: Colors.grey)));
  }
}
