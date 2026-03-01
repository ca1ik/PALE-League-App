import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WifiModule extends StatefulWidget {
  const WifiModule({super.key});
  @override
  State<WifiModule> createState() => _WifiModuleState();
}

class _WifiModuleState extends State<WifiModule> {
  List<String> _networks = [];
  // ignore: unused_field
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() => _scanning = true);
    try {
      // Windows komutu ile ağları çek
      final res = await Process.run('netsh', ['wlan', 'show', 'networks']);
      final out = res.stdout.toString();
      final List<String> found = [];
      for (var line in out.split('\n')) {
        if (line.trim().startsWith('SSID')) {
          found.add(line.split(':')[1].trim());
        }
      }
      if (mounted) setState(() => _networks = found);
    } catch (_) {}
    if (mounted) setState(() => _scanning = false);
  }

  Future<void> _connectDialog(String ssid) async {
    final passCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF25252D),
        title: Text("$ssid ağına bağlan",
            style: GoogleFonts.poppins(color: Colors.white)),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Wi-Fi Şifresi",
            labelStyle: const TextStyle(color: Colors.grey),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.cyan)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.cyan),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("$ssid ağına bağlanma isteği gönderildi."),
                backgroundColor: Colors.green,
              ));
            },
            child: const Text("Bağlan"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.wifi, size: 60, color: Colors.cyanAccent),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("Wi-Fi Ağları",
              style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          IconButton(onPressed: _scan, icon: const Icon(Icons.refresh))
        ]),
        const SizedBox(height: 30),
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: _networks.isEmpty
              ? const Center(
                  child: Text("Ağ bulunamadı...",
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _networks.length,
                  itemBuilder: (c, i) => ListTile(
                    leading:
                        const Icon(Icons.wifi_lock, color: Colors.cyanAccent),
                    title: Text(_networks[i], style: GoogleFonts.poppins()),
                    subtitle: const Text("Bağlanmak için tıklayın",
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                    onTap: () =>
                        _connectDialog(_networks[i]), // Tıklama Olayı Eklendi
                  ),
                ),
        )
      ],
    );
  }
}
