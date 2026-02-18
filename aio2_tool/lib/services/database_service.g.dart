// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_service.dart';

// ignore_for_file: type=lint
class $PlayerTablesTable extends PlayerTables
    with TableInfo<$PlayerTablesTable, PlayerTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayerTablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
      'rating', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<String> position = GeneratedColumn<String>(
      'position', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _teamMeta = const VerificationMeta('team');
  @override
  late final GeneratedColumn<String> team = GeneratedColumn<String>(
      'team', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cardTypeMeta =
      const VerificationMeta('cardType');
  @override
  late final GeneratedColumn<String> cardType = GeneratedColumn<String>(
      'card_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Yedek'));
  static const VerificationMeta _marketValueMeta =
      const VerificationMeta('marketValue');
  @override
  late final GeneratedColumn<String> marketValue = GeneratedColumn<String>(
      'market_value', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('€1.0M'));
  static const VerificationMeta _statsJsonMeta =
      const VerificationMeta('statsJson');
  @override
  late final GeneratedColumn<String> statsJson = GeneratedColumn<String>(
      'stats_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _playStylesJsonMeta =
      const VerificationMeta('playStylesJson');
  @override
  late final GeneratedColumn<String> playStylesJson = GeneratedColumn<String>(
      'play_styles_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _recLinkMeta =
      const VerificationMeta('recLink');
  @override
  late final GeneratedColumn<String> recLink = GeneratedColumn<String>(
      'rec_link', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _manualGoalsMeta =
      const VerificationMeta('manualGoals');
  @override
  late final GeneratedColumn<int> manualGoals = GeneratedColumn<int>(
      'manual_goals', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _manualAssistsMeta =
      const VerificationMeta('manualAssists');
  @override
  late final GeneratedColumn<int> manualAssists = GeneratedColumn<int>(
      'manual_assists', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _manualMatchesMeta =
      const VerificationMeta('manualMatches');
  @override
  late final GeneratedColumn<String> manualMatches = GeneratedColumn<String>(
      'manual_matches', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        rating,
        position,
        team,
        cardType,
        role,
        marketValue,
        statsJson,
        playStylesJson,
        recLink,
        manualGoals,
        manualAssists,
        manualMatches
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'player_tables';
  @override
  VerificationContext validateIntegrity(Insertable<PlayerTable> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('team')) {
      context.handle(
          _teamMeta, team.isAcceptableOrUnknown(data['team']!, _teamMeta));
    } else if (isInserting) {
      context.missing(_teamMeta);
    }
    if (data.containsKey('card_type')) {
      context.handle(_cardTypeMeta,
          cardType.isAcceptableOrUnknown(data['card_type']!, _cardTypeMeta));
    } else if (isInserting) {
      context.missing(_cardTypeMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    }
    if (data.containsKey('market_value')) {
      context.handle(
          _marketValueMeta,
          marketValue.isAcceptableOrUnknown(
              data['market_value']!, _marketValueMeta));
    }
    if (data.containsKey('stats_json')) {
      context.handle(_statsJsonMeta,
          statsJson.isAcceptableOrUnknown(data['stats_json']!, _statsJsonMeta));
    }
    if (data.containsKey('play_styles_json')) {
      context.handle(
          _playStylesJsonMeta,
          playStylesJson.isAcceptableOrUnknown(
              data['play_styles_json']!, _playStylesJsonMeta));
    }
    if (data.containsKey('rec_link')) {
      context.handle(_recLinkMeta,
          recLink.isAcceptableOrUnknown(data['rec_link']!, _recLinkMeta));
    }
    if (data.containsKey('manual_goals')) {
      context.handle(
          _manualGoalsMeta,
          manualGoals.isAcceptableOrUnknown(
              data['manual_goals']!, _manualGoalsMeta));
    }
    if (data.containsKey('manual_assists')) {
      context.handle(
          _manualAssistsMeta,
          manualAssists.isAcceptableOrUnknown(
              data['manual_assists']!, _manualAssistsMeta));
    }
    if (data.containsKey('manual_matches')) {
      context.handle(
          _manualMatchesMeta,
          manualMatches.isAcceptableOrUnknown(
              data['manual_matches']!, _manualMatchesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayerTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerTable(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rating'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}position'])!,
      team: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}team'])!,
      cardType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_type'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      marketValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}market_value'])!,
      statsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stats_json'])!,
      playStylesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}play_styles_json'])!,
      recLink: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rec_link'])!,
      manualGoals: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}manual_goals'])!,
      manualAssists: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}manual_assists'])!,
      manualMatches: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}manual_matches'])!,
    );
  }

  @override
  $PlayerTablesTable createAlias(String alias) {
    return $PlayerTablesTable(attachedDatabase, alias);
  }
}

class PlayerTable extends DataClass implements Insertable<PlayerTable> {
  final int id;
  final String name;
  final int rating;
  final String position;
  final String team;
  final String cardType;
  final String role;
  final String marketValue;
  final String statsJson;
  final String playStylesJson;
  final String recLink;
  final int manualGoals;
  final int manualAssists;
  final String manualMatches;
  const PlayerTable(
      {required this.id,
      required this.name,
      required this.rating,
      required this.position,
      required this.team,
      required this.cardType,
      required this.role,
      required this.marketValue,
      required this.statsJson,
      required this.playStylesJson,
      required this.recLink,
      required this.manualGoals,
      required this.manualAssists,
      required this.manualMatches});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['rating'] = Variable<int>(rating);
    map['position'] = Variable<String>(position);
    map['team'] = Variable<String>(team);
    map['card_type'] = Variable<String>(cardType);
    map['role'] = Variable<String>(role);
    map['market_value'] = Variable<String>(marketValue);
    map['stats_json'] = Variable<String>(statsJson);
    map['play_styles_json'] = Variable<String>(playStylesJson);
    map['rec_link'] = Variable<String>(recLink);
    map['manual_goals'] = Variable<int>(manualGoals);
    map['manual_assists'] = Variable<int>(manualAssists);
    map['manual_matches'] = Variable<String>(manualMatches);
    return map;
  }

  PlayerTablesCompanion toCompanion(bool nullToAbsent) {
    return PlayerTablesCompanion(
      id: Value(id),
      name: Value(name),
      rating: Value(rating),
      position: Value(position),
      team: Value(team),
      cardType: Value(cardType),
      role: Value(role),
      marketValue: Value(marketValue),
      statsJson: Value(statsJson),
      playStylesJson: Value(playStylesJson),
      recLink: Value(recLink),
      manualGoals: Value(manualGoals),
      manualAssists: Value(manualAssists),
      manualMatches: Value(manualMatches),
    );
  }

  factory PlayerTable.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerTable(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      rating: serializer.fromJson<int>(json['rating']),
      position: serializer.fromJson<String>(json['position']),
      team: serializer.fromJson<String>(json['team']),
      cardType: serializer.fromJson<String>(json['cardType']),
      role: serializer.fromJson<String>(json['role']),
      marketValue: serializer.fromJson<String>(json['marketValue']),
      statsJson: serializer.fromJson<String>(json['statsJson']),
      playStylesJson: serializer.fromJson<String>(json['playStylesJson']),
      recLink: serializer.fromJson<String>(json['recLink']),
      manualGoals: serializer.fromJson<int>(json['manualGoals']),
      manualAssists: serializer.fromJson<int>(json['manualAssists']),
      manualMatches: serializer.fromJson<String>(json['manualMatches']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'rating': serializer.toJson<int>(rating),
      'position': serializer.toJson<String>(position),
      'team': serializer.toJson<String>(team),
      'cardType': serializer.toJson<String>(cardType),
      'role': serializer.toJson<String>(role),
      'marketValue': serializer.toJson<String>(marketValue),
      'statsJson': serializer.toJson<String>(statsJson),
      'playStylesJson': serializer.toJson<String>(playStylesJson),
      'recLink': serializer.toJson<String>(recLink),
      'manualGoals': serializer.toJson<int>(manualGoals),
      'manualAssists': serializer.toJson<int>(manualAssists),
      'manualMatches': serializer.toJson<String>(manualMatches),
    };
  }

  PlayerTable copyWith(
          {int? id,
          String? name,
          int? rating,
          String? position,
          String? team,
          String? cardType,
          String? role,
          String? marketValue,
          String? statsJson,
          String? playStylesJson,
          String? recLink,
          int? manualGoals,
          int? manualAssists,
          String? manualMatches}) =>
      PlayerTable(
        id: id ?? this.id,
        name: name ?? this.name,
        rating: rating ?? this.rating,
        position: position ?? this.position,
        team: team ?? this.team,
        cardType: cardType ?? this.cardType,
        role: role ?? this.role,
        marketValue: marketValue ?? this.marketValue,
        statsJson: statsJson ?? this.statsJson,
        playStylesJson: playStylesJson ?? this.playStylesJson,
        recLink: recLink ?? this.recLink,
        manualGoals: manualGoals ?? this.manualGoals,
        manualAssists: manualAssists ?? this.manualAssists,
        manualMatches: manualMatches ?? this.manualMatches,
      );
  PlayerTable copyWithCompanion(PlayerTablesCompanion data) {
    return PlayerTable(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      rating: data.rating.present ? data.rating.value : this.rating,
      position: data.position.present ? data.position.value : this.position,
      team: data.team.present ? data.team.value : this.team,
      cardType: data.cardType.present ? data.cardType.value : this.cardType,
      role: data.role.present ? data.role.value : this.role,
      marketValue:
          data.marketValue.present ? data.marketValue.value : this.marketValue,
      statsJson: data.statsJson.present ? data.statsJson.value : this.statsJson,
      playStylesJson: data.playStylesJson.present
          ? data.playStylesJson.value
          : this.playStylesJson,
      recLink: data.recLink.present ? data.recLink.value : this.recLink,
      manualGoals:
          data.manualGoals.present ? data.manualGoals.value : this.manualGoals,
      manualAssists: data.manualAssists.present
          ? data.manualAssists.value
          : this.manualAssists,
      manualMatches: data.manualMatches.present
          ? data.manualMatches.value
          : this.manualMatches,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerTable(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rating: $rating, ')
          ..write('position: $position, ')
          ..write('team: $team, ')
          ..write('cardType: $cardType, ')
          ..write('role: $role, ')
          ..write('marketValue: $marketValue, ')
          ..write('statsJson: $statsJson, ')
          ..write('playStylesJson: $playStylesJson, ')
          ..write('recLink: $recLink, ')
          ..write('manualGoals: $manualGoals, ')
          ..write('manualAssists: $manualAssists, ')
          ..write('manualMatches: $manualMatches')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      rating,
      position,
      team,
      cardType,
      role,
      marketValue,
      statsJson,
      playStylesJson,
      recLink,
      manualGoals,
      manualAssists,
      manualMatches);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerTable &&
          other.id == this.id &&
          other.name == this.name &&
          other.rating == this.rating &&
          other.position == this.position &&
          other.team == this.team &&
          other.cardType == this.cardType &&
          other.role == this.role &&
          other.marketValue == this.marketValue &&
          other.statsJson == this.statsJson &&
          other.playStylesJson == this.playStylesJson &&
          other.recLink == this.recLink &&
          other.manualGoals == this.manualGoals &&
          other.manualAssists == this.manualAssists &&
          other.manualMatches == this.manualMatches);
}

class PlayerTablesCompanion extends UpdateCompanion<PlayerTable> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> rating;
  final Value<String> position;
  final Value<String> team;
  final Value<String> cardType;
  final Value<String> role;
  final Value<String> marketValue;
  final Value<String> statsJson;
  final Value<String> playStylesJson;
  final Value<String> recLink;
  final Value<int> manualGoals;
  final Value<int> manualAssists;
  final Value<String> manualMatches;
  const PlayerTablesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rating = const Value.absent(),
    this.position = const Value.absent(),
    this.team = const Value.absent(),
    this.cardType = const Value.absent(),
    this.role = const Value.absent(),
    this.marketValue = const Value.absent(),
    this.statsJson = const Value.absent(),
    this.playStylesJson = const Value.absent(),
    this.recLink = const Value.absent(),
    this.manualGoals = const Value.absent(),
    this.manualAssists = const Value.absent(),
    this.manualMatches = const Value.absent(),
  });
  PlayerTablesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int rating,
    required String position,
    required String team,
    required String cardType,
    this.role = const Value.absent(),
    this.marketValue = const Value.absent(),
    this.statsJson = const Value.absent(),
    this.playStylesJson = const Value.absent(),
    this.recLink = const Value.absent(),
    this.manualGoals = const Value.absent(),
    this.manualAssists = const Value.absent(),
    this.manualMatches = const Value.absent(),
  })  : name = Value(name),
        rating = Value(rating),
        position = Value(position),
        team = Value(team),
        cardType = Value(cardType);
  static Insertable<PlayerTable> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? rating,
    Expression<String>? position,
    Expression<String>? team,
    Expression<String>? cardType,
    Expression<String>? role,
    Expression<String>? marketValue,
    Expression<String>? statsJson,
    Expression<String>? playStylesJson,
    Expression<String>? recLink,
    Expression<int>? manualGoals,
    Expression<int>? manualAssists,
    Expression<String>? manualMatches,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rating != null) 'rating': rating,
      if (position != null) 'position': position,
      if (team != null) 'team': team,
      if (cardType != null) 'card_type': cardType,
      if (role != null) 'role': role,
      if (marketValue != null) 'market_value': marketValue,
      if (statsJson != null) 'stats_json': statsJson,
      if (playStylesJson != null) 'play_styles_json': playStylesJson,
      if (recLink != null) 'rec_link': recLink,
      if (manualGoals != null) 'manual_goals': manualGoals,
      if (manualAssists != null) 'manual_assists': manualAssists,
      if (manualMatches != null) 'manual_matches': manualMatches,
    });
  }

  PlayerTablesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? rating,
      Value<String>? position,
      Value<String>? team,
      Value<String>? cardType,
      Value<String>? role,
      Value<String>? marketValue,
      Value<String>? statsJson,
      Value<String>? playStylesJson,
      Value<String>? recLink,
      Value<int>? manualGoals,
      Value<int>? manualAssists,
      Value<String>? manualMatches}) {
    return PlayerTablesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      position: position ?? this.position,
      team: team ?? this.team,
      cardType: cardType ?? this.cardType,
      role: role ?? this.role,
      marketValue: marketValue ?? this.marketValue,
      statsJson: statsJson ?? this.statsJson,
      playStylesJson: playStylesJson ?? this.playStylesJson,
      recLink: recLink ?? this.recLink,
      manualGoals: manualGoals ?? this.manualGoals,
      manualAssists: manualAssists ?? this.manualAssists,
      manualMatches: manualMatches ?? this.manualMatches,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(position.value);
    }
    if (team.present) {
      map['team'] = Variable<String>(team.value);
    }
    if (cardType.present) {
      map['card_type'] = Variable<String>(cardType.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (marketValue.present) {
      map['market_value'] = Variable<String>(marketValue.value);
    }
    if (statsJson.present) {
      map['stats_json'] = Variable<String>(statsJson.value);
    }
    if (playStylesJson.present) {
      map['play_styles_json'] = Variable<String>(playStylesJson.value);
    }
    if (recLink.present) {
      map['rec_link'] = Variable<String>(recLink.value);
    }
    if (manualGoals.present) {
      map['manual_goals'] = Variable<int>(manualGoals.value);
    }
    if (manualAssists.present) {
      map['manual_assists'] = Variable<int>(manualAssists.value);
    }
    if (manualMatches.present) {
      map['manual_matches'] = Variable<String>(manualMatches.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayerTablesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rating: $rating, ')
          ..write('position: $position, ')
          ..write('team: $team, ')
          ..write('cardType: $cardType, ')
          ..write('role: $role, ')
          ..write('marketValue: $marketValue, ')
          ..write('statsJson: $statsJson, ')
          ..write('playStylesJson: $playStylesJson, ')
          ..write('recLink: $recLink, ')
          ..write('manualGoals: $manualGoals, ')
          ..write('manualAssists: $manualAssists, ')
          ..write('manualMatches: $manualMatches')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlayerTablesTable playerTables = $PlayerTablesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [playerTables];
}

typedef $$PlayerTablesTableCreateCompanionBuilder = PlayerTablesCompanion
    Function({
  Value<int> id,
  required String name,
  required int rating,
  required String position,
  required String team,
  required String cardType,
  Value<String> role,
  Value<String> marketValue,
  Value<String> statsJson,
  Value<String> playStylesJson,
  Value<String> recLink,
  Value<int> manualGoals,
  Value<int> manualAssists,
  Value<String> manualMatches,
});
typedef $$PlayerTablesTableUpdateCompanionBuilder = PlayerTablesCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<int> rating,
  Value<String> position,
  Value<String> team,
  Value<String> cardType,
  Value<String> role,
  Value<String> marketValue,
  Value<String> statsJson,
  Value<String> playStylesJson,
  Value<String> recLink,
  Value<int> manualGoals,
  Value<int> manualAssists,
  Value<String> manualMatches,
});

class $$PlayerTablesTableFilterComposer
    extends Composer<_$AppDatabase, $PlayerTablesTable> {
  $$PlayerTablesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get team => $composableBuilder(
      column: $table.team, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cardType => $composableBuilder(
      column: $table.cardType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get marketValue => $composableBuilder(
      column: $table.marketValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get statsJson => $composableBuilder(
      column: $table.statsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get playStylesJson => $composableBuilder(
      column: $table.playStylesJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recLink => $composableBuilder(
      column: $table.recLink, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get manualGoals => $composableBuilder(
      column: $table.manualGoals, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get manualAssists => $composableBuilder(
      column: $table.manualAssists, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get manualMatches => $composableBuilder(
      column: $table.manualMatches, builder: (column) => ColumnFilters(column));
}

class $$PlayerTablesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayerTablesTable> {
  $$PlayerTablesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get team => $composableBuilder(
      column: $table.team, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cardType => $composableBuilder(
      column: $table.cardType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get marketValue => $composableBuilder(
      column: $table.marketValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get statsJson => $composableBuilder(
      column: $table.statsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get playStylesJson => $composableBuilder(
      column: $table.playStylesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recLink => $composableBuilder(
      column: $table.recLink, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get manualGoals => $composableBuilder(
      column: $table.manualGoals, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get manualAssists => $composableBuilder(
      column: $table.manualAssists,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get manualMatches => $composableBuilder(
      column: $table.manualMatches,
      builder: (column) => ColumnOrderings(column));
}

class $$PlayerTablesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayerTablesTable> {
  $$PlayerTablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get team =>
      $composableBuilder(column: $table.team, builder: (column) => column);

  GeneratedColumn<String> get cardType =>
      $composableBuilder(column: $table.cardType, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get marketValue => $composableBuilder(
      column: $table.marketValue, builder: (column) => column);

  GeneratedColumn<String> get statsJson =>
      $composableBuilder(column: $table.statsJson, builder: (column) => column);

  GeneratedColumn<String> get playStylesJson => $composableBuilder(
      column: $table.playStylesJson, builder: (column) => column);

  GeneratedColumn<String> get recLink =>
      $composableBuilder(column: $table.recLink, builder: (column) => column);

  GeneratedColumn<int> get manualGoals => $composableBuilder(
      column: $table.manualGoals, builder: (column) => column);

  GeneratedColumn<int> get manualAssists => $composableBuilder(
      column: $table.manualAssists, builder: (column) => column);

  GeneratedColumn<String> get manualMatches => $composableBuilder(
      column: $table.manualMatches, builder: (column) => column);
}

class $$PlayerTablesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlayerTablesTable,
    PlayerTable,
    $$PlayerTablesTableFilterComposer,
    $$PlayerTablesTableOrderingComposer,
    $$PlayerTablesTableAnnotationComposer,
    $$PlayerTablesTableCreateCompanionBuilder,
    $$PlayerTablesTableUpdateCompanionBuilder,
    (
      PlayerTable,
      BaseReferences<_$AppDatabase, $PlayerTablesTable, PlayerTable>
    ),
    PlayerTable,
    PrefetchHooks Function()> {
  $$PlayerTablesTableTableManager(_$AppDatabase db, $PlayerTablesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayerTablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayerTablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayerTablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> rating = const Value.absent(),
            Value<String> position = const Value.absent(),
            Value<String> team = const Value.absent(),
            Value<String> cardType = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> marketValue = const Value.absent(),
            Value<String> statsJson = const Value.absent(),
            Value<String> playStylesJson = const Value.absent(),
            Value<String> recLink = const Value.absent(),
            Value<int> manualGoals = const Value.absent(),
            Value<int> manualAssists = const Value.absent(),
            Value<String> manualMatches = const Value.absent(),
          }) =>
              PlayerTablesCompanion(
            id: id,
            name: name,
            rating: rating,
            position: position,
            team: team,
            cardType: cardType,
            role: role,
            marketValue: marketValue,
            statsJson: statsJson,
            playStylesJson: playStylesJson,
            recLink: recLink,
            manualGoals: manualGoals,
            manualAssists: manualAssists,
            manualMatches: manualMatches,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required int rating,
            required String position,
            required String team,
            required String cardType,
            Value<String> role = const Value.absent(),
            Value<String> marketValue = const Value.absent(),
            Value<String> statsJson = const Value.absent(),
            Value<String> playStylesJson = const Value.absent(),
            Value<String> recLink = const Value.absent(),
            Value<int> manualGoals = const Value.absent(),
            Value<int> manualAssists = const Value.absent(),
            Value<String> manualMatches = const Value.absent(),
          }) =>
              PlayerTablesCompanion.insert(
            id: id,
            name: name,
            rating: rating,
            position: position,
            team: team,
            cardType: cardType,
            role: role,
            marketValue: marketValue,
            statsJson: statsJson,
            playStylesJson: playStylesJson,
            recLink: recLink,
            manualGoals: manualGoals,
            manualAssists: manualAssists,
            manualMatches: manualMatches,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlayerTablesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlayerTablesTable,
    PlayerTable,
    $$PlayerTablesTableFilterComposer,
    $$PlayerTablesTableOrderingComposer,
    $$PlayerTablesTableAnnotationComposer,
    $$PlayerTablesTableCreateCompanionBuilder,
    $$PlayerTablesTableUpdateCompanionBuilder,
    (
      PlayerTable,
      BaseReferences<_$AppDatabase, $PlayerTablesTable, PlayerTable>
    ),
    PlayerTable,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlayerTablesTableTableManager get playerTables =>
      $$PlayerTablesTableTableManager(_db, _db.playerTables);
}
