// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'net_worth_snapshot_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetNetWorthSnapshotModelCollection on Isar {
  IsarCollection<NetWorthSnapshotModel> get netWorthSnapshotModels =>
      this.collection();
}

const NetWorthSnapshotModelSchema = CollectionSchema(
  name: r'NetWorthSnapshotModel',
  id: -2406595477780789931,
  properties: {
    r'capturedAt': PropertySchema(
      id: 0,
      name: r'capturedAt',
      type: IsarType.dateTime,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'dayKey': PropertySchema(id: 2, name: r'dayKey', type: IsarType.long),
    r'perWalletJson': PropertySchema(
      id: 3,
      name: r'perWalletJson',
      type: IsarType.string,
    ),
    r'total': PropertySchema(id: 4, name: r'total', type: IsarType.double),
  },

  estimateSize: _netWorthSnapshotModelEstimateSize,
  serialize: _netWorthSnapshotModelSerialize,
  deserialize: _netWorthSnapshotModelDeserialize,
  deserializeProp: _netWorthSnapshotModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'dayKey': IndexSchema(
      id: -3264092797330672150,
      name: r'dayKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dayKey',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _netWorthSnapshotModelGetId,
  getLinks: _netWorthSnapshotModelGetLinks,
  attach: _netWorthSnapshotModelAttach,
  version: '3.3.2',
);

int _netWorthSnapshotModelEstimateSize(
  NetWorthSnapshotModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.perWalletJson.length * 3;
  return bytesCount;
}

void _netWorthSnapshotModelSerialize(
  NetWorthSnapshotModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.capturedAt);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeLong(offsets[2], object.dayKey);
  writer.writeString(offsets[3], object.perWalletJson);
  writer.writeDouble(offsets[4], object.total);
}

NetWorthSnapshotModel _netWorthSnapshotModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = NetWorthSnapshotModel();
  object.capturedAt = reader.readDateTime(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.dayKey = reader.readLong(offsets[2]);
  object.id = id;
  object.perWalletJson = reader.readString(offsets[3]);
  object.total = reader.readDouble(offsets[4]);
  return object;
}

P _netWorthSnapshotModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _netWorthSnapshotModelGetId(NetWorthSnapshotModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _netWorthSnapshotModelGetLinks(
  NetWorthSnapshotModel object,
) {
  return [];
}

void _netWorthSnapshotModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  NetWorthSnapshotModel object,
) {
  object.id = id;
}

extension NetWorthSnapshotModelQueryWhereSort
    on QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QWhere> {
  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterWhere>
  anyDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'dayKey'),
      );
    });
  }
}

extension NetWorthSnapshotModelQueryWhere
    on
        QueryBuilder<
          NetWorthSnapshotModel,
          NetWorthSnapshotModel,
          QWhereClause
        > {
  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterWhereClause>
  dayKeyEqualTo(int dayKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'dayKey', value: [dayKey]),
      );
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterWhereClause>
  dayKeyNotEqualTo(int dayKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dayKey',
                lower: [],
                upper: [dayKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dayKey',
                lower: [dayKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dayKey',
                lower: [dayKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dayKey',
                lower: [],
                upper: [dayKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterWhereClause>
  dayKeyGreaterThan(int dayKey, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'dayKey',
          lower: [dayKey],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterWhereClause>
  dayKeyLessThan(int dayKey, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'dayKey',
          lower: [],
          upper: [dayKey],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterWhereClause>
  dayKeyBetween(
    int lowerDayKey,
    int upperDayKey, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'dayKey',
          lower: [lowerDayKey],
          includeLower: includeLower,
          upper: [upperDayKey],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension NetWorthSnapshotModelQueryFilter
    on
        QueryBuilder<
          NetWorthSnapshotModel,
          NetWorthSnapshotModel,
          QFilterCondition
        > {
  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  capturedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'capturedAt', value: value),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  capturedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'capturedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  capturedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'capturedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  capturedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'capturedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  dayKeyEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dayKey', value: value),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  dayKeyGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dayKey',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  dayKeyLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dayKey',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  dayKeyBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dayKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  perWalletJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'perWalletJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  perWalletJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'perWalletJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  perWalletJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'perWalletJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  perWalletJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'perWalletJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  perWalletJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'perWalletJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  perWalletJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'perWalletJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  perWalletJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'perWalletJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  perWalletJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'perWalletJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  perWalletJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'perWalletJson', value: ''),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  perWalletJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'perWalletJson', value: ''),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  totalEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'total',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  totalGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'total',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  totalLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'total',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    NetWorthSnapshotModel,
    NetWorthSnapshotModel,
    QAfterFilterCondition
  >
  totalBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'total',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }
}

extension NetWorthSnapshotModelQueryObject
    on
        QueryBuilder<
          NetWorthSnapshotModel,
          NetWorthSnapshotModel,
          QFilterCondition
        > {}

extension NetWorthSnapshotModelQueryLinks
    on
        QueryBuilder<
          NetWorthSnapshotModel,
          NetWorthSnapshotModel,
          QFilterCondition
        > {}

extension NetWorthSnapshotModelQuerySortBy
    on QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QSortBy> {
  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  sortByCapturedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capturedAt', Sort.asc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  sortByCapturedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capturedAt', Sort.desc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  sortByDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayKey', Sort.asc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  sortByDayKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayKey', Sort.desc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  sortByPerWalletJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perWalletJson', Sort.asc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  sortByPerWalletJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perWalletJson', Sort.desc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  sortByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.asc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  sortByTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.desc);
    });
  }
}

extension NetWorthSnapshotModelQuerySortThenBy
    on QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QSortThenBy> {
  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  thenByCapturedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capturedAt', Sort.asc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  thenByCapturedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capturedAt', Sort.desc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  thenByDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayKey', Sort.asc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  thenByDayKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayKey', Sort.desc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  thenByPerWalletJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perWalletJson', Sort.asc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  thenByPerWalletJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perWalletJson', Sort.desc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  thenByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.asc);
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QAfterSortBy>
  thenByTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.desc);
    });
  }
}

extension NetWorthSnapshotModelQueryWhereDistinct
    on QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QDistinct> {
  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QDistinct>
  distinctByCapturedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'capturedAt');
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QDistinct>
  distinctByDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dayKey');
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QDistinct>
  distinctByPerWalletJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'perWalletJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<NetWorthSnapshotModel, NetWorthSnapshotModel, QDistinct>
  distinctByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'total');
    });
  }
}

extension NetWorthSnapshotModelQueryProperty
    on
        QueryBuilder<
          NetWorthSnapshotModel,
          NetWorthSnapshotModel,
          QQueryProperty
        > {
  QueryBuilder<NetWorthSnapshotModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<NetWorthSnapshotModel, DateTime, QQueryOperations>
  capturedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'capturedAt');
    });
  }

  QueryBuilder<NetWorthSnapshotModel, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<NetWorthSnapshotModel, int, QQueryOperations> dayKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayKey');
    });
  }

  QueryBuilder<NetWorthSnapshotModel, String, QQueryOperations>
  perWalletJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'perWalletJson');
    });
  }

  QueryBuilder<NetWorthSnapshotModel, double, QQueryOperations>
  totalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'total');
    });
  }
}
