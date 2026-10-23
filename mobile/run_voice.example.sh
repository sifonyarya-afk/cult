#!/usr/bin/env bash
# Copy to run_voice.sh, put your key in .cult_yandex_tts_key, then:
#   chmod +x run_voice.sh && ./run_voice.sh
set -euo pipefail
cd "$(dirname "$0")"
KEY_FILE=".cult_yandex_tts_key"
if [[ ! -f "$KEY_FILE" ]]; then
  echo "Create $KEY_FILE with one line: your Yandex SpeechKit API key"
  exit 1
fi
KEY="$(tr -d '[:space:]' <"$KEY_FILE")"
flutter pub get
flutter run --dart-define="CULT_YANDEX_TTS_KEY=$KEY"
