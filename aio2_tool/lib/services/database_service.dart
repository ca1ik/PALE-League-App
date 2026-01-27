import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
// jsonEncode/Decode için gerekli:
import 'dart:convert';

part 'database_service.g.dart';

// --- TABLOLAR ---

// Oyuncular Tablosu (SQL Karşılığı)
class PlayerTables extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get rating => integer()();
  TextColumn get position => text()();
  TextColumn get team => text()();
  TextColumn get cardType => text()(); // TOTS, TOTW vb.
  TextColumn get role => text().withDefault(const Constant('Yok'))();

  // Resim Verisi (Hata çıkaran kısım burasıydı, artık güvenli BLOB)
  BlobColumn get playerImage => blob().nullable()();

  // İstatistikleri JSON String olarak tutacağız (Kolay yönetim için)
  TextColumn get statsJson => text()();

  // Playstyle'ları da JSON listesi olarak tutabiliriz veya ayrı tablo yapabiliriz.
  // Basitlik ve hız için JSON string: "['Hızlı Adım', 'Sert Şut']"
  TextColumn get playStylesJson => text()();

  TextColumn get marketValue => text().withDefault(const Constant('N/A'))();
  TextColumn get recLink => text().nullable()();

  // Manuel İstatistikler
  IntColumn get manualGoals => integer().withDefault(const Constant(0))();
  IntColumn get manualAssists => integer().withDefault(const Constant(0))();
  IntColumn get manualMatches => integer().withDefault(const Constant(0))();
}

// --- VERİTABANI SINIFI ---

@DriftDatabase(tables: [PlayerTables])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // --- SORGULAR (FİLTRELEME İÇİN) ---

  // Tüm Oyuncuları Getir
  Future<List<PlayerTable>> getAllPlayers() => select(playerTables).get();

  // Canlı Takip (Stream) - UI anlık güncellenir
  Stream<List<PlayerTable>> watchAllPlayers() => select(playerTables).watch();

  // **GLOBAL KARTLAR İÇİN FİLTRELEME** // (İstediğin A-Z, Reyting, Pozisyon vb. hepsi burada)
  Stream<List<PlayerTable>> watchFilteredPlayers({
    String? searchQuery,
    String? cardTypeFilter,
    String? sortOption, // 'Rating', 'Name', 'Newest'
  }) {
    var query = select(playerTables);

    // Arama Filtresi
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query.where((tbl) => tbl.name.contains(searchQuery.toLowerCase()));
    }

    // Kart Tipi Filtresi
    if (cardTypeFilter != null && cardTypeFilter != "Tümü") {
      query.where((tbl) => tbl.cardType.equals(cardTypeFilter));
    }

    // Sıralama Mantığı
    if (sortOption == 'Rating') {
      query.orderBy(
          [(t) => OrderingTerm(expression: t.rating, mode: OrderingMode.desc)]);
    } else if (sortOption == 'A-Z') {
      query.orderBy(
          [(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]);
    } else if (sortOption == 'Z-A') {
      query.orderBy(
          [(t) => OrderingTerm(expression: t.name, mode: OrderingMode.desc)]);
    } else {
      // Varsayılan: ID'ye göre (En yeni eklenen en sonda)
      query.orderBy(
          [(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)]);
    }

    return query.watch();
  }

  // Yeni Oyuncu Ekle
  Future<int> insertPlayer(PlayerTablesCompanion player) {
    return into(playerTables).insert(player);
  }

  // Oyuncu Sil
  Future<int> deletePlayer(int id) {
    return (delete(playerTables)..where((t) => t.id.equals(id))).go();
  }

  // Oyuncu Güncelle
  Future<bool> updatePlayer(PlayerTable player) {
    return update(playerTables).replace(player);
  }
}

// Veritabanı dosyasını açma işlemi (Windows/Android uyumlu)
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'palehax_v2.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
