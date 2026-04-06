// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prediction_cache_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPredictionCacheModelCollection on Isar {
  IsarCollection<PredictionCacheModel> get predictionCacheModels =>
      this.collection();
}

const PredictionCacheModelSchema = CollectionSchema(
  name: r'PredictionCacheModel',
  id: 6419492953542884426,
  properties: {
    r'aiInsight': PropertySchema(
      id: 0,
      name: r'aiInsight',
      type: IsarType.string,
    ),
    r'categoryPredictionsJson': PropertySchema(
      id: 1,
      name: r'categoryPredictionsJson',
      type: IsarType.string,
    ),
    r'confidence': PropertySchema(
      id: 2,
      name: r'confidence',
      type: IsarType.string,
    ),
    r'currentDay': PropertySchema(
      id: 3,
      name: r'currentDay',
      type: IsarType.long,
    ),
    r'currentTotal': PropertySchema(
      id: 4,
      name: r'currentTotal',
      type: IsarType.double,
    ),
    r'dailyAverage': PropertySchema(
      id: 5,
      name: r'dailyAverage',
      type: IsarType.double,
    ),
    r'daysInMonth': PropertySchema(
      id: 6,
      name: r'daysInMonth',
      type: IsarType.long,
    ),
    r'daysRemaining': PropertySchema(
      id: 7,
      name: r'daysRemaining',
      type: IsarType.long,
    ),
    r'generatedAt': PropertySchema(
      id: 8,
      name: r'generatedAt',
      type: IsarType.dateTime,
    ),
    r'lastMonthTotal': PropertySchema(
      id: 9,
      name: r'lastMonthTotal',
      type: IsarType.double,
    ),
    r'predictedTotal': PropertySchema(
      id: 10,
      name: r'predictedTotal',
      type: IsarType.double,
    ),
    r'projectedDailyAverage': PropertySchema(
      id: 11,
      name: r'projectedDailyAverage',
      type: IsarType.double,
    ),
    r'trend': PropertySchema(
      id: 12,
      name: r'trend',
      type: IsarType.string,
    )
  },
  estimateSize: _predictionCacheModelEstimateSize,
  serialize: _predictionCacheModelSerialize,
  deserialize: _predictionCacheModelDeserialize,
  deserializeProp: _predictionCacheModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _predictionCacheModelGetId,
  getLinks: _predictionCacheModelGetLinks,
  attach: _predictionCacheModelAttach,
  version: '3.1.0+1',
);

int _predictionCacheModelEstimateSize(
  PredictionCacheModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.aiInsight.length * 3;
  bytesCount += 3 + object.categoryPredictionsJson.length * 3;
  bytesCount += 3 + object.confidence.length * 3;
  bytesCount += 3 + object.trend.length * 3;
  return bytesCount;
}

void _predictionCacheModelSerialize(
  PredictionCacheModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.aiInsight);
  writer.writeString(offsets[1], object.categoryPredictionsJson);
  writer.writeString(offsets[2], object.confidence);
  writer.writeLong(offsets[3], object.currentDay);
  writer.writeDouble(offsets[4], object.currentTotal);
  writer.writeDouble(offsets[5], object.dailyAverage);
  writer.writeLong(offsets[6], object.daysInMonth);
  writer.writeLong(offsets[7], object.daysRemaining);
  writer.writeDateTime(offsets[8], object.generatedAt);
  writer.writeDouble(offsets[9], object.lastMonthTotal);
  writer.writeDouble(offsets[10], object.predictedTotal);
  writer.writeDouble(offsets[11], object.projectedDailyAverage);
  writer.writeString(offsets[12], object.trend);
}

PredictionCacheModel _predictionCacheModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PredictionCacheModel();
  object.aiInsight = reader.readString(offsets[0]);
  object.categoryPredictionsJson = reader.readString(offsets[1]);
  object.confidence = reader.readString(offsets[2]);
  object.currentDay = reader.readLong(offsets[3]);
  object.currentTotal = reader.readDouble(offsets[4]);
  object.dailyAverage = reader.readDouble(offsets[5]);
  object.daysInMonth = reader.readLong(offsets[6]);
  object.daysRemaining = reader.readLong(offsets[7]);
  object.generatedAt = reader.readDateTime(offsets[8]);
  object.id = id;
  object.lastMonthTotal = reader.readDouble(offsets[9]);
  object.predictedTotal = reader.readDouble(offsets[10]);
  object.projectedDailyAverage = reader.readDouble(offsets[11]);
  object.trend = reader.readString(offsets[12]);
  return object;
}

P _predictionCacheModelDeserializeProp<P>(
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
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readDouble(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _predictionCacheModelGetId(PredictionCacheModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _predictionCacheModelGetLinks(
    PredictionCacheModel object) {
  return [];
}

void _predictionCacheModelAttach(
    IsarCollection<dynamic> col, Id id, PredictionCacheModel object) {
  object.id = id;
}

extension PredictionCacheModelQueryWhereSort
    on QueryBuilder<PredictionCacheModel, PredictionCacheModel, QWhere> {
  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PredictionCacheModelQueryWhere
    on QueryBuilder<PredictionCacheModel, PredictionCacheModel, QWhereClause> {
  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterWhereClause>
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

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterWhereClause>
      idBetween(
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

extension PredictionCacheModelQueryFilter on QueryBuilder<PredictionCacheModel,
    PredictionCacheModel, QFilterCondition> {
  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> aiInsightEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiInsight',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> aiInsightGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'aiInsight',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> aiInsightLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'aiInsight',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> aiInsightBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'aiInsight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> aiInsightStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'aiInsight',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> aiInsightEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'aiInsight',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
          QAfterFilterCondition>
      aiInsightContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'aiInsight',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
          QAfterFilterCondition>
      aiInsightMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'aiInsight',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> aiInsightIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiInsight',
        value: '',
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> aiInsightIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'aiInsight',
        value: '',
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> categoryPredictionsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryPredictionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> categoryPredictionsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryPredictionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> categoryPredictionsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryPredictionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> categoryPredictionsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryPredictionsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> categoryPredictionsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryPredictionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> categoryPredictionsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryPredictionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
          QAfterFilterCondition>
      categoryPredictionsJsonContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryPredictionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
          QAfterFilterCondition>
      categoryPredictionsJsonMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryPredictionsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> categoryPredictionsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryPredictionsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> categoryPredictionsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryPredictionsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> confidenceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'confidence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> confidenceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'confidence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> confidenceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'confidence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> confidenceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'confidence',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> confidenceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'confidence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> confidenceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'confidence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
          QAfterFilterCondition>
      confidenceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'confidence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
          QAfterFilterCondition>
      confidenceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'confidence',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> confidenceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'confidence',
        value: '',
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> confidenceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'confidence',
        value: '',
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> currentDayEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentDay',
        value: value,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> currentDayGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentDay',
        value: value,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> currentDayLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentDay',
        value: value,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> currentDayBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentDay',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> currentTotalEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> currentTotalGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> currentTotalLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> currentTotalBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentTotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> dailyAverageEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dailyAverage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> dailyAverageGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dailyAverage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> dailyAverageLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dailyAverage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> dailyAverageBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dailyAverage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> daysInMonthEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'daysInMonth',
        value: value,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> daysInMonthGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'daysInMonth',
        value: value,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> daysInMonthLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'daysInMonth',
        value: value,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> daysInMonthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'daysInMonth',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> daysRemainingEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'daysRemaining',
        value: value,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> daysRemainingGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'daysRemaining',
        value: value,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> daysRemainingLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'daysRemaining',
        value: value,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> daysRemainingBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'daysRemaining',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> generatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'generatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> generatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'generatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> generatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'generatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> generatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'generatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> lastMonthTotalEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMonthTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> lastMonthTotalGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastMonthTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> lastMonthTotalLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastMonthTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> lastMonthTotalBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastMonthTotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> predictedTotalEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'predictedTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> predictedTotalGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'predictedTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> predictedTotalLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'predictedTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> predictedTotalBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'predictedTotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> projectedDailyAverageEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'projectedDailyAverage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> projectedDailyAverageGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'projectedDailyAverage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> projectedDailyAverageLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'projectedDailyAverage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> projectedDailyAverageBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'projectedDailyAverage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> trendEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trend',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> trendGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'trend',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> trendLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'trend',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> trendBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'trend',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> trendStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'trend',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> trendEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'trend',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
          QAfterFilterCondition>
      trendContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'trend',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
          QAfterFilterCondition>
      trendMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'trend',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> trendIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trend',
        value: '',
      ));
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel,
      QAfterFilterCondition> trendIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'trend',
        value: '',
      ));
    });
  }
}

extension PredictionCacheModelQueryObject on QueryBuilder<PredictionCacheModel,
    PredictionCacheModel, QFilterCondition> {}

extension PredictionCacheModelQueryLinks on QueryBuilder<PredictionCacheModel,
    PredictionCacheModel, QFilterCondition> {}

extension PredictionCacheModelQuerySortBy
    on QueryBuilder<PredictionCacheModel, PredictionCacheModel, QSortBy> {
  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByAiInsight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiInsight', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByAiInsightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiInsight', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByCategoryPredictionsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryPredictionsJson', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByCategoryPredictionsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryPredictionsJson', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByCurrentDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentDay', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByCurrentDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentDay', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByCurrentTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentTotal', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByCurrentTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentTotal', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByDailyAverage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyAverage', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByDailyAverageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyAverage', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByDaysInMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysInMonth', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByDaysInMonthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysInMonth', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByDaysRemaining() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysRemaining', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByDaysRemainingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysRemaining', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByGeneratedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAt', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByGeneratedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAt', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByLastMonthTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMonthTotal', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByLastMonthTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMonthTotal', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByPredictedTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedTotal', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByPredictedTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedTotal', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByProjectedDailyAverage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectedDailyAverage', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByProjectedDailyAverageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectedDailyAverage', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByTrend() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trend', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      sortByTrendDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trend', Sort.desc);
    });
  }
}

extension PredictionCacheModelQuerySortThenBy
    on QueryBuilder<PredictionCacheModel, PredictionCacheModel, QSortThenBy> {
  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByAiInsight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiInsight', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByAiInsightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiInsight', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByCategoryPredictionsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryPredictionsJson', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByCategoryPredictionsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryPredictionsJson', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByCurrentDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentDay', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByCurrentDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentDay', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByCurrentTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentTotal', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByCurrentTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentTotal', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByDailyAverage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyAverage', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByDailyAverageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyAverage', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByDaysInMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysInMonth', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByDaysInMonthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysInMonth', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByDaysRemaining() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysRemaining', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByDaysRemainingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysRemaining', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByGeneratedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAt', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByGeneratedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAt', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByLastMonthTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMonthTotal', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByLastMonthTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMonthTotal', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByPredictedTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedTotal', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByPredictedTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedTotal', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByProjectedDailyAverage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectedDailyAverage', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByProjectedDailyAverageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectedDailyAverage', Sort.desc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByTrend() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trend', Sort.asc);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QAfterSortBy>
      thenByTrendDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trend', Sort.desc);
    });
  }
}

extension PredictionCacheModelQueryWhereDistinct
    on QueryBuilder<PredictionCacheModel, PredictionCacheModel, QDistinct> {
  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QDistinct>
      distinctByAiInsight({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aiInsight', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QDistinct>
      distinctByCategoryPredictionsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryPredictionsJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QDistinct>
      distinctByConfidence({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'confidence', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QDistinct>
      distinctByCurrentDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentDay');
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QDistinct>
      distinctByCurrentTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentTotal');
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QDistinct>
      distinctByDailyAverage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dailyAverage');
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QDistinct>
      distinctByDaysInMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'daysInMonth');
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QDistinct>
      distinctByDaysRemaining() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'daysRemaining');
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QDistinct>
      distinctByGeneratedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'generatedAt');
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QDistinct>
      distinctByLastMonthTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastMonthTotal');
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QDistinct>
      distinctByPredictedTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'predictedTotal');
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QDistinct>
      distinctByProjectedDailyAverage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'projectedDailyAverage');
    });
  }

  QueryBuilder<PredictionCacheModel, PredictionCacheModel, QDistinct>
      distinctByTrend({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trend', caseSensitive: caseSensitive);
    });
  }
}

extension PredictionCacheModelQueryProperty on QueryBuilder<
    PredictionCacheModel, PredictionCacheModel, QQueryProperty> {
  QueryBuilder<PredictionCacheModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PredictionCacheModel, String, QQueryOperations>
      aiInsightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aiInsight');
    });
  }

  QueryBuilder<PredictionCacheModel, String, QQueryOperations>
      categoryPredictionsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryPredictionsJson');
    });
  }

  QueryBuilder<PredictionCacheModel, String, QQueryOperations>
      confidenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'confidence');
    });
  }

  QueryBuilder<PredictionCacheModel, int, QQueryOperations>
      currentDayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentDay');
    });
  }

  QueryBuilder<PredictionCacheModel, double, QQueryOperations>
      currentTotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentTotal');
    });
  }

  QueryBuilder<PredictionCacheModel, double, QQueryOperations>
      dailyAverageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dailyAverage');
    });
  }

  QueryBuilder<PredictionCacheModel, int, QQueryOperations>
      daysInMonthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'daysInMonth');
    });
  }

  QueryBuilder<PredictionCacheModel, int, QQueryOperations>
      daysRemainingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'daysRemaining');
    });
  }

  QueryBuilder<PredictionCacheModel, DateTime, QQueryOperations>
      generatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'generatedAt');
    });
  }

  QueryBuilder<PredictionCacheModel, double, QQueryOperations>
      lastMonthTotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMonthTotal');
    });
  }

  QueryBuilder<PredictionCacheModel, double, QQueryOperations>
      predictedTotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'predictedTotal');
    });
  }

  QueryBuilder<PredictionCacheModel, double, QQueryOperations>
      projectedDailyAverageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'projectedDailyAverage');
    });
  }

  QueryBuilder<PredictionCacheModel, String, QQueryOperations> trendProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trend');
    });
  }
}
