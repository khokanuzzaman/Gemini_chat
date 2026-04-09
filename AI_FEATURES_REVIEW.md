# PocketPilot AI - AI Features Review

Reviewed on: 2026-04-23  
Scope: source-code review of `lib/`, `README.md`, `PROJECT_CONTEXT.md`, and `pubspec.yaml`

## High-Level Summary

PocketPilot AI has a Bengali-first AI layer centered around chat-based finance entry and personal finance insights. The app uses OpenAI for generative/text understanding features, OpenAI Whisper for speech-to-text, Google ML Kit for local OCR, and local statistical services for anomaly/recurring pattern detection.

Important distinction: the current RAG implementation is prompt-context RAG over local finance data. It does not use embeddings or a vector database.

## AI Feature Inventory

| Feature | Status | Engine | What it does | Main files |
| --- | --- | --- | --- | --- |
| Bengali AI chat assistant | Implemented | OpenAI `gpt-4o-mini` | Streams Bengali finance assistant replies and detects structured finance actions | `lib/features/chat/data/datasources/openai_chat_datasource.dart`, `lib/features/chat/presentation/providers/chat_provider.dart` |
| Natural-language expense entry | Implemented | OpenAI + parser | Converts Bengali/English chat messages into single or multiple expense drafts | `lib/core/ai/prompt_builder.dart`, `lib/core/ai/expense_parser.dart`, `lib/core/ai/expense_result.dart` |
| Natural-language income entry | Implemented | OpenAI + parser | Detects income entries, source type, recurring flag, and date | `lib/core/ai/prompt_builder.dart`, `lib/core/ai/income_data.dart`, `lib/features/chat/presentation/widgets/income_confirmation_widget.dart` |
| Mixed expense + income extraction | Implemented | OpenAI + parser | Can parse responses containing both expenses and incomes in one structured result | `lib/core/ai/expense_parser.dart`, `lib/features/chat/presentation/widgets/multiple_income_confirmation_widget.dart` |
| Voice input | Implemented | OpenAI Whisper `whisper-1` | Records audio, transcribes speech, then sends transcript through the chat/expense flow | `lib/core/audio/voice_recorder_service.dart`, `lib/features/chat/data/datasources/openai_voice_datasource.dart` |
| Receipt/image read | Implemented | Google ML Kit OCR + OpenAI | Picks camera/gallery image, extracts receipt text locally, validates receipt-like format, then AI parses expense details | `lib/core/scanner/receipt_scanner_service.dart`, `lib/core/mlkit/ocr_service.dart`, `lib/features/chat/data/datasources/openai_receipt_datasource.dart` |
| RAG personal finance Q&A | Implemented | Local context builder + OpenAI | Answers questions using expenses, budgets, goals, recurring patterns, anomalies, and predictions | `lib/core/ai/rag_context_builder.dart`, `lib/core/ai/rag_prompt_builder.dart`, `lib/core/ai/rag_response_parser.dart` |
| RAG visual cards | Implemented | Parser + UI | Converts AI/RAG answers into summary, category, comparison, and today cards | `lib/features/chat/presentation/widgets/rag/`, `lib/core/ai/rag_response_parser.dart` |
| AI budget planner | Implemented | OpenAI `gpt-4o-mini` | Generates budget plan JSON and Bengali explanation from income and spending history | `lib/features/budget/data/datasources/budget_planner_datasource.dart`, `lib/features/budget/presentation/screens/budget_planner_screen.dart` |
| Expense prediction | Implemented | OpenAI `gpt-4o-mini` | Predicts end-of-month spend, confidence, trend, category forecasts, and advice | `lib/features/prediction/data/datasources/prediction_datasource.dart`, `lib/features/prediction/presentation/providers/prediction_provider.dart` |
| Anomaly detection | Implemented | Local statistical logic | Detects category spikes, large transactions, daily spikes, and frequency increases | `lib/features/anomaly/data/services/anomaly_detection_service.dart` |
| Recurring expense detection | Implemented | Local statistical logic | Detects weekly/monthly recurring patterns by category, description, interval, and confidence score | `lib/features/recurring/data/services/recurring_detection_service.dart` |
| Split bill suggestion | Implemented | AI parser result + local calculation | Detects split intent from parsed expense data and suggests per-person split | `lib/core/ai/expense_result.dart`, `lib/features/split/presentation/widgets/split_suggestion_widget.dart` |
| Token usage and rate-limit tracking | Implemented | OpenAI response metadata | Tracks estimated/live token usage and rate-limit headers for chat, voice, receipt, budget, prediction | `lib/core/ai/token_usage.dart`, `lib/core/ai/rate_limit_snapshot.dart` |

## Feature Details

### 1. Bengali AI Chat

The main chat feature is a streaming Bengali finance assistant. It uses OpenAI Chat Completions with `gpt-4o-mini`, streams response tokens, and shows the in-progress answer in the chat UI.

Key behavior:

- Understands Bengali-first expense/income messages.
- Uses a finance-specific system prompt.
- Returns conversational replies plus structured JSON when an expense or income is detected.
- Supports streaming usage metadata through `stream_options.include_usage`.
- Tracks OpenAI rate-limit headers when available.

Key files:

- `lib/core/constants/api_constants.dart`
- `lib/features/chat/data/datasources/openai_chat_datasource.dart`
- `lib/features/chat/data/repositories/chat_repository_impl.dart`
- `lib/features/chat/presentation/providers/chat_provider.dart`
- `lib/features/chat/presentation/screens/chat_screen.dart`

### 2. Natural-Language Expense Detection

Users can type messages like Bengali expense statements and the AI can return structured expense data. The parser then turns the AI response into app-confirmable expense drafts.

Supported capabilities found in code:

- Single expense detection.
- Multiple expense detection.
- Category assignment using built-in and custom categories.
- Bengali/English date extraction.
- Past-date handling such as আজকে, গতকাল, পরশু, last week, and date formats.
- Split bill detection with person count.
- Receipt-style expense result support.

Key files:

- `lib/core/ai/prompt_builder.dart`
- `lib/core/ai/expense_parser.dart`
- `lib/core/ai/expense_result.dart`
- `lib/core/ai/bangla_date_parser.dart`
- `lib/features/chat/presentation/widgets/expense_confirmation_widget.dart`
- `lib/features/chat/presentation/widgets/multiple_expense_confirmation_widget.dart`

### 3. Natural-Language Income Detection

The AI prompt also asks for income extraction. Parsed income entries are shown through confirmation widgets before saving.

Supported capabilities found in code:

- Single income detection.
- Multiple income detection.
- Mixed expense and income response handling.
- Income source classification.
- Recurring income flag.
- Date parsing for income entries.

Key files:

- `lib/core/ai/prompt_builder.dart`
- `lib/core/ai/income_data.dart`
- `lib/core/ai/expense_parser.dart`
- `lib/features/chat/presentation/widgets/income_confirmation_widget.dart`
- `lib/features/chat/presentation/widgets/multiple_income_confirmation_widget.dart`

### 4. Voice Input

Voice input records user audio and sends it to OpenAI Whisper. The transcript is then passed into the same chat/expense/income flow.

Flow:

1. User taps mic in chat.
2. App records audio locally.
3. Audio is sent to OpenAI Whisper `whisper-1`.
4. Transcript is displayed/used as the user message.
5. The normal AI chat parser detects expenses, incomes, or general questions.

Key files:

- `lib/core/audio/voice_recorder_service.dart`
- `lib/features/chat/data/datasources/openai_voice_datasource.dart`
- `lib/features/chat/domain/usecases/send_voice_message_usecase.dart`
- `lib/features/chat/presentation/providers/chat_provider.dart`
- `lib/features/chat/presentation/widgets/recording_indicator.dart`

### 5. Receipt/Image Read

The app reads receipt images through a hybrid pipeline. It does not currently send images directly to a vision model. Instead, the image is processed locally, OCR text is extracted, and the extracted text is sent to OpenAI for receipt understanding.

Flow:

1. User chooses camera or gallery.
2. Image is optionally preprocessed/cropped.
3. Google ML Kit extracts text locally.
4. Receipt format checker scores whether the OCR text looks like a receipt.
5. OpenAI parses merchant, amount, date, category, confidence, and line-item style details from OCR text.
6. User sees a receipt confirmation widget before saving.

Key files:

- `lib/core/scanner/receipt_scanner_service.dart`
- `lib/core/scanner/receipt_image_preprocessor.dart`
- `lib/core/scanner/receipt_format_checker.dart`
- `lib/core/mlkit/ocr_service.dart`
- `lib/features/chat/data/datasources/openai_receipt_datasource.dart`
- `lib/features/chat/domain/usecases/scan_receipt_usecase.dart`
- `lib/features/chat/presentation/widgets/receipt_confirmation_widget.dart`

### 6. RAG Personal Finance Q&A

RAG mode builds a local finance context and injects it into the OpenAI prompt. This lets the assistant answer questions about actual user spending and financial state.

Context sources found in code:

- Current month expenses.
- Today expenses.
- Last month and comparison period expenses.
- Category totals.
- Recent transactions.
- Active budget plan.
- Savings goals.
- Recurring expenses.
- Anomaly alerts.
- Prediction data.

Supported RAG answer/card types:

- Monthly summary.
- Category breakdown.
- Month-to-month comparison.
- Today summary.
- General financial answer.

Important implementation note:

- This is not embedding-based RAG.
- No vector database or embedding API usage was found.
- The app builds structured local context and sends that context to `gpt-4o-mini`.

Key files:

- `lib/core/ai/rag_context_builder.dart`
- `lib/core/ai/rag_prompt_builder.dart`
- `lib/core/ai/rag_response_parser.dart`
- `lib/features/chat/presentation/providers/chat_provider.dart`
- `lib/features/chat/presentation/widgets/rag/rag_summary_widget.dart`
- `lib/features/chat/presentation/widgets/rag/rag_category_widget.dart`
- `lib/features/chat/presentation/widgets/rag/rag_comparison_widget.dart`
- `lib/features/chat/presentation/widgets/rag/rag_today_widget.dart`

### 7. AI Budget Planner

The budget planner uses OpenAI to generate category-level budget recommendations. It combines user income, previous category spending, and a selected budget rule, then expects JSON plus Bengali explanation.

Outputs include:

- Total budget.
- Category budget map.
- Savings target.
- Budget rule.
- Bengali AI explanation.

Key files:

- `lib/features/budget/data/datasources/budget_planner_datasource.dart`
- `lib/features/budget/presentation/providers/budget_provider.dart`
- `lib/features/budget/presentation/screens/budget_planner_screen.dart`
- `lib/features/budget/domain/entities/budget_plan_entity.dart`

### 8. Expense Prediction

The prediction feature uses OpenAI to forecast end-of-month spending based on current-month and last-month expense data.

Outputs include:

- Predicted end-of-month total.
- Current total.
- Confidence.
- Trend.
- Days remaining.
- Category predictions.
- Bengali reasoning and tips.

Key files:

- `lib/features/prediction/data/datasources/prediction_datasource.dart`
- `lib/features/prediction/data/repositories/prediction_repository_impl.dart`
- `lib/features/prediction/presentation/providers/prediction_provider.dart`
- `lib/features/prediction/presentation/widgets/prediction_card.dart`
- `lib/features/prediction/presentation/widgets/prediction_widget.dart`

### 9. Local Anomaly Detection

Anomaly detection is local statistical intelligence, not an OpenAI call. It analyzes stored expenses to find suspicious or unusual spending patterns.

Detected anomaly types:

- Category spike.
- Large transaction.
- Daily spending spike.
- Spending frequency increase.

Key files:

- `lib/features/anomaly/data/services/anomaly_detection_service.dart`
- `lib/features/anomaly/presentation/providers/anomaly_provider.dart`
- `lib/features/anomaly/presentation/screens/anomaly_screen.dart`
- `lib/features/anomaly/presentation/widgets/anomaly_alert_card.dart`

### 10. Local Recurring Expense Detection

Recurring expense detection is also local statistical intelligence. It groups expenses by category and normalized description, then detects weekly/monthly patterns.

Detected pattern data:

- Frequency.
- Average amount.
- Day of week or day of month.
- Last occurrence.
- Next expected date.
- Confidence score.

Key files:

- `lib/features/recurring/data/services/recurring_detection_service.dart`
- `lib/features/recurring/presentation/providers/recurring_provider.dart`
- `lib/features/recurring/presentation/screens/recurring_screen.dart`

### 11. Split Bill Intelligence

The chat parser can identify split bill intent from an expense result. The UI then calculates per-person amount locally and offers split-bill creation.

Key files:

- `lib/core/ai/expense_result.dart`
- `lib/features/split/presentation/widgets/split_suggestion_widget.dart`
- `lib/features/split/presentation/screens/add_edit_split_screen.dart`

### 12. Token Usage and Rate Limits

The app tracks OpenAI usage metadata where available and keeps service-specific rate-limit snapshots.

Tracked services include:

- Chat.
- Voice.
- Receipt.
- Budget planner.
- Prediction.

Key files:

- `lib/core/ai/token_usage.dart`
- `lib/core/ai/rate_limit_snapshot.dart`
- `lib/features/chat/presentation/widgets/usage_details_sheet.dart`

## AI Data Flow Map

### Chat Text Flow

```text
ChatScreen
  -> ChatNotifier / chatProvider
  -> SendMessageUseCase
  -> ChatRepositoryImpl
  -> OpenAiChatDataSource
  -> OpenAI gpt-4o-mini streaming response
  -> ExpenseParser / RagResponseParser
  -> MessageBubble + confirmation widgets / RAG cards
```

### Voice Flow

```text
Mic button
  -> VoiceRecorderService
  -> OpenAiVoiceDataSource
  -> OpenAI Whisper transcript
  -> ChatRepositoryImpl
  -> normal chat text flow
```

### Receipt/Image Flow

```text
Camera/Gallery
  -> ReceiptScannerService
  -> ReceiptImagePreprocessor
  -> Google ML Kit OCR
  -> ReceiptFormatChecker
  -> OpenAiReceiptDataSource
  -> ReceiptConfirmationWidget
```

### RAG Flow

```text
RAG toggle enabled
  -> RagContextBuilder reads local Isar data
  -> RagPromptBuilder injects context
  -> OpenAiChatDataSource streams answer
  -> RagResponseParser chooses card type
  -> RAG widgets render structured finance card
```

## Models, APIs, and Engines

| Area | Model / Engine | Source |
| --- | --- | --- |
| Chat assistant | OpenAI `gpt-4o-mini` | `ApiConstants.chatModel` |
| Receipt AI parsing | OpenAI `gpt-4o-mini` | `ApiConstants.chatModel` |
| Budget planner | OpenAI `gpt-4o-mini` | budget planner datasource |
| Prediction | OpenAI `gpt-4o-mini` | prediction datasource |
| Voice transcription | OpenAI `whisper-1` | `ApiConstants.voiceModel` |
| OCR | Google ML Kit `TextRecognizer` | `OcrService` |
| Anomaly detection | Local statistical rules | `AnomalyDetectionService` |
| Recurring detection | Local statistical rules | `RecurringDetectionService` |

## User-Facing AI Entry Points

| Entry point | AI behavior |
| --- | --- |
| Chat text input | Conversational assistant, expense/income extraction, RAG question answering |
| Chat mic button | Voice transcription, then normal chat extraction |
| Chat attachment camera/gallery | Receipt image OCR and AI receipt parsing |
| RAG smart mode toggle | Adds personal local finance context to chat answers |
| Budget planner screen | AI-generated budget plan |
| Prediction widgets | AI monthly spending forecast |
| Anomaly screen/cards | Local unusual spending alerts |
| Recurring screen | Local recurring expense pattern suggestions |

## Privacy and Cost Notes

- OpenAI receives chat messages and generated local context when AI chat/RAG is used.
- OpenAI receives audio files when voice transcription is used.
- OpenAI receives OCR-extracted receipt text for receipt parsing.
- Google ML Kit OCR runs locally on device for text extraction.
- Local Isar data is used to build RAG context, predictions, anomalies, recurring patterns, and budget recommendations.
- OpenAI API usage depends on `OPENAI_API_KEY` from `.env`.
- Token usage tracking exists, but final billing should still be verified from the OpenAI dashboard.

## Current Limitations / Release Risks

- Receipt image reading is OCR-first, not direct multimodal vision; bad OCR can reduce receipt parsing quality.
- RAG is context-injection based and can become less accurate if local context is incomplete or too large.
- No embeddings or vector search were found, so semantic long-term retrieval is not currently implemented.
- AI JSON parsing has fallback/heuristic handling, so malformed model responses can still require robust UI confirmation.
- Voice requires network access for Whisper transcription.
- OpenAI-backed features require a valid API key and reachable OpenAI API.
- All detected expenses, incomes, and receipts should remain confirmation-first before saving to avoid accidental writes.

## Source Areas Reviewed

| Area | Paths |
| --- | --- |
| AI core | `lib/core/ai/` |
| Chat AI | `lib/features/chat/` |
| Voice | `lib/core/audio/`, `lib/features/chat/data/datasources/openai_voice_datasource.dart` |
| Receipt/OCR | `lib/core/scanner/`, `lib/core/mlkit/`, `lib/features/chat/data/datasources/openai_receipt_datasource.dart` |
| Budget AI | `lib/features/budget/data/datasources/budget_planner_datasource.dart` |
| Prediction AI | `lib/features/prediction/` |
| Anomaly detection | `lib/features/anomaly/` |
| Recurring detection | `lib/features/recurring/` |
| Split suggestions | `lib/features/split/` |
| App context docs | `README.md`, `PROJECT_CONTEXT.md` |
