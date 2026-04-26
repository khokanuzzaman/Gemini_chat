// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_ledger_sync_state_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSmsLedgerSyncStateModelCollection on Isar {
  IsarCollection<SmsLedgerSyncStateModel> get smsLedgerSyncStateModels =>
      this.collection();
}

const SmsLedgerSyncStateModelSchema = CollectionSchema(
  name: r'SmsLedgerSyncStateModel',
  id: -4583826117804625308,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'initialBackfillComplete': PropertySchema(
      id: 1,
      name: r'initialBackfillComplete',
      type: IsarType.bool,
    ),
    r'lastSuccessfulSyncAt': PropertySchema(
      id: 2,
      name: r'lastSuccessfulSyncAt',
      type: IsarType.dateTime,
    ),
    r'lastSyncedSmsDate': PropertySchema(
      id: 3,
      name: r'lastSyncedSmsDate',
      type: IsarType.dateTime,
    ),
    r'lastSyncedSmsId': PropertySchema(
      id: 4,
      name: r'lastSyncedSmsId',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 5,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _smsLedgerSyncStateModelEstimateSize,
  serialize: _smsLedgerSyncStateModelSerialize,
  deserialize: _smsLedgerSyncStateModelDeserialize,
  deserializeProp: _smsLedgerSyncStateModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'lastSuccessfulSyncAt': IndexSchema(
      id: 8664126968204961506,
      name: r'lastSuccessfulSyncAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'lastSuccessfulSyncAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'lastSyncedSmsDate': IndexSchema(
      id: 1524943049011494250,
      name: r'lastSyncedSmsDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'lastSyncedSmsDate',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'updatedAt': IndexSchema(
      id: -6238191080293565125,
      name: r'updatedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'updatedAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _smsLedgerSyncStateModelGetId,
  getLinks: _smsLedgerSyncStateModelGetLinks,
  attach: _smsLedgerSyncStateModelAttach,
  version: '3.3.2',
);

int _smsLedgerSyncStateModelEstimateSize(
  SmsLedgerSyncStateModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _smsLedgerSyncStateModelSerialize(
  SmsLedgerSyncStateModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeBool(offsets[1], object.initialBackfillComplete);
  writer.writeDateTime(offsets[2], object.lastSuccessfulSyncAt);
  writer.writeDateTime(offsets[3], object.lastSyncedSmsDate);
  writer.writeLong(offsets[4], object.lastSyncedSmsId);
  writer.writeDateTime(offsets[5], object.updatedAt);
}

SmsLedgerSyncStateModel _smsLedgerSyncStateModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SmsLedgerSyncStateModel();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.initialBackfillComplete = reader.readBool(offsets[1]);
  object.lastSuccessfulSyncAt = reader.readDateTimeOrNull(offsets[2]);
  object.lastSyncedSmsDate = reader.readDateTimeOrNull(offsets[3]);
  object.lastSyncedSmsId = reader.readLongOrNull(offsets[4]);
  object.updatedAt = reader.readDateTime(offsets[5]);
  return object;
}

P _smsLedgerSyncStateModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _smsLedgerSyncStateModelGetId(SmsLedgerSyncStateModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _smsLedgerSyncStateModelGetLinks(
  SmsLedgerSyncStateModel object,
) {
  return [];
}

void _smsLedgerSyncStateModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  SmsLedgerSyncStateModel object,
) {
  object.id = id;
}

extension SmsLedgerSyncStateModelQueryWhereSort
    on QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QWhere> {
  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterWhere>
  anyLastSuccessfulSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'lastSuccessfulSyncAt'),
      );
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterWhere>
  anyLastSyncedSmsDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'lastSyncedSmsDate'),
      );
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterWhere>
  anyUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAt'),
      );
    });
  }
}

extension SmsLedgerSyncStateModelQueryWhere
    on
        QueryBuilder<
          SmsLedgerSyncStateModel,
          SmsLedgerSyncStateModel,
          QWhereClause
        > {
  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
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

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
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

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  lastSuccessfulSyncAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'lastSuccessfulSyncAt',
          value: [null],
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  lastSuccessfulSyncAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'lastSuccessfulSyncAt',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  lastSuccessfulSyncAtEqualTo(DateTime? lastSuccessfulSyncAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'lastSuccessfulSyncAt',
          value: [lastSuccessfulSyncAt],
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  lastSuccessfulSyncAtNotEqualTo(DateTime? lastSuccessfulSyncAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastSuccessfulSyncAt',
                lower: [],
                upper: [lastSuccessfulSyncAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastSuccessfulSyncAt',
                lower: [lastSuccessfulSyncAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastSuccessfulSyncAt',
                lower: [lastSuccessfulSyncAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastSuccessfulSyncAt',
                lower: [],
                upper: [lastSuccessfulSyncAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  lastSuccessfulSyncAtGreaterThan(
    DateTime? lastSuccessfulSyncAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'lastSuccessfulSyncAt',
          lower: [lastSuccessfulSyncAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  lastSuccessfulSyncAtLessThan(
    DateTime? lastSuccessfulSyncAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'lastSuccessfulSyncAt',
          lower: [],
          upper: [lastSuccessfulSyncAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  lastSuccessfulSyncAtBetween(
    DateTime? lowerLastSuccessfulSyncAt,
    DateTime? upperLastSuccessfulSyncAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'lastSuccessfulSyncAt',
          lower: [lowerLastSuccessfulSyncAt],
          includeLower: includeLower,
          upper: [upperLastSuccessfulSyncAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  lastSyncedSmsDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'lastSyncedSmsDate',
          value: [null],
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  lastSyncedSmsDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'lastSyncedSmsDate',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  lastSyncedSmsDateEqualTo(DateTime? lastSyncedSmsDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'lastSyncedSmsDate',
          value: [lastSyncedSmsDate],
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  lastSyncedSmsDateNotEqualTo(DateTime? lastSyncedSmsDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastSyncedSmsDate',
                lower: [],
                upper: [lastSyncedSmsDate],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastSyncedSmsDate',
                lower: [lastSyncedSmsDate],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastSyncedSmsDate',
                lower: [lastSyncedSmsDate],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastSyncedSmsDate',
                lower: [],
                upper: [lastSyncedSmsDate],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  lastSyncedSmsDateGreaterThan(
    DateTime? lastSyncedSmsDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'lastSyncedSmsDate',
          lower: [lastSyncedSmsDate],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  lastSyncedSmsDateLessThan(
    DateTime? lastSyncedSmsDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'lastSyncedSmsDate',
          lower: [],
          upper: [lastSyncedSmsDate],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  lastSyncedSmsDateBetween(
    DateTime? lowerLastSyncedSmsDate,
    DateTime? upperLastSyncedSmsDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'lastSyncedSmsDate',
          lower: [lowerLastSyncedSmsDate],
          includeLower: includeLower,
          upper: [upperLastSyncedSmsDate],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  updatedAtEqualTo(DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'updatedAt', value: [updatedAt]),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  updatedAtNotEqualTo(DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [],
                upper: [updatedAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [updatedAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [updatedAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [],
                upper: [updatedAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  updatedAtGreaterThan(DateTime updatedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAt',
          lower: [updatedAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  updatedAtLessThan(DateTime updatedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAt',
          lower: [],
          upper: [updatedAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterWhereClause
  >
  updatedAtBetween(
    DateTime lowerUpdatedAt,
    DateTime upperUpdatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAt',
          lower: [lowerUpdatedAt],
          includeLower: includeLower,
          upper: [upperUpdatedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SmsLedgerSyncStateModelQueryFilter
    on
        QueryBuilder<
          SmsLedgerSyncStateModel,
          SmsLedgerSyncStateModel,
          QFilterCondition
        > {
  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
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
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
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
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
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
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
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
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
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
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
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
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
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
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
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
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  initialBackfillCompleteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'initialBackfillComplete',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  lastSuccessfulSyncAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastSuccessfulSyncAt'),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  lastSuccessfulSyncAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastSuccessfulSyncAt'),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  lastSuccessfulSyncAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastSuccessfulSyncAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  lastSuccessfulSyncAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastSuccessfulSyncAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  lastSuccessfulSyncAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastSuccessfulSyncAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  lastSuccessfulSyncAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastSuccessfulSyncAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  lastSyncedSmsDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastSyncedSmsDate'),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  lastSyncedSmsDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastSyncedSmsDate'),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  lastSyncedSmsDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastSyncedSmsDate', value: value),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  lastSyncedSmsDateGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastSyncedSmsDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  lastSyncedSmsDateLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastSyncedSmsDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  lastSyncedSmsDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastSyncedSmsDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  lastSyncedSmsIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastSyncedSmsId'),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  lastSyncedSmsIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastSyncedSmsId'),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  lastSyncedSmsIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastSyncedSmsId', value: value),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  lastSyncedSmsIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastSyncedSmsId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  lastSyncedSmsIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastSyncedSmsId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  lastSyncedSmsIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastSyncedSmsId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  updatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SmsLedgerSyncStateModel,
    SmsLedgerSyncStateModel,
    QAfterFilterCondition
  >
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SmsLedgerSyncStateModelQueryObject
    on
        QueryBuilder<
          SmsLedgerSyncStateModel,
          SmsLedgerSyncStateModel,
          QFilterCondition
        > {}

extension SmsLedgerSyncStateModelQueryLinks
    on
        QueryBuilder<
          SmsLedgerSyncStateModel,
          SmsLedgerSyncStateModel,
          QFilterCondition
        > {}

extension SmsLedgerSyncStateModelQuerySortBy
    on QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QSortBy> {
  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  sortByInitialBackfillComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialBackfillComplete', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  sortByInitialBackfillCompleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialBackfillComplete', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  sortByLastSuccessfulSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSuccessfulSyncAt', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  sortByLastSuccessfulSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSuccessfulSyncAt', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  sortByLastSyncedSmsDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedSmsDate', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  sortByLastSyncedSmsDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedSmsDate', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  sortByLastSyncedSmsId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedSmsId', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  sortByLastSyncedSmsIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedSmsId', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SmsLedgerSyncStateModelQuerySortThenBy
    on
        QueryBuilder<
          SmsLedgerSyncStateModel,
          SmsLedgerSyncStateModel,
          QSortThenBy
        > {
  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  thenByInitialBackfillComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialBackfillComplete', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  thenByInitialBackfillCompleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialBackfillComplete', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  thenByLastSuccessfulSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSuccessfulSyncAt', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  thenByLastSuccessfulSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSuccessfulSyncAt', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  thenByLastSyncedSmsDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedSmsDate', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  thenByLastSyncedSmsDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedSmsDate', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  thenByLastSyncedSmsId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedSmsId', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  thenByLastSyncedSmsIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedSmsId', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SmsLedgerSyncStateModelQueryWhereDistinct
    on
        QueryBuilder<
          SmsLedgerSyncStateModel,
          SmsLedgerSyncStateModel,
          QDistinct
        > {
  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QDistinct>
  distinctByInitialBackfillComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'initialBackfillComplete');
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QDistinct>
  distinctByLastSuccessfulSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSuccessfulSyncAt');
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QDistinct>
  distinctByLastSyncedSmsDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncedSmsDate');
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QDistinct>
  distinctByLastSyncedSmsId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncedSmsId');
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, SmsLedgerSyncStateModel, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension SmsLedgerSyncStateModelQueryProperty
    on
        QueryBuilder<
          SmsLedgerSyncStateModel,
          SmsLedgerSyncStateModel,
          QQueryProperty
        > {
  QueryBuilder<SmsLedgerSyncStateModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, bool, QQueryOperations>
  initialBackfillCompleteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'initialBackfillComplete');
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, DateTime?, QQueryOperations>
  lastSuccessfulSyncAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSuccessfulSyncAt');
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, DateTime?, QQueryOperations>
  lastSyncedSmsDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncedSmsDate');
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, int?, QQueryOperations>
  lastSyncedSmsIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncedSmsId');
    });
  }

  QueryBuilder<SmsLedgerSyncStateModel, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
