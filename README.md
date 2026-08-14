# YPadel: Счет и статистика

Минимальное приложение для счета в паделе, построенное вокруг реального использования всех согласованных системных разрешений. Интерфейс написан только кодом на UIKit; storyboard/xib и тестовых таргетов нет.

Проект предназначен исключительно для iPhone и работает только в портретной ориентации. Поддержка iPad, Mac Catalyst, запуска iPhone/iPad-приложения на Mac, visionOS и Apple Vision отключена для приложения и всех extensions.

## Настройка

Все заменяемые значения находятся в `Config/Shared.xcconfig`:

- `APP_BUNDLE_IDENTIFIER`
- `APP_GROUP_IDENTIFIER`
- `APPMETRICA_API_KEY` — пустой ключ безопасно отключает активацию SDK

Debug backend URL находится в `Config/Debug.xcconfig`, Release URL — в `Config/Release.xcconfig`.

После изменения bundle ID нужно также заменить производные bundle ID расширений и создать подходящие App ID/capabilities в Apple Developer. Для push и App Group запуск на физическом устройстве требует выбранную Development Team.

## Генерация проекта

```sh
xcodegen generate
open YPadel.xcodeproj
```

Deployment target приложения и notification extensions — iOS 15.0; Lock Screen widget — iOS 16.0.

## Локальный backend

```sh
python3 backend/server.py
curl http://localhost:8080/health
curl -X POST http://localhost:8080/sync -H 'Content-Type: application/json' -d '{}'
```

Backend намеренно состоит из одного файла и двух маршрутов: `GET /health` и `POST /sync`. Данные последней синхронизации хранятся только в памяти процесса.

## Проверка на устройстве

Камера, Face ID, Bluetooth-подключение, push token и часть поведения геолокации должны финально проверяться на реальном iPhone. На симуляторе доступны сборка, экран, локальное уведомление и системные сценарии, которые он поддерживает.
