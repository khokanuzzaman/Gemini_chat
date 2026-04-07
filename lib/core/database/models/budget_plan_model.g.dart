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
    r'aiExplanation': PropertySchema(
      id: 0,
      name: r'aiExplanation',
      type: IsarType.string,
    ),
    r'budgetRule': PropertySchema(
      id: 1,
      name: r'budgetRule',
      type: IsarType.string,
    ),
    r'categoryBudgetsJson': PropertySchema(
      id: 2,
      name: r'categoryBudgetsJson',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'isActive': PropertySchema(
      id: 4,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'monthlyIncome': PropertySchema(
      id: 5,
      name: r'monthlyIncome',
      type: IsarType.double,
    ),
    r'savingsAmount': PropertySchema(
      id: 6,
      name: r'savingsAmount',
      type: IsarType.double,
    ),
    r'savingsPercentage': PropertySchema(
      id: 7,
      name: r'savingsPercentage',
      type: IsarType.double,
    ),
    r'totalBudgeted': PropertySchema(
      id: 8,
      name: r'totalBudgeted',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 9,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
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
  bytesCount += 3 + object.aiExplanation.length * 3;
  bytesCount += 3 + object.budgetRule.length * 3;
  bytesCount += 3 + object.categoryBudgetsJson.length * 3;
  return bytesCount;
}

void _budgetPlanModelSerialize(
  BudgetPlanModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.aiExplanation);
  writer.writeString(offsets[1], object.budgetRule);
  writer.writeString(offsets[2], object.categoryBudgetsJson);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeBool(offsets[4], object.isActive);
  writer.writeDouble(offsets[5], object.monthlyIncome);
  writer.writeDouble(offsets[6], object.savingsAmount);
  writer.writeDouble(offsets[7], object.savingsPercentage);
  writer.writeDouble(offsets[8], object.totalBudgeted);
  writer.writeDateTime(offsets[9], object.updatedAt);
}

BudgetPlanModel _budgetPlanModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BudgetPlanModel();
  object.aiExplanation = reader.readString(offsets[0]);
  object.budgetRule = reader.readString(offsets[1]);
  object.categoryBudgetsJson = reader.readString(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.id = id;
  object.isActive = reader.readBool(offsets[4]);
  object.monthlyIncome = reader.readDouble(offsets[5]);
  object.savingsAmount = reader.readDouble(offsets[6]);
  object.savingsPercentage = reader.readDouble(offsets[7]);
  object.totalBudgeted = reader.readDouble(offsets[8]);
  object.updatedAt = reader.readDateTime(offsets[9]);
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
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readDouble(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
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
    IsarCollection<dynamic> col, Id id, BudgetPlanModel object) {
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
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
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
      Id id,
      {bool include = false}) {
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
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension BudgetPlanModelQueryFilter
    on QueryBuilder<BudgetPlanModel, BudgetPlanModel, QFilterCondition> {
  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      aiExplanationEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiExplanation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      aiExplanationGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'aiExplanation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      aiExplanationLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'aiExplanation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      aiExplanationBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'aiExplanation',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      aiExplanationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'aiExplanation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      aiExplanationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'aiExplanation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      aiExplanationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'aiExplanation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      aiExplanationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'aiExplanation',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      aiExplanationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiExplanation',
        value: '',
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      aiExplanationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'aiExplanation',
        value: '',
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      budgetRuleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'budgetRule',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      budgetRuleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'budgetRule',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      budgetRuleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'budgetRule',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      budgetRuleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'budgetRule',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      budgetRuleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'budgetRule',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      budgetRuleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'budgetRule',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      budgetRuleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'budgetRule',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      budgetRuleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'budgetRule',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      budgetRuleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'budgetRule',
        value: '',
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      budgetRuleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'budgetRule',
        value: '',
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      categoryBudgetsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryBudgetsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      categoryBudgetsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryBudgetsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      categoryBudgetsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryBudgetsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      categoryBudgetsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryBudgetsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      categoryBudgetsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryBudgetsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      categoryBudgetsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryBudgetsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      categoryBudgetsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryBudgetsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      categoryBudgetsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryBudgetsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      categoryBudgetsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryBudgetsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      categoryBudgetsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryBudgetsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
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
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
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
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      monthlyIncomeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'monthlyIncome',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      monthlyIncomeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'monthlyIncome',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      monthlyIncomeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'monthlyIncome',
        value: value,
        epsilon: epsilon,
      ));
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
      return query.addFilterCondition(FilterCondition.between(
        property: r'monthlyIncome',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      savingsAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'savingsAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      savingsAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'savingsAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      savingsAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'savingsAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      savingsAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'savingsAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      savingsPercentageEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'savingsPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      savingsPercentageGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'savingsPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      savingsPercentageLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'savingsPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      savingsPercentageBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'savingsPercentage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      totalBudgetedEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalBudgeted',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      totalBudgetedGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalBudgeted',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      totalBudgetedLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalBudgeted',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      totalBudgetedBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalBudgeted',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
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
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
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
      sortByAiExplanation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiExplanation', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      sortByAiExplanationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiExplanation', Sort.desc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      sortByBudgetRule() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budgetRule', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      sortByBudgetRuleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budgetRule', Sort.desc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      sortByCategoryBudgetsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryBudgetsJson', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      sortByCategoryBudgetsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryBudgetsJson', Sort.desc);
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
      sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
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
      sortBySavingsAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savingsAmount', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      sortBySavingsAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savingsAmount', Sort.desc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      sortBySavingsPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savingsPercentage', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      sortBySavingsPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savingsPercentage', Sort.desc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      sortByTotalBudgeted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalBudgeted', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      sortByTotalBudgetedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalBudgeted', Sort.desc);
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
      thenByAiExplanation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiExplanation', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      thenByAiExplanationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiExplanation', Sort.desc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      thenByBudgetRule() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budgetRule', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      thenByBudgetRuleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budgetRule', Sort.desc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      thenByCategoryBudgetsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryBudgetsJson', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      thenByCategoryBudgetsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryBudgetsJson', Sort.desc);
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
      thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
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
      thenBySavingsAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savingsAmount', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      thenBySavingsAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savingsAmount', Sort.desc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      thenBySavingsPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savingsPercentage', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      thenBySavingsPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savingsPercentage', Sort.desc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      thenByTotalBudgeted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalBudgeted', Sort.asc);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QAfterSortBy>
      thenByTotalBudgetedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalBudgeted', Sort.desc);
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
      distinctByAiExplanation({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aiExplanation',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QDistinct>
      distinctByBudgetRule({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'budgetRule', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QDistinct>
      distinctByCategoryBudgetsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryBudgetsJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QDistinct>
      distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QDistinct>
      distinctByMonthlyIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'monthlyIncome');
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QDistinct>
      distinctBySavingsAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'savingsAmount');
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QDistinct>
      distinctBySavingsPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'savingsPercentage');
    });
  }

  QueryBuilder<BudgetPlanModel, BudgetPlanModel, QDistinct>
      distinctByTotalBudgeted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalBudgeted');
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
      aiExplanationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aiExplanation');
    });
  }

  QueryBuilder<BudgetPlanModel, String, QQueryOperations> budgetRuleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'budgetRule');
    });
  }

  QueryBuilder<BudgetPlanModel, String, QQueryOperations>
      categoryBudgetsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryBudgetsJson');
    });
  }

  QueryBuilder<BudgetPlanModel, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<BudgetPlanModel, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<BudgetPlanModel, double, QQueryOperations>
      monthlyIncomeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'monthlyIncome');
    });
  }

  QueryBuilder<BudgetPlanModel, double, QQueryOperations>
      savingsAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'savingsAmount');
    });
  }

  QueryBuilder<BudgetPlanModel, double, QQueryOperations>
      savingsPercentageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'savingsPercentage');
    });
  }

  QueryBuilder<BudgetPlanModel, double, QQueryOperations>
      totalBudgetedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalBudgeted');
    });
  }

  QueryBuilder<BudgetPlanModel, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
