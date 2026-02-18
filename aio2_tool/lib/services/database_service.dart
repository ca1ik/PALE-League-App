import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database_service.g.dart'; // Bu dosya build_runner ile oluşacak

// Tablo Tanımı
class PlayerTables extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get rating => integer()();
  TextColumn get position => text()();
  TextColumn get team => text()();
  TextColumn get cardType => text()();
  TextColumn get role => text().withDefault(const Constant('Yedek'))();
  TextColumn get marketValue => text().withDefault(const Constant('€1.0M'))();

  // JSON olarak saklanan kompleks veriler
  TextColumn get statsJson => text().withDefault(const Constant('{}'))();
  TextColumn get playStylesJson => text().withDefault(const Constant('[]'))();

  // Ekstra Veriler
  TextColumn get recLink => text().withDefault(const Constant(''))();
  IntColumn get manualGoals => integer().withDefault(const Constant(0))();
  IntColumn get manualAssists => integer().withDefault(const Constant(0))();
  // List<MatchStat> JSON olarak saklanabilir, burada basitleştirilmiş string tutuyoruz
  TextColumn get manualMatches => text().withDefault(const Constant('[]'))();
}

@DriftDatabase(tables: [PlayerTables])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Oyuncuları Getir (Stream)
  Stream<List<PlayerTable>> watchAllPlayers() {
    return (select(playerTables)
          ..orderBy([
            (t) => OrderingTerm(expression: t.rating, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  // Filtreli Oyuncu Getir
  Stream<List<PlayerTable>> watchFilteredPlayers({
    required String searchQuery,
    required String cardTypeFilter,
    required String sortOption,
  }) {
    var query = select(playerTables);

    // Arama Filtresi
    if (searchQuery.isNotEmpty) {
      query.where((t) => t.name.like('%$searchQuery%'));
    }

    // Kart Tipi Filtresi
    if (cardTypeFilter != "Tümü") {
      query.where((t) => t.cardType.equals(cardTypeFilter));
    }

    // Sıralama
    if (sortOption == "Reyting") {
      query.orderBy(
          [(t) => OrderingTerm(expression: t.rating, mode: OrderingMode.desc)]);
    } else if (sortOption == "A-Z") {
      query.orderBy(
          [(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]);
    } else {
      query.orderBy(
          [(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)]);
    }

    return query.watch();
  }

  // Oyuncu Ekle / Güncelle
  Future<int> insertPlayer(PlayerTablesCompanion entry) {
    return into(playerTables).insertOnConflictUpdate(entry);
  }

  // Oyuncu Sil
  Future<int> deletePlayerByNameAndType(String name, String type) {
    return (delete(playerTables)
          ..where((t) => t.name.equals(name) & t.cardType.equals(type)))
        .go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'palehax_db.sqlite'));
    return NativeDatabase(file);
  });
}
