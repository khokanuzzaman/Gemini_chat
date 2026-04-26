// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_payment_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDebtPaymentModelCollection on Isar {
  IsarCollection<DebtPaymentModel> get debtPaymentModels => this.collection();
}

const DebtPaymentModelSchema = CollectionSchema(
  name: r'DebtPaymentModel',
  id: -8165019702810419063,
  properties: {
    r'amount': PropertySchema(id: 0, name: r'amount', type: IsarType.double),
    r'debtId': PropertySchema(id: 1, name: r'debtId', type: IsarType.long),
    r'installmentNumber': PropertySchema(
      id: 2,
      name: r'installmentNumber',
      type: IsarType.long,
    ),
    r'isInstallment': PropertySchema(
      id: 3,
      name: r'isInstallment',
      type: IsarType.bool,
    ),
    r'note': PropertySchema(id: 4, name: r'note', type: IsarType.string),
    r'paidAt': PropertySchema(id: 5, name: r'paidAt', type: IsarType.dateTime),
    r'walletId': PropertySchema(id: 6, name: r'walletId', type: IsarType.long),
  },

  estimateSize: _debtPaymentModelEstimateSize,
  serialize: _debtPaymentModelSerialize,
  deserialize: _debtPaymentModelDeserialize,
  deserializeProp: _debtPaymentModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'debtId': IndexSchema(
      id: 7945793207552902711,
      name: r'debtId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'debtId',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'paidAt': IndexSchema(
      id: -701685063105958775,
      name: r'paidAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'paidAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _debtPaymentModelGetId,
  getLinks: _debtPaymentModelGetLinks,
  attach: _debtPaymentModelAttach,
  version: '3.3.2',
);

int _debtPaymentModelEstimateSize(
  DebtPaymentModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _debtPaymentModelSerialize(
  DebtPaymentModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.amount);
  writer.writeLong(offsets[1], object.debtId);
  writer.writeLong(offsets[2], object.installmentNumber);
  writer.writeBool(offsets[3], object.isInstallment);
  writer.writeString(offsets[4], object.note);
  writer.writeDateTime(offsets[5], object.paidAt);
  writer.writeLong(offsets[6], object.walletId);
}

DebtPaymentModel _debtPaymentModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DebtPaymentModel();
  object.amount = reader.readDouble(offsets[0]);
  object.debtId = reader.readLong(offsets[1]);
  object.id = id;
  object.installmentNumber = reader.readLongOrNull(offsets[2]);
  object.isInstallment = reader.readBool(offsets[3]);
  object.note = reader.readStringOrNull(offsets[4]);
  object.paidAt = reader.readDateTime(offsets[5]);
  object.walletId = reader.readLongOrNull(offsets[6]);
  return object;
}

P _debtPaymentModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _debtPaymentModelGetId(DebtPaymentModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _debtPaymentModelGetLinks(DebtPaymentModel object) {
  return [];
}

void _debtPaymentModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  DebtPaymentModel object,
) {
  object.id = id;
}

extension DebtPaymentModelQueryWhereSort
    on QueryBuilder<DebtPaymentModel, DebtPaymentModel, QWhere> {
  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterWhere> anyDebtId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'debtId'),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterWhere> anyPaidAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'paidAt'),
      );
    });
  }
}

extension DebtPaymentModelQueryWhere
    on QueryBuilder<DebtPaymentModel, DebtPaymentModel, QWhereClause> {
  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterWhereClause>
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

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterWhereClause>
  debtIdEqualTo(int debtId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'debtId', value: [debtId]),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterWhereClause>
  debtIdNotEqualTo(int debtId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'debtId',
                lower: [],
                upper: [debtId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'debtId',
                lower: [debtId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'debtId',
                lower: [debtId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'debtId',
                lower: [],
                upper: [debtId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterWhereClause>
  debtIdGreaterThan(int debtId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'debtId',
          lower: [debtId],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterWhereClause>
  debtIdLessThan(int debtId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'debtId',
          lower: [],
          upper: [debtId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterWhereClause>
  debtIdBetween(
    int lowerDebtId,
    int upperDebtId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'debtId',
          lower: [lowerDebtId],
          includeLower: includeLower,
          upper: [upperDebtId],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterWhereClause>
  paidAtEqualTo(DateTime paidAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'paidAt', value: [paidAt]),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterWhereClause>
  paidAtNotEqualTo(DateTime paidAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'paidAt',
                lower: [],
                upper: [paidAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'paidAt',
                lower: [paidAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'paidAt',
                lower: [paidAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'paidAt',
                lower: [],
                upper: [paidAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterWhereClause>
  paidAtGreaterThan(DateTime paidAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'paidAt',
          lower: [paidAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterWhereClause>
  paidAtLessThan(DateTime paidAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'paidAt',
          lower: [],
          upper: [paidAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterWhereClause>
  paidAtBetween(
    DateTime lowerPaidAt,
    DateTime upperPaidAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'paidAt',
          lower: [lowerPaidAt],
          includeLower: includeLower,
          upper: [upperPaidAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension DebtPaymentModelQueryFilter
    on QueryBuilder<DebtPaymentModel, DebtPaymentModel, QFilterCondition> {
  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  amountEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'amount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'amount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'amount',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'amount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  debtIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'debtId', value: value),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  debtIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'debtId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  debtIdLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'debtId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  debtIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'debtId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
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

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
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

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
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

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  installmentNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'installmentNumber'),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  installmentNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'installmentNumber'),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  installmentNumberEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'installmentNumber', value: value),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  installmentNumberGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'installmentNumber',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  installmentNumberLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'installmentNumber',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  installmentNumberBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'installmentNumber',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  isInstallmentEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isInstallment', value: value),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'note'),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'note'),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  noteEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  noteGreaterThan(
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

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  noteLessThan(
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

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  noteBetween(
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

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  noteStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  noteEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  noteContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  noteMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  paidAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'paidAt', value: value),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  paidAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'paidAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  paidAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'paidAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  paidAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'paidAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  walletIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'walletId'),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  walletIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'walletId'),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  walletIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'walletId', value: value),
      );
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  walletIdGreaterThan(int? value, {bool include = false}) {
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

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  walletIdLessThan(int? value, {bool include = false}) {
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

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterFilterCondition>
  walletIdBetween(
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

extension DebtPaymentModelQueryObject
    on QueryBuilder<DebtPaymentModel, DebtPaymentModel, QFilterCondition> {}

extension DebtPaymentModelQueryLinks
    on QueryBuilder<DebtPaymentModel, DebtPaymentModel, QFilterCondition> {}

extension DebtPaymentModelQuerySortBy
    on QueryBuilder<DebtPaymentModel, DebtPaymentModel, QSortBy> {
  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  sortByDebtId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'debtId', Sort.asc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  sortByDebtIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'debtId', Sort.desc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  sortByInstallmentNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installmentNumber', Sort.asc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  sortByInstallmentNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installmentNumber', Sort.desc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  sortByIsInstallment() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInstallment', Sort.asc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  sortByIsInstallmentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInstallment', Sort.desc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  sortByPaidAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAt', Sort.asc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  sortByPaidAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAt', Sort.desc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  sortByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  sortByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension DebtPaymentModelQuerySortThenBy
    on QueryBuilder<DebtPaymentModel, DebtPaymentModel, QSortThenBy> {
  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  thenByDebtId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'debtId', Sort.asc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  thenByDebtIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'debtId', Sort.desc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  thenByInstallmentNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installmentNumber', Sort.asc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  thenByInstallmentNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installmentNumber', Sort.desc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  thenByIsInstallment() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInstallment', Sort.asc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  thenByIsInstallmentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInstallment', Sort.desc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  thenByPaidAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAt', Sort.asc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  thenByPaidAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAt', Sort.desc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  thenByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QAfterSortBy>
  thenByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension DebtPaymentModelQueryWhereDistinct
    on QueryBuilder<DebtPaymentModel, DebtPaymentModel, QDistinct> {
  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QDistinct>
  distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QDistinct>
  distinctByDebtId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'debtId');
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QDistinct>
  distinctByInstallmentNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'installmentNumber');
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QDistinct>
  distinctByIsInstallment() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isInstallment');
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QDistinct> distinctByNote({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QDistinct>
  distinctByPaidAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paidAt');
    });
  }

  QueryBuilder<DebtPaymentModel, DebtPaymentModel, QDistinct>
  distinctByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walletId');
    });
  }
}

extension DebtPaymentModelQueryProperty
    on QueryBuilder<DebtPaymentModel, DebtPaymentModel, QQueryProperty> {
  QueryBuilder<DebtPaymentModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DebtPaymentModel, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<DebtPaymentModel, int, QQueryOperations> debtIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'debtId');
    });
  }

  QueryBuilder<DebtPaymentModel, int?, QQueryOperations>
  installmentNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'installmentNumber');
    });
  }

  QueryBuilder<DebtPaymentModel, bool, QQueryOperations>
  isInstallmentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isInstallment');
    });
  }

  QueryBuilder<DebtPaymentModel, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<DebtPaymentModel, DateTime, QQueryOperations> paidAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paidAt');
    });
  }

  QueryBuilder<DebtPaymentModel, int?, QQueryOperations> walletIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walletId');
    });
  }
}
