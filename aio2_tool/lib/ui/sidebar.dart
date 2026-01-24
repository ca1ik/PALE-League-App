// ... Diğer importlar
import '../modules/palehax_players_view.dart'; // Eğer gerekirse

// _ClassicSidebarState sınıfının içine şu değişkeni ekle:
bool _isPaleHaxExpanded = false;

// Ardından "PALEHAX" bölümünü (eski tek butonu) şu kodla değiştir:

                  // --- PALEHAX GRUBU ---
                  GestureDetector(
                    onTap: () => setState(() => _isPaleHaxExpanded = !_isPaleHaxExpanded),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isPaleHaxExpanded ? Colors.cyan.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _isPaleHaxExpanded ? Icons.keyboard_arrow_up : Icons.sports_soccer,
                            color: isDark ? Colors.white : Colors.black,
                            size: 24,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "PaleHax",
                            style: GoogleFonts.poppins(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // PaleHax Alt Menüleri
                  AnimatedCrossFade(
                    firstChild: Container(),
                    secondChild: Column(
                      children: [
                        _classicItem(14, Icons.home, "Anasayfa", isDark, isRgb: true),
                        _classicItem(15, Icons.groups, "Oyuncular", isDark, isRgb: true), // ÖNEMLİ
                        _classicItem(16, Icons.shield, "Takımlar", isDark),
                        _classicItem(17, Icons.scoreboard, "Maçlar", isDark),
                        _classicItem(18, Icons.format_list_numbered, "Puan Durumu", isDark),
                        _classicItem(19, Icons.bar_chart, "İstatistikler", isDark),
                        
                        // Transferler (Alt classlı istendi ama basitlik için buraya ekliyorum)
                        _classicItem(20, Icons.compare_arrows, "Transferler", isDark),
                        
                        _classicItem(21, Icons.emoji_events, "Challenge", isDark, isRgb: true),
                        _classicItem(22, Icons.workspace_premium, "Hall of Fame", isDark, isRgb: true),
                      ],
                    ),
                    crossFadeState: _isPaleHaxExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),