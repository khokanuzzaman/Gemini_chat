# PocketPilot AI — AI Expense Tracker

> বাংলায় কথা বলুন, খরচ ট্র্যাক করুন। Powered by OpenAI.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4o%20mini-412991?logo=openai&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![CI](https://github.com/khokanuzzaman/Gemini_chat/actions/workflows/flutter_ci.yml/badge.svg)

## Screenshots
<!-- Dashboard | Chat | Analytics -->
<!-- ![Dashboard](screenshots/dashboard.png) -->

Run the app and capture these screenshots:
1. `screenshots/splash.png`
2. `screenshots/onboarding.png`
3. `screenshots/dashboard.png`
4. `screenshots/chat.png`
5. `screenshots/voice_recording.png`
6. `screenshots/receipt_scan.png`
7. `screenshots/expense_list.png`
8. `screenshots/analytics.png`
9. `screenshots/rag_response.png`

## Features
- 💬 AI Chat — বাংলায় expense add করুন
- 🎤 Voice Input — কথা বলে expense add
- 📷 Receipt Scanner — Photo তুলে add
- 📊 Smart Dashboard — Visual analytics
- 🧠 RAG Insights — Personal AI assistant
- 📅 Past Date Support — যেকোনো তারিখের expense
- 🔢 Multiple Expense — একসাথে অনেক expense

## Architecture

### Tech Stack
| Layer | Technology |
| --- | --- |
| Framework | Flutter 3.x |
| State Management | Riverpod |
| Local Database | Isar |
| AI — Chat | OpenAI GPT-4o mini |
| AI — Voice | OpenAI Whisper |
| AI — OCR | Google ML Kit (offline) |
| Architecture | Clean Architecture |

### Folder Structure
```text
lib/
├── core/
│   ├── ai/              # RAG, parsers, prompt builders
│   ├── audio/           # Voice recording service
│   ├── constants/       # API keys, strings, theme
│   ├── database/        # Isar service, seed data
│   ├── errors/          # Failure classes
│   ├── mlkit/           # OCR service
│   ├── scanner/         # Receipt scanner
│   ├── theme/           # Colors, typography, spacing
│   └── utils/           # Category icons, helpers
├── features/
│   ├── chat/            # AI chat feature
│   │   ├── data/        # OpenAI datasources, Isar models
│   │   ├── domain/      # Entities, use cases, repository
│   │   └── presentation/# Screens, widgets, providers
│   ├── expense/         # Dashboard, list, analytics
│   ├── onboarding/      # First launch flow
│   ├── settings/        # App settings
│   └── splash/          # Splash screen
└── main.dart
```

### Provider Architecture
| Feature | Provider | Cost |
| --- | --- | --- |
| Text Chat | OpenAI GPT-4o mini | $0.15 / 1M tokens |
| Voice STT | OpenAI Whisper | $0.006 / minute |
| OCR | ML Kit | Free, offline |
| Receipt AI | OpenAI GPT-4o mini | $0.15 / 1M tokens |

## Setup

### Prerequisites
- Flutter 3.x
- OpenAI API key from `platform.openai.com`

### Installation
```bash
git clone https://github.com/khokanuzzaman/Gemini_chat.git
cd Gemini_chat

flutter pub get

cp .env.example .env
# Add your OpenAI key to .env

flutter run
```

### Environment Variables
```env
OPENAI_API_KEY=your_openai_key_here
```

Get your key: https://platform.openai.com

## Cost Estimate
| Usage | Daily Cost |
| --- | --- |
| Development | ~$0.02/day |
| $5 credit | ~7-8 months |

## AI Features Explained

### Few-shot Prompting
Category detection uses carefully chosen examples in the system prompt for consistent classification.

### RAG (Retrieval Augmented Generation)
Personal expense data from Isar is injected into AI context when the user asks data-driven questions.

### Multi-format Input
- Text: `রিকশায় ৬০ টাকা`
- Voice: Speak in Bengali
- Receipt: Camera or gallery
- Past dates: `2/02/2026` তারপর list
- Multiple: `নাস্তা ৩০, লাঞ্চ ২০০, ডিনার ৪০০`

## Development

### Quality Checks
```bash
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

### Branch Strategy
- `main` — production-ready code
- `develop` — active development
- `feature/*` — feature branches

### Commit Convention
- `feat:` new feature
- `fix:` bug fix
- `refactor:` code improvement
- `docs:` documentation
- `test:` tests
- `chore:` maintenance

## License
MIT License — see [LICENSE](LICENSE)
