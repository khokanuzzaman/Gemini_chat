// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_plan_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBudgetPlanModelCollection on Isar {
  IsarCollection<BudgetPlanModel> get budgetPlanModels => this.collection();
}

const BudgetPlanModelSchema = CollectionSchema(
  name: r'BudgetPlanModel',
  id: -5796088655154344446,
  properties: {
    r'aiSuggestion': PropertySchema(
      id: 0,
      name: r'aiSuggestion',
      type: IsarType.string,
    ),
    r'categoryAmounts': PropertySchema(
      id: 1,
      name: r'categoryAmounts',
      type: IsarType.doubleList,
    ),
    r'categoryNames': PropertySchema(
      id: 2,
      name: r'categoryNames',
      type: IsarType.stringList,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'monthlyIncome': PropertySchema(
      id: 4,
      name: r'monthlyIncome',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 5,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },
  estimateSize: _budgetPlanModelEstimateSize,
  serialize: _budgetPlanModelSerialize,
  deserialize: _budgetPlanModelDeserialize,
  deserializeProp: _budgetPlanModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _budgetPlanModelGetId,
  getLinks: _budgetPlanModelGetLinks,
  attach: _budgetPlanModelAttach,
  version: '3.1.0+1',
);

int _budgetPlanModelEstimateSize(
  BudgetPlanModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.aiSuggestion.length * 3;
  bytesCount += 3 + object.categoryAmounts.length * 8;
  bytesCount += 3 + object.categoryNames.length * 3;
  {
    for (var i = 0; i < object.categoryNames.length; i++) {
      final value = object.categoryNames[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _budgetPlanModelSerialize(
  BudgetPlanModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.aiSuggestion);
  writer.writeDoubleList(offsets[1], object.categoryAmounts);
  writer.writeStringList(offsets[2], object.categoryNames);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeDouble(offsets[4], object.monthlyIncome);
  writer.writeDateTime(offsets[5], object.updatedAt);
}

BudgetPlanModel _budgetPlanModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BudgetPlanModel();
  object.aiSuggestion = reader.readString(offsets[0]);
  object.categoryAmounts = reader.readDoubleList(offsets[1]) ?? [];
  object.categoryNames = reader.readStringList(offsets[2]) ?? [];
  object.createdAt = reader.readDateTime(offsets[3]);
  object.id = id;
  object.monthlyIncome = reader.readDouble(offsets[4]);
  object.updatedAt = reader.readDateTime(offsets[5]);
  return object;
}

P _budgetPlanModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDoubleList(offset) ?? []) as P;
    case 2:
      return (reader.readStringList(offset) ?? []) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _budgetPlanModelGetId(BudgetPlanModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _budgetPlanModelGetLinks(BudgetPlanModel object) {
  return [];
}

void _budgetPlanModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  BudgetPlanModel object,
) {
  object.id = id;
}

extension BudgetPlanModelQueryWhereSort
    on QueryBuilder<BudgetPlanModel, BudgetPlanModel, QWhere> {
  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BudgetPlanModelQueryWhere
    on QueryBuilder<BudgetPlanModel, BudgetPlanModel, QWhereClause> {
  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterWhereClause>
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

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterWhereClause> idBetween(
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

extension BudgetPlanModelQueryFilter
    on QueryBuilder<BudgetPlanModel, BudgetPlanModel, QFilterCondition> {
  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  aiSuggestionEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'aiSuggestion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  aiSuggestionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'aiSuggestion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  aiSuggestionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'aiSuggestion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  aiSuggestionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'aiSuggestion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  aiSuggestionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'aiSuggestion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  aiSuggestionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'aiSuggestion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  aiSuggestionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'aiSuggestion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  aiSuggestionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'aiSuggestion',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  aiSuggestionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'aiSuggestion', value: ''),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  aiSuggestionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'aiSuggestion', value: ''),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryAmountsElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'categoryAmounts',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryAmountsElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'categoryAmounts',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryAmountsElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'categoryAmounts',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryAmountsElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'categoryAmounts',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryAmountsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'categoryAmounts', length, true, length, true);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryAmountsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'categoryAmounts', 0, true, 0, true);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryAmountsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'categoryAmounts', 0, false, 999999, true);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryAmountsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'categoryAmounts', 0, true, length, include);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryAmountsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'categoryAmounts',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryAmountsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'categoryAmounts',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryNamesElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'categoryNames',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryNamesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'categoryNames',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryNamesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'categoryNames',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryNamesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'categoryNames',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryNamesElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'categoryNames',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryNamesElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'categoryNames',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryNamesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'categoryNames',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryNamesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'categoryNames',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryNamesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'categoryNames', value: ''),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryNamesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'categoryNames', value: ''),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryNamesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'categoryNames', length, true, length, true);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryNamesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'categoryNames', 0, true, 0, true);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryNamesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'categoryNames', 0, false, 999999, true);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryNamesLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'categoryNames', 0, true, length, include);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryNamesLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'categoryNames', length, include, 999999, true);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  categoryNamesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'categoryNames',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
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

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
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

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
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

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
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

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
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

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
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

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  monthlyIncomeEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'monthlyIncome',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  monthlyIncomeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'monthlyIncome',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  monthlyIncomeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'monthlyIncome',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  monthlyIncomeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'monthlyIncome',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
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

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
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

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
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

extension BudgetPlanModelQueryObject
    on QueryBuilder<BudgetPlanModel, BudgetPlanModel, QFilterCondition> {}

extension BudgetPlanModelQueryLinks
    on QueryBuilder<BudgetPlanModel, BudgetPlanModel, QFilterCondition> {}

extension BudgetPlanModelQuerySortBy
    on QueryBuilder<BudgetPlanModel, BudgetPlanModel, QSortBy> {
  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
  sortByAiSuggestion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiSuggestion', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
  sortByAiSuggestionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiSuggestion', Sort.desc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
  sortByMonthlyIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyIncome', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
  sortByMonthlyIncomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyIncome', Sort.desc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension BudgetPlanModelQuerySortThenBy
    on QueryBuilder<BudgetPlanModel, BudgetPlanModel, QSortThenBy> {
  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
  thenByAiSuggestion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiSuggestion', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
  thenByAiSuggestionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiSuggestion', Sort.desc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
  thenByMonthlyIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyIncome', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
  thenByMonthlyIncomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyIncome', Sort.desc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension BudgetPlanModelQueryWhereDistinct
    on QueryBuilder<BudgetPlanModel, BudgetPlanModel, QDistinct> {
  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QDistinct>
  distinctByAiSuggestion({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aiSuggestion', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QDistinct>
  distinctByCategoryAmounts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryAmounts');
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QDistinct>
  distinctByCategoryNames() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryNames');
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QDistinct>
  distinctByMonthlyIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'monthlyIncome');
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension BudgetPlanModelQueryProperty
    on QueryBuilder<BudgetPlanModel, BudgetPlanModel, QQueryProperty> {
  QueryBuilder<BudgetPlanModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BudgetPlanModel, String, QQueryOperations>
  aiSuggestionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aiSuggestion');
    });
  }

  QueryBuilder<BudgetPlanModel, List<double>, QQueryOperations>
  categoryAmountsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryAmounts');
    });
  }

  QueryBuilder<BudgetPlanModel, List<String>, QQueryOperations>
  categoryNamesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryNames');
    });
  }

  QueryBuilder<BudgetPlanModel, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<BudgetPlanModel, double, QQueryOperations>
  monthlyIncomeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'monthlyIncome');
    });
  }

  QueryBuilder<BudgetPlanModel, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
