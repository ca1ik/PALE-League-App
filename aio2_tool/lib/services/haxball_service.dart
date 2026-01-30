import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:win32/win32.dart';

class HaxBallService {
  static const String _windowTitle = "HaxBall";

  static Future<void> launchAndEmbed(
      int parentHwnd, int x, int y, int width, int height) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dirPath = '${directory.path}/PaleHaxGame';
      final haxDir = Directory(dirPath);

      if (!await haxDir.exists()) await haxDir.create(recursive: true);

      final filePath = '$dirPath/HaxBall.exe';
      final file = File(filePath);

      if (!await file.exists()) {
        final ByteData data = await rootBundle.load('assets/HaxBall.exe');
        final List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await file.writeAsBytes(bytes);
      }

      await Process.start(filePath, [],
          mode: ProcessStartMode.detached, workingDirectory: dirPath);

      int haxHwnd = 0;
      int attempts = 0;

      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        attempts++;
        final lpWindowName = _windowTitle.toNativeUtf16();
        haxHwnd = FindWindow(nullptr, lpWindowName);
        free(lpWindowName);

        if (haxHwnd != 0) {
          timer.cancel();
          _embedWindow(haxHwnd, parentHwnd, x, y, width, height);
        } else if (attempts > 50) {
          timer.cancel();
          print("HaxBall penceresi bulunamadı.");
        }
      });
    } catch (e) {
      print("Hata: $e");
    }
  }

  static void _embedWindow(int child, int parent, int x, int y, int w, int h) {
    int style = GetWindowLongPtr(child, GWL_STYLE);
    style &= ~(WS_CAPTION |
        WS_THICKFRAME |
        WS_MINIMIZEBOX |
        WS_MAXIMIZEBOX |
        WS_SYSMENU |
        WS_POPUP);
    style |= WS_CHILD;
    SetWindowLongPtr(child, GWL_STYLE, style);
    SetParent(child, parent);
    MoveWindow(child, x, y, w, h, TRUE);
    ShowWindow(child, SW_SHOW);
    SetFocus(child);
  }
}
