# YPoints Privacy Policy

> Draft prepared for release. The complete document must be reconfirmed before the app is submitted to the App Store. This text is not legal advice. Remove this notice and provide the effective date before publication.

Effective date: `PENDING`

## 1. Data controller

YPoints is owned and operated by Evgenii Bezgin (`Евгений Безгин` in Russian-language forms).

For privacy questions and data deletion requests, contact bezgineg@yandex.ru.

## 2. Purpose of the application

YPoints helps users keep score and statistics for padel matches, synchronize a local scoreboard, find courts, add players and match materials, save a result card, and receive notifications. No account is required to use the application.

## 3. Permissions and data that remain on the device

YPoints requests a system permission only after an explicit user action. Access can be revoked in iPhone Settings.

- **Bluetooth:** the current score can be transferred directly between nearby compatible iPhones. This data is not sent to the YPoints server or AppMetrica.
- **Camera and Photos:** the application can take a photo, display permitted photos, select an image, and save a result card to the Photo Library. Photos are not sent to the YPoints server or AppMetrica.
- **Contacts:** the application uses permitted names to select players. Contacts and selected names are not sent to the YPoints server or AppMetrica.
- **Face ID:** iOS performs a local authentication check before private statistics are opened. YPoints does not receive or store biometric data.
- **Location:** the current position is used to search for nearby courts through Apple Maps. YPoints does not send coordinates to its server or AppMetrica.
- **Microphone:** a voice note is recorded and stored locally. Audio is not sent to the YPoints server or AppMetrica.

Data stored inside YPoints is retained until it is reset or replaced using available application actions, or until the application is deleted. Result cards saved to the system Photos application remain there until the user deletes them and are not removed when YPoints is deleted.

## 4. Data transmitted to the YPoints server

For minimal synchronization, the application may transmit the following data to Yandex Cloud:

- a random installation identifier that is not based on a name, contacts, or Apple ID;
- an opaque match token;
- a revision number and compact score state;
- an APNs device token and push environment for notification delivery;
- the bundle identifier and application version used to obtain the remote `cloudSyncEnabled` setting.

Contacts, photos, audio, coordinates, ATT status, and IDFA are not sent to the YPoints server. The backend does not contain user accounts and, under the accepted data model, does not associate stored data with an identified person.

Match-state and APNs-token synchronization occurs only while the server-controlled `cloudSyncEnabled` setting is enabled. Core features continue to work locally when it is disabled.

No automatic deletion period is currently configured for server data. You can request deletion by contacting bezgineg@yandex.ru.

## 5. AppMetrica

YPoints uses the AppMetrica SDK for product analytics, application diagnostics, and promotion attribution. Depending on the actual SDK configuration, the SDK may process technical information about the device and application, IP address, device model, connection type, SDK version, bundle identifier, product interaction data, and diagnostic data.

Automatic location collection in AppMetrica is disabled. Contacts, photos, audio, coordinates, and the contents of user notes are not added to custom analytics events.

IDFA may be transmitted to AppMetrica for advertising attribution only after the user authorizes tracking through the system App Tracking Transparency request. If permission is declined, the application continues to work and AppMetrica operates without IDFA.

AppMetrica data is retained for the period during which the service is used and is deleted in accordance with AppMetrica terms and applicable law. AppMetrica data-processing terms are available in the [service terms](https://yandex.com/legal/metrica_termsofuse/) and [Yandex Privacy Policy](https://yandex.com/legal/confidential/).

## 6. Push notifications

After notification permission is granted, the application receives an APNs device token from Apple and may send it to the YPoints server to deliver invitations and notifications about match starts and results. Notifications can be disabled in iPhone Settings. The token may change, so the application may transmit its latest value again.

## 7. Service providers

Data is shared only with providers required for the described application behavior:

- Apple, for iOS system functions, maps, the Photo Library, biometric authentication, and APNs;
- Yandex Cloud, for minimal server synchronization and remote configuration;
- AppMetrica, for analytics, diagnostics, and user-authorized attribution.

YPoints does not sell user data or disclose it to third parties for money or other compensation.

## 8. Managing data and permissions

Users can:

- change access to Bluetooth, camera, Contacts, Face ID, location, microphone, Photos, tracking, and notifications in iPhone Settings;
- reset or replace local materials using available application actions, delete the application, and separately delete saved result cards from the system Photos application;
- request information about server data or request its deletion by contacting bezgineg@yandex.ru.

Revoking a permission does not automatically delete materials previously saved on the device or records stored on the backend. Server-data deletion can be requested at bezgineg@yandex.ru.

## 9. Children

YPoints is intended for a general audience and is not directed specifically at children. The application does not request a date of birth and does not create user accounts.

## 10. Changes to this policy

If the categories of data or processing methods change, an updated version of this policy will be published at the same address with a new effective date.

## 11. Contact

- Application owner: Evgenii Bezgin (`Евгений Безгин`).
- Privacy contact email: bezgineg@yandex.ru.

---

# Политика конфиденциальности YPoints

> Черновик для подготовки релиза. Документ будет целиком повторно согласован перед фактической отправкой в App Store. Этот текст не является юридической консультацией. До публикации необходимо удалить эту пометку и указать дату вступления политики в силу.

Дата вступления в силу: `PENDING`

## 1. Кто отвечает за данные

Владелец и оператор приложения YPoints — Евгений Безгин (`Evgenii Bezgin` для англоязычных форм).

По вопросам конфиденциальности и удаления данных: bezgineg@yandex.ru.

## 2. Для чего предназначено приложение

YPoints помогает вести счёт и статистику матча в падел, синхронизировать локальное табло, находить корты, добавлять игроков и материалы матча, сохранять карточку результата и получать уведомления. Для работы приложения не требуется создавать учётную запись.

## 3. Доступы и данные, которые остаются на устройстве

YPoints запрашивает системные разрешения только после явного действия пользователя. Доступ можно отозвать в настройках iPhone.

- **Bluetooth:** текущий счёт может передаваться напрямую между находящимися рядом совместимыми iPhone. Эти данные не отправляются на сервер YPoints или в AppMetrica.
- **Камера и Фото:** приложение может сделать снимок, показать разрешённые фотографии, выбрать изображение и сохранить карточку результата в медиатеку. Фотографии не отправляются на сервер YPoints или в AppMetrica.
- **Контакты:** приложение использует разрешённые имена для выбора игроков. Контакты и выбранные имена не отправляются на сервер YPoints или в AppMetrica.
- **Face ID:** iOS выполняет локальную проверку для доступа к статистике. YPoints не получает и не хранит биометрические данные.
- **Геолокация:** текущая позиция используется для поиска ближайших кортов через системные карты. YPoints не отправляет координаты на собственный сервер или в AppMetrica.
- **Микрофон:** голосовая заметка записывается и хранится локально. Аудио не отправляется на сервер YPoints или в AppMetrica.

Данные внутри YPoints хранятся до их сброса или замены доступными действиями приложения либо до удаления приложения. Карточки результатов, сохранённые в системное приложение «Фото», хранятся до их удаления пользователем из «Фото» и не удаляются при удалении YPoints.

## 4. Данные, передаваемые серверу YPoints

Для минимальной синхронизации приложение может передавать в Yandex Cloud:

- случайный идентификатор установки, не основанный на имени, контактах или Apple ID;
- непрозрачный токен матча;
- номер ревизии и компактное состояние счёта;
- APNs device token и среду push для доставки уведомлений;
- bundle identifier и версию приложения для получения удалённой настройки `cloudSyncEnabled`.

Контакты, фотографии, аудио, координаты, статус ATT и IDFA на сервер YPoints не передаются. Backend не содержит пользовательских аккаунтов и по принятой модели не связывает данные с установленной личностью.

Синхронизация состояния матча и APNs token выполняется только при включённой серверной настройке `cloudSyncEnabled`. При её выключении основные функции продолжают работать локально.

Автоматический срок удаления серверных данных не установлен. Запросить их удаление можно по адресу bezgineg@yandex.ru.

## 5. AppMetrica

YPoints использует SDK AppMetrica для продуктовой аналитики, диагностики работы приложения и оценки эффективности продвижения. SDK может обрабатывать техническую информацию об устройстве и приложении, IP-адрес, модель устройства, тип соединения, версию SDK, bundle identifier, данные о взаимодействии с продуктом и диагностические данные в соответствии с фактической конфигурацией SDK.

Автоматический сбор геопозиции в AppMetrica отключён. Контакты, фотографии, аудио, координаты и содержимое пользовательских заметок не добавляются в пользовательские события аналитики.

IDFA может быть передан AppMetrica для рекламной атрибуции только после того, как пользователь разрешит отслеживание в системном запросе App Tracking Transparency. При отказе приложение продолжает работать, а AppMetrica используется без IDFA.

Данные AppMetrica хранятся в течение срока использования сервиса и удаляются в соответствии с условиями AppMetrica и применимым законодательством. Условия обработки данных AppMetrica опубликованы в [условиях сервиса](https://yandex.com/legal/metrica_termsofuse/) и [политике конфиденциальности Яндекса](https://yandex.com/legal/confidential/).

## 6. Push-уведомления

После разрешения уведомлений приложение получает APNs device token от Apple и может передать его серверу YPoints для доставки приглашений, уведомлений о начале и результате матча. Пользователь может отключить уведомления в настройках iPhone. Токен может изменяться, поэтому приложение передаёт его актуальное значение повторно.

## 7. Передача третьим лицам

Данные передаются только поставщикам, необходимым для заявленной работы приложения:

- Apple — для системных функций iOS, карт, медиатеки, биометрической проверки и APNs;
- Yandex Cloud — для минимальной серверной синхронизации и удалённой настройки;
- AppMetrica — для аналитики, диагностики и разрешённой пользователем атрибуции.

YPoints не продаёт пользовательские данные и не передаёт их третьим лицам за деньги или иное вознаграждение.

## 8. Управление данными и разрешениями

Пользователь может:

- изменить доступ к Bluetooth, камере, контактам, Face ID, геолокации, микрофону, Фото, отслеживанию и уведомлениям в настройках iPhone;
- сбросить или заменить локальные материалы доступными действиями приложения, удалить само приложение, а сохранённые карточки результатов отдельно удалить из системного приложения «Фото»;
- запросить сведения о серверных данных или их удаление по адресу bezgineg@yandex.ru.

Отзыв разрешения не удаляет автоматически ранее сохранённые на устройстве материалы или записи на backend. Запросить удаление серверных данных можно по адресу bezgineg@yandex.ru.

## 9. Дети

YPoints предназначен для общей аудитории и не ориентирован специально на детей. Приложение не запрашивает дату рождения и не создаёт пользовательские аккаунты.

## 10. Изменения политики

При изменении состава данных или способов их обработки актуальная версия этой политики будет опубликована по тому же адресу с новой датой вступления в силу.

## 11. Контакты

- Владелец приложения: Евгений Безгин (`Evgenii Bezgin`).
- Email по вопросам конфиденциальности: bezgineg@yandex.ru.
