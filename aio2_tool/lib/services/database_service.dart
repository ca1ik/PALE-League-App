import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database_service.g.dart';

@DataClassName('PlayerTable')
class PlayerTables extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get rating => integer()();
  TextColumn get position => text()();
  TextColumn get team => text()();
  TextColumn get cardType => text()();
  TextColumn get role => text()();
  TextColumn get marketValue => text()();
  TextColumn get statsJson => text()();
  TextColumn get playStylesJson => text()();
  TextColumn get recLink => text().nullable()();

  // Manuel İstatistikler
  IntColumn get manualGoals => integer().withDefault(const Constant(0))();
  IntColumn get manualAssists => integer().withDefault(const Constant(0))();
  IntColumn get manualMatches => integer().withDefault(const Constant(0))();
}

@DriftDatabase(tables: [PlayerTables])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(playerTables, playerTables.manualGoals);
            await m.addColumn(playerTables, playerTables.manualAssists);
            await m.addColumn(playerTables, playerTables.manualMatches);
          }
        },
      );

  // CRUD İşlemleri
  Future<int> insertPlayer(PlayerTablesCompanion player) =>
      into(playerTables).insert(player);

  // ID ile Silme (Eski Yöntem)
  Future<int> deletePlayer(int id) =>
      (delete(playerTables)..where((t) => t.id.equals(id))).go();

  // --- YENİ EKLENEN: İsim ve Kart Tipine Göre Silme ---
  Future<int> deletePlayerByNameAndType(String n, String t) {
    return (delete(playerTables)
          ..where((tbl) => tbl.name.equals(n) & tbl.cardType.equals(t)))
        .go();
  }

  Stream<List<PlayerTable>> watchAllPlayers() => select(playerTables).watch();

  Stream<List<PlayerTable>> watchFilteredPlayers({
    required String searchQuery,
    required String cardTypeFilter,
    required String sortOption,
  }) {
    var query = select(playerTables);

    if (searchQuery.isNotEmpty) {
      query.where((t) => t.name.like('%$searchQuery%'));
    }

    if (cardTypeFilter != "Tümü") {
      query.where((t) => t.cardType.equals(cardTypeFilter));
    }

    if (sortOption == "Reyting") {
      query.orderBy(
          [(t) => OrderingTerm(expression: t.rating, mode: OrderingMode.desc)]);
    } else if (sortOption == "A-Z") {
      query.orderBy(
          [(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]);
    } else if (sortOption == "Z-A") {
      query.orderBy(
          [(t) => OrderingTerm(expression: t.name, mode: OrderingMode.desc)]);
    } else if (sortOption == "En Yeni") {
      query.orderBy(
          [(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)]);
    }

    return query.watch();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'palehax_db_v2.sqlite'));
    return NativeDatabase(file);
  });
}
