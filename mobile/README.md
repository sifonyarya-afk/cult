# CULT Clinic

Приложение клиники для iPhone. Запись, услуги, магазин, корзина, кабинет, чат и бонусы хранятся на телефоне.

**Мира** — косметолог CULT на центральной жемчужине нижней панели. Живой голос без карточек-подсказок: слушает → отвечает → слушает. Запись на услугу — только после уточнений и кнопки **«Запись»**. Чат с администратором/врачом — через меню ☰. iOS спросит Микрофон и «Распознавание речи».

Если агента нет / старый UI — на Mac почти всегда **старый коммит** и `git pull` не прошёл. Актуальная метка: **`mira-train-v40`** (`cultBuildTag` в `mobile/lib/data.dart`).

В zsh строка после `#` — не комментарий (если нет `INTERACTIVE_COMMENTS`). Не копируйте команды с `# …` в конец: будет `fatal: '#' does not appear to be a git repository` и `pathspec '#'`.

**Скопируйте блок целиком, без правок (комментариев в нём нет):**

```bash
cd ~/Desktop/cult/cult
git status
git stash push -u -m "local before pull"
git pull origin main
git rev-parse --short HEAD
git log -1 --oneline
grep cultBuildTag mobile/lib/data.dart
grep speech_to_text mobile/pubspec.yaml
```

После `pull` `cultBuildTag` должен быть `mira-train-v40`. Если `pull` снова ругается на локальные файлы:

```bash
cd ~/Desktop/cult/cult
git fetch origin
git reset --hard origin/main
```

Это сбросит только локальные правки Xcode/`pubspec.lock` в этой папке. Затем:

```bash
cd ~/Desktop/cult/cult/mobile
flutter pub get
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
cd ios
pod install
cd ..
flutter run
```

В `flutter pub get` должны появиться `speech_to_text 7.4.0` и `flutter_tts` (не 7.5 — он требует Dart 3.12). В приложении: плавающая капсула внизу, по центру шампань-кнопка **Агент** (микрофон); Настройки → Сборка = `floating-dock-v23`.

### SIGKILL / Lost connection to device при `flutter run`

Это не «старый код»: `22ea0d1` уже скачан. iOS убивает процесс при установке/отладке. На Mac:

1. На iPhone удалите приложение **CULT** (долгое нажатие → Удалить).
2. Настройки → Конфиденциальность → **Режим разработчика** → Вкл. (если был выкл — перезагрузка).
3. Кабель (не только Wi‑Fi). Разблокируйте телефон, нажмите Trust.
4. В Terminal из `mobile`:

```bash
cd ~/Desktop/cult/cult/mobile
flutter clean
flutter pub get
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
(cd ios && pod install)
flutter devices
flutter run -d "$(flutter devices | grep -i iphone | head -1 | sed -E 's/.*• ([^ ]+) •.*/\1/')"
```

5. Если снова SIGKILL сразу после Installing: откройте `ios/Runner.xcworkspace` в Xcode → выберите iPhone → Product → Run. При первом запуске на телефоне: Настройки → Основные → VPN и устройство → доверьте разработчику.
6. Не жмите `q` в старом сеансе и сразу новый `flutter run` без паузы — дождитесь полного стопа или `flutter run` после удаления приложения с телефона.

**Живой голос (не робот):** системный TTS iPhone всегда слегка синтетический. Чтобы звучало как человек:
1. **Лучший вариант** — Профиль → **Живой голос агента** → API-ключ [Yandex SpeechKit](https://cloud.yandex.ru/services/speechkit) (голос Alena). Кнопка «Прослушать тест».
2. Без ключа — iPhone: Универсальный доступ → Spoken Content → Голоса → Русский → **Premium Милена**.

Нужны Mac, Xcode и Flutter.

## Запуск на iPhone

Сначала зайдите в папку приложения (не в `ios`):

```bash
cd ~/Desktop/cult/cult/mobile
```

Проверьте приглашение терминала: путь должен заканчиваться на `mobile`, не на `ios`.

Затем:

```bash
flutter pub get
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
(cd ios && pod install)
open ios/Runner.xcworkspace
```

Открывайте именно **`Runner.xcworkspace`**, не `Runner.xcodeproj`.

### Если снова чистите проект

Все команды ниже тоже только из `mobile`:

```bash
cd ~/Desktop/cult/cult/mobile
flutter clean
flutter pub get
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
(cd ios && pod install)
open ios/Runner.xcworkspace
```

Не делайте `cd ios` перед этим блоком. Сообщение Flutter `Changing current working directory to: .../mobile` меняет каталог только внутри Flutter, не в вашем терминале — если вы уже были в `ios`, следующий `cd ios` ищет несуществующий `ios/ios`.

Предупреждение CocoaPods про `platform iOS 15.0` / «no platform was specified» можно игнорировать, если в конце есть `Pod installation complete!`.

### `git pull` ругается на локальные изменения / zsh и `#`

`flutter run` и Xcode правят `Podfile`, `project.pbxproj`, `Runner.xcscheme`, `pubspec.lock`. Stash нужен **всех** грязных файлов, не только `mobile/ios`.

Не вставляйте в Terminal команды с `# комментарий` — в zsh это ломает `git pull`/`git stash`.

```bash
cd ~/Desktop/cult/cult
git stash push -u -m "local before pull"
git pull origin main
```

Если merge всё ещё abort:

```bash
cd ~/Desktop/cult/cult
git fetch origin
git reset --hard origin/main
```

Затем сборка из `mobile` (см. блок в начале README).

### `No Podfile found` / `pod install` из `mobile`

`Podfile` лежит в `mobile/ios`. Из папки `mobile` вызывайте так:

```bash
(cd ios && pod install)
```

или `cd ios && pod install && cd ..`. Не запускайте голый `pod install` в `mobile` — CocoaPods ищет Podfile рядом и пишет `No Podfile found`.

После `git pull` с голосовым агентом в `flutter pub get` должны появиться `speech_to_text` и `flutter_tts`. Если их нет — код ещё старый, сделайте `git pull` из корня `cult`.

### `TUIPredictionViewCell` / Auto Layout / `NSAutoresizingMaskLayoutConstraint`

Это системная клавиатура iOS (подсказки над клавиатурой), не баг CULT. Можно игнорировать. На работу приложения не влияет.

### `Lost connection to device`

Отладчик потерял iPhone. Разблокируйте телефон, проверьте кабель/Wi‑Fi debugging, затем снова:

```bash
cd ~/Desktop/cult/cult/mobile
flutter devices
flutter run
```

### `Installing and launching...` крутится долго

`Xcode build done` уже был — ошибка не в компиляции, а в установке/отладчике на телефоне.

1. Разблокируйте iPhone и оставьте экран включённым.
2. Подтвердите «Доверять этому компьютеру», если спросит.
3. Настройки → Конфиденциальность и безопасность → **Режим разработчика** → Вкл. (перезагрузка).
4. После первой установки: Настройки → Основные → VPN и управление устройством → доверьте сертификат разработчика.
5. Подождите 1–2 минуты. Если крутится дальше — `Ctrl+C`, удалите CULT с телефона, затем снова:

```bash
cd ~/Desktop/cult/cult/mobile
flutter run
```

Чтобы просто открыть приложение без отладчика (иконка с домашнего экрана):

```bash
flutter run --release
```

### `Error connecting to the service protocol` / `Connection reset by peer`

Сборка и установка прошли (`Xcode build done`, `Installing and launching…`), но Flutter не смог подключить hot-reload к телефону. **Часто CULT уже открыт на iPhone** — проверьте экран. Это сбой отладчика, не кода.

1. Разблокируйте телефон, отключите VPN, оставьте кабель.
2. Если iOS спросил **Локальная сеть** для Runner/Flutter — разрешите.
3. В Terminal:

```bash
cd ~/Desktop/cult/cult/mobile
killall -9 dart flutter Runner lldb-rpc-server 2>/dev/null
flutter devices
flutter run
```

4. Если снова reset — без отладчика (приложение ставится и работает):

```bash
cd ~/Desktop/cult/cult/mobile
flutter run --release
```

5. Запасной вариант: Xcode → Stop → Product → Clean Build Folder → Run из `Runner.xcworkspace`, либо переподключите кабель / другой порт USB.

Предупреждение CocoaPods «no platform was specified» значит, что на Mac ещё старый `Podfile` (не подтянули фиксы). Сделайте `git stash` + `git pull` из корня `cult` — см. блок выше.

### `CwlCatchExceptionSupport-umbrella.h` · quoted include

Сообщение Xcode вроде:

`Pods/.../CwlCatchExceptionSupport-umbrella.h: double-quoted include "CwlCatchException.h" in framework header, expected angle-bracketed instead`

Это warning от зависимости `speech_to_text` (CwlCatchException), **не ошибка приложения**. В актуальном `ios/Podfile` umbrella переписывается на `#import <…>` при `pod install`, warning выключен.

```bash
cd ~/Desktop/cult/cult
git pull origin main
cd mobile
flutter pub get
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
(cd ios && pod install)
open ios/Runner.xcworkspace
```

В Xcode: Product → Clean Build Folder → Run. Метка сборки: `mira-train-v40`.

### `module 'Flutter' not found` / VerifyModule (`url_launcher_ios`, `shared_preferences_foundation`)

Xcode 15+/16 гоняет **VerifyModule** по pod-фреймворкам без `Flutter.framework` и падает:

- `url_launcher_ios-Swift.h` → `module 'Flutter' not found`
- то же для `shared_preferences_foundation`
- warning `CwlCatchExceptionSupport` (`double-quoted include … expected angle-bracketed`) — шум от `speech_to_text` / CwlCatchException; в `Podfile` umbrella правится на `<…>` и warning выключен. Не блокирует сборку. После `pull`: `pod install` заново.

В `ios/Podfile` уже: `use_frameworks! :linkage => :static`, `ENABLE_MODULE_VERIFIER = NO` на project и targets.

**Обязательно** подтянуть Podfile и снести DerivedData (старый VerifyModule кэш иначе остаётся):

```bash
cd ~/Desktop/cult/cult
git pull origin main
cd mobile
flutter pub get
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
(cd ios && pod install)
grep ENABLE_MODULE_VERIFIER ios/Pods/Pods.xcodeproj/project.pbxproj | head
```

`grep` должен показать `ENABLE_MODULE_VERIFIER = NO`. Потом только **`Runner.xcworkspace`** (не `.xcodeproj`):

```bash
open ios/Runner.xcworkspace
```

В Xcode: Product → Clean Build Folder, затем Run. Или из Terminal: `flutter run`.

Если снова VerifyModule — вы открыли старый workspace или DerivedData не удалился; повторите блок выше и закройте все окна Xcode перед `pod install`.

### `Exited with status code 127`

Значит Xcode не нашёл Flutter (`FLUTTER_ROOT` / `xcode_backend.sh`). Обычно после `flutter clean` без нового `flutter pub get`, или открыт `.xcodeproj` вместо workspace.

Закройте Xcode и из `mobile`:

```bash
cd ~/Desktop/cult/cult/mobile
flutter pub get
(cd ios && pod install)
open ios/Runner.xcworkspace
```

В Xcode: Product → Clean Build Folder, затем Run. В Build Settings у Runner должны быть User-Defined значения `FLUTTER_ROOT` (путь к Flutter SDK на Mac).

### `Cannot create a FlutterEngine…` / `ptrace… Operation not permitted` / `killed the LLDB RPC server`

Это сбой **отладчика Xcode/LLDB**, не кода CULT. Debug-сборка на iOS 14+ обязана стартовать с подключённым Flutter tooling или Xcode. Если LLDB умер или вы открыли иконку с домашнего экрана — увидите:

- `Could not call ptrace(PT_TRACE_ME): Operation not permitted`
- `Cannot create a FlutterEngine instance in debug mode without Flutter tooling or Xcode`
- `Xcode has killed the LLDB RPC server`

**Надёжный способ — запускать из Terminal:**

```bash
cd ~/Desktop/cult/cult/mobile
flutter pub get
flutter devices
flutter run
```

Выберите свой iPhone в списке. Не запускайте Debug-иконку CULT с домашнего экрана.

Если всё же через Xcode:

1. На iPhone: Настройки → Конфиденциальность и безопасность → **Режим разработчика** → Вкл. (перезагрузка).
2. В Xcode: Stop (■), затем Product → Clean Build Folder.
3. Снова Run из **`Runner.xcworkspace`** (не `.xcodeproj`), подождите пока LLDB останется подключённым.
4. Если LLDB снова убит — закройте Xcode и используйте только `flutter run`.

Сброс зависшего отладчика:

```bash
killall lldb-rpc-server 2>/dev/null
killall Runner 2>/dev/null
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
```

Проверьте место: `df -h /` (желательно ≥ 5–10 GB).

Чтобы открывать приложение с иконки без кабеля — соберите **Profile** или **Release** (`flutter run --release` или схему Release в Xcode). Debug с домашнего экрана на iOS так не стартует.

### `No space left on device` / `database or disk is full`

На Mac закончилось место на диске (часто из‑за `DerivedData` Xcode). Закройте Xcode и в Terminal:

```bash
df -h /
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/*
cd ~/Desktop/cult/cult/mobile
flutter clean
flutter pub get
(cd ios && pod install)
open ios/Runner.xcworkspace
```

В Finder → Об этом Mac → Хранилище освободите ещё место, если `df -h /` показывает меньше ~5–10 GB свободно.

В Xcode: цель Runner → Signing & Capabilities → Team. Выберите свой Apple ID (Personal Team). Без команды подписи сборка на iPhone не запускается.

Если CocoaPods не установлен: `brew install cocoapods`.

Либо без Xcode, из `mobile`:

```bash
flutter pub get
flutter run
```

Собрать установочный файл iPhone с Linux нельзя: подпись делает только Xcode.

## YClients

Филиал CULT в Сочи уже встроен. Сначала короткая заставка (~3 с), затем выбор «женщина / мужчина». Услуги, врачи, прайс и записи — из YClients. Войти по телефону можно из профиля: клиент и визиты синхронизируются с филиалом. Свободные окна записи появляются, когда в филиале открыто расписание.
