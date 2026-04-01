#!/bin/zsh

set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
project_dir=$(cd "$script_dir/.." && pwd)
env_file="$project_dir/.env"

if [[ ! -f "$env_file" ]]; then
  echo ".env not found"
  exit 1
fi

source "$env_file"

if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  echo "OPENAI_API_KEY is missing in .env"
  exit 1
fi

cd "$project_dir"
flutter run -d macos
