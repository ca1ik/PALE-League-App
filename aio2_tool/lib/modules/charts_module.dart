import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

// --- MODLARIN TANIMI ---
enum ChartViewMode { list, graph, analysis }

// --- GETX CONTROLLER ---
class CryptoController extends GetxController {
  var cryptoList = [].obs;
  var isLoading = true.obs;
  var viewMode = ChartViewMode.list.obs; // Varsayılan mod: Liste
  Timer? _timer;

  @override
  void onInit() {
    fetchPrices();
    // 1 dakikada bir otomatik güncelleme
    _timer =
        Timer.periodic(const Duration(minutes: 1), (timer) => fetchPrices());
    super.onInit();
  }

  Future<void> fetchPrices() async {
    try {
      // En iyi 50 coini çeker
      final response = await http.get(Uri.parse(
          'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=50&page=1&sparkline=true'));
      if (response.statusCode == 200) {
        cryptoList.value = json.decode(response.body);
        isLoading.value = false;
      }
    } catch (e) {
      Get.snackbar("Borsa Hatası", "Veriler güncellenemedi.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.5));
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

// --- ANA MODÜL ---
class ChartsModule extends StatelessWidget {
  const ChartsModule({super.key});

  @override
  Widget build(BuildContext context) {
    final CryptoController controller = Get.put(CryptoController());
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- ÜST BAŞLIK VE MOD SEÇİCİ ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Borsa Terminali",
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            _buildModeSelector(controller, isDark),
          ],
        ),
        const SizedBox(height: 20),

        // --- ANA İÇERİK (DİNAMİK) ---
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
            }

            // Seçilen moda göre ekranı değiştirir
            switch (controller.viewMode.value) {
              case ChartViewMode.graph:
                return _buildGraphView(controller.cryptoList, isDark);
              case ChartViewMode.analysis:
                return _buildAnalysisView(controller.cryptoList, isDark);
              default:
                return _buildListView(controller.cryptoList, isDark);
            }
          }),
        ),
      ],
    );
  }

  // --- 1. MOD SEÇİCİ (3 BUTON) ---
  Widget _buildModeSelector(CryptoController controller, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _modeBtn(controller, ChartViewMode.list, Icons.format_list_bulleted),
          _modeBtn(controller, ChartViewMode.graph, Icons.bar_chart),
          _modeBtn(controller, ChartViewMode.analysis, Icons.grid_view),
        ],
      ),
    );
  }

  Widget _modeBtn(
      CryptoController controller, ChartViewMode mode, IconData icon) {
    return Obx(() {
      bool isSelected = controller.viewMode.value == mode;
      return GestureDetector(
        onTap: () => controller.viewMode.value = mode,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 20, color: isSelected ? Colors.white : Colors.grey),
        ),
      );
    });
  }

  // --- 2. LİSTE GÖRÜNÜMÜ (TOP 50) ---
  Widget _buildListView(List cryptoList, bool isDark) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: cryptoList.length,
      itemBuilder: (context, index) =>
          _buildCryptoCard(cryptoList[index], isDark),
    );
  }

  // --- 3. GRAFİK GÖRÜNÜMÜ (MARKET CAP ANALİZİ) ---
  Widget _buildGraphView(List cryptoList, bool isDark) {
    return Column(
      children: [
        const Text("Piyasa Değeri Karşılaştırması (Milyar \$)",
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 20),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (cryptoList[0]['market_cap'] / 1000000000) * 1.2,
              barGroups: cryptoList.take(6).toList().asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value['market_cap'].toDouble() / 1000000000,
                      color: const Color(0xFF6C63FF),
                      width: 25,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, _) => Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                          cryptoList[val.toInt()]['symbol'].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  // --- 4. ANALİZ GÖRÜNÜMÜ (HEATMAP - SICAKLIK HARİTASI) ---
  Widget _buildAnalysisView(List cryptoList, bool isDark) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 30, // İlk 30 coini gösterelim
      itemBuilder: (context, index) {
        var coin = cryptoList[index];
        double change = coin['price_change_percentage_24h'] ?? 0.0;
        bool isUp = change >= 0;
        return Container(
          decoration: BoxDecoration(
            color: isUp
                ? Colors.green.withOpacity(0.15)
                : Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isUp
                    ? Colors.green.withOpacity(0.5)
                    : Colors.red.withOpacity(0.5),
                width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(coin['symbol'].toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text("${isUp ? '+' : ''}${change.toStringAsFixed(1)}%",
                  style: TextStyle(
                      color: isUp ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  // --- YARDIMCI BİLEŞEN: COIN KARTI ---
  Widget _buildCryptoCard(dynamic coin, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          Image.network(coin['image'], width: 28, height: 28),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coin['name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(coin['symbol'].toUpperCase(),
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 35,
              child:
                  LineChart(_sparklineData(coin['sparkline_in_7d']['price'])),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("\$${coin['current_price']}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                "${coin['price_change_percentage_24h'].toStringAsFixed(2)}%",
                style: TextStyle(
                    color: coin['price_change_percentage_24h'] >= 0
                        ? Colors.green
                        : Colors.red,
                    fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  LineChartData _sparklineData(List<dynamic> prices) {
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: prices
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
              .toList(),
          isCurved: true,
          color: const Color(0xFF6C63FF),
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
              show: true, color: const Color(0xFF6C63FF).withOpacity(0.05)),
        ),
      ],
    );
  }
}
