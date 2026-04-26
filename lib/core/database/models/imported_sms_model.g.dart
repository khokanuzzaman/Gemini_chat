// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'imported_sms_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetImportedSmsModelCollection on Isar {
  IsarCollection<ImportedSmsModel> get importedSmsModels => this.collection();
}

const ImportedSmsModelSchema = CollectionSchema(
  name: r'ImportedSmsModel',
  id: -9178211302544289951,
  properties: {
    r'expenseId': PropertySchema(
      id: 0,
      name: r'expenseId',
      type: IsarType.long,
    ),
    r'importedAt': PropertySchema(
      id: 1,
      name: r'importedAt',
      type: IsarType.dateTime,
    ),
    r'incomeId': PropertySchema(id: 2, name: r'incomeId', type: IsarType.long),
    r'sender': PropertySchema(id: 3, name: r'sender', type: IsarType.string),
    r'signature': PropertySchema(
      id: 4,
      name: r'signature',
      type: IsarType.string,
    ),
    r'smsDate': PropertySchema(
      id: 5,
      name: r'smsDate',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _importedSmsModelEstimateSize,
  serialize: _importedSmsModelSerialize,
  deserialize: _importedSmsModelDeserialize,
  deserializeProp: _importedSmsModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'signature': IndexSchema(
      id: 4701578645143940109,
      name: r'signature',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'signature',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'smsDate': IndexSchema(
      id: -7939190727316161361,
      name: r'smsDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'smsDate',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'importedAt': IndexSchema(
      id: 5552566418050361863,
      name: r'importedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'importedAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _importedSmsModelGetId,
  getLinks: _importedSmsModelGetLinks,
  attach: _importedSmsModelAttach,
  version: '3.3.2',
);

int _importedSmsModelEstimateSize(
  ImportedSmsModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.sender.length * 3;
  bytesCount += 3 + object.signature.length * 3;
  return bytesCount;
}

void _importedSmsModelSerialize(
  ImportedSmsModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.expenseId);
  writer.writeDateTime(offsets[1], object.importedAt);
  writer.writeLong(offsets[2], object.incomeId);
  writer.writeString(offsets[3], object.sender);
  writer.writeString(offsets[4], object.signature);
  writer.writeDateTime(offsets[5], object.smsDate);
}

ImportedSmsModel _importedSmsModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ImportedSmsModel();
  object.expenseId = reader.readLongOrNull(offsets[0]);
  object.id = id;
  object.importedAt = reader.readDateTime(offsets[1]);
  object.incomeId = reader.readLongOrNull(offsets[2]);
  object.sender = reader.readString(offsets[3]);
  object.signature = reader.readString(offsets[4]);
  object.smsDate = reader.readDateTime(offsets[5]);
  return object;
}

P _importedSmsModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _importedSmsModelGetId(ImportedSmsModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _importedSmsModelGetLinks(ImportedSmsModel object) {
  return [];
}

void _importedSmsModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  ImportedSmsModel object,
) {
  object.id = id;
}

extension ImportedSmsModelByIndex on IsarCollection<ImportedSmsModel> {
  Future<ImportedSmsModel?> getBySignature(String signature) {
    return getByIndex(r'signature', [signature]);
  }

  ImportedSmsModel? getBySignatureSync(String signature) {
    return getByIndexSync(r'signature', [signature]);
  }

  Future<bool> deleteBySignature(String signature) {
    return deleteByIndex(r'signature', [signature]);
  }

  bool deleteBySignatureSync(String signature) {
    return deleteByIndexSync(r'signature', [signature]);
  }

  Future<List<ImportedSmsModel?>> getAllBySignature(
    List<String> signatureValues,
  ) {
    final values = signatureValues.map((e) => [e]).toList();
    return getAllByIndex(r'signature', values);
  }

  List<ImportedSmsModel?> getAllBySignatureSync(List<String> signatureValues) {
    final values = signatureValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'signature', values);
  }

  Future<int> deleteAllBySignature(List<String> signatureValues) {
    final values = signatureValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'signature', values);
  }

  int deleteAllBySignatureSync(List<String> signatureValues) {
    final values = signatureValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'signature', values);
  }

  Future<Id> putBySignature(ImportedSmsModel object) {
    return putByIndex(r'signature', object);
  }

  Id putBySignatureSync(ImportedSmsModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'signature', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySignature(List<ImportedSmsModel> objects) {
    return putAllByIndex(r'signature', objects);
  }

  List<Id> putAllBySignatureSync(
    List<ImportedSmsModel> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'signature', objects, saveLinks: saveLinks);
  }
}

extension ImportedSmsModelQueryWhereSort
    on QueryBuilder<ImportedSmsModel, ImportedSmsModel, QWhere> {
  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhere> anySmsDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'smsDate'),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhere>
  anyImportedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'importedAt'),
      );
    });
  }
}

extension ImportedSmsModelQueryWhere
    on QueryBuilder<ImportedSmsModel, ImportedSmsModel, QWhereClause> {
  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhereClause>
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

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhereClause>
  signatureEqualTo(String signature) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'signature', value: [signature]),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhereClause>
  signatureNotEqualTo(String signature) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'signature',
                lower: [],
                upper: [signature],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'signature',
                lower: [signature],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'signature',
                lower: [signature],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'signature',
                lower: [],
                upper: [signature],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhereClause>
  smsDateEqualTo(DateTime smsDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'smsDate', value: [smsDate]),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhereClause>
  smsDateNotEqualTo(DateTime smsDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'smsDate',
                lower: [],
                upper: [smsDate],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'smsDate',
                lower: [smsDate],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'smsDate',
                lower: [smsDate],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'smsDate',
                lower: [],
                upper: [smsDate],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhereClause>
  smsDateGreaterThan(DateTime smsDate, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'smsDate',
          lower: [smsDate],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhereClause>
  smsDateLessThan(DateTime smsDate, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'smsDate',
          lower: [],
          upper: [smsDate],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhereClause>
  smsDateBetween(
    DateTime lowerSmsDate,
    DateTime upperSmsDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'smsDate',
          lower: [lowerSmsDate],
          includeLower: includeLower,
          upper: [upperSmsDate],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhereClause>
  importedAtEqualTo(DateTime importedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'importedAt', value: [importedAt]),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhereClause>
  importedAtNotEqualTo(DateTime importedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'importedAt',
                lower: [],
                upper: [importedAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'importedAt',
                lower: [importedAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'importedAt',
                lower: [importedAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'importedAt',
                lower: [],
                upper: [importedAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhereClause>
  importedAtGreaterThan(DateTime importedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'importedAt',
          lower: [importedAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhereClause>
  importedAtLessThan(DateTime importedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'importedAt',
          lower: [],
          upper: [importedAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterWhereClause>
  importedAtBetween(
    DateTime lowerImportedAt,
    DateTime upperImportedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'importedAt',
          lower: [lowerImportedAt],
          includeLower: includeLower,
          upper: [upperImportedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension ImportedSmsModelQueryFilter
    on QueryBuilder<ImportedSmsModel, ImportedSmsModel, QFilterCondition> {
  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  expenseIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'expenseId'),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  expenseIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'expenseId'),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  expenseIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'expenseId', value: value),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  expenseIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'expenseId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  expenseIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'expenseId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  expenseIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'expenseId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
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

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
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

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
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

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  importedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'importedAt', value: value),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  importedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'importedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  importedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'importedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  importedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'importedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  incomeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'incomeId'),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  incomeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'incomeId'),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  incomeIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'incomeId', value: value),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  incomeIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'incomeId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  incomeIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'incomeId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  incomeIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'incomeId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  senderEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sender',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  senderGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sender',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  senderLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sender',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  senderBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sender',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  senderStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sender',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  senderEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sender',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  senderContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sender',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  senderMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sender',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  senderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sender', value: ''),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  senderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sender', value: ''),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  signatureEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'signature',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  signatureGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'signature',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  signatureLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'signature',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  signatureBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'signature',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  signatureStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'signature',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  signatureEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'signature',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  signatureContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'signature',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  signatureMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'signature',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  signatureIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'signature', value: ''),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  signatureIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'signature', value: ''),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  smsDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'smsDate', value: value),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  smsDateGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'smsDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  smsDateLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'smsDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterFilterCondition>
  smsDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'smsDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension ImportedSmsModelQueryObject
    on QueryBuilder<ImportedSmsModel, ImportedSmsModel, QFilterCondition> {}

extension ImportedSmsModelQueryLinks
    on QueryBuilder<ImportedSmsModel, ImportedSmsModel, QFilterCondition> {}

extension ImportedSmsModelQuerySortBy
    on QueryBuilder<ImportedSmsModel, ImportedSmsModel, QSortBy> {
  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  sortByExpenseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expenseId', Sort.asc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  sortByExpenseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expenseId', Sort.desc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  sortByImportedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importedAt', Sort.asc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  sortByImportedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importedAt', Sort.desc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  sortByIncomeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'incomeId', Sort.asc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  sortByIncomeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'incomeId', Sort.desc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  sortBySender() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sender', Sort.asc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  sortBySenderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sender', Sort.desc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  sortBySignature() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signature', Sort.asc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  sortBySignatureDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signature', Sort.desc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  sortBySmsDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'smsDate', Sort.asc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  sortBySmsDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'smsDate', Sort.desc);
    });
  }
}

extension ImportedSmsModelQuerySortThenBy
    on QueryBuilder<ImportedSmsModel, ImportedSmsModel, QSortThenBy> {
  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  thenByExpenseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expenseId', Sort.asc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  thenByExpenseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expenseId', Sort.desc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  thenByImportedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importedAt', Sort.asc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  thenByImportedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importedAt', Sort.desc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  thenByIncomeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'incomeId', Sort.asc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  thenByIncomeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'incomeId', Sort.desc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  thenBySender() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sender', Sort.asc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  thenBySenderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sender', Sort.desc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  thenBySignature() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signature', Sort.asc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  thenBySignatureDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signature', Sort.desc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  thenBySmsDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'smsDate', Sort.asc);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QAfterSortBy>
  thenBySmsDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'smsDate', Sort.desc);
    });
  }
}

extension ImportedSmsModelQueryWhereDistinct
    on QueryBuilder<ImportedSmsModel, ImportedSmsModel, QDistinct> {
  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QDistinct>
  distinctByExpenseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expenseId');
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QDistinct>
  distinctByImportedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'importedAt');
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QDistinct>
  distinctByIncomeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'incomeId');
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QDistinct> distinctBySender({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sender', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QDistinct>
  distinctBySignature({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'signature', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ImportedSmsModel, ImportedSmsModel, QDistinct>
  distinctBySmsDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'smsDate');
    });
  }
}

extension ImportedSmsModelQueryProperty
    on QueryBuilder<ImportedSmsModel, ImportedSmsModel, QQueryProperty> {
  QueryBuilder<ImportedSmsModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ImportedSmsModel, int?, QQueryOperations> expenseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expenseId');
    });
  }

  QueryBuilder<ImportedSmsModel, DateTime, QQueryOperations>
  importedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'importedAt');
    });
  }

  QueryBuilder<ImportedSmsModel, int?, QQueryOperations> incomeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'incomeId');
    });
  }

  QueryBuilder<ImportedSmsModel, String, QQueryOperations> senderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sender');
    });
  }

  QueryBuilder<ImportedSmsModel, String, QQueryOperations> signatureProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'signature');
    });
  }

  QueryBuilder<ImportedSmsModel, DateTime, QQueryOperations> smsDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'smsDate');
    });
  }
}
