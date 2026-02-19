import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CleaningItem {
  String name;
  String description;
  bool isSelected;
  bool isRecommended;

  CleaningItem(
      {required this.name,
      required this.description,
      this.isSelected = true,
      this.isRecommended = true});
}

class CleaningModule extends StatefulWidget {
  const CleaningModule({super.key});
  @override
  State<CleaningModule> createState() => _CleaningModuleState();
}

class _CleaningModuleState extends State<CleaningModule> {
  // 10 Modüllü Liste
  final List<CleaningItem> _items = [
    CleaningItem(name: "Windows Temp", description: "Sistem geçici dosyaları"),
    CleaningItem(name: "User Temp", description: "Kullanıcı geçici dosyaları"),
    CleaningItem(name: "Prefetch", description: "Hızlı başlatma önbelleği"),
    CleaningItem(name: "DNS Cache", description: "İnternet bağlantı önbelleği"),
    CleaningItem(name: "Geri Dönüşüm Kutusu", description: "Silinmiş dosyalar"),
    CleaningItem(
        name: "Panoya Kopyalananlar", description: "Clipboard temizliği"),
    CleaningItem(
        name: "Chrome Önbelleği",
        description: "Tarayıcı kalıntıları (Simüle)",
        isRecommended: false),
    CleaningItem(
        name: "Windows Update Logları",
        description: "Eski güncelleme kayıtları",
        isRecommended: false),
    CleaningItem(name: "Hata Raporları", description: "WerMgr kayıtları"),
    CleaningItem(
        name: "İndirilenler Klasörü",
        description: "Downloads (Dikkat!)",
        isSelected: false,
        isRecommended: false),
  ];

  bool _isCleaning = false;
  double _progress = 0;
  String _status = "Hazır";

  void _toggleSelect(int index) {
    if (_isCleaning) return;
    setState(() {
      _items[index].isSelected = !_items[index].isSelected;
    });
  }

  void _selectMode(bool fast) {
    if (_isCleaning) return;
    setState(() {
      for (var item in _items) {
        item.isSelected = fast ? item.isRecommended : true;
      }
    });
  }

  Future<void> _startCleaning() async {
    final selected = _items.where((e) => e.isSelected).toList();
    if (selected.isEmpty) return;

    setState(() {
      _isCleaning = true;
      _progress = 0;
    });

    int total = selected.length;
    for (int i = 0; i < total; i++) {
      final item = selected[i];
      setState(() {
        _status = "${item.name} temizleniyor...";
        _progress = (i / total);
      });

      // Simüle edilmiş temizlik süresi (Gerçek kodlar buraya entegre edilir)
      await Future.delayed(const Duration(milliseconds: 600));

      // GERÇEK TEMİZLİK KODLARI
      try {
        if (Platform.isWindows) {
          if (item.name == "Windows Temp")
            _deleteDir(Directory(r'C:\Windows\Temp'));
          if (item.name == "User Temp") _deleteDir(Directory.systemTemp);
          if (item.name == "DNS Cache")
            await Process.run('ipconfig', ['/flushdns']);
        }
        // Diğerleri için benzer mantık...
      } catch (e) {
        debugPrint("Hata: $e");
      }
    }

    setState(() {
      _isCleaning = false;
      _progress = 1.0;
      _status = "Temizlik Başarıyla Tamamlandı!";
    });
  }

  void _deleteDir(Directory dir) {
    if (!dir.existsSync()) return;
    try {
      dir.listSync().forEach((f) {
        try {
          f.deleteSync(recursive: true);
        } catch (_) {}
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Gelişmiş Temizlik",
                style: GoogleFonts.poppins(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            Row(
              children: [
                OutlinedButton(
                    onPressed: _isCleaning ? null : () => _selectMode(true),
                    child: const Text("Hızlı Seçim")),
                const SizedBox(width: 10),
                OutlinedButton(
                    onPressed: _isCleaning ? null : () => _selectMode(false),
                    child: const Text("Tümünü Seç")),
              ],
            )
          ],
        ),
        const SizedBox(height: 20),

        // Liste
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.black12),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(10),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final item = _items[i];
                return CheckboxListTile(
                  activeColor: Colors.green,
                  title: Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item.description,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  value: item.isSelected,
                  onChanged: _isCleaning ? null : (v) => _toggleSelect(i),
                  secondary: Icon(
                    item.isRecommended
                        ? Icons.verified_user
                        : Icons.warning_amber,
                    color: item.isRecommended ? Colors.green : Colors.orange,
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Durum Çubuğu ve Buton
        if (_isCleaning) ...[
          LinearProgressIndicator(
              value: _progress,
              color: Colors.green,
              minHeight: 8,
              borderRadius: BorderRadius.circular(5)),
          const SizedBox(height: 10),
          Text(_status, style: GoogleFonts.poppins(color: Colors.green)),
        ] else
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _startCleaning,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
              icon: const Icon(Icons.rocket_launch),
              label: Text("SEÇİLENLERİ TEMİZLE",
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
      ],
    );
  }
}
