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

Филиал CULT в Сочи уже встроен в приложение. После сплэша можно войти по телефону и имени — клиент создаётся или находится в базе YClients. Прайс и онлайн-запись идут в этот филиал. Свободные окна появляются, когда в филиале открыто расписание. Карта лояльности читается по телефону после входа.
