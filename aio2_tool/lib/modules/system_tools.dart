import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- DNS MODÜLÜ ---
class DnsModule extends StatefulWidget {
  const DnsModule({super.key});
  @override
  State<DnsModule> createState() => _DnsModuleState();
}

class _DnsModuleState extends State<DnsModule> {
  final _ctrl = TextEditingController(text: "8.8.8.8");

  Future<void> _set() async {
    try {
      // DNS ayarlarını netsh üzerinden uygular
      await Process.run('netsh', [
        'interface',
        'ip',
        'set',
        'dns',
        'name="Wi-Fi"',
        'source=static',
        'addr=${_ctrl.text}'
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("DNS Değiştirildi!"),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Hata: Yetki yetersiz veya bağlantı bulunamadı."),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.dns, size: 60, color: Colors.indigoAccent),
        const SizedBox(height: 20),
        Text(
          "DNS Ayarları",
          style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 300,
          child: TextField(
            controller: _ctrl,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.black12,
              labelText: "DNS Adresi",
              labelStyle:
                  TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _set,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigoAccent,
              foregroundColor: Colors.white),
          child: const Text("Uygula"),
        )
      ],
    );
  }
}

// --- GÜÇ MODÜLÜ ---
class PowerModule extends StatelessWidget {
  const PowerModule({super.key});

  Future<void> _p(String g, BuildContext context) async {
    try {
      await Process.run('powercfg', ['/setactive', g]);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Güç Planı Değiştirildi!"),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      debugPrint("Güç planı hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        const Icon(Icons.bolt, size: 60, color: Colors.amber),
        const SizedBox(height: 20),
        Text(
          "Güç Yönetimi",
          style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87),
        ),
        const SizedBox(height: 30),
        ListTile(
          title: Text("Yüksek Performans",
              style: GoogleFonts.poppins(
                  color: isDark ? Colors.white : Colors.black87)),
          leading: const Icon(Icons.bolt, color: Colors.orange),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          tileColor: isDark ? Colors.white10 : Colors.black12,
          onTap: () => _p("8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c", context),
        ),
        const SizedBox(height: 10),
        ListTile(
          title: Text("Dengeli",
              style: GoogleFonts.poppins(
                  color: isDark ? Colors.white : Colors.black87)),
          leading: const Icon(Icons.battery_std, color: Colors.blue),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          tileColor: isDark ? Colors.white10 : Colors.black12,
          onTap: () => _p("381b4222-f694-41f0-9685-ff5bb260df2e", context),
        ),
      ],
    );
  }
}

// --- GÜVENLİK MODÜLÜ ---
class SecurityModule extends StatelessWidget {
  const SecurityModule({super.key});

  // ÇÖKMEYİ ÖNLEYEN GÜVENLİ ÇALIŞTIRMA FONKSİYONU
  Future<void> _openTaskManager(BuildContext context) async {
    try {
      // Process.run yerine Process.start ve detached mod kullanıldı
      await Process.start('taskmgr.exe', [], mode: ProcessStartMode.detached);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Görev Yöneticisi başlatılamadı: $e"),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.security, size: 60, color: Colors.redAccent),
        const SizedBox(height: 20),
        Text(
          "Güvenlik Merkezi",
          style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: () =>
              _openTaskManager(context), // Güvenli fonksiyon çağrıldı
          icon: const Icon(Icons.table_chart),
          label: const Text("Görev Yöneticisi"),
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
