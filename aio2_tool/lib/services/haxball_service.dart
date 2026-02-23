import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class HaxBallService {
  // Mobilde EXE gömme işlemi yapılamaz. Bunun yerine tarayıcıda açıyoruz.
  static Future<void> launchAndEmbed(
      int parentHwnd, int x, int y, int width, int height) async {
    try {
      final Uri url = Uri.parse("https://www.haxball.com");
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      print("HaxBall Servis Hatası: $e");
    }
  }
}
