import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../../features/category/data/models/category_model.dart';
import '../../features/category/domain/entities/category_entity.dart';
import '../../features/chat/data/models/message_model.dart';
import '../../features/debt/data/models/debt_model.dart';
import '../../features/debt/data/models/debt_payment_model.dart';
import '../../features/debt/domain/entities/debt_entity.dart';
import '../../features/goals/domain/entities/goal_entity.dart';
import '../../features/prediction/data/models/prediction_cache_model.dart';
import '../../features/recurring/domain/entities/recurring_expense_entity.dart';
import '../../features/wallet/domain/entities/wallet_entity.dart';
import '../database/models/budget_plan_model.dart';
import '../database/models/expense_record_model.dart';
import '../database/models/goal_model.dart';
import '../database/models/goal_saving_model.dart';
import '../database/models/imported_sms_model.dart';
import '../database/models/income_record_model.dart';
import '../database/models/recurring_expense_model.dart';
import '../database/models/sms_ledger_entry_model.dart';
import '../database/models/sms_ledger_sync_state_model.dart';
import '../database/models/split_bill_model.dart';
import '../database/models/wallet_model.dart';
import '../sms/parsed_transaction.dart';
import 'backup_exception.dart';

class IsarExportService {
  Future<Map<String, dynamic>> exportAll(Isar isar) async {
    final expenses = await isar.expenseRecordModels.where().findAll();
    final income = await isar.incomeRecordModels.where().findAll();
    final categories = await isar.categoryModels.where().findAll();
    final wallets = await isar.walletModels.where().findAll();
    final messages = await isar.messageModels.where().findAll();
    final budgetPlans = await isar.budgetPlanModels.where().findAll();
    final goals = await isar.goalModels.where().findAll();
    final goalSavings = await isar.goalSavingModels.where().findAll();
    final recurringExpenses = await isar.recurringExpenseModels
        .where()
        .findAll();
    final splitBills = await isar.splitBillModels.where().findAll();
    final debts = await isar.debtModels.where().findAll();
    final debtPayments = await isar.debtPaymentModels.where().findAll();
    final importedSms = await isar.importedSmsModels.where().findAll();
    final smsLedgerEntries = await isar.smsLedgerEntryModels.where().findAll();
    final smsLedgerSyncStates = await isar.smsLedgerSyncStateModels
        .where()
        .findAll();
    final predictionCaches = await isar.predictionCacheModels.where().findAll();

    return <String, dynamic>{
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'collections': <String, dynamic>{
        'expenses': expenses.map(_expenseToMap).toList(growable: false),
        'income': income.map(_incomeToMap).toList(growable: false),
        'categories': categories.map(_categoryToMap).toList(growable: false),
        'wallets': wallets.map(_walletToMap).toList(growable: false),
        'messages': messages.map(_messageToMap).toList(growable: false),
        'budgetPlans': budgetPlans
            .map(_budgetPlanToMap)
            .toList(growable: false),
        'goals': goals.map(_goalToMap).toList(growable: false),
        'goalSavings': goalSavings
            .map(_goalSavingToMap)
            .toList(growable: false),
        'recurringExpenses': recurringExpenses
            .map(_recurringToMap)
            .toList(growable: false),
        'splitBills': splitBills.map(_splitBillToMap).toList(growable: false),
        'debts': debts.map(_debtToMap).toList(growable: false),
        'debtPayments': debtPayments
            .map(_debtPaymentToMap)
            .toList(growable: false),
        'importedSms': importedSms
            .map(_importedSmsToMap)
            .toList(growable: false),
        'smsLedgerEntries': smsLedgerEntries
            .map(_smsLedgerEntryToMap)
            .toList(growable: false),
        'smsLedgerSyncStates': smsLedgerSyncStates
            .map(_smsLedgerSyncStateToMap)
            .toList(growable: false),
        'predictionCaches': predictionCaches
            .map(_predictionCacheToMap)
            .toList(growable: false),
      },
    };
  }

  Future<void> importAll(Isar isar, Map<String, dynamic> data) async {
    final version = _asInt(data['version']);
    if (version != 1) {
      throw const BackupException(
        'এই ব্যাকআপ ভার্সন সাপোর্টেড না',
        isRecoverable: false,
      );
    }

    final collections = data['collections'];
    if (collections is! Map) {
      throw const BackupException(
        'ব্যাকআপ ডেটা ফরম্যাট সঠিক নয়',
        isRecoverable: false,
      );
    }

    await isar.writeTxn(() async {
      for (final entry in collections.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        switch (key) {
          case 'expenses':
            await isar.expenseRecordModels.clear();
            await isar.expenseRecordModels.putAll(_decodeExpenses(value));
            break;
          case 'income':
            await isar.incomeRecordModels.clear();
            await isar.incomeRecordModels.putAll(_decodeIncome(value));
            break;
          case 'categories':
            await isar.categoryModels.clear();
            await isar.categoryModels.putAll(_decodeCategories(value));
            break;
          case 'wallets':
            await isar.walletModels.clear();
            await isar.walletModels.putAll(_decodeWallets(value));
            break;
          case 'messages':
            await isar.messageModels.clear();
            await isar.messageModels.putAll(_decodeMessages(value));
            break;
          case 'budgetPlans':
            await isar.budgetPlanModels.clear();
            await isar.budgetPlanModels.putAll(_decodeBudgetPlans(value));
            break;
          case 'goals':
            await isar.goalModels.clear();
            await isar.goalModels.putAll(_decodeGoals(value));
            break;
          case 'goalSavings':
            await isar.goalSavingModels.clear();
            await isar.goalSavingModels.putAll(_decodeGoalSavings(value));
            break;
          case 'recurringExpenses':
            await isar.recurringExpenseModels.clear();
            await isar.recurringExpenseModels.putAll(_decodeRecurring(value));
            break;
          case 'splitBills':
            await isar.splitBillModels.clear();
            await isar.splitBillModels.putAll(_decodeSplitBills(value));
            break;
          case 'debts':
            await isar.debtModels.clear();
            await isar.debtModels.putAll(_decodeDebts(value));
            break;
          case 'debtPayments':
            await isar.debtPaymentModels.clear();
            await isar.debtPaymentModels.putAll(_decodeDebtPayments(value));
            break;
          case 'importedSms':
            await isar.importedSmsModels.clear();
            await isar.importedSmsModels.putAll(_decodeImportedSms(value));
            break;
          case 'smsLedgerEntries':
            await isar.smsLedgerEntryModels.clear();
            await isar.smsLedgerEntryModels.putAll(
              _decodeSmsLedgerEntries(value),
            );
            break;
          case 'smsLedgerSyncStates':
            await isar.smsLedgerSyncStateModels.clear();
            await isar.smsLedgerSyncStateModels.putAll(
              _decodeSmsLedgerSyncStates(value),
            );
            break;
          case 'predictionCaches':
            await isar.predictionCacheModels.clear();
            await isar.predictionCacheModels.putAll(
              _decodePredictionCaches(value),
            );
            break;
          default:
            // Unknown collection keys are ignored to keep future compatibility.
            break;
        }
      }
    });

    final categoryCount = await isar.categoryModels.count();
    if (categoryCount == 0) {
      final defaults = defaultCategories
          .map(CategoryModel.fromEntity)
          .toList(growable: false);
      await isar.writeTxn(() async {
        await isar.categoryModels.putAll(defaults);
      });
    }
  }

  Map<String, dynamic> _expenseToMap(ExpenseRecordModel model) {
    return <String, dynamic>{
      'id': model.id,
      'amount': model.amount,
      'category': model.category,
      'description': model.description,
      'walletId': model.walletId,
      'isManual': model.isManual,
      'date': _serializeDate(model.date),
    };
  }

  Map<String, dynamic> _incomeToMap(IncomeRecordModel model) {
    return <String, dynamic>{
      'id': model.id,
      'amount': model.amount,
      'source': model.source,
      'description': model.description,
      'walletId': model.walletId,
      'isRecurring': model.isRecurring,
      'isManual': model.isManual,
      'note': model.note,
      'date': _serializeDate(model.date),
      'createdAt': _serializeDate(model.createdAt),
    };
  }

  Map<String, dynamic> _categoryToMap(CategoryModel model) {
    return <String, dynamic>{
      'id': model.id,
      'name': model.name,
      'icon': model.icon,
      'colorValue': model.colorValue,
      'isDefault': model.isDefault,
      'sortOrder': model.sortOrder,
      'createdAt': _serializeDate(model.createdAt),
    };
  }

  Map<String, dynamic> _walletToMap(WalletModel model) {
    return <String, dynamic>{
      'id': model.id,
      'name': model.name,
      'type': model.type.name,
      'emoji': model.emoji,
      'initialBalance': model.initialBalance,
      'currentBalance': model.currentBalance,
      'accountNumber': model.accountNumber,
      'note': model.note,
      'sortOrder': model.sortOrder,
      'isArchived': model.isArchived,
      'createdAt': _serializeDate(model.createdAt),
      'updatedAt': _serializeDate(model.updatedAt),
    };
  }

  Map<String, dynamic> _messageToMap(MessageModel model) {
    return <String, dynamic>{
      'id': model.id,
      'text': model.text,
      'isUser': model.isUser,
      'isReceipt': model.isReceipt,
      'isVoice': model.isVoice,
      'usedRagContext': model.usedRagContext,
      'isRag': model.isRag,
      'ragType': model.ragType,
      'isError': model.isError,
      'promptTokenCount': model.promptTokenCount,
      'outputTokenCount': model.outputTokenCount,
      'totalTokenCount': model.totalTokenCount,
      'createdAt': _serializeDate(model.createdAt),
    };
  }

  Map<String, dynamic> _budgetPlanToMap(BudgetPlanModel model) {
    return <String, dynamic>{
      'id': model.id,
      'monthlyIncome': model.monthlyIncome,
      'categoryBudgetsJson': model.categoryBudgetsJson,
      'totalBudgeted': model.totalBudgeted,
      'savingsAmount': model.savingsAmount,
      'savingsPercentage': model.savingsPercentage,
      'aiExplanation': model.aiExplanation,
      'budgetRule': model.budgetRule,
      'createdAt': _serializeDate(model.createdAt),
      'updatedAt': _serializeDate(model.updatedAt),
      'isActive': model.isActive,
    };
  }

  Map<String, dynamic> _goalToMap(GoalModel model) {
    return <String, dynamic>{
      'id': model.id,
      'title': model.title,
      'emoji': model.emoji,
      'targetAmount': model.targetAmount,
      'savedAmount': model.savedAmount,
      'targetDate': _serializeDate(model.targetDate),
      'createdAt': _serializeDate(model.createdAt),
      'status': model.status.name,
      'notes': model.notes,
    };
  }

  Map<String, dynamic> _recurringToMap(RecurringExpenseModel model) {
    return <String, dynamic>{
      'id': model.id,
      'description': model.description,
      'category': model.category,
      'averageAmount': model.averageAmount,
      'confidenceScore': model.confidenceScore,
      'frequency': model.frequency.name,
      'dayOfMonth': model.dayOfMonth,
      'dayOfWeek': model.dayOfWeek,
      'lastOccurrence': _serializeDate(model.lastOccurrence),
      'nextExpected': _serializeNullableDate(model.nextExpected),
      'isActive': model.isActive,
      'reminderEnabled': model.reminderEnabled,
    };
  }

  Map<String, dynamic> _goalSavingToMap(GoalSavingModel model) {
    return <String, dynamic>{
      'id': model.id,
      'goalId': model.goalId,
      'amount': model.amount,
      'date': _serializeDate(model.date),
      'note': model.note,
    };
  }

  Map<String, dynamic> _splitBillToMap(SplitBillModel model) {
    return <String, dynamic>{
      'id': model.id,
      'title': model.title,
      'totalAmount': model.totalAmount,
      'personsJson': model.personsJson,
      'date': _serializeDate(model.date),
      'notes': model.notes,
      'isSettled': model.isSettled,
      'category': model.category,
    };
  }

  Map<String, dynamic> _debtToMap(DebtModel model) {
    return <String, dynamic>{
      'id': model.id,
      'personName': model.personName,
      'personPhone': model.personPhone,
      'type': model.type.name,
      'originalAmount': model.originalAmount,
      'remainingAmount': model.remainingAmount,
      'description': model.description,
      'category': model.category,
      'walletId': model.walletId,
      'status': model.status.name,
      'createdAt': _serializeDate(model.createdAt),
      'dueDate': _serializeNullableDate(model.dueDate),
      'settledAt': _serializeNullableDate(model.settledAt),
      'note': model.note,
      'reminderEnabled': model.reminderEnabled,
      'isEMI': model.isEMI,
      'annualInterestRate': model.annualInterestRate,
      'totalInstallments': model.totalInstallments,
      'paidInstallments': model.paidInstallments,
      'emiAmount': model.emiAmount,
      'nextInstallmentDate': _serializeNullableDate(model.nextInstallmentDate),
      'installmentDayOfMonth': model.installmentDayOfMonth,
    };
  }

  Map<String, dynamic> _debtPaymentToMap(DebtPaymentModel model) {
    return <String, dynamic>{
      'id': model.id,
      'debtId': model.debtId,
      'amount': model.amount,
      'walletId': model.walletId,
      'note': model.note,
      'paidAt': _serializeDate(model.paidAt),
      'isInstallment': model.isInstallment,
      'installmentNumber': model.installmentNumber,
    };
  }

  Map<String, dynamic> _importedSmsToMap(ImportedSmsModel model) {
    return <String, dynamic>{
      'id': model.id,
      'signature': model.signature,
      'sender': model.sender,
      'smsDate': _serializeDate(model.smsDate),
      'importedAt': _serializeDate(model.importedAt),
      'expenseId': model.expenseId,
      'incomeId': model.incomeId,
    };
  }

  Map<String, dynamic> _smsLedgerEntryToMap(SmsLedgerEntryModel model) {
    return <String, dynamic>{
      'id': model.id,
      'signature': model.signature,
      'smsId': model.smsId,
      'sender': model.sender,
      'rawMessage': model.rawMessage,
      'source': model.source.name,
      'direction': model.direction.name,
      'kind': model.kind.name,
      'type': model.type.name,
      'amount': model.amount,
      'fee': model.fee,
      'balanceAfter': model.balanceAfter,
      'reference': model.reference,
      'counterparty': model.counterparty,
      'merchantName': model.merchantName,
      'accountMask': model.accountMask,
      'rawCategory': model.rawCategory,
      'confidence': model.confidence,
      'occurredAt': _serializeDate(model.occurredAt),
      'receivedAt': _serializeDate(model.receivedAt),
      'isImported': model.isImported,
      'importedAt': _serializeNullableDate(model.importedAt),
      'isIgnored': model.isIgnored,
      'ignoredAt': _serializeNullableDate(model.ignoredAt),
      'createdAt': _serializeDate(model.createdAt),
      'updatedAt': _serializeDate(model.updatedAt),
    };
  }

  Map<String, dynamic> _smsLedgerSyncStateToMap(SmsLedgerSyncStateModel model) {
    return <String, dynamic>{
      'id': model.id,
      'initialBackfillComplete': model.initialBackfillComplete,
      'lastSuccessfulSyncAt': _serializeNullableDate(
        model.lastSuccessfulSyncAt,
      ),
      'lastSyncedSmsDate': _serializeNullableDate(model.lastSyncedSmsDate),
      'lastSyncedSmsId': model.lastSyncedSmsId,
      'createdAt': _serializeDate(model.createdAt),
      'updatedAt': _serializeDate(model.updatedAt),
    };
  }

  Map<String, dynamic> _predictionCacheToMap(PredictionCacheModel model) {
    return <String, dynamic>{
      'id': model.id,
      'predictedTotal': model.predictedTotal,
      'currentTotal': model.currentTotal,
      'lastMonthTotal': model.lastMonthTotal,
      'dailyAverage': model.dailyAverage,
      'projectedDailyAverage': model.projectedDailyAverage,
      'trend': model.trend,
      'confidence': model.confidence,
      'categoryPredictionsJson': model.categoryPredictionsJson,
      'aiInsight': model.aiInsight,
      'generatedAt': _serializeDate(model.generatedAt),
      'currentDay': model.currentDay,
      'daysInMonth': model.daysInMonth,
      'daysRemaining': model.daysRemaining,
    };
  }

  List<ExpenseRecordModel> _decodeExpenses(dynamic raw) {
    final rows = _asMapList(raw);
    return rows
        .map((row) {
          final model = ExpenseRecordModel()
            ..amount = _asInt(row['amount'])
            ..category = _asString(row['category'], fallback: 'Other')
            ..description = _asString(row['description'])
            ..walletId = _asNullableInt(row['walletId'])
            ..isManual = _asBool(row['isManual'])
            ..date = _asDate(row['date']);
          final id = _asNullableInt(row['id']);
          if (id != null && id > 0) {
            model.id = id;
          }
          return model;
        })
        .toList(growable: false);
  }

  List<IncomeRecordModel> _decodeIncome(dynamic raw) {
    final rows = _asMapList(raw);
    return rows
        .map((row) {
          final date = _asDate(row['date']);
          final model = IncomeRecordModel()
            ..amount = _asInt(row['amount'])
            ..source = _asString(row['source'], fallback: 'Other')
            ..description = _asString(row['description'])
            ..walletId = _asNullableInt(row['walletId'])
            ..isRecurring = _asBool(row['isRecurring'])
            ..isManual = _asBool(row['isManual'])
            ..note = _asNullableString(row['note'])
            ..date = date
            ..createdAt = _asDate(row['createdAt'], fallback: date);
          final id = _asNullableInt(row['id']);
          if (id != null && id > 0) {
            model.id = id;
          }
          return model;
        })
        .toList(growable: false);
  }

  List<CategoryModel> _decodeCategories(dynamic raw) {
    final rows = _asMapList(raw);
    return rows
        .map((row) {
          final model = CategoryModel()
            ..name = _asString(row['name'], fallback: 'Other')
            ..icon = _asString(row['icon'], fallback: 'category')
            ..colorValue = _asInt(row['colorValue'], fallback: 0xFF80868B)
            ..isDefault = _asBool(row['isDefault'])
            ..sortOrder = _asInt(row['sortOrder'])
            ..createdAt = _asDate(row['createdAt']);
          final id = _asNullableInt(row['id']);
          if (id != null && id > 0) {
            model.id = id;
          }
          return model;
        })
        .toList(growable: false);
  }

  List<WalletModel> _decodeWallets(dynamic raw) {
    final rows = _asMapList(raw);
    return rows
        .map((row) {
          final model = WalletModel()
            ..name = _asString(row['name'], fallback: 'Wallet')
            ..type = _enumByName(
              WalletType.values,
              _asString(row['type'], fallback: WalletType.cash.name),
              WalletType.cash,
            )
            ..emoji = _asString(row['emoji'], fallback: '💼')
            ..initialBalance = _asDouble(row['initialBalance'])
            ..currentBalance = _asDouble(row['currentBalance'])
            ..accountNumber = _asNullableString(row['accountNumber'])
            ..note = _asNullableString(row['note'])
            ..sortOrder = _asInt(row['sortOrder'])
            ..isArchived = _asBool(row['isArchived'])
            ..createdAt = _asDate(row['createdAt'])
            ..updatedAt = _asDate(row['updatedAt']);
          final id = _asNullableInt(row['id']);
          if (id != null && id > 0) {
            model.id = id;
          }
          return model;
        })
        .toList(growable: false);
  }

  List<MessageModel> _decodeMessages(dynamic raw) {
    final rows = _asMapList(raw);
    return rows
        .map((row) {
          final model = MessageModel()
            ..text = _asString(row['text'])
            ..isUser = _asBool(row['isUser'])
            ..isReceipt = _asBool(row['isReceipt'])
            ..isVoice = _asBool(row['isVoice'])
            ..usedRagContext = _asBool(row['usedRagContext'])
            ..isRag = _asBool(row['isRag'])
            ..ragType = _asNullableString(row['ragType'])
            ..isError = _asBool(row['isError'])
            ..promptTokenCount = _asNullableInt(row['promptTokenCount'])
            ..outputTokenCount = _asNullableInt(row['outputTokenCount'])
            ..totalTokenCount = _asNullableInt(row['totalTokenCount'])
            ..createdAt = _asDate(row['createdAt']);
          final id = _asNullableInt(row['id']);
          if (id != null && id > 0) {
            model.id = id;
          }
          return model;
        })
        .toList(growable: false);
  }

  List<BudgetPlanModel> _decodeBudgetPlans(dynamic raw) {
    final rows = _asMapList(raw);
    return rows
        .map((row) {
          final budgetsRaw = row['categoryBudgetsJson'];
          final categoryBudgetsJson = budgetsRaw is String
              ? budgetsRaw
              : jsonEncode(budgetsRaw ?? <String, dynamic>{});
          final model = BudgetPlanModel()
            ..monthlyIncome = _asDouble(row['monthlyIncome'])
            ..categoryBudgetsJson = categoryBudgetsJson
            ..totalBudgeted = _asDouble(row['totalBudgeted'])
            ..savingsAmount = _asDouble(row['savingsAmount'])
            ..savingsPercentage = _asDouble(row['savingsPercentage'])
            ..aiExplanation = _asString(row['aiExplanation'])
            ..budgetRule = _asString(row['budgetRule'])
            ..createdAt = _asDate(row['createdAt'])
            ..updatedAt = _asDate(row['updatedAt'])
            ..isActive = _asBool(row['isActive']);
          final id = _asNullableInt(row['id']);
          if (id != null && id > 0) {
            model.id = id;
          }
          return model;
        })
        .toList(growable: false);
  }

  List<GoalModel> _decodeGoals(dynamic raw) {
    final rows = _asMapList(raw);
    return rows
        .map((row) {
          final model = GoalModel()
            ..title = _asString(row['title'], fallback: 'Goal')
            ..emoji = _asString(row['emoji'], fallback: '🎯')
            ..targetAmount = _asDouble(row['targetAmount'])
            ..savedAmount = _asDouble(row['savedAmount'])
            ..targetDate = _asDate(row['targetDate'])
            ..createdAt = _asDate(row['createdAt'])
            ..status = _enumByName(
              GoalStatus.values,
              _asString(row['status'], fallback: GoalStatus.active.name),
              GoalStatus.active,
            )
            ..notes = _asNullableString(row['notes']);
          final id = _asNullableInt(row['id']);
          if (id != null && id > 0) {
            model.id = id;
          }
          return model;
        })
        .toList(growable: false);
  }

  List<RecurringExpenseModel> _decodeRecurring(dynamic raw) {
    final rows = _asMapList(raw);
    return rows
        .map((row) {
          final model = RecurringExpenseModel()
            ..description = _asString(row['description'])
            ..category = _asString(row['category'], fallback: 'Other')
            ..averageAmount = _asDouble(row['averageAmount'])
            ..confidenceScore = _asDouble(row['confidenceScore'])
            ..frequency = _enumByName(
              RecurringFrequency.values,
              _asString(
                row['frequency'],
                fallback: RecurringFrequency.monthly.name,
              ),
              RecurringFrequency.monthly,
            )
            ..dayOfMonth = _asInt(row['dayOfMonth'])
            ..dayOfWeek = _asInt(row['dayOfWeek'])
            ..lastOccurrence = _asDate(row['lastOccurrence'])
            ..nextExpected = _asNullableDate(row['nextExpected'])
            ..isActive = _asBool(row['isActive'])
            ..reminderEnabled = _asBool(row['reminderEnabled']);
          final id = _asNullableInt(row['id']);
          if (id != null && id > 0) {
            model.id = id;
          }
          return model;
        })
        .toList(growable: false);
  }

  List<GoalSavingModel> _decodeGoalSavings(dynamic raw) {
    final rows = _asMapList(raw);
    return rows
        .map((row) {
          final model = GoalSavingModel()
            ..goalId = _asInt(row['goalId'])
            ..amount = _asDouble(row['amount'])
            ..date = _asDate(row['date'])
            ..note = _asNullableString(row['note']);
          final id = _asNullableInt(row['id']);
          if (id != null && id > 0) {
            model.id = id;
          }
          return model;
        })
        .toList(growable: false);
  }

  List<SplitBillModel> _decodeSplitBills(dynamic raw) {
    final rows = _asMapList(raw);
    return rows
        .map((row) {
          final personsRaw = row['personsJson'];
          final personsJson = personsRaw is String
              ? personsRaw
              : jsonEncode(personsRaw ?? const []);
          final model = SplitBillModel()
            ..title = _asString(row['title'])
            ..totalAmount = _asDouble(row['totalAmount'])
            ..personsJson = personsJson
            ..date = _asDate(row['date'])
            ..notes = _asNullableString(row['notes'])
            ..isSettled = _asBool(row['isSettled'])
            ..category = _asString(row['category'], fallback: 'Other');
          final id = _asNullableInt(row['id']);
          if (id != null && id > 0) {
            model.id = id;
          }
          return model;
        })
        .toList(growable: false);
  }

  List<DebtModel> _decodeDebts(dynamic raw) {
    final rows = _asMapList(raw);
    return rows
        .map((row) {
          final model = DebtModel()
            ..personName = _asString(row['personName'])
            ..personPhone = _asNullableString(row['personPhone'])
            ..type = _enumByName(
              DebtType.values,
              _asString(row['type'], fallback: DebtType.iOwe.name),
              DebtType.iOwe,
            )
            ..originalAmount = _asDouble(row['originalAmount'])
            ..remainingAmount = _asDouble(row['remainingAmount'])
            ..description = _asNullableString(row['description'])
            ..category = _asNullableString(row['category'])
            ..walletId = _asNullableInt(row['walletId'])
            ..status = _enumByName(
              DebtStatus.values,
              _asString(row['status'], fallback: DebtStatus.active.name),
              DebtStatus.active,
            )
            ..createdAt = _asDate(row['createdAt'])
            ..dueDate = _asNullableDate(row['dueDate'])
            ..settledAt = _asNullableDate(row['settledAt'])
            ..note = _asNullableString(row['note'])
            ..reminderEnabled = _asBool(row['reminderEnabled'])
            ..isEMI = _asBool(row['isEMI'])
            ..annualInterestRate = _asDouble(row['annualInterestRate'])
            ..totalInstallments = _asInt(row['totalInstallments'])
            ..paidInstallments = _asInt(row['paidInstallments'])
            ..emiAmount = _asDouble(row['emiAmount'])
            ..nextInstallmentDate = _asNullableDate(row['nextInstallmentDate'])
            ..installmentDayOfMonth = _asNullableInt(
              row['installmentDayOfMonth'],
            );
          final id = _asNullableInt(row['id']);
          if (id != null && id > 0) {
            model.id = id;
          }
          return model;
        })
        .toList(growable: false);
  }

  List<DebtPaymentModel> _decodeDebtPayments(dynamic raw) {
    final rows = _asMapList(raw);
    return rows
        .map((row) {
          final model = DebtPaymentModel()
            ..debtId = _asInt(row['debtId'])
            ..amount = _asDouble(row['amount'])
            ..walletId = _asNullableInt(row['walletId'])
            ..note = _asNullableString(row['note'])
            ..paidAt = _asDate(row['paidAt'])
            ..isInstallment = _asBool(row['isInstallment'])
            ..installmentNumber = _asNullableInt(row['installmentNumber']);
          final id = _asNullableInt(row['id']);
          if (id != null && id > 0) {
            model.id = id;
          }
          return model;
        })
        .toList(growable: false);
  }

  List<ImportedSmsModel> _decodeImportedSms(dynamic raw) {
    final rows = _asMapList(raw);
    return rows
        .map((row) {
          final model = ImportedSmsModel()
            ..signature = _asString(row['signature'])
            ..sender = _asString(row['sender'])
            ..smsDate = _asDate(row['smsDate'])
            ..importedAt = _asDate(row['importedAt'])
            ..expenseId = _asNullableInt(row['expenseId'])
            ..incomeId = _asNullableInt(row['incomeId']);
          final id = _asNullableInt(row['id']);
          if (id != null && id > 0) {
            model.id = id;
          }
          return model;
        })
        .toList(growable: false);
  }

  List<SmsLedgerEntryModel> _decodeSmsLedgerEntries(dynamic raw) {
    final rows = _asMapList(raw);
    return rows
        .map((row) {
          final model = SmsLedgerEntryModel()
            ..signature = _asString(row['signature'])
            ..smsId = _asInt(row['smsId'])
            ..sender = _asString(row['sender'])
            ..rawMessage = _asString(row['rawMessage'])
            ..source = _enumByName(
              ParsedTransactionSource.values,
              _asString(
                row['source'],
                fallback: ParsedTransactionSource.bank.name,
              ),
              ParsedTransactionSource.bank,
            )
            ..direction = _enumByName(
              ParsedTransactionDirection.values,
              _asString(
                row['direction'],
                fallback: ParsedTransactionDirection.unknown.name,
              ),
              ParsedTransactionDirection.unknown,
            )
            ..kind = _enumByName(
              ParsedTransactionKind.values,
              _asString(
                row['kind'],
                fallback: ParsedTransactionKind.payment.name,
              ),
              ParsedTransactionKind.payment,
            )
            ..type = _enumByName(
              TransactionType.values,
              _asString(row['type'], fallback: TransactionType.expense.name),
              TransactionType.expense,
            )
            ..amount = _asDouble(row['amount'])
            ..fee = _asNullableDouble(row['fee'])
            ..balanceAfter = _asNullableDouble(row['balanceAfter'])
            ..reference = _asNullableString(row['reference'])
            ..counterparty = _asNullableString(row['counterparty'])
            ..merchantName = _asNullableString(row['merchantName'])
            ..accountMask = _asNullableString(row['accountMask'])
            ..rawCategory = _asNullableString(row['rawCategory'])
            ..confidence = _asDouble(row['confidence'], fallback: 1)
            ..occurredAt = _asDate(row['occurredAt'])
            ..receivedAt = _asDate(row['receivedAt'])
            ..isImported = _asBool(row['isImported'])
            ..importedAt = _asNullableDate(row['importedAt'])
            ..isIgnored = _asBool(row['isIgnored'])
            ..ignoredAt = _asNullableDate(row['ignoredAt'])
            ..createdAt = _asDate(row['createdAt'])
            ..updatedAt = _asDate(row['updatedAt']);
          final id = _asNullableInt(row['id']);
          if (id != null && id > 0) {
            model.id = id;
          }
          return model;
        })
        .toList(growable: false);
  }

  List<SmsLedgerSyncStateModel> _decodeSmsLedgerSyncStates(dynamic raw) {
    final rows = _asMapList(raw);
    return rows
        .map((row) {
          final model = SmsLedgerSyncStateModel()
            ..initialBackfillComplete = _asBool(row['initialBackfillComplete'])
            ..lastSuccessfulSyncAt = _asNullableDate(
              row['lastSuccessfulSyncAt'],
            )
            ..lastSyncedSmsDate = _asNullableDate(row['lastSyncedSmsDate'])
            ..lastSyncedSmsId = _asNullableInt(row['lastSyncedSmsId'])
            ..createdAt = _asDate(row['createdAt'])
            ..updatedAt = _asDate(row['updatedAt']);
          final id = _asNullableInt(row['id']);
          if (id != null && id > 0) {
            model.id = id;
          }
          return model;
        })
        .toList(growable: false);
  }

  List<PredictionCacheModel> _decodePredictionCaches(dynamic raw) {
    final rows = _asMapList(raw);
    return rows
        .map((row) {
          final model = PredictionCacheModel()
            ..predictedTotal = _asDouble(row['predictedTotal'])
            ..currentTotal = _asDouble(row['currentTotal'])
            ..lastMonthTotal = _asDouble(row['lastMonthTotal'])
            ..dailyAverage = _asDouble(row['dailyAverage'])
            ..projectedDailyAverage = _asDouble(row['projectedDailyAverage'])
            ..trend = _asString(row['trend'], fallback: 'stable')
            ..confidence = _asString(row['confidence'], fallback: 'medium')
            ..categoryPredictionsJson = _asString(
              row['categoryPredictionsJson'],
              fallback: '{}',
            )
            ..aiInsight = _asString(row['aiInsight'])
            ..generatedAt = _asDate(row['generatedAt'])
            ..currentDay = _asInt(row['currentDay'])
            ..daysInMonth = _asInt(row['daysInMonth'])
            ..daysRemaining = _asInt(row['daysRemaining']);
          final id = _asNullableInt(row['id']);
          if (id != null && id > 0) {
            model.id = id;
          }
          return model;
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _asMapList(dynamic raw) {
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  String _serializeDate(DateTime value) {
    return value.toIso8601String();
  }

  String? _serializeNullableDate(DateTime? value) {
    return value?.toIso8601String();
  }

  DateTime _asDate(dynamic value, {DateTime? fallback}) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed.isUtc ? parsed.toLocal() : parsed;
      }
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    final safeFallback = fallback;
    if (safeFallback != null) {
      return safeFallback.isUtc ? safeFallback.toLocal() : safeFallback;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime? _asNullableDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return _asDate(value);
  }

  String _asString(dynamic value, {String fallback = ''}) {
    if (value is String) {
      return value;
    }
    if (value == null) {
      return fallback;
    }
    return value.toString();
  }

  String? _asNullableString(dynamic value) {
    if (value == null) {
      return null;
    }
    final raw = value.toString();
    return raw;
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  int? _asNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  double _asDouble(dynamic value, {double fallback = 0}) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  double? _asNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    return fallback;
  }

  T _enumByName<T extends Enum>(List<T> values, String name, T fallback) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return fallback;
  }
}
