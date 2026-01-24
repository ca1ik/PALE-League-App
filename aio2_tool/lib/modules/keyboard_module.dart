import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KeyboardModule extends StatefulWidget {
  const KeyboardModule({super.key});

  @override
  State<KeyboardModule> createState() => _KeyboardModuleState();
}

class _KeyboardModuleState extends State<KeyboardModule> {
  bool _filterKeys = false;
  double _responseRate = 0; // ms cinsinden

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Klavye Optimizasyonu",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 20),

        // Örnek bir ayar kartı
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: Text("Filter Keys (Filtre Tuşlarını) Kapat",
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black)),
                subtitle: Text(
                    "Gecikmeyi önlemek için filtre tuşlarını devre dışı bırakır.",
                    style: TextStyle(
                        color: isDark ? Colors.grey : Colors.black54,
                        fontSize: 12)),
                value: _filterKeys,
                onChanged: (val) {
                  setState(() => _filterKeys = val);
                },
              ),
              const Divider(),
              ListTile(
                title: Text("Klavye Tepki Süresi: ${_responseRate.toInt()} ms",
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black)),
                subtitle: Slider(
                  value: _responseRate,
                  min: 0,
                  max: 50,
                  divisions: 10,
                  label: "${_responseRate.toInt()} ms",
                  onChanged: (val) {
                    setState(() => _responseRate = val);
                  },
                ),
              ),
            ],
          ),
        ),

        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.bolt),
            label: const Text("Ayarları Uygula"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Klavye ayarları kayıt defterine işlendi!")),
              );
            },
          ),
        )
      ],
    );
  }
}
