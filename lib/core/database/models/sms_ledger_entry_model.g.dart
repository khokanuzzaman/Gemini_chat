// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_ledger_entry_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSmsLedgerEntryModelCollection on Isar {
  IsarCollection<SmsLedgerEntryModel> get smsLedgerEntryModels =>
      this.collection();
}

const SmsLedgerEntryModelSchema = CollectionSchema(
  name: r'SmsLedgerEntryModel',
  id: 1972843996293797682,
  properties: {
    r'accountMask': PropertySchema(
      id: 0,
      name: r'accountMask',
      type: IsarType.string,
    ),
    r'amount': PropertySchema(id: 1, name: r'amount', type: IsarType.double),
    r'balanceAfter': PropertySchema(
      id: 2,
      name: r'balanceAfter',
      type: IsarType.double,
    ),
    r'canImport': PropertySchema(
      id: 3,
      name: r'canImport',
      type: IsarType.bool,
    ),
    r'confidence': PropertySchema(
      id: 4,
      name: r'confidence',
      type: IsarType.double,
    ),
    r'counterparty': PropertySchema(
      id: 5,
      name: r'counterparty',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 6,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'direction': PropertySchema(
      id: 7,
      name: r'direction',
      type: IsarType.byte,
      enumMap: _SmsLedgerEntryModeldirectionEnumValueMap,
    ),
    r'displayTitle': PropertySchema(
      id: 8,
      name: r'displayTitle',
      type: IsarType.string,
    ),
    r'fee': PropertySchema(id: 9, name: r'fee', type: IsarType.double),
    r'ignoredAt': PropertySchema(
      id: 10,
      name: r'ignoredAt',
      type: IsarType.dateTime,
    ),
    r'importedAt': PropertySchema(
      id: 11,
      name: r'importedAt',
      type: IsarType.dateTime,
    ),
    r'isExpenseLike': PropertySchema(
      id: 12,
      name: r'isExpenseLike',
      type: IsarType.bool,
    ),
    r'isIgnored': PropertySchema(
      id: 13,
      name: r'isIgnored',
      type: IsarType.bool,
    ),
    r'isImported': PropertySchema(
      id: 14,
      name: r'isImported',
      type: IsarType.bool,
    ),
    r'isIncomeLike': PropertySchema(
      id: 15,
      name: r'isIncomeLike',
      type: IsarType.bool,
    ),
    r'isTransferLike': PropertySchema(
      id: 16,
      name: r'isTransferLike',
      type: IsarType.bool,
    ),
    r'kind': PropertySchema(
      id: 17,
      name: r'kind',
      type: IsarType.byte,
      enumMap: _SmsLedgerEntryModelkindEnumValueMap,
    ),
    r'merchantName': PropertySchema(
      id: 18,
      name: r'merchantName',
      type: IsarType.string,
    ),
    r'occurredAt': PropertySchema(
      id: 19,
      name: r'occurredAt',
      type: IsarType.dateTime,
    ),
    r'rawCategory': PropertySchema(
      id: 20,
      name: r'rawCategory',
      type: IsarType.string,
    ),
    r'rawMessage': PropertySchema(
      id: 21,
      name: r'rawMessage',
      type: IsarType.string,
    ),
    r'receivedAt': PropertySchema(
      id: 22,
      name: r'receivedAt',
      type: IsarType.dateTime,
    ),
    r'reference': PropertySchema(
      id: 23,
      name: r'reference',
      type: IsarType.string,
    ),
    r'sender': PropertySchema(id: 24, name: r'sender', type: IsarType.string),
    r'signature': PropertySchema(
      id: 25,
      name: r'signature',
      type: IsarType.string,
    ),
    r'smsId': PropertySchema(id: 26, name: r'smsId', type: IsarType.long),
    r'source': PropertySchema(
      id: 27,
      name: r'source',
      type: IsarType.byte,
      enumMap: _SmsLedgerEntryModelsourceEnumValueMap,
    ),
    r'type': PropertySchema(
      id: 28,
      name: r'type',
      type: IsarType.byte,
      enumMap: _SmsLedgerEntryModeltypeEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 29,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _smsLedgerEntryModelEstimateSize,
  serialize: _smsLedgerEntryModelSerialize,
  deserialize: _smsLedgerEntryModelDeserialize,
  deserializeProp: _smsLedgerEntryModelDeserializeProp,
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
    r'smsId': IndexSchema(
      id: -2965135931201390284,
      name: r'smsId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'smsId',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'occurredAt': IndexSchema(
      id: 1229694562040044173,
      name: r'occurredAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'occurredAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'receivedAt': IndexSchema(
      id: -6277795886715409418,
      name: r'receivedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'receivedAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'isImported': IndexSchema(
      id: -7437563992851340482,
      name: r'isImported',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isImported',
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
    r'isIgnored': IndexSchema(
      id: 6565288632218566391,
      name: r'isIgnored',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isIgnored',
          type: IndexType.value,
          caseSensitive: false,
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

  getId: _smsLedgerEntryModelGetId,
  getLinks: _smsLedgerEntryModelGetLinks,
  attach: _smsLedgerEntryModelAttach,
  version: '3.3.2',
);

int _smsLedgerEntryModelEstimateSize(
  SmsLedgerEntryModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.accountMask;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.counterparty;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.displayTitle.length * 3;
  {
    final value = object.merchantName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.rawCategory;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.rawMessage.length * 3;
  {
    final value = object.reference;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sender.length * 3;
  bytesCount += 3 + object.signature.length * 3;
  return bytesCount;
}

void _smsLedgerEntryModelSerialize(
  SmsLedgerEntryModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.accountMask);
  writer.writeDouble(offsets[1], object.amount);
  writer.writeDouble(offsets[2], object.balanceAfter);
  writer.writeBool(offsets[3], object.canImport);
  writer.writeDouble(offsets[4], object.confidence);
  writer.writeString(offsets[5], object.counterparty);
  writer.writeDateTime(offsets[6], object.createdAt);
  writer.writeByte(offsets[7], object.direction.index);
  writer.writeString(offsets[8], object.displayTitle);
  writer.writeDouble(offsets[9], object.fee);
  writer.writeDateTime(offsets[10], object.ignoredAt);
  writer.writeDateTime(offsets[11], object.importedAt);
  writer.writeBool(offsets[12], object.isExpenseLike);
  writer.writeBool(offsets[13], object.isIgnored);
  writer.writeBool(offsets[14], object.isImported);
  writer.writeBool(offsets[15], object.isIncomeLike);
  writer.writeBool(offsets[16], object.isTransferLike);
  writer.writeByte(offsets[17], object.kind.index);
  writer.writeString(offsets[18], object.merchantName);
  writer.writeDateTime(offsets[19], object.occurredAt);
  writer.writeString(offsets[20], object.rawCategory);
  writer.writeString(offsets[21], object.rawMessage);
  writer.writeDateTime(offsets[22], object.receivedAt);
  writer.writeString(offsets[23], object.reference);
  writer.writeString(offsets[24], object.sender);
  writer.writeString(offsets[25], object.signature);
  writer.writeLong(offsets[26], object.smsId);
  writer.writeByte(offsets[27], object.source.index);
  writer.writeByte(offsets[28], object.type.index);
  writer.writeDateTime(offsets[29], object.updatedAt);
}

SmsLedgerEntryModel _smsLedgerEntryModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SmsLedgerEntryModel();
  object.accountMask = reader.readStringOrNull(offsets[0]);
  object.amount = reader.readDouble(offsets[1]);
  object.balanceAfter = reader.readDoubleOrNull(offsets[2]);
  object.confidence = reader.readDouble(offsets[4]);
  object.counterparty = reader.readStringOrNull(offsets[5]);
  object.createdAt = reader.readDateTime(offsets[6]);
  object.direction =
      _SmsLedgerEntryModeldirectionValueEnumMap[reader.readByteOrNull(
        offsets[7],
      )] ??
      ParsedTransactionDirection.debit;
  object.fee = reader.readDoubleOrNull(offsets[9]);
  object.id = id;
  object.ignoredAt = reader.readDateTimeOrNull(offsets[10]);
  object.importedAt = reader.readDateTimeOrNull(offsets[11]);
  object.isIgnored = reader.readBool(offsets[13]);
  object.isImported = reader.readBool(offsets[14]);
  object.kind =
      _SmsLedgerEntryModelkindValueEnumMap[reader.readByteOrNull(
        offsets[17],
      )] ??
      ParsedTransactionKind.sendMoney;
  object.merchantName = reader.readStringOrNull(offsets[18]);
  object.occurredAt = reader.readDateTime(offsets[19]);
  object.rawCategory = reader.readStringOrNull(offsets[20]);
  object.rawMessage = reader.readString(offsets[21]);
  object.receivedAt = reader.readDateTime(offsets[22]);
  object.reference = reader.readStringOrNull(offsets[23]);
  object.sender = reader.readString(offsets[24]);
  object.signature = reader.readString(offsets[25]);
  object.smsId = reader.readLong(offsets[26]);
  object.source =
      _SmsLedgerEntryModelsourceValueEnumMap[reader.readByteOrNull(
        offsets[27],
      )] ??
      ParsedTransactionSource.bkash;
  object.type =
      _SmsLedgerEntryModeltypeValueEnumMap[reader.readByteOrNull(
        offsets[28],
      )] ??
      TransactionType.expense;
  object.updatedAt = reader.readDateTime(offsets[29]);
  return object;
}

P _smsLedgerEntryModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (_SmsLedgerEntryModeldirectionValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              ParsedTransactionDirection.debit)
          as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 11:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readBool(offset)) as P;
    case 14:
      return (reader.readBool(offset)) as P;
    case 15:
      return (reader.readBool(offset)) as P;
    case 16:
      return (reader.readBool(offset)) as P;
    case 17:
      return (_SmsLedgerEntryModelkindValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              ParsedTransactionKind.sendMoney)
          as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readDateTime(offset)) as P;
    case 20:
      return (reader.readStringOrNull(offset)) as P;
    case 21:
      return (reader.readString(offset)) as P;
    case 22:
      return (reader.readDateTime(offset)) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
    case 24:
      return (reader.readString(offset)) as P;
    case 25:
      return (reader.readString(offset)) as P;
    case 26:
      return (reader.readLong(offset)) as P;
    case 27:
      return (_SmsLedgerEntryModelsourceValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              ParsedTransactionSource.bkash)
          as P;
    case 28:
      return (_SmsLedgerEntryModeltypeValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              TransactionType.expense)
          as P;
    case 29:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _SmsLedgerEntryModeldirectionEnumValueMap = {
  'debit': 0,
  'credit': 1,
  'unknown': 2,
};
const _SmsLedgerEntryModeldirectionValueEnumMap = {
  0: ParsedTransactionDirection.debit,
  1: ParsedTransactionDirection.credit,
  2: ParsedTransactionDirection.unknown,
};
const _SmsLedgerEntryModelkindEnumValueMap = {
  'sendMoney': 0,
  'receivedMoney': 1,
  'cashOut': 2,
  'cashIn': 3,
  'payment': 4,
  'addMoney': 5,
  'bankDebit': 6,
  'bankCredit': 7,
  'transfer': 8,
  'atmWithdrawal': 9,
  'cardPurchase': 10,
  'billPay': 11,
  'unknown': 12,
};
const _SmsLedgerEntryModelkindValueEnumMap = {
  0: ParsedTransactionKind.sendMoney,
  1: ParsedTransactionKind.receivedMoney,
  2: ParsedTransactionKind.cashOut,
  3: ParsedTransactionKind.cashIn,
  4: ParsedTransactionKind.payment,
  5: ParsedTransactionKind.addMoney,
  6: ParsedTransactionKind.bankDebit,
  7: ParsedTransactionKind.bankCredit,
  8: ParsedTransactionKind.transfer,
  9: ParsedTransactionKind.atmWithdrawal,
  10: ParsedTransactionKind.cardPurchase,
  11: ParsedTransactionKind.billPay,
  12: ParsedTransactionKind.unknown,
};
const _SmsLedgerEntryModelsourceEnumValueMap = {
  'bkash': 0,
  'nagad': 1,
  'rocket': 2,
  'bank': 3,
  'unknown': 4,
};
const _SmsLedgerEntryModelsourceValueEnumMap = {
  0: ParsedTransactionSource.bkash,
  1: ParsedTransactionSource.nagad,
  2: ParsedTransactionSource.rocket,
  3: ParsedTransactionSource.bank,
  4: ParsedTransactionSource.unknown,
};
const _SmsLedgerEntryModeltypeEnumValueMap = {
  'expense': 0,
  'income': 1,
  'transfer': 2,
  'unknown': 3,
};
const _SmsLedgerEntryModeltypeValueEnumMap = {
  0: TransactionType.expense,
  1: TransactionType.income,
  2: TransactionType.transfer,
  3: TransactionType.unknown,
};

Id _smsLedgerEntryModelGetId(SmsLedgerEntryModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _smsLedgerEntryModelGetLinks(
  SmsLedgerEntryModel object,
) {
  return [];
}

void _smsLedgerEntryModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  SmsLedgerEntryModel object,
) {
  object.id = id;
}

extension SmsLedgerEntryModelByIndex on IsarCollection<SmsLedgerEntryModel> {
  Future<SmsLedgerEntryModel?> getBySignature(String signature) {
    return getByIndex(r'signature', [signature]);
  }

  SmsLedgerEntryModel? getBySignatureSync(String signature) {
    return getByIndexSync(r'signature', [signature]);
  }

  Future<bool> deleteBySignature(String signature) {
    return deleteByIndex(r'signature', [signature]);
  }

  bool deleteBySignatureSync(String signature) {
    return deleteByIndexSync(r'signature', [signature]);
  }

  Future<List<SmsLedgerEntryModel?>> getAllBySignature(
    List<String> signatureValues,
  ) {
    final values = signatureValues.map((e) => [e]).toList();
    return getAllByIndex(r'signature', values);
  }

  List<SmsLedgerEntryModel?> getAllBySignatureSync(
    List<String> signatureValues,
  ) {
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

  Future<Id> putBySignature(SmsLedgerEntryModel object) {
    return putByIndex(r'signature', object);
  }

  Id putBySignatureSync(SmsLedgerEntryModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'signature', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySignature(List<SmsLedgerEntryModel> objects) {
    return putAllByIndex(r'signature', objects);
  }

  List<Id> putAllBySignatureSync(
    List<SmsLedgerEntryModel> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'signature', objects, saveLinks: saveLinks);
  }
}

extension SmsLedgerEntryModelQueryWhereSort
    on QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QWhere> {
  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhere>
  anySmsId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'smsId'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhere>
  anyOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'occurredAt'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhere>
  anyReceivedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'receivedAt'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhere>
  anyIsImported() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isImported'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhere>
  anyImportedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'importedAt'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhere>
  anyIsIgnored() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isIgnored'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhere>
  anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhere>
  anyUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAt'),
      );
    });
  }
}

extension SmsLedgerEntryModelQueryWhere
    on QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QWhereClause> {
  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  signatureEqualTo(String signature) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'signature', value: [signature]),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  smsIdEqualTo(int smsId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'smsId', value: [smsId]),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  smsIdNotEqualTo(int smsId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'smsId',
                lower: [],
                upper: [smsId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'smsId',
                lower: [smsId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'smsId',
                lower: [smsId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'smsId',
                lower: [],
                upper: [smsId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  smsIdGreaterThan(int smsId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'smsId',
          lower: [smsId],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  smsIdLessThan(int smsId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'smsId',
          lower: [],
          upper: [smsId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  smsIdBetween(
    int lowerSmsId,
    int upperSmsId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'smsId',
          lower: [lowerSmsId],
          includeLower: includeLower,
          upper: [upperSmsId],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  occurredAtEqualTo(DateTime occurredAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'occurredAt', value: [occurredAt]),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  occurredAtNotEqualTo(DateTime occurredAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurredAt',
                lower: [],
                upper: [occurredAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurredAt',
                lower: [occurredAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurredAt',
                lower: [occurredAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurredAt',
                lower: [],
                upper: [occurredAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  occurredAtGreaterThan(DateTime occurredAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'occurredAt',
          lower: [occurredAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  occurredAtLessThan(DateTime occurredAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'occurredAt',
          lower: [],
          upper: [occurredAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  occurredAtBetween(
    DateTime lowerOccurredAt,
    DateTime upperOccurredAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'occurredAt',
          lower: [lowerOccurredAt],
          includeLower: includeLower,
          upper: [upperOccurredAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  receivedAtEqualTo(DateTime receivedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'receivedAt', value: [receivedAt]),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  receivedAtNotEqualTo(DateTime receivedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'receivedAt',
                lower: [],
                upper: [receivedAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'receivedAt',
                lower: [receivedAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'receivedAt',
                lower: [receivedAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'receivedAt',
                lower: [],
                upper: [receivedAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  receivedAtGreaterThan(DateTime receivedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'receivedAt',
          lower: [receivedAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  receivedAtLessThan(DateTime receivedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'receivedAt',
          lower: [],
          upper: [receivedAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  receivedAtBetween(
    DateTime lowerReceivedAt,
    DateTime upperReceivedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'receivedAt',
          lower: [lowerReceivedAt],
          includeLower: includeLower,
          upper: [upperReceivedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  isImportedEqualTo(bool isImported) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'isImported', value: [isImported]),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  isImportedNotEqualTo(bool isImported) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isImported',
                lower: [],
                upper: [isImported],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isImported',
                lower: [isImported],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isImported',
                lower: [isImported],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isImported',
                lower: [],
                upper: [isImported],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  importedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'importedAt', value: [null]),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  importedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'importedAt',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  importedAtEqualTo(DateTime? importedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'importedAt', value: [importedAt]),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  importedAtNotEqualTo(DateTime? importedAt) {
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  importedAtGreaterThan(DateTime? importedAt, {bool include = false}) {
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  importedAtLessThan(DateTime? importedAt, {bool include = false}) {
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  importedAtBetween(
    DateTime? lowerImportedAt,
    DateTime? upperImportedAt, {
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  isIgnoredEqualTo(bool isIgnored) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'isIgnored', value: [isIgnored]),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  isIgnoredNotEqualTo(bool isIgnored) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isIgnored',
                lower: [],
                upper: [isIgnored],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isIgnored',
                lower: [isIgnored],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isIgnored',
                lower: [isIgnored],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isIgnored',
                lower: [],
                upper: [isIgnored],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  createdAtEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  createdAtLessThan(DateTime createdAt, {bool include = false}) {
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  createdAtBetween(
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
  updatedAtEqualTo(DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'updatedAt', value: [updatedAt]),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterWhereClause>
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

extension SmsLedgerEntryModelQueryFilter
    on
        QueryBuilder<
          SmsLedgerEntryModel,
          SmsLedgerEntryModel,
          QFilterCondition
        > {
  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  accountMaskIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'accountMask'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  accountMaskIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'accountMask'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  accountMaskEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'accountMask',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  accountMaskGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'accountMask',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  accountMaskLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'accountMask',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  accountMaskBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'accountMask',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  accountMaskStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'accountMask',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  accountMaskEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'accountMask',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  accountMaskContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'accountMask',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  accountMaskMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'accountMask',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  accountMaskIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'accountMask', value: ''),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  accountMaskIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'accountMask', value: ''),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  balanceAfterIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'balanceAfter'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  balanceAfterIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'balanceAfter'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  balanceAfterEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'balanceAfter',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  balanceAfterGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'balanceAfter',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  balanceAfterLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'balanceAfter',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  balanceAfterBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'balanceAfter',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  canImportEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'canImport', value: value),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  confidenceEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'confidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  confidenceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'confidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  confidenceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'confidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  confidenceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'confidence',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  counterpartyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'counterparty'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  counterpartyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'counterparty'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  counterpartyEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'counterparty',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  counterpartyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'counterparty',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  counterpartyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'counterparty',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  counterpartyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'counterparty',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  counterpartyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'counterparty',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  counterpartyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'counterparty',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  counterpartyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'counterparty',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  counterpartyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'counterparty',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  counterpartyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'counterparty', value: ''),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  counterpartyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'counterparty', value: ''),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  directionEqualTo(ParsedTransactionDirection value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'direction', value: value),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  directionGreaterThan(
    ParsedTransactionDirection value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'direction',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  directionLessThan(ParsedTransactionDirection value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'direction',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  directionBetween(
    ParsedTransactionDirection lower,
    ParsedTransactionDirection upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'direction',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  displayTitleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'displayTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  displayTitleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'displayTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  displayTitleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'displayTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  displayTitleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'displayTitle',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  displayTitleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'displayTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  displayTitleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'displayTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  displayTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'displayTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  displayTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'displayTitle',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  displayTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'displayTitle', value: ''),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  displayTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'displayTitle', value: ''),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  feeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'fee'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  feeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'fee'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  feeEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'fee',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  feeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fee',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  feeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fee',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  feeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fee',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  ignoredAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'ignoredAt'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  ignoredAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'ignoredAt'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  ignoredAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ignoredAt', value: value),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  ignoredAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ignoredAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  ignoredAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ignoredAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  ignoredAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ignoredAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  importedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'importedAt'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  importedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'importedAt'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  importedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'importedAt', value: value),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  importedAtGreaterThan(DateTime? value, {bool include = false}) {
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  importedAtLessThan(DateTime? value, {bool include = false}) {
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  importedAtBetween(
    DateTime? lower,
    DateTime? upper, {
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  isExpenseLikeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isExpenseLike', value: value),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  isIgnoredEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isIgnored', value: value),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  isImportedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isImported', value: value),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  isIncomeLikeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isIncomeLike', value: value),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  isTransferLikeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isTransferLike', value: value),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  kindEqualTo(ParsedTransactionKind value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'kind', value: value),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  kindGreaterThan(ParsedTransactionKind value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'kind',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  kindLessThan(ParsedTransactionKind value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'kind',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  kindBetween(
    ParsedTransactionKind lower,
    ParsedTransactionKind upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'kind',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  merchantNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'merchantName'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  merchantNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'merchantName'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  merchantNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'merchantName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  merchantNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'merchantName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  merchantNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'merchantName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  merchantNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'merchantName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  merchantNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'merchantName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  merchantNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'merchantName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  merchantNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'merchantName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  merchantNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'merchantName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  merchantNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'merchantName', value: ''),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  merchantNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'merchantName', value: ''),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  occurredAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'occurredAt', value: value),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  occurredAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'occurredAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  occurredAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'occurredAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  occurredAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'occurredAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawCategoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'rawCategory'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawCategoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'rawCategory'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawCategoryEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'rawCategory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawCategoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rawCategory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawCategoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rawCategory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawCategoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rawCategory',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawCategoryStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'rawCategory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawCategoryEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'rawCategory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawCategoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'rawCategory',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawCategoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'rawCategory',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawCategoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'rawCategory', value: ''),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawCategoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'rawCategory', value: ''),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawMessageEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'rawMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawMessageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rawMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawMessageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rawMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawMessageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rawMessage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawMessageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'rawMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawMessageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'rawMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawMessageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'rawMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawMessageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'rawMessage',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawMessageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'rawMessage', value: ''),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  rawMessageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'rawMessage', value: ''),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  receivedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'receivedAt', value: value),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  receivedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'receivedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  receivedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'receivedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  receivedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'receivedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  referenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'reference'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  referenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'reference'),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  referenceEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'reference',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  referenceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'reference',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  referenceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'reference',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  referenceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'reference',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  referenceStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'reference',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  referenceEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'reference',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  referenceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'reference',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  referenceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'reference',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  referenceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'reference', value: ''),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  referenceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'reference', value: ''),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  senderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sender', value: ''),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  senderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sender', value: ''),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  signatureIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'signature', value: ''),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  signatureIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'signature', value: ''),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  smsIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'smsId', value: value),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  smsIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'smsId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  smsIdLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'smsId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  smsIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'smsId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  sourceEqualTo(ParsedTransactionSource value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'source', value: value),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  sourceGreaterThan(ParsedTransactionSource value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'source',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  sourceLessThan(ParsedTransactionSource value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'source',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  sourceBetween(
    ParsedTransactionSource lower,
    ParsedTransactionSource upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'source',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  typeEqualTo(TransactionType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: value),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  typeGreaterThan(TransactionType value, {bool include = false}) {
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  typeLessThan(TransactionType value, {bool include = false}) {
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  typeBetween(
    TransactionType lower,
    TransactionType upper, {
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterFilterCondition>
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

extension SmsLedgerEntryModelQueryObject
    on
        QueryBuilder<
          SmsLedgerEntryModel,
          SmsLedgerEntryModel,
          QFilterCondition
        > {}

extension SmsLedgerEntryModelQueryLinks
    on
        QueryBuilder<
          SmsLedgerEntryModel,
          SmsLedgerEntryModel,
          QFilterCondition
        > {}

extension SmsLedgerEntryModelQuerySortBy
    on QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QSortBy> {
  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByAccountMask() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountMask', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByAccountMaskDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountMask', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByBalanceAfter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceAfter', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByBalanceAfterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceAfter', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByCanImport() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canImport', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByCanImportDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canImport', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByCounterparty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'counterparty', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByCounterpartyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'counterparty', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByDirectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByDisplayTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayTitle', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByDisplayTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayTitle', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fee', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByFeeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fee', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByIgnoredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ignoredAt', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByIgnoredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ignoredAt', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByImportedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importedAt', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByImportedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importedAt', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByIsExpenseLike() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpenseLike', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByIsExpenseLikeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpenseLike', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByIsIgnored() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIgnored', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByIsIgnoredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIgnored', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByIsImported() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isImported', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByIsImportedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isImported', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByIsIncomeLike() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIncomeLike', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByIsIncomeLikeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIncomeLike', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByIsTransferLike() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTransferLike', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByIsTransferLikeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTransferLike', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByMerchantName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merchantName', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByMerchantNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merchantName', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByOccurredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByRawCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawCategory', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByRawCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawCategory', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByRawMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawMessage', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByRawMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawMessage', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByReceivedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedAt', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByReceivedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedAt', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByReference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reference', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByReferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reference', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortBySender() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sender', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortBySenderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sender', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortBySignature() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signature', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortBySignatureDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signature', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortBySmsId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'smsId', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortBySmsIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'smsId', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SmsLedgerEntryModelQuerySortThenBy
    on QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QSortThenBy> {
  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByAccountMask() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountMask', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByAccountMaskDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountMask', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByBalanceAfter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceAfter', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByBalanceAfterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceAfter', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByCanImport() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canImport', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByCanImportDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canImport', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByCounterparty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'counterparty', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByCounterpartyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'counterparty', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByDirectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByDisplayTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayTitle', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByDisplayTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayTitle', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fee', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByFeeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fee', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByIgnoredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ignoredAt', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByIgnoredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ignoredAt', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByImportedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importedAt', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByImportedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importedAt', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByIsExpenseLike() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpenseLike', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByIsExpenseLikeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpenseLike', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByIsIgnored() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIgnored', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByIsIgnoredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIgnored', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByIsImported() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isImported', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByIsImportedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isImported', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByIsIncomeLike() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIncomeLike', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByIsIncomeLikeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIncomeLike', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByIsTransferLike() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTransferLike', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByIsTransferLikeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTransferLike', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByMerchantName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merchantName', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByMerchantNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'merchantName', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByOccurredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByRawCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawCategory', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByRawCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawCategory', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByRawMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawMessage', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByRawMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawMessage', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByReceivedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedAt', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByReceivedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedAt', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByReference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reference', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByReferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reference', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenBySender() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sender', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenBySenderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sender', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenBySignature() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signature', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenBySignatureDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signature', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenBySmsId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'smsId', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenBySmsIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'smsId', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SmsLedgerEntryModelQueryWhereDistinct
    on QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct> {
  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByAccountMask({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountMask', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByBalanceAfter() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'balanceAfter');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByCanImport() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'canImport');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'confidence');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByCounterparty({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'counterparty', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'direction');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByDisplayTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fee');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByIgnoredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ignoredAt');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByImportedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'importedAt');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByIsExpenseLike() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isExpenseLike');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByIsIgnored() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isIgnored');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByIsImported() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isImported');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByIsIncomeLike() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isIncomeLike');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByIsTransferLike() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isTransferLike');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kind');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByMerchantName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'merchantName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'occurredAt');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByRawCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rawCategory', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByRawMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rawMessage', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByReceivedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receivedAt');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByReference({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reference', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctBySender({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sender', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctBySignature({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'signature', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctBySmsId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'smsId');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension SmsLedgerEntryModelQueryProperty
    on QueryBuilder<SmsLedgerEntryModel, SmsLedgerEntryModel, QQueryProperty> {
  QueryBuilder<SmsLedgerEntryModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, String?, QQueryOperations>
  accountMaskProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountMask');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, double?, QQueryOperations>
  balanceAfterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'balanceAfter');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, bool, QQueryOperations>
  canImportProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'canImport');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, double, QQueryOperations>
  confidenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'confidence');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, String?, QQueryOperations>
  counterpartyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'counterparty');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<
    SmsLedgerEntryModel,
    ParsedTransactionDirection,
    QQueryOperations
  >
  directionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'direction');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, String, QQueryOperations>
  displayTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayTitle');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, double?, QQueryOperations> feeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fee');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, DateTime?, QQueryOperations>
  ignoredAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ignoredAt');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, DateTime?, QQueryOperations>
  importedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'importedAt');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, bool, QQueryOperations>
  isExpenseLikeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isExpenseLike');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, bool, QQueryOperations>
  isIgnoredProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isIgnored');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, bool, QQueryOperations>
  isImportedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isImported');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, bool, QQueryOperations>
  isIncomeLikeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isIncomeLike');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, bool, QQueryOperations>
  isTransferLikeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isTransferLike');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, ParsedTransactionKind, QQueryOperations>
  kindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kind');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, String?, QQueryOperations>
  merchantNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'merchantName');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, DateTime, QQueryOperations>
  occurredAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'occurredAt');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, String?, QQueryOperations>
  rawCategoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rawCategory');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, String, QQueryOperations>
  rawMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rawMessage');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, DateTime, QQueryOperations>
  receivedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receivedAt');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, String?, QQueryOperations>
  referenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reference');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, String, QQueryOperations> senderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sender');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, String, QQueryOperations>
  signatureProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'signature');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, int, QQueryOperations> smsIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'smsId');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, ParsedTransactionSource, QQueryOperations>
  sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, TransactionType, QQueryOperations>
  typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<SmsLedgerEntryModel, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
