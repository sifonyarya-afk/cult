# CULT Clinic

Приложение клиники для iPhone. Запись, услуги, магазин, корзина, кабинет, чат и бонусы хранятся на телефоне.

Нужны Mac, Xcode и Flutter.

```bash
flutter pub get
flutter run
```

Подключите iPhone кабелем и подтвердите доверие к компьютеру. Сборку из Xcode открывайте так:

```bash
flutter pub get
cd ios
pod install
open Runner.xcworkspace
```

Нужен файл `Runner.xcworkspace`, не `Runner.xcodeproj`. Иначе Xcode пишет `Framework 'Pods_Runner' not found`.

В Xcode: цель Runner → Signing & Capabilities → Team. Выберите свой Apple ID (Personal Team). Без команды подписи сборка на iPhone не запускается. Если CocoaPods не установлен: `brew install cocoapods`.

Собрать установочный файл iPhone с Linux нельзя: подпись делает только Xcode.

## YClients

Филиал CULT в Сочи уже встроен. Сначала короткая заставка (~3 с), затем выбор «женщина / мужчина». Услуги, врачи, прайс и записи — из YClients. Войти по телефону можно из профиля: клиент и визиты синхронизируются с филиалом. Свободные окна записи появляются, когда в филиале открыто расписание.
