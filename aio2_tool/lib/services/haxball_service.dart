import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:win32/win32.dart';

class HaxBallService {
  // HaxBall pencere başlığı (Exe açıldığında sol üstte yazar)
  static const String _windowTitle = "HaxBall";

  // Oyunu başlat ve GÖM
  static Future<void> launchAndEmbed(
      int parentHwnd, int x, int y, int width, int height) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dirPath = '${directory.path}/PaleHaxGame';
      final haxDir = Directory(dirPath);

      if (!await haxDir.exists()) await haxDir.create(recursive: true);

      final filePath = '$dirPath/HaxBall.exe';
      final file = File(filePath);

      // Dosya yoksa assets'ten çıkar
      if (!await file.exists()) {
        final ByteData data = await rootBundle.load('assets/HaxBall.exe');
        final List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await file.writeAsBytes(bytes);
      }

      // 1. Başlat
      await Process.start(filePath, [],
          mode: ProcessStartMode.detached, workingDirectory: dirPath);

      // 2. Pencereyi Bul ve Göm (Biraz beklememiz gerekebilir)
      int haxHwnd = 0;
      int attempts = 0;

      Timer.periodic(const Duration(milliseconds: 200), (timer) {
        attempts++;
        final lpWindowName = _windowTitle.toNativeUtf16();
        haxHwnd = FindWindow(nullptr, lpWindowName);
        free(lpWindowName);

        if (haxHwnd != 0) {
          timer.cancel();
          _embedWindow(haxHwnd, parentHwnd, x, y, width, height);
        } else if (attempts > 50) {
          // 10 saniye sonra vazgeç
          timer.cancel();
          print("HaxBall penceresi bulunamadı.");
        }
      });
    } catch (e) {
      print("HaxBall Servis Hatası: $e");
    }
  }

  static void _embedWindow(int child, int parent, int x, int y, int w, int h) {
    // Stilleri temizle (Kenarlık, başlık çubuğu vs. kaldır)
    int style = GetWindowLongPtr(child, GWL_STYLE);
    style &= ~(WS_CAPTION |
        WS_THICKFRAME |
        WS_MINIMIZEBOX |
        WS_MAXIMIZEBOX |
        WS_SYSMENU |
        WS_POPUP);
    style |= WS_CHILD; // Çocuğu yap

    SetWindowLongPtr(child, GWL_STYLE, style);
    SetParent(child, parent);

    // Konumlandır
    MoveWindow(child, x, y, w, h, TRUE);

    // Göster ve Odaklan
    ShowWindow(child, SW_SHOW);
    SetFocus(child);
  }
}
