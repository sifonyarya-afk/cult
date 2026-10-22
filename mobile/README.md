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
