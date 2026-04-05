// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMessageModelCollection on Isar {
  IsarCollection<MessageModel> get messageModels => this.collection();
}

const MessageModelSchema = CollectionSchema(
  name: r'MessageModel',
  id: -902762555029995869,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'isError': PropertySchema(id: 1, name: r'isError', type: IsarType.bool),
    r'isRag': PropertySchema(id: 2, name: r'isRag', type: IsarType.bool),
    r'isReceipt': PropertySchema(
      id: 3,
      name: r'isReceipt',
      type: IsarType.bool,
    ),
    r'isUser': PropertySchema(id: 4, name: r'isUser', type: IsarType.bool),
    r'isVoice': PropertySchema(id: 5, name: r'isVoice', type: IsarType.bool),
    r'outputTokenCount': PropertySchema(
      id: 6,
      name: r'outputTokenCount',
      type: IsarType.long,
    ),
    r'promptTokenCount': PropertySchema(
      id: 7,
      name: r'promptTokenCount',
      type: IsarType.long,
    ),
    r'ragType': PropertySchema(id: 8, name: r'ragType', type: IsarType.string),
    r'text': PropertySchema(id: 9, name: r'text', type: IsarType.string),
    r'totalTokenCount': PropertySchema(
      id: 10,
      name: r'totalTokenCount',
      type: IsarType.long,
    ),
    r'usedRagContext': PropertySchema(
      id: 11,
      name: r'usedRagContext',
      type: IsarType.bool,
    ),
  },
  estimateSize: _messageModelEstimateSize,
  serialize: _messageModelSerialize,
  deserialize: _messageModelDeserialize,
  deserializeProp: _messageModelDeserializeProp,
  idName: r'id',
  indexes: {
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
  },
  links: {},
  embeddedSchemas: {},
  getId: _messageModelGetId,
  getLinks: _messageModelGetLinks,
  attach: _messageModelAttach,
  version: '3.1.0+1',
);

int _messageModelEstimateSize(
  MessageModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.ragType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.text.length * 3;
  return bytesCount;
}

void _messageModelSerialize(
  MessageModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeBool(offsets[1], object.isError);
  writer.writeBool(offsets[2], object.isRag);
  writer.writeBool(offsets[3], object.isReceipt);
  writer.writeBool(offsets[4], object.isUser);
  writer.writeBool(offsets[5], object.isVoice);
  writer.writeLong(offsets[6], object.outputTokenCount);
  writer.writeLong(offsets[7], object.promptTokenCount);
  writer.writeString(offsets[8], object.ragType);
  writer.writeString(offsets[9], object.text);
  writer.writeLong(offsets[10], object.totalTokenCount);
  writer.writeBool(offsets[11], object.usedRagContext);
}

MessageModel _messageModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MessageModel();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.isError = reader.readBool(offsets[1]);
  object.isRag = reader.readBool(offsets[2]);
  object.isReceipt = reader.readBool(offsets[3]);
  object.isUser = reader.readBool(offsets[4]);
  object.isVoice = reader.readBool(offsets[5]);
  object.outputTokenCount = reader.readLongOrNull(offsets[6]);
  object.promptTokenCount = reader.readLongOrNull(offsets[7]);
  object.ragType = reader.readStringOrNull(offsets[8]);
  object.text = reader.readString(offsets[9]);
  object.totalTokenCount = reader.readLongOrNull(offsets[10]);
  object.usedRagContext = reader.readBool(offsets[11]);
  return object;
}

P _messageModelDeserializeProp<P>(
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
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _messageModelGetId(MessageModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _messageModelGetLinks(MessageModel object) {
  return [];
}

void _messageModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  MessageModel object,
) {
  object.id = id;
}

extension MessageModelQueryWhereSort
    on QueryBuilder<MessageModel, MessageModel, QWhere> {
  QueryBuilder<MessageModel, MessageModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension MessageModelQueryWhere
    on QueryBuilder<MessageModel, MessageModel, QWhereClause> {
  QueryBuilder<MessageModel, MessageModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<MessageModel, MessageModel, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<MessageModel, MessageModel, QAfterWhereClause> createdAtEqualTo(
    DateTime createdAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterWhereClause>
  createdAtNotEqualTo(DateTime createdAt) {
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

  QueryBuilder<MessageModel, MessageModel, QAfterWhereClause>
  createdAtGreaterThan(DateTime createdAt, {bool include = false}) {
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

  QueryBuilder<MessageModel, MessageModel, QAfterWhereClause> createdAtLessThan(
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

  QueryBuilder<MessageModel, MessageModel, QAfterWhereClause> createdAtBetween(
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
}

extension MessageModelQueryFilter
    on QueryBuilder<MessageModel, MessageModel, QFilterCondition> {
  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  isErrorEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isError', value: value),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> isRagEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isRag', value: value),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  isReceiptEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isReceipt', value: value),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> isUserEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isUser', value: value),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  isVoiceEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isVoice', value: value),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  outputTokenCountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'outputTokenCount'),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  outputTokenCountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'outputTokenCount'),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  outputTokenCountEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'outputTokenCount', value: value),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  outputTokenCountGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'outputTokenCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  outputTokenCountLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'outputTokenCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  outputTokenCountBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'outputTokenCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  promptTokenCountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'promptTokenCount'),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  promptTokenCountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'promptTokenCount'),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  promptTokenCountEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'promptTokenCount', value: value),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  promptTokenCountGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'promptTokenCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  promptTokenCountLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'promptTokenCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  promptTokenCountBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'promptTokenCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  ragTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'ragType'),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  ragTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'ragType'),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  ragTypeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'ragType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  ragTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ragType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  ragTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ragType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  ragTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ragType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  ragTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'ragType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  ragTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'ragType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  ragTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'ragType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  ragTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'ragType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  ragTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ragType', value: ''),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  ragTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'ragType', value: ''),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> textEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  textGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> textLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> textBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'text',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  textStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> textEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> textContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition> textMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'text',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  totalTokenCountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'totalTokenCount'),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  totalTokenCountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'totalTokenCount'),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  totalTokenCountEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'totalTokenCount', value: value),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  totalTokenCountGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalTokenCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  totalTokenCountLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalTokenCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  totalTokenCountBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalTokenCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterFilterCondition>
  usedRagContextEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'usedRagContext', value: value),
      );
    });
  }
}

extension MessageModelQueryObject
    on QueryBuilder<MessageModel, MessageModel, QFilterCondition> {}

extension MessageModelQueryLinks
    on QueryBuilder<MessageModel, MessageModel, QFilterCondition> {}

extension MessageModelQuerySortBy
    on QueryBuilder<MessageModel, MessageModel, QSortBy> {
  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByIsError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isError', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByIsErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isError', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByIsRag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRag', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByIsRagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRag', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByIsReceipt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isReceipt', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByIsReceiptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isReceipt', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByIsUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByIsUserDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByIsVoice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVoice', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByIsVoiceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVoice', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
  sortByOutputTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputTokenCount', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
  sortByOutputTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputTokenCount', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
  sortByPromptTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptTokenCount', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
  sortByPromptTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptTokenCount', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByRagType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ragType', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByRagTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ragType', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> sortByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
  sortByTotalTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTokenCount', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
  sortByTotalTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTokenCount', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
  sortByUsedRagContext() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedRagContext', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
  sortByUsedRagContextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedRagContext', Sort.desc);
    });
  }
}

extension MessageModelQuerySortThenBy
    on QueryBuilder<MessageModel, MessageModel, QSortThenBy> {
  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByIsError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isError', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByIsErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isError', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByIsRag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRag', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByIsRagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRag', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByIsReceipt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isReceipt', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByIsReceiptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isReceipt', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByIsUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByIsUserDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByIsVoice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVoice', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByIsVoiceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVoice', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
  thenByOutputTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputTokenCount', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
  thenByOutputTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputTokenCount', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
  thenByPromptTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptTokenCount', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
  thenByPromptTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptTokenCount', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByRagType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ragType', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByRagTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ragType', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy> thenByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
  thenByTotalTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTokenCount', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
  thenByTotalTokenCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTokenCount', Sort.desc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
  thenByUsedRagContext() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedRagContext', Sort.asc);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QAfterSortBy>
  thenByUsedRagContextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usedRagContext', Sort.desc);
    });
  }
}

extension MessageModelQueryWhereDistinct
    on QueryBuilder<MessageModel, MessageModel, QDistinct> {
  QueryBuilder<MessageModel, MessageModel, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<MessageModel, MessageModel, QDistinct> distinctByIsError() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isError');
    });
  }

  QueryBuilder<MessageModel, MessageModel, QDistinct> distinctByIsRag() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isRag');
    });
  }

  QueryBuilder<MessageModel, MessageModel, QDistinct> distinctByIsReceipt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isReceipt');
    });
  }

  QueryBuilder<MessageModel, MessageModel, QDistinct> distinctByIsUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isUser');
    });
  }

  QueryBuilder<MessageModel, MessageModel, QDistinct> distinctByIsVoice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isVoice');
    });
  }

  QueryBuilder<MessageModel, MessageModel, QDistinct>
  distinctByOutputTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'outputTokenCount');
    });
  }

  QueryBuilder<MessageModel, MessageModel, QDistinct>
  distinctByPromptTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'promptTokenCount');
    });
  }

  QueryBuilder<MessageModel, MessageModel, QDistinct> distinctByRagType({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ragType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QDistinct> distinctByText({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'text', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageModel, MessageModel, QDistinct>
  distinctByTotalTokenCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalTokenCount');
    });
  }

  QueryBuilder<MessageModel, MessageModel, QDistinct>
  distinctByUsedRagContext() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'usedRagContext');
    });
  }
}

extension MessageModelQueryProperty
    on QueryBuilder<MessageModel, MessageModel, QQueryProperty> {
  QueryBuilder<MessageModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MessageModel, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<MessageModel, bool, QQueryOperations> isErrorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isError');
    });
  }

  QueryBuilder<MessageModel, bool, QQueryOperations> isRagProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isRag');
    });
  }

  QueryBuilder<MessageModel, bool, QQueryOperations> isReceiptProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isReceipt');
    });
  }

  QueryBuilder<MessageModel, bool, QQueryOperations> isUserProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isUser');
    });
  }

  QueryBuilder<MessageModel, bool, QQueryOperations> isVoiceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isVoice');
    });
  }

  QueryBuilder<MessageModel, int?, QQueryOperations>
  outputTokenCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'outputTokenCount');
    });
  }

  QueryBuilder<MessageModel, int?, QQueryOperations>
  promptTokenCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'promptTokenCount');
    });
  }

  QueryBuilder<MessageModel, String?, QQueryOperations> ragTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ragType');
    });
  }

  QueryBuilder<MessageModel, String, QQueryOperations> textProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'text');
    });
  }

  QueryBuilder<MessageModel, int?, QQueryOperations> totalTokenCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalTokenCount');
    });
  }

  QueryBuilder<MessageModel, bool, QQueryOperations> usedRagContextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'usedRagContext');
    });
  }
}
