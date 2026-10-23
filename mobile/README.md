# CULT Clinic

Приложение клиники для iPhone. Запись, услуги, магазин, корзина, кабинет, чат и бонусы хранятся на телефоне.

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

Предупреждение CocoaPods про `platform iOS 15.0` можно игнорировать, если в конце есть `Pod installation complete!`.

### `module 'Flutter' not found` / `shared_preferences_foundation` / VerifyModule

Xcode 15+/16 проверяет pod-модули отдельно от Flutter и падает на `shared_preferences_foundation` (`VerifyModule` → `module 'Flutter' not found`). В `ios/Podfile` уже отключён `ENABLE_MODULE_VERIFIER` и стоит `use_frameworks! :linkage => :static`.

Закройте Xcode и из `mobile` пересоберите pods:

```bash
cd ~/Desktop/cult/cult/mobile
flutter pub get
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
(cd ios && pod install)
open ios/Runner.xcworkspace
```

В Xcode: Product → Clean Build Folder, затем Run. Открывайте именно **`Runner.xcworkspace`**.

Если снова белый экран без ошибок — плагин SharedPreferences не поднялся; приложение всё равно должно показать сплэш за несколько секунд (локальное состояние стартует пустым). Пересоберите pods командами выше.

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
