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

### `Xcode has killed the LLDB RPC server`

Отладчик Xcode отвалился (часто после нехватки места на диске или «зависшего» Run). Приложение CULT тут ни при чём.

1. В Xcode: Stop (■).
2. В Terminal завершите зависший процесс и очистите кэш отладки:

```bash
kill 7490 2>/dev/null
killall lldb-rpc-server 2>/dev/null
killall Runner 2>/dev/null
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

3. Проверьте свободное место: `df -h /` (нужно ≥ 5–10 GB).
4. Надёжнее запускать без Xcode-отладчика:

```bash
cd ~/Desktop/cult/cult/mobile
flutter pub get
flutter run
```

Или в Xcode: Product → Run без breakpoint’ов; если снова убьёт LLDB — используйте только `flutter run`.

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
