import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:http/http.dart' as http;
import '../providers/language_provider.dart';

class TurkeyMapModule extends StatefulWidget {
  const TurkeyMapModule({super.key});

  @override
  _TurkeyMapModuleState createState() => _TurkeyMapModuleState();
}

class _TurkeyMapModuleState extends State<TurkeyMapModule> {
  late MapShapeSource _shapeSource;
  int _selectedIndex = -1;

  // Seçilen şehir verileri
  Map<String, dynamic>? _weatherData;
  bool _isLoading = false;

  // 81 İl İçin Koordinat Listesi (Enlem, Boylam)
  final Map<String, List<double>> _cityCoordinates = {
    'Adana': [37.0000, 35.3213],
    'Adiyaman': [37.7648, 38.2786],
    'Afyonkarahisar': [38.7507, 30.5567],
    'Agri': [39.7191, 43.0503],
    'Aksaray': [38.3687, 34.0370],
    'Amasya': [40.6499, 35.8353],
    'Ankara': [39.9334, 32.8597],
    'Antalya': [36.8969, 30.7133],
    'Ardahan': [41.1105, 42.7022],
    'Artvin': [41.1828, 41.8183],
    'Aydin': [37.8444, 27.8458],
    'Balikesir': [39.6484, 27.8826],
    'Bartin': [41.6344, 32.3375],
    'Batman': [37.8812, 41.1291],
    'Bayburt': [40.2552, 40.2249],
    'Bilecik': [40.1451, 29.9798],
    'Bingol': [38.8847, 40.4939],
    'Bitlis': [38.4006, 42.1095],
    'Bolu': [40.7350, 31.6061],
    'Burdur': [37.7204, 30.2908],
    'Bursa': [40.1885, 29.0610],
    'Canakkale': [40.1553, 26.4142],
    'Cankiri': [40.6013, 33.6134],
    'Corum': [40.5506, 34.9556],
    'Denizli': [37.7765, 29.0864],
    'Diyarbakir': [37.9144, 40.2306],
    'Duzce': [40.8438, 31.1565],
    'Edirne': [41.6772, 26.5559],
    'Elazig': [38.6810, 39.2264],
    'Erzincan': [39.7500, 39.5000],
    'Erzurum': [39.9000, 41.2700],
    'Eskisehir': [39.7767, 30.5206],
    'Gaziantep': [37.0662, 37.3833],
    'Giresun': [40.9128, 38.3895],
    'Gumushane': [40.4600, 39.4700],
    'Hakkari': [37.5833, 43.7333],
    'Hatay': [36.4018, 36.3498],
    'Igdir': [39.9167, 44.0333],
    'Isparta': [37.7648, 30.5566],
    'Istanbul': [41.0082, 28.9784],
    'Izmir': [38.4192, 27.1287],
    'Kahramanmaras': [37.5858, 36.9371],
    'Karabuk': [41.2061, 32.6204],
    'Karaman': [37.1759, 33.2287],
    'Kars': [40.6172, 43.0974],
    'Kastamonu': [41.3887, 33.7827],
    'Kayseri': [38.7312, 35.4787],
    'Kilis': [36.7184, 37.1212],
    'Kirikkale': [39.8468, 33.5153],
    'Kirklareli': [41.7333, 27.2167],
    'Kirsehir': [39.1425, 34.1709],
    'Kocaeli': [40.8533, 29.8815],
    'Konya': [37.8667, 32.4833],
    'Kutahya': [39.4167, 29.9833],
    'Malatya': [38.3552, 38.3095],
    'Manisa': [38.6191, 27.4289],
    'Mardin': [37.3212, 40.7245],
    'Mersin': [36.8000, 34.6333],
    'Mugla': [37.2153, 28.3636],
    'Mus': [38.9462, 41.7539],
    'Nevsehir': [38.6939, 34.6857],
    'Nigde': [37.9667, 34.6833],
    'Ordu': [40.9839, 37.8764],
    'Osmaniye': [37.0742, 36.2478],
    'Rize': [41.0201, 40.5234],
    'Sakarya': [40.7569, 30.3783],
    'Samsun': [41.2928, 36.3313],
    'Sanliurfa': [37.1591, 38.7969],
    'Siirt': [37.9333, 41.9500],
    'Sinop': [42.0231, 35.1531],
    'Sivas': [39.7477, 37.0179],
    'Sirnak': [37.4187, 42.4918],
    'Tekirdag': [40.9833, 27.5167],
    'Tokat': [40.3167, 36.5500],
    'Trabzon': [41.0015, 39.7178],
    'Tunceli': [39.1079, 39.5401],
    'Usak': [38.6823, 29.4082],
    'Van': [38.4891, 43.4089],
    'Yalova': [40.6500, 29.2667],
    'Yozgat': [39.8181, 34.8147],
    'Zonguldak': [41.4564, 31.7987],
  };

  @override
  void initState() {
    _shapeSource = MapShapeSource.asset(
      'assets/turkey.json',
      shapeDataField: 'name',
      dataCount: _cityCoordinates.length,
      primaryValueMapper: (int index) => _cityCoordinates.keys.elementAt(index),
    );
    super.initState();
  }

  // --- API İSTEĞİ (Open-Meteo) ---
  Future<void> _fetchWeather(String city) async {
    setState(() {
      _isLoading = true;
      _weatherData = null;
    });

    try {
      // Şehrin koordinatlarını al
      // JSON'daki isim (örn: "Afyon") ile Listemizdeki isim (örn: "Afyonkarahisar") eşleşmezse default Ankara
      List<double> coords = _cityCoordinates[city] ??
          _cityCoordinates.entries
              .firstWhere((e) => e.key.contains(city) || city.contains(e.key),
                  orElse: () => MapEntry("Ankara", [39.93, 32.85]))
              .value;

      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=${coords[0]}&longitude=${coords[1]}&current_weather=true&daily=weathercode,temperature_2m_max,temperature_2m_min&timezone=auto');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _weatherData = data;
          _isLoading = false;
        });

        // Veri geldikten sonra BottomSheet'i aç
        if (mounted) {
          _showWeatherSheet(context, city);
        }
      } else {
        throw Exception("API Hatası");
      }
    } catch (e) {
      debugPrint("Hava durumu hatası: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24).withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, color: Colors.blueAccent),
                const SizedBox(width: 10),
                Text(
                  lang.translate('weather_title'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_isLoading) ...[
                  const Spacer(),
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                ]
              ],
            ),
          ),
          Expanded(
            child: SfMaps(
              layers: [
                MapShapeLayer(
                  source: _shapeSource,
                  showDataLabels: true,
                  selectedIndex: _selectedIndex,
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  strokeColor: isDark ? Colors.black54 : Colors.white,
                  strokeWidth: 0.5,
                  selectionSettings: const MapSelectionSettings(
                    color: Colors.blueAccent,
                    strokeColor: Colors.white,
                    strokeWidth: 2,
                  ),
                  dataLabelSettings: MapDataLabelSettings(
                    textStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onSelectionChanged: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                    // Tıklanan şehrin ismini al
                    String cityName = _cityCoordinates.keys.elementAt(index);
                    // API isteğini başlat
                    _fetchWeather(cityName);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              lang.translate('select_city'),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          )
        ],
      ),
    );
  }

  void _showWeatherSheet(BuildContext context, String city) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    // Veriler null ise veya yükleniyorsa gösterme
    if (_weatherData == null) return;

    final current = _weatherData!['current_weather'];
    final daily = _weatherData!['daily'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E24),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5)
          ],
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),

            // Şehir ve Sıcaklık
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(city.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5)),
                    Text(_getDate(0),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    _getWeatherIcon(current['weathercode'], size: 40),
                    const SizedBox(width: 10),
                    Text("${current['temperature']}°C",
                        style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 32,
                            fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),

            const Divider(color: Colors.white10, height: 30),

            // Bugün ve Yarın (API'den)
            // Daily dizisinde 0: Bugün, 1: Yarın
            _weatherRow(lang.translate('today'), daily['temperature_2m_max'][0],
                daily['temperature_2m_min'][0], daily['weathercode'][0]),
            _weatherRow(
                lang.translate('tomorrow'),
                daily['temperature_2m_max'][1],
                daily['temperature_2m_min'][1],
                daily['weathercode'][1]),

            const SizedBox(height: 15),
            Text(lang.translate('weekly'),
                style: const TextStyle(
                    color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // Haftalık Liste (API'den)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(5, (index) {
                  // Bugün ve yarını geçip sonraki 5 günü gösterelim (index + 2)
                  int i = index + 2;
                  if (i >= daily['time'].length) return const SizedBox();

                  return _weeklySmallCard(_getDate(i, short: true),
                      daily['temperature_2m_max'][i], daily['weathercode'][i]);
                }),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _weatherRow(String day, double max, double min, int code) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          _getWeatherIcon(code, size: 24),
          const SizedBox(width: 20),
          Text(day, style: const TextStyle(color: Colors.white, fontSize: 16)),
          const Spacer(),
          Text("${max.round()}° / ${min.round()}°",
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _weeklySmallCard(String day, double temp, int code) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Text(day, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          _getWeatherIcon(code, size: 24),
          const SizedBox(height: 8),
          Text("${temp.round()}°",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- WMO Kodlarına Göre İkon ve Renk ---
  Widget _getWeatherIcon(int code, {double size = 30}) {
    IconData icon;
    Color color;

    if (code == 0) {
      // Açık
      icon = Icons.wb_sunny;
      color = Colors.orangeAccent;
    } else if (code >= 1 && code <= 3) {
      // Bulutlu
      icon = Icons.cloud;
      color = Colors.blueGrey;
    } else if (code >= 45 && code <= 48) {
      // Sisli
      icon = Icons.blur_on;
      color = Colors.grey;
    } else if (code >= 51 && code <= 67) {
      // Yağmurlu
      icon = Icons.water_drop;
      color = Colors.blueAccent;
    } else if (code >= 71 && code <= 77) {
      // Karlı
      icon = Icons.ac_unit;
      color = Colors.cyanAccent;
    } else if (code >= 95) {
      // Fırtına
      icon = Icons.flash_on;
      color = Colors.yellow;
    } else {
      icon = Icons.wb_cloudy;
      color = Colors.white;
    }

    return Icon(icon, color: color, size: size);
  }

  String _getDate(int daysFromNow, {bool short = false}) {
    final date = DateTime.now().add(Duration(days: daysFromNow));
    if (short) return "${date.day}/${date.month}";
    return "${date.day}.${date.month}.${date.year}";
  }
}
//edit time
