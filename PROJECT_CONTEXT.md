# Project Context

## Overview
`gemini_chat` is a Flutter expense tracker for Bangladesh, branded in the UI as `PocketPilot AI`.

Core direction:
- Bengali-first UX
- local-first data storage with Isar
- OpenAI-assisted expense intelligence where it adds value
- simple math/local analysis for features that do not need AI

## Current Stack
- Flutter 3.x
- Riverpod for state management
- Isar for local persistence
- SharedPreferences for lightweight app settings and caches
- OpenAI GPT-4o mini for text-based AI features
- OpenAI Whisper for speech-to-text
- Google ML Kit for OCR
- `flutter_local_notifications` for reminders and alerts

## Main App Shell
Bottom navigation currently has 5 tabs:
1. `হোম`
2. `চ্যাট`
3. `খরচ`
4. `বিশ্লেষণ`
5. `Split`

App bootstrap flow:
1. Splash
2. Onboarding
3. Main shell

## Data Storage
Main Isar collections registered in [main.dart](/Users/jotnosqh/Desktop/development/ai-project/gemini_chat/lib/main.dart):
- `MessageModel`
- `ExpenseRecordModel`
- `CategoryModel`
- `BudgetPlanModel`
- `GoalModel`
- `GoalSavingModel`
- `RecurringExpenseModel`
- `SplitBillModel`
- `PredictionCacheModel`

Local-only persisted data includes:
- expenses
- chat messages
- categories
- budget plans
- goals and goal savings
- recurring expense patterns
- split bills
- prediction cache

## AI vs Local Logic
Uses OpenAI GPT-4o mini:
- chat expense extraction
- receipt understanding
- RAG-based finance responses
- expense prediction
- AI budget planner

Does not need AI:
- recurring expense detection
- goal tracking math
- split bill settlements
- anomaly detection
- category budget progress

## Current Feature Inventory

### Core Expense
1. AI chat expense entry
2. Voice expense entry
3. Receipt scan expense entry
4. Multiple expenses from one message
5. Past-date expense entry
6. Manual add, edit, delete
7. Expense list with search and filters
8. Dashboard summary
9. Analytics charts and breakdowns

### Smart / AI
10. RAG personal finance insights
11. AI Budget Planner
12. Regular Expenses detection
13. Expense Prediction
14. Smart Split Bill
15. Goal Tracking
16. Spending Alerts

### Management / Customization
17. Custom category management
18. Custom categories supported in AI parsing
19. CSV export
20. Manual category budget settings

### System / UX
21. Notifications and budget alerts
22. Biometric lock
23. Dark mode / theme settings

Support flows also present:
- Splash screen
- Onboarding
- Settings screen

## Feature Notes

### Categories
- Default categories are seeded on app bootstrap.
- Users can add custom categories.
- `categoryProvider` merges stored custom categories with guaranteed defaults.
- AI Budget Planner reads category names from `categoryProvider`, so custom categories are included during new budget generation.
- If a custom category is added after a budget already exists, the budget should be regenerated to include it in the AI-generated plan.

### AI Budget Planner
Key files:
- [budget_provider.dart](/Users/jotnosqh/Desktop/development/ai-project/gemini_chat/lib/features/budget/presentation/providers/budget_provider.dart)
- [budget_planner_screen.dart](/Users/jotnosqh/Desktop/development/ai-project/gemini_chat/lib/features/budget/presentation/screens/budget_planner_screen.dart)
- [budget_dashboard.dart](/Users/jotnosqh/Desktop/development/ai-project/gemini_chat/lib/features/budget/presentation/widgets/budget_dashboard.dart)

Behavior:
- user enters income and selects a budget rule
- AI generates category-wise monthly limits
- active budget is saved locally
- notification budget limits are updated from the active plan
- dashboard and RAG can read the active budget

### Expense Prediction
- uses GPT-4o mini
- caches the latest prediction in Isar
- analytics shows the full prediction card
- dashboard shows a small teaser

### Regular Expenses
- local math-based recurring pattern detection
- confidence score is part of the entity
- UI shows recurrence, next expected date, and confidence

### Goal Tracking
- goal progress is local math
- RAG can answer goal-related questions from local context
- goal reminders are notification-based

### Spending Alerts
- local anomaly detection
- analytics has an anomaly tab
- dashboard can show alert summary
- high severity anomalies can trigger notifications

### Smart Split Bill
- fully local calculation
- active and completed split tabs
- detail view shows settlement suggestions
- can save personal share as an expense

## RAG Context Coverage
RAG context builder currently includes local data for relevant questions about:
- expenses
- goals
- active budget
- recurring expenses
- prediction
- anomalies

Important file:
- [rag_context_builder.dart](/Users/jotnosqh/Desktop/development/ai-project/gemini_chat/lib/core/ai/rag_context_builder.dart)

## Important Directories
- [lib/core/ai](/Users/jotnosqh/Desktop/development/ai-project/gemini_chat/lib/core/ai): prompt builders, parsers, RAG
- [lib/core/database/models](/Users/jotnosqh/Desktop/development/ai-project/gemini_chat/lib/core/database/models): Isar models
- [lib/core/notifications](/Users/jotnosqh/Desktop/development/ai-project/gemini_chat/lib/core/notifications): reminders, notification providers, budget sync
- [lib/features/chat](/Users/jotnosqh/Desktop/development/ai-project/gemini_chat/lib/features/chat): AI chat flow
- [lib/features/expense](/Users/jotnosqh/Desktop/development/ai-project/gemini_chat/lib/features/expense): dashboard, analytics, expense list
- [lib/features/budget](/Users/jotnosqh/Desktop/development/ai-project/gemini_chat/lib/features/budget): AI budget planner
- [lib/features/goals](/Users/jotnosqh/Desktop/development/ai-project/gemini_chat/lib/features/goals): saving goals
- [lib/features/prediction](/Users/jotnosqh/Desktop/development/ai-project/gemini_chat/lib/features/prediction): end-of-month prediction
- [lib/features/recurring](/Users/jotnosqh/Desktop/development/ai-project/gemini_chat/lib/features/recurring): recurring expense detection
- [lib/features/anomaly](/Users/jotnosqh/Desktop/development/ai-project/gemini_chat/lib/features/anomaly): spending alerts
- [lib/features/split](/Users/jotnosqh/Desktop/development/ai-project/gemini_chat/lib/features/split): split bill flow

## Environment
Expected `.env` keys:
- `OPENAI_API_KEY`

## Useful Dev Commands
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --debug
./tool/run_macos_local.sh
```

## Known Dev Note
As of 2026-04-08, macOS local run builds successfully but currently hits a notification initialization error at startup because macOS-specific initialization settings are not being passed to `flutter_local_notifications`.

Relevant files:
- [notification_service.dart](/Users/jotnosqh/Desktop/development/ai-project/gemini_chat/lib/core/notifications/notification_service.dart)
- [main.dart](/Users/jotnosqh/Desktop/development/ai-project/gemini_chat/lib/main.dart)
