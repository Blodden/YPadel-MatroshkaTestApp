# YPoints

Минимальное приложение YPoints для счета и статистики в паделе, построенное вокруг реального использования всех согласованных системных разрешений. Счёт учитывает очки `0–15–30–40`, преимущество, геймы, сеты, тай-брейк при `6:6` и победу в матче после двух сетов. Публичное и техническое имя проекта — `YPoints`. Интерфейс написан только кодом на UIKit; storyboard/xib и тестовых таргетов нет.

Проект предназначен исключительно для iPhone и работает только в портретной ориентации. Поддержка iPad, Mac Catalyst, запуска iPhone/iPad-приложения на Mac, visionOS и Apple Vision отключена для приложения и всех extensions.

Иконка приложения находится в `App/Assets.xcassets/AppIcon.appiconset` и собирается как `AppIcon` основного target.

## Настройка

Все заменяемые значения находятся в `Config/Shared.xcconfig`:

- `APP_BUNDLE_IDENTIFIER`
- `APP_GROUP_IDENTIFIER`
- `APPMETRICA_API_KEY` — пустой ключ безопасно отключает активацию SDK

Debug backend URL находится в `Config/Debug.xcconfig`, Release URL — в `Config/Release.xcconfig`.

Перед Release также нужно заполнить PRIVACY_POLICY_URL и SUPPORT_URL в Config/Shared.xcconfig.

После изменения bundle ID нужно также заменить производные bundle ID расширений и создать подходящие App ID/capabilities в Apple Developer. Для push и App Group запуск на физическом устройстве требует выбранную Development Team.

Исходные entitlements приложения и виджета генерируются XcodeGen из `project.yml`: приложение получает Push Notifications и App Group, виджет — тот же App Group. Не редактируйте сгенерированные `.entitlements` отдельно от `project.yml`. Privacy Manifest есть у приложения (`App/PrivacyInfo.xcprivacy`) и виджета (`Widget/PrivacyInfo.xcprivacy`); причины доступа к UserDefaults разделяют обычные настройки приложения и данные App Group.

## Генерация проекта

```sh
xcodegen generate
open YPoints.xcodeproj
```

Deployment target приложения и notification extensions — iOS 15.0; Lock Screen widget — iOS 16.0.

## Локальный backend

```sh
python3 backend/server.py
curl http://localhost:8080/health
curl -X POST http://localhost:8080/sync -H 'Content-Type: application/json' -d '{"installationId":"local","matchToken":null,"clientRevision":1,"snapshot":{"leftName":"Мы","rightName":"Соперники","leftPoints":2,"rightPoints":1,"leftGames":3,"rightGames":2,"leftSets":1,"rightSets":0,"state":"active","revision":1,"updatedAt":"2026-08-17T12:00:00Z"},"push":{"token":null,"environment":"sandbox","enabled":false}}'
```

Backend намеренно состоит из одного файла и двух маршрутов: `GET /health` и `POST /sync`. Данные последней синхронизации хранятся только в памяти процесса.

POST /sync принимает локальный revision/snapshot, непривязанный к личности installation ID, опциональный match token и APNs token. Сервер возвращает актуальный snapshot и честный pushStatus: pending_credentials, пока APNs Team и .p8 не настроены.

## ATT и AppMetrica

В приложении нет рекламных экранов и Yandex Mobile Ads. Строка «Оценка продвижения» напрямую открывает системный ATT-диалог. AppMetricaAdSupport использует IDFA для атрибуции только после разрешения iOS; при отказе AppMetrica работает без IDFA. API key читается из xcconfig, а событие launch отправляется один раз на процесс после успешной активации SDK.

Автоматический сбор location в AppMetrica явно отключён. Координаты используются только MapKit/Core Location на устройстве и не попадают в custom events или backend.

## Проверка на устройстве

Камера, Face ID, Bluetooth-подключение, push token и часть поведения геолокации должны финально проверяться на реальном iPhone. На симуляторе доступны сборка, экран, локальное уведомление и системные сценарии, которые он поддерживает.
