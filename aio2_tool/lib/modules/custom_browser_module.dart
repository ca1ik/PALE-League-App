import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:file_picker/file_picker.dart'; // Dosya seçimi için
import 'package:process_run/shell.dart'; // Çalıştırmak için

class CustomBrowserModule extends StatefulWidget {
  const CustomBrowserModule({super.key});

  @override
  State<CustomBrowserModule> createState() => _CustomBrowserModuleState();
}

class _CustomBrowserModuleState extends State<CustomBrowserModule> {
  String? _browserPath;
  final Box _box = Hive.box('natroff_memory');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _browserPath = _box.get('custom_browser_path');
  }

  Future<void> _pickBrowser() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe'],
      dialogTitle: "Tarayıcınızın .exe dosyasını seçin (Örn: chrome.exe)",
    );

    if (result != null) {
      String path = result.files.single.path!;
      setState(() {
        _browserPath = path;
      });
      _box.put('custom_browser_path', path);
    }
  }

  void _resetBrowser() {
    _box.delete('custom_browser_path');
    setState(() {
      _browserPath = null;
    });
  }

  Future<void> _launchBrowser() async {
    if (_browserPath == null) return;

    setState(() => _isLoading = true);

    // Haxball için Sınırsız FPS Argümanları
    var shell = Shell();
    // Tırnak içine alarak boşluklu dosya yollarını koruyoruz
    String cmd =
        '"$_browserPath" --disable-frame-rate-limit --disable-gpu-vsync --args --disable-features=UseSkiaRenderer';

    try {
      await shell.run(cmd);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Başlatma hatası: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
              color: const Color(0xFF101014).withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                    color: Colors.cyan.withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 5)
              ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.rocket_launch,
                  size: 80, color: Colors.cyanAccent),
              const SizedBox(height: 20),
              Text(
                "SINIRSIZ FPS BAŞLATICI",
                style: GoogleFonts.orbitron(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                "Seçtiğiniz tarayıcıyı V-Sync kapalı ve FPS kilidi olmadan başlatır.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 40),
              if (_browserPath == null) ...[
                ElevatedButton.icon(
                  onPressed: _pickBrowser,
                  icon: const Icon(Icons.folder_open),
                  label: const Text("TARAYICI SEÇ (.exe)"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 20),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                )
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _browserPath!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.amber),
                        tooltip: "Değiştir",
                        onPressed: _pickBrowser,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _launchBrowser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      shadowColor: Colors.greenAccent.withOpacity(0.5),
                      elevation: 10,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text(
                            "OYUNU BAŞLAT",
                            style: GoogleFonts.orbitron(
                                color: Colors.black,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _resetBrowser,
                  child: const Text("Sıfırla",
                      style: TextStyle(color: Colors.redAccent)),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
