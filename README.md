# YPoints

Минимальное приложение YPoints для счета и статистики в паделе, построенное вокруг реального использования всех согласованных системных разрешений. Счёт учитывает очки `0–15–30–40`, преимущество, геймы, сеты, тай-брейк при `6:6` и победу в матче после двух сетов. Публичное и техническое имя проекта — `YPoints`. Интерфейс написан только кодом на UIKit; storyboard/xib и тестовых таргетов нет.

Проект предназначен исключительно для iPhone и работает только в портретной ориентации. Поддержка iPad, Mac Catalyst, запуска iPhone/iPad-приложения на Mac, visionOS и Apple Vision отключена для приложения и всех extensions.

Иконка приложения находится в `App/Assets.xcassets/AppIcon.appiconset` и собирается как `AppIcon` основного target.

## Настройка

Все заменяемые значения находятся в `Config/Shared.xcconfig`:

- `APP_BUNDLE_IDENTIFIER` — `com.idev.ypoints`
- `APP_GROUP_IDENTIFIER` — `group.com.idev.ypoints`
- `APPMETRICA_API_KEY` — валидный SDK key приложения YPoints в AppMetrica

Bundle identifiers следуют соглашению `com.idev.<имя приложения в нижнем регистре>`; extensions добавляют суффиксы `.widget`, `.notification-service` и `.notification-content`.

Backend URL находится в `Config/Debug.xcconfig` и `Config/Release.xcconfig`. Оба варианта сейчас используют production HTTPS API Gateway в Yandex Cloud.

Перед Release также нужно заполнить PRIVACY_POLICY_URL и SUPPORT_URL в Config/Shared.xcconfig.

После изменения bundle ID нужно также заменить производные bundle ID расширений и создать подходящие App ID/capabilities в Apple Developer. Для push и App Group запуск на физическом устройстве требует выбранную Development Team.

Исходные entitlements приложения, виджета и notification extensions генерируются XcodeGen из `project.yml`: приложение получает Push Notifications и App Group, а расширения — тот же App Group. Не редактируйте сгенерированные `.entitlements` отдельно от `project.yml`. Privacy Manifest есть у каждого target, который читает обычные настройки или данные App Group.

Импортированный push-код пока не является частью проекта. `IMPORTED_NOTIFICATIONS_CONDITION` в `Config/Shared.xcconfig` оставлен пустым, поэтому обе notification extensions всегда используют текущую реализацию YPoints. После появления `ImportedNotificationProcessor` и `ImportedNotificationRenderer` значение можно заменить на `IMPORTED_NOTIFICATIONS_AVAILABLE`: при `cloudSyncEnabled = true` extensions выберут импортированные реализации, при `false` — текущие. Без импортированных файлов проект продолжает собираться.

## Генерация проекта

```sh
xcodegen generate
open YPoints.xcodeproj
```

Deployment target приложения и notification extensions — iOS 15.0; Lock Screen widget — iOS 16.0.

## Backend в Yandex Cloud

```sh
curl https://d5d27ljq6thqpj2secmq.sax5b7yq.apigw.yandexcloud.net/health
curl 'https://d5d27ljq6thqpj2secmq.sax5b7yq.apigw.yandexcloud.net/config?appId=com.idev.ypoints&appVersion=1.0'
curl -X POST https://d5d27ljq6thqpj2secmq.sax5b7yq.apigw.yandexcloud.net/sync -H 'Content-Type: application/json' -d '{"appId":"com.idev.ypoints","installationId":"local","matchToken":null,"clientRevision":1,"snapshot":{"leftName":"Мы","rightName":"Соперники","leftPoints":2,"rightPoints":1,"leftGames":3,"rightGames":2,"leftSets":1,"rightSets":0,"state":"active","revision":1,"updatedAt":"2026-08-18T12:00:00Z"},"push":{"token":null,"environment":"sandbox","enabled":false}}'
```

Backend использует один API Gateway `mobile-api`, одну Cloud Function `mobile-sync` и одну Serverless YDB `mobile-apps` в изолированном каталоге `mobile-backends`. Исходник функции находится в `backend/index.py`, закреплённая зависимость — в `backend/requirements.txt`, спецификация шлюза — в `backend/openapi.yaml`.

Для защиты от случайного перерасхода шлюз ограничен `10 RPS`, функция — одним экземпляром и двумя одновременными запросами на зону, YDB — `10 RU/с` и `1 ГБ`. API намеренно остаётся анонимным для минимального MVP: `matchToken` работает как секрет конкретного матча, поэтому через backend нельзя передавать чувствительные пользовательские данные.

`POST /sync` принимает `appId`, локальный revision/snapshot, непривязанный к личности installation ID, опциональный match token и APNs token. Сочетание `appId + matchToken` разделяет данные разных приложений на общем backend. Сервер возвращает актуальный snapshot и честный `pushStatus: pending_credentials`, пока APNs Team и `.p8` не настроены. Контакты, фото, аудио, координаты, ATT-статус и IDFA не передаются.

`GET /config` возвращает `cloudSyncEnabled` для переданного `appVersion` (`CFBundleShortVersionString`). В Cloud хранится один необязательный порог `disabledFromVersion`: для версий ниже порога backend возвращает `true`, а для равной и более новых — `false`. Сравнение выполняется по числовым компонентам, поэтому `1.10` новее `1.2`; если порог удалён, все версии получают `true`. Приложение запрашивает флаг при запуске, хранит последнее успешное значение отдельно для каждой версии в `UserDefaults` и проверяет его перед каждым `/sync`, включая регистрацию APNs-токена. Если холодный backend отвечает после четырёхсекундного дедлайна splash, основной экран сразу открывается с кэшем, а уже начатый запрос затем обновляет кэш и строку статуса без повторного показа splash. При выключенном флаге счёт, виджет и Bluetooth продолжают работать локально.

Изменение флага выполняется приватным IAM-вызовом функции и не опубликовано через API Gateway:

```sh
yc serverless function invoke --id d4eod1tle64d77d5q5tb --data '{"action":"setFeatureFlagRule","appId":"com.idev.ypoints","key":"cloudSyncEnabled","disabledFromVersion":"1.3"}'
```

В примере версии `1.0`–`1.2.x` получают `true`, а `1.3` и выше — `false`. Чтобы изменить границу, замените только `disabledFromVersion`. Версия должна состоять из одного–трёх числовых компонентов, например `1`, `1.3` или `1.3.2`; строкового сравнения нет.

Чтобы удалить порог и вернуть `true` всем версиям:

```sh
yc serverless function invoke --id d4eod1tle64d77d5q5tb --data '{"action":"clearFeatureFlagRule","appId":"com.idev.ypoints","key":"cloudSyncEnabled"}'
```

`appVersion` обязателен только в публичном запросе `/config`; административный вызов задаёт или удаляет единый порог. Новое правило применяется после следующего запуска приложения; при недоступности backend используется последнее сохранённое значение текущей версии.

Cloud Function авторизуется в YDB через привязанный сервисный аккаунт; долгоживущих ключей в репозитории нет. На другом компьютере достаточно установить `yc`, войти в тот же аккаунт и выбрать каталог `mobile-backends`.

Повторное развёртывание кода функции и спецификации шлюза:

```sh
yc config profile activate mobile-backend
yc serverless function version create --function-id d4eod1tle64d77d5q5tb --runtime python312 --entrypoint index.handler --memory 256m --execution-timeout 10s --source-path backend --service-account-id ajedaljpsc9s15h4pn3h --environment YDB_ENDPOINT=grpcs://ydb.serverless.yandexcloud.net:2135,YDB_DATABASE=/ru-central1/b1gphpa2kupo8no6avg6/etn9g57v0om80lma5b4i
yc serverless api-gateway update --id d5d27ljq6thqpj2secmq --spec backend/openapi.yaml --execution-timeout 15s
```

## ATT и AppMetrica

В приложении нет рекламных экранов и Yandex Mobile Ads. Строка «Оценка продвижения» напрямую открывает системный ATT-диалог. AppMetricaAdSupport использует IDFA для атрибуции только после разрешения iOS; при отказе AppMetrica работает без IDFA. Основной валидный API key читается из xcconfig и используется при активации SDK.

`AnalyticsReporter.changeAPIKey(_:)` переключает последующие custom events на reporter другого API key в рамках текущего запуска. Перед переключением текущая дополнительная сессия останавливается, новая запускается вручную. Ключ не сохраняется между запусками; автоматические события и прочие данные основной SDK-конфигурации продолжают относиться к ключу, с которым AppMetrica была активирована при старте приложения. Передача основного ключа в метод возвращает custom events на основной reporter.

Автоматический сбор location в AppMetrica явно отключён. Координаты используются только MapKit/Core Location на устройстве и не попадают в custom events или backend.

## Проверка на устройстве

Камера, Face ID, Bluetooth-подключение, push token и часть поведения геолокации должны финально проверяться на реальном iPhone. На симуляторе доступны сборка, экран, локальное уведомление и системные сценарии, которые он поддерживает.
