// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDebtModelCollection on Isar {
  IsarCollection<DebtModel> get debtModels => this.collection();
}

const DebtModelSchema = CollectionSchema(
  name: r'DebtModel',
  id: 7879871328374011369,
  properties: {
    r'annualInterestRate': PropertySchema(
      id: 0,
      name: r'annualInterestRate',
      type: IsarType.double,
    ),
    r'category': PropertySchema(
      id: 1,
      name: r'category',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'description': PropertySchema(
      id: 3,
      name: r'description',
      type: IsarType.string,
    ),
    r'dueDate': PropertySchema(
      id: 4,
      name: r'dueDate',
      type: IsarType.dateTime,
    ),
    r'emiAmount': PropertySchema(
      id: 5,
      name: r'emiAmount',
      type: IsarType.double,
    ),
    r'installmentDayOfMonth': PropertySchema(
      id: 6,
      name: r'installmentDayOfMonth',
      type: IsarType.long,
    ),
    r'isEMI': PropertySchema(id: 7, name: r'isEMI', type: IsarType.bool),
    r'nextInstallmentDate': PropertySchema(
      id: 8,
      name: r'nextInstallmentDate',
      type: IsarType.dateTime,
    ),
    r'note': PropertySchema(id: 9, name: r'note', type: IsarType.string),
    r'originalAmount': PropertySchema(
      id: 10,
      name: r'originalAmount',
      type: IsarType.double,
    ),
    r'paidInstallments': PropertySchema(
      id: 11,
      name: r'paidInstallments',
      type: IsarType.long,
    ),
    r'personName': PropertySchema(
      id: 12,
      name: r'personName',
      type: IsarType.string,
    ),
    r'personPhone': PropertySchema(
      id: 13,
      name: r'personPhone',
      type: IsarType.string,
    ),
    r'remainingAmount': PropertySchema(
      id: 14,
      name: r'remainingAmount',
      type: IsarType.double,
    ),
    r'reminderEnabled': PropertySchema(
      id: 15,
      name: r'reminderEnabled',
      type: IsarType.bool,
    ),
    r'settledAt': PropertySchema(
      id: 16,
      name: r'settledAt',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 17,
      name: r'status',
      type: IsarType.byte,
      enumMap: _DebtModelstatusEnumValueMap,
    ),
    r'totalInstallments': PropertySchema(
      id: 18,
      name: r'totalInstallments',
      type: IsarType.long,
    ),
    r'type': PropertySchema(
      id: 19,
      name: r'type',
      type: IsarType.byte,
      enumMap: _DebtModeltypeEnumValueMap,
    ),
    r'walletId': PropertySchema(id: 20, name: r'walletId', type: IsarType.long),
  },

  estimateSize: _debtModelEstimateSize,
  serialize: _debtModelSerialize,
  deserialize: _debtModelDeserialize,
  deserializeProp: _debtModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'personName': IndexSchema(
      id: 1248926044822021493,
      name: r'personName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'personName',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'nextInstallmentDate': IndexSchema(
      id: -7209920988982693581,
      name: r'nextInstallmentDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'nextInstallmentDate',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _debtModelGetId,
  getLinks: _debtModelGetLinks,
  attach: _debtModelAttach,
  version: '3.3.2',
);

int _debtModelEstimateSize(
  DebtModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.category;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.personName.length * 3;
  {
    final value = object.personPhone;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _debtModelSerialize(
  DebtModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.annualInterestRate);
  writer.writeString(offsets[1], object.category);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.description);
  writer.writeDateTime(offsets[4], object.dueDate);
  writer.writeDouble(offsets[5], object.emiAmount);
  writer.writeLong(offsets[6], object.installmentDayOfMonth);
  writer.writeBool(offsets[7], object.isEMI);
  writer.writeDateTime(offsets[8], object.nextInstallmentDate);
  writer.writeString(offsets[9], object.note);
  writer.writeDouble(offsets[10], object.originalAmount);
  writer.writeLong(offsets[11], object.paidInstallments);
  writer.writeString(offsets[12], object.personName);
  writer.writeString(offsets[13], object.personPhone);
  writer.writeDouble(offsets[14], object.remainingAmount);
  writer.writeBool(offsets[15], object.reminderEnabled);
  writer.writeDateTime(offsets[16], object.settledAt);
  writer.writeByte(offsets[17], object.status.index);
  writer.writeLong(offsets[18], object.totalInstallments);
  writer.writeByte(offsets[19], object.type.index);
  writer.writeLong(offsets[20], object.walletId);
}

DebtModel _debtModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DebtModel();
  object.annualInterestRate = reader.readDouble(offsets[0]);
  object.category = reader.readStringOrNull(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.description = reader.readStringOrNull(offsets[3]);
  object.dueDate = reader.readDateTimeOrNull(offsets[4]);
  object.emiAmount = reader.readDouble(offsets[5]);
  object.id = id;
  object.installmentDayOfMonth = reader.readLongOrNull(offsets[6]);
  object.isEMI = reader.readBool(offsets[7]);
  object.nextInstallmentDate = reader.readDateTimeOrNull(offsets[8]);
  object.note = reader.readStringOrNull(offsets[9]);
  object.originalAmount = reader.readDouble(offsets[10]);
  object.paidInstallments = reader.readLong(offsets[11]);
  object.personName = reader.readString(offsets[12]);
  object.personPhone = reader.readStringOrNull(offsets[13]);
  object.remainingAmount = reader.readDouble(offsets[14]);
  object.reminderEnabled = reader.readBool(offsets[15]);
  object.settledAt = reader.readDateTimeOrNull(offsets[16]);
  object.status =
      _DebtModelstatusValueEnumMap[reader.readByteOrNull(offsets[17])] ??
      DebtStatus.active;
  object.totalInstallments = reader.readLong(offsets[18]);
  object.type =
      _DebtModeltypeValueEnumMap[reader.readByteOrNull(offsets[19])] ??
      DebtType.iOwe;
  object.walletId = reader.readLongOrNull(offsets[20]);
  return object;
}

P _debtModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readDouble(offset)) as P;
    case 15:
      return (reader.readBool(offset)) as P;
    case 16:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 17:
      return (_DebtModelstatusValueEnumMap[reader.readByteOrNull(offset)] ??
              DebtStatus.active)
          as P;
    case 18:
      return (reader.readLong(offset)) as P;
    case 19:
      return (_DebtModeltypeValueEnumMap[reader.readByteOrNull(offset)] ??
              DebtType.iOwe)
          as P;
    case 20:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _DebtModelstatusEnumValueMap = {
  'active': 0,
  'settled': 1,
  'overdue': 2,
  'cancelled': 3,
};
const _DebtModelstatusValueEnumMap = {
  0: DebtStatus.active,
  1: DebtStatus.settled,
  2: DebtStatus.overdue,
  3: DebtStatus.cancelled,
};
const _DebtModeltypeEnumValueMap = {'iOwe': 0, 'theyOwe': 1};
const _DebtModeltypeValueEnumMap = {0: DebtType.iOwe, 1: DebtType.theyOwe};

Id _debtModelGetId(DebtModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _debtModelGetLinks(DebtModel object) {
  return [];
}

void _debtModelAttach(IsarCollection<dynamic> col, Id id, DebtModel object) {
  object.id = id;
}

extension DebtModelQueryWhereSort
    on QueryBuilder<DebtModel, DebtModel, QWhere> {
  QueryBuilder<DebtModel, DebtModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhere> anyNextInstallmentDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'nextInstallmentDate'),
      );
    });
  }
}

extension DebtModelQueryWhere
    on QueryBuilder<DebtModel, DebtModel, QWhereClause> {
  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause> personNameEqualTo(
    String personName,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'personName', value: [personName]),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause> personNameNotEqualTo(
    String personName,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'personName',
                lower: [],
                upper: [personName],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'personName',
                lower: [personName],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'personName',
                lower: [personName],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'personName',
                lower: [],
                upper: [personName],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause> createdAtEqualTo(
    DateTime createdAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause> createdAtNotEqualTo(
    DateTime createdAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [],
                upper: [createdAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [createdAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [createdAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [],
                upper: [createdAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause> createdAtGreaterThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [createdAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause> createdAtLessThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [],
          upper: [createdAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause> createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [lowerCreatedAt],
          includeLower: includeLower,
          upper: [upperCreatedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause>
  nextInstallmentDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'nextInstallmentDate',
          value: [null],
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause>
  nextInstallmentDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'nextInstallmentDate',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause>
  nextInstallmentDateEqualTo(DateTime? nextInstallmentDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'nextInstallmentDate',
          value: [nextInstallmentDate],
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause>
  nextInstallmentDateNotEqualTo(DateTime? nextInstallmentDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'nextInstallmentDate',
                lower: [],
                upper: [nextInstallmentDate],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'nextInstallmentDate',
                lower: [nextInstallmentDate],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'nextInstallmentDate',
                lower: [nextInstallmentDate],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'nextInstallmentDate',
                lower: [],
                upper: [nextInstallmentDate],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause>
  nextInstallmentDateGreaterThan(
    DateTime? nextInstallmentDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'nextInstallmentDate',
          lower: [nextInstallmentDate],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause>
  nextInstallmentDateLessThan(
    DateTime? nextInstallmentDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'nextInstallmentDate',
          lower: [],
          upper: [nextInstallmentDate],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterWhereClause>
  nextInstallmentDateBetween(
    DateTime? lowerNextInstallmentDate,
    DateTime? upperNextInstallmentDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'nextInstallmentDate',
          lower: [lowerNextInstallmentDate],
          includeLower: includeLower,
          upper: [upperNextInstallmentDate],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension DebtModelQueryFilter
    on QueryBuilder<DebtModel, DebtModel, QFilterCondition> {
  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  annualInterestRateEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'annualInterestRate',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  annualInterestRateGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'annualInterestRate',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  annualInterestRateLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'annualInterestRate',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  annualInterestRateBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'annualInterestRate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'category'),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  categoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'category'),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> categoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> categoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> categoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> categoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'category',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> categoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> categoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> categoryContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> categoryMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'category',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> createdAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'description'),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'description'),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'description',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  descriptionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> descriptionContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> descriptionMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'description',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> dueDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'dueDate'),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> dueDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'dueDate'),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> dueDateEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dueDate', value: value),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> dueDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dueDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> dueDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dueDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> dueDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dueDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> emiAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'emiAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  emiAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'emiAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> emiAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'emiAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> emiAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'emiAmount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  installmentDayOfMonthIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'installmentDayOfMonth'),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  installmentDayOfMonthIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'installmentDayOfMonth'),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  installmentDayOfMonthEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'installmentDayOfMonth',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  installmentDayOfMonthGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'installmentDayOfMonth',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  installmentDayOfMonthLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'installmentDayOfMonth',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  installmentDayOfMonthBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'installmentDayOfMonth',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> isEMIEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isEMI', value: value),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  nextInstallmentDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'nextInstallmentDate'),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  nextInstallmentDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'nextInstallmentDate'),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  nextInstallmentDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nextInstallmentDate', value: value),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  nextInstallmentDateGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nextInstallmentDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  nextInstallmentDateLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nextInstallmentDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  nextInstallmentDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nextInstallmentDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'note'),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'note'),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> noteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'note',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> noteContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> noteMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'note',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  originalAmountEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'originalAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  originalAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'originalAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  originalAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'originalAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  originalAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'originalAmount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  paidInstallmentsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'paidInstallments', value: value),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  paidInstallmentsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'paidInstallments',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  paidInstallmentsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'paidInstallments',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  paidInstallmentsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'paidInstallments',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> personNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'personName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  personNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'personName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> personNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'personName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> personNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'personName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  personNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'personName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> personNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'personName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> personNameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'personName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> personNameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'personName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  personNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'personName', value: ''),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  personNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'personName', value: ''),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  personPhoneIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'personPhone'),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  personPhoneIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'personPhone'),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> personPhoneEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'personPhone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  personPhoneGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'personPhone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> personPhoneLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'personPhone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> personPhoneBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'personPhone',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  personPhoneStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'personPhone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> personPhoneEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'personPhone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> personPhoneContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'personPhone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> personPhoneMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'personPhone',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  personPhoneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'personPhone', value: ''),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  personPhoneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'personPhone', value: ''),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  remainingAmountEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'remainingAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  remainingAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'remainingAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  remainingAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'remainingAmount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  remainingAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'remainingAmount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  reminderEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'reminderEnabled', value: value),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> settledAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'settledAt'),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  settledAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'settledAt'),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> settledAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'settledAt', value: value),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  settledAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'settledAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> settledAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'settledAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> settledAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'settledAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> statusEqualTo(
    DebtStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: value),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> statusGreaterThan(
    DebtStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> statusLessThan(
    DebtStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> statusBetween(
    DebtStatus lower,
    DebtStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  totalInstallmentsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'totalInstallments', value: value),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  totalInstallmentsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalInstallments',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  totalInstallmentsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalInstallments',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  totalInstallmentsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalInstallments',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> typeEqualTo(
    DebtType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: value),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> typeGreaterThan(
    DebtType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> typeLessThan(
    DebtType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> typeBetween(
    DebtType lower,
    DebtType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> walletIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'walletId'),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition>
  walletIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'walletId'),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> walletIdEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'walletId', value: value),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> walletIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'walletId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> walletIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'walletId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterFilterCondition> walletIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'walletId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension DebtModelQueryObject
    on QueryBuilder<DebtModel, DebtModel, QFilterCondition> {}

extension DebtModelQueryLinks
    on QueryBuilder<DebtModel, DebtModel, QFilterCondition> {}

extension DebtModelQuerySortBy on QueryBuilder<DebtModel, DebtModel, QSortBy> {
  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByAnnualInterestRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'annualInterestRate', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
  sortByAnnualInterestRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'annualInterestRate', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByEmiAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emiAmount', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByEmiAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emiAmount', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
  sortByInstallmentDayOfMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installmentDayOfMonth', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
  sortByInstallmentDayOfMonthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installmentDayOfMonth', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByIsEMI() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEMI', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByIsEMIDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEMI', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByNextInstallmentDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextInstallmentDate', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
  sortByNextInstallmentDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextInstallmentDate', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByOriginalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalAmount', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByOriginalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalAmount', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByPaidInstallments() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidInstallments', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
  sortByPaidInstallmentsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidInstallments', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByPersonName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personName', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByPersonNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personName', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByPersonPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personPhone', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByPersonPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personPhone', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByRemainingAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingAmount', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByRemainingAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingAmount', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByReminderEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderEnabled', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByReminderEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderEnabled', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortBySettledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settledAt', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortBySettledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settledAt', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByTotalInstallments() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalInstallments', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
  sortByTotalInstallmentsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalInstallments', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> sortByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension DebtModelQuerySortThenBy
    on QueryBuilder<DebtModel, DebtModel, QSortThenBy> {
  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByAnnualInterestRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'annualInterestRate', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
  thenByAnnualInterestRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'annualInterestRate', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByEmiAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emiAmount', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByEmiAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emiAmount', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
  thenByInstallmentDayOfMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installmentDayOfMonth', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
  thenByInstallmentDayOfMonthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installmentDayOfMonth', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByIsEMI() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEMI', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByIsEMIDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEMI', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByNextInstallmentDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextInstallmentDate', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
  thenByNextInstallmentDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextInstallmentDate', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByOriginalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalAmount', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByOriginalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalAmount', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByPaidInstallments() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidInstallments', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
  thenByPaidInstallmentsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidInstallments', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByPersonName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personName', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByPersonNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personName', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByPersonPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personPhone', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByPersonPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personPhone', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByRemainingAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingAmount', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByRemainingAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingAmount', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByReminderEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderEnabled', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByReminderEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderEnabled', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenBySettledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settledAt', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenBySettledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settledAt', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByTotalInstallments() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalInstallments', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy>
  thenByTotalInstallmentsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalInstallments', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QAfterSortBy> thenByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension DebtModelQueryWhereDistinct
    on QueryBuilder<DebtModel, DebtModel, QDistinct> {
  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByAnnualInterestRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'annualInterestRate');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByCategory({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByDescription({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dueDate');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByEmiAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'emiAmount');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct>
  distinctByInstallmentDayOfMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'installmentDayOfMonth');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByIsEMI() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isEMI');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct>
  distinctByNextInstallmentDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextInstallmentDate');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByNote({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByOriginalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'originalAmount');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByPaidInstallments() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paidInstallments');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByPersonName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'personName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByPersonPhone({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'personPhone', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByRemainingAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remainingAmount');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByReminderEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reminderEnabled');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctBySettledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'settledAt');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByTotalInstallments() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalInstallments');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }

  QueryBuilder<DebtModel, DebtModel, QDistinct> distinctByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walletId');
    });
  }
}

extension DebtModelQueryProperty
    on QueryBuilder<DebtModel, DebtModel, QQueryProperty> {
  QueryBuilder<DebtModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DebtModel, double, QQueryOperations>
  annualInterestRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'annualInterestRate');
    });
  }

  QueryBuilder<DebtModel, String?, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<DebtModel, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<DebtModel, String?, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<DebtModel, DateTime?, QQueryOperations> dueDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dueDate');
    });
  }

  QueryBuilder<DebtModel, double, QQueryOperations> emiAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'emiAmount');
    });
  }

  QueryBuilder<DebtModel, int?, QQueryOperations>
  installmentDayOfMonthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'installmentDayOfMonth');
    });
  }

  QueryBuilder<DebtModel, bool, QQueryOperations> isEMIProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isEMI');
    });
  }

  QueryBuilder<DebtModel, DateTime?, QQueryOperations>
  nextInstallmentDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextInstallmentDate');
    });
  }

  QueryBuilder<DebtModel, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<DebtModel, double, QQueryOperations> originalAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originalAmount');
    });
  }

  QueryBuilder<DebtModel, int, QQueryOperations> paidInstallmentsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paidInstallments');
    });
  }

  QueryBuilder<DebtModel, String, QQueryOperations> personNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'personName');
    });
  }

  QueryBuilder<DebtModel, String?, QQueryOperations> personPhoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'personPhone');
    });
  }

  QueryBuilder<DebtModel, double, QQueryOperations> remainingAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remainingAmount');
    });
  }

  QueryBuilder<DebtModel, bool, QQueryOperations> reminderEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reminderEnabled');
    });
  }

  QueryBuilder<DebtModel, DateTime?, QQueryOperations> settledAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'settledAt');
    });
  }

  QueryBuilder<DebtModel, DebtStatus, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<DebtModel, int, QQueryOperations> totalInstallmentsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalInstallments');
    });
  }

  QueryBuilder<DebtModel, DebtType, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<DebtModel, int?, QQueryOperations> walletIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walletId');
    });
  }
}
