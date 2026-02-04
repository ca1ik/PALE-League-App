
// Bu extension sayesinde player_data.dart dosyasına dokunmadan
// oyunculara yeni özellikler kazandırıyoruz.
extension PlayerLogic on Player {
  // --- 1. FM TARZI (1-20) STAT HESAPLAMA ---
  // Mevcut 0-99 arası verileri alıp, pozisyona göre ağırlıklandırarak 1-20 skalasına çeker.
  Map<String, int> get calculatedFmStats {
    // Veritabanındaki ham veriyi al, yoksa rating'den türet
    int getRaw(String key) => (stats[key] ?? rating);

    // 99'luk sistemi 20'liğe çevir (Min 1, Max 20)
    int to20(double val) => (val / 5.0).round().clamp(1, 20);

    // Temel Özellikler
    int pac = to20(getRaw("Hız") * 1.0);
    int sho = to20(getRaw("Bitiricilik") * 1.0);
    int pas = to20(getRaw("Pas") * 1.0);
    int dri = to20(getRaw("Top Sürme") * 1.0);
    int def = to20(getRaw("Top Kapma") * 1.0);
    int phy = to20(getRaw("Güç") * 1.0);

    // Zihinsel (Gizli) Özellikler - Pozisyona göre değişir
    int pos = to20((getRaw("Pozisyon Alma") + getRaw("Görüş")) / 2.0);
    int viz = to20((getRaw("Pas") + getRaw("Top Sürme")) / 2.0);
    int ref = position.contains("GK") ? to20(getRaw("Reflex") * 1.0) : 1;

    return {
      "Hız": pac,
      "Şut": sho,
      "Pas": pas,
      "Dripling": dri,
      "Defans": def,
      "Fizik": phy,
      "Pozisyon": pos, // Boşa kaçma zekası
      "Vizyon": viz, // Pas kanalı görme
      "Refleks": ref, // Kalecilik
    };
  }

  // --- 2. YAPAY ZEKA TALİMATI ---
  // Oyuncunun mevkisine göre varsayılan talimatını belirler
  String get defaultAIInstruction {
    if (position.contains("GK")) return "Sweeper Keeper";
    if (position.contains("CB") || position.contains("DEF"))
      return "Mark Tight"; // Sıkı Markaj
    if (position.contains("CDM"))
      return "Cut Passing Lanes"; // Pas Kanalı Kapat
    if (position.contains("RW") || position.contains("LW"))
      return "Drift Wide"; // Kanata Açıl
    if (position.contains("ST") || position.contains("FWD"))
      return "Get In Behind"; // Arkaya Koş
    return "Playmaker"; // Diğerleri
  }

  // --- 3. MEVKİ AĞIRLIK PUANI (OTOMATİK DİZ İÇİN) ---
  // Otomatik dizme butonunun "Bu adam buraya ne kadar uygun?" sorusunun cevabı
  int calculateScoreForPosition(String targetPos) {
    var s = calculatedFmStats;
    int score = rating; // Baz puan

    // Hedef mevkide mi?
    if (position.contains(targetPos)) score += 50;

    // Hedef mevkinin gerektirdiği statlar yüksek mi?
    switch (targetPos) {
      case "GK":
        score += s["Refleks"]! * 3;
        break;
      case "DEF":
      case "CB":
        score += s["Defans"]! * 2 + s["Fizik"]!;
        break;
      case "MID":
      case "CM":
        score += s["Pas"]! * 2 + s["Vizyon"]!;
        break;
      case "FWD":
      case "ST":
        score += s["Şut"]! * 2 + s["Hız"]!;
        break;
      case "RW":
      case "LW":
        score += s["Hız"]! * 2 + s["Dripling"]!;
        break;
    }
    return score;
  }
}
