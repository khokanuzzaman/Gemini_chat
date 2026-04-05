// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_expense_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRecurringExpenseModelCollection on Isar {
  IsarCollection<RecurringExpenseModel> get recurringExpenseModels =>
      this.collection();
}

const RecurringExpenseModelSchema = CollectionSchema(
  name: r'RecurringExpenseModel',
  id: 6832131763582375165,
  properties: {
    r'averageAmount': PropertySchema(
      id: 0,
      name: r'averageAmount',
      type: IsarType.double,
    ),
    r'category': PropertySchema(
      id: 1,
      name: r'category',
      type: IsarType.string,
    ),
    r'dayOfMonth': PropertySchema(
      id: 2,
      name: r'dayOfMonth',
      type: IsarType.long,
    ),
    r'dayOfWeek': PropertySchema(
      id: 3,
      name: r'dayOfWeek',
      type: IsarType.long,
    ),
    r'description': PropertySchema(
      id: 4,
      name: r'description',
      type: IsarType.string,
    ),
    r'frequency': PropertySchema(
      id: 5,
      name: r'frequency',
      type: IsarType.byte,
      enumMap: _RecurringExpenseModelfrequencyEnumValueMap,
    ),
    r'isActive': PropertySchema(id: 6, name: r'isActive', type: IsarType.bool),
    r'lastOccurrence': PropertySchema(
      id: 7,
      name: r'lastOccurrence',
      type: IsarType.dateTime,
    ),
    r'nextExpected': PropertySchema(
      id: 8,
      name: r'nextExpected',
      type: IsarType.dateTime,
    ),
    r'reminderEnabled': PropertySchema(
      id: 9,
      name: r'reminderEnabled',
      type: IsarType.bool,
    ),
  },
  estimateSize: _recurringExpenseModelEstimateSize,
  serialize: _recurringExpenseModelSerialize,
  deserialize: _recurringExpenseModelDeserialize,
  deserializeProp: _recurringExpenseModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _recurringExpenseModelGetId,
  getLinks: _recurringExpenseModelGetLinks,
  attach: _recurringExpenseModelAttach,
  version: '3.1.0+1',
);

int _recurringExpenseModelEstimateSize(
  RecurringExpenseModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.category.length * 3;
  bytesCount += 3 + object.description.length * 3;
  return bytesCount;
}

void _recurringExpenseModelSerialize(
  RecurringExpenseModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.averageAmount);
  writer.writeString(offsets[1], object.category);
  writer.writeLong(offsets[2], object.dayOfMonth);
  writer.writeLong(offsets[3], object.dayOfWeek);
  writer.writeString(offsets[4], object.description);
  writer.writeByte(offsets[5], object.frequency.index);
  writer.writeBool(offsets[6], object.isActive);
  writer.writeDateTime(offsets[7], object.lastOccurrence);
  writer.writeDateTime(offsets[8], object.nextExpected);
  writer.writeBool(offsets[9], object.reminderEnabled);
}

RecurringExpenseModel _recurringExpenseModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RecurringExpenseModel();
  object.averageAmount = reader.readDouble(offsets[0]);
  object.category = reader.readString(offsets[1]);
  object.dayOfMonth = reader.readLong(offsets[2]);
  object.dayOfWeek = reader.readLong(offsets[3]);
  object.description = reader.readString(offsets[4]);
  object.frequency =
      _RecurringExpenseModelfrequencyValueEnumMap[reader.readByteOrNull(
        offsets[5],
      )] ??
      RecurringFrequency.daily;
  object.id = id;
  object.isActive = reader.readBool(offsets[6]);
  object.lastOccurrence = reader.readDateTime(offsets[7]);
  object.nextExpected = reader.readDateTimeOrNull(offsets[8]);
  object.reminderEnabled = reader.readBool(offsets[9]);
  return object;
}

P _recurringExpenseModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (_RecurringExpenseModelfrequencyValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              RecurringFrequency.daily)
          as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _RecurringExpenseModelfrequencyEnumValueMap = {
  'daily': 0,
  'weekly': 1,
  'monthly': 2,
};
const _RecurringExpenseModelfrequencyValueEnumMap = {
  0: RecurringFrequency.daily,
  1: RecurringFrequency.weekly,
  2: RecurringFrequency.monthly,
};

Id _recurringExpenseModelGetId(RecurringExpenseModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _recurringExpenseModelGetLinks(
  RecurringExpenseModel object,
) {
  return [];
}

void _recurringExpenseModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  RecurringExpenseModel object,
) {
  object.id = id;
}

extension RecurringExpenseModelQueryWhereSort
    on QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QWhere> {
  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RecurringExpenseModelQueryWhere
    on
        QueryBuilder<
          RecurringExpenseModel,
          RecurringExpenseModel,
          QWhereClause
        > {
  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterWhereClause>
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

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterWhereClause>
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
}

extension RecurringExpenseModelQueryFilter
    on
        QueryBuilder<
          RecurringExpenseModel,
          RecurringExpenseModel,
          QFilterCondition
        > {
  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  averageAmountEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'averageAmount',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  averageAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'averageAmount',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  averageAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'averageAmount',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  averageAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'averageAmount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  categoryEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  categoryGreaterThan(
    String value, {
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

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  categoryLessThan(
    String value, {
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

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  categoryBetween(
    String lower,
    String upper, {
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

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  categoryStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  categoryEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  categoryContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  categoryMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  dayOfMonthEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dayOfMonth', value: value),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  dayOfMonthGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dayOfMonth',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  dayOfMonthLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dayOfMonth',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  dayOfMonthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dayOfMonth',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  dayOfWeekEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dayOfWeek', value: value),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  dayOfWeekGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dayOfWeek',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  dayOfWeekLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dayOfWeek',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  dayOfWeekBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dayOfWeek',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  descriptionEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  descriptionGreaterThan(
    String value, {
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

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  descriptionLessThan(
    String value, {
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

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  descriptionBetween(
    String lower,
    String upper, {
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

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  descriptionEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  descriptionContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  descriptionMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  frequencyEqualTo(RecurringFrequency value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'frequency', value: value),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  frequencyGreaterThan(RecurringFrequency value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'frequency',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  frequencyLessThan(RecurringFrequency value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'frequency',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  frequencyBetween(
    RecurringFrequency lower,
    RecurringFrequency upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'frequency',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
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
    RecurringExpenseModel,
    RecurringExpenseModel,
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
    RecurringExpenseModel,
    RecurringExpenseModel,
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
    RecurringExpenseModel,
    RecurringExpenseModel,
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
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isActive', value: value),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  lastOccurrenceEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastOccurrence', value: value),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  lastOccurrenceGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastOccurrence',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  lastOccurrenceLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastOccurrence',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  lastOccurrenceBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastOccurrence',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  nextExpectedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'nextExpected'),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  nextExpectedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'nextExpected'),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  nextExpectedEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nextExpected', value: value),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  nextExpectedGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nextExpected',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  nextExpectedLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nextExpected',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  nextExpectedBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nextExpected',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringExpenseModel,
    RecurringExpenseModel,
    QAfterFilterCondition
  >
  reminderEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'reminderEnabled', value: value),
      );
    });
  }
}

extension RecurringExpenseModelQueryObject
    on
        QueryBuilder<
          RecurringExpenseModel,
          RecurringExpenseModel,
          QFilterCondition
        > {}

extension RecurringExpenseModelQueryLinks
    on
        QueryBuilder<
          RecurringExpenseModel,
          RecurringExpenseModel,
          QFilterCondition
        > {}

extension RecurringExpenseModelQuerySortBy
    on QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QSortBy> {
  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByAverageAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageAmount', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByAverageAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageAmount', Sort.desc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByDayOfMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfMonth', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByDayOfMonthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfMonth', Sort.desc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByDayOfWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByDayOfWeekDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.desc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByFrequencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.desc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByLastOccurrence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOccurrence', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByLastOccurrenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOccurrence', Sort.desc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByNextExpected() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextExpected', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByNextExpectedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextExpected', Sort.desc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByReminderEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderEnabled', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  sortByReminderEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderEnabled', Sort.desc);
    });
  }
}

extension RecurringExpenseModelQuerySortThenBy
    on QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QSortThenBy> {
  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByAverageAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageAmount', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByAverageAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageAmount', Sort.desc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByDayOfMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfMonth', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByDayOfMonthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfMonth', Sort.desc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByDayOfWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByDayOfWeekDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.desc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByFrequencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.desc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByLastOccurrence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOccurrence', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByLastOccurrenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOccurrence', Sort.desc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByNextExpected() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextExpected', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByNextExpectedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextExpected', Sort.desc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByReminderEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderEnabled', Sort.asc);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QAfterSortBy>
  thenByReminderEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderEnabled', Sort.desc);
    });
  }
}

extension RecurringExpenseModelQueryWhereDistinct
    on QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QDistinct> {
  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QDistinct>
  distinctByAverageAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'averageAmount');
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QDistinct>
  distinctByCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QDistinct>
  distinctByDayOfMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dayOfMonth');
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QDistinct>
  distinctByDayOfWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dayOfWeek');
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QDistinct>
  distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QDistinct>
  distinctByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'frequency');
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QDistinct>
  distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QDistinct>
  distinctByLastOccurrence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastOccurrence');
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QDistinct>
  distinctByNextExpected() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextExpected');
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringExpenseModel, QDistinct>
  distinctByReminderEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reminderEnabled');
    });
  }
}

extension RecurringExpenseModelQueryProperty
    on
        QueryBuilder<
          RecurringExpenseModel,
          RecurringExpenseModel,
          QQueryProperty
        > {
  QueryBuilder<RecurringExpenseModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RecurringExpenseModel, double, QQueryOperations>
  averageAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'averageAmount');
    });
  }

  QueryBuilder<RecurringExpenseModel, String, QQueryOperations>
  categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<RecurringExpenseModel, int, QQueryOperations>
  dayOfMonthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayOfMonth');
    });
  }

  QueryBuilder<RecurringExpenseModel, int, QQueryOperations>
  dayOfWeekProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayOfWeek');
    });
  }

  QueryBuilder<RecurringExpenseModel, String, QQueryOperations>
  descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<RecurringExpenseModel, RecurringFrequency, QQueryOperations>
  frequencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'frequency');
    });
  }

  QueryBuilder<RecurringExpenseModel, bool, QQueryOperations>
  isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<RecurringExpenseModel, DateTime, QQueryOperations>
  lastOccurrenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastOccurrence');
    });
  }

  QueryBuilder<RecurringExpenseModel, DateTime?, QQueryOperations>
  nextExpectedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextExpected');
    });
  }

  QueryBuilder<RecurringExpenseModel, bool, QQueryOperations>
  reminderEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reminderEnabled');
    });
  }
}
