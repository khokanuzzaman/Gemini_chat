#!/bin/zsh

set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
project_dir=$(cd "$script_dir/.." && pwd)
env_file="$project_dir/.env"

if [[ ! -f "$env_file" ]]; then
  echo ".env not found (copy .env.example -> .env)"
  exit 1
fi

# No OpenAI key is needed to run the app. AI is off in Phase 1; when enabled it
# routes through a backend proxy set at build time
# (--dart-define=API_BASE_URL=...). The .env holds only non-secret runtime config
# (Google sign-in, RevenueCat) and is loaded by flutter_dotenv at runtime.

cd "$project_dir"
flutter run -d macos
