import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PaleWebView extends StatelessWidget {
  final String url;
  const PaleWebView({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.public, size: 60, color: Colors.white54),
          const SizedBox(height: 20),
          Text(
            "Görüntülenen Sayfa:",
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 5),
          Text(
            url,
            style: const TextStyle(
                color: Colors.cyanAccent, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              final Uri uri = Uri.parse(url);
              if (!await launchUrl(uri)) {
                debugPrint('Could not launch $uri');
              }
            },
            icon: const Icon(Icons.open_in_browser),
            label: const Text("Tarayıcıda Aç"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
            ),
          )
        ],
      ),
    );
  }
}
