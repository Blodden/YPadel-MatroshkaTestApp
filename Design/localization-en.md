# YPoints approved English and Russian localization

Status: `approved`

Approved by the user on 2026-08-20 before implementation.

The application follows the iPhone system language. English is the development and fallback localization; Russian remains the second fully shipped localization. No in-app language selector is added. Product behavior, navigation, layout, analytics identifiers, persistence keys, backend fields, deep links, and notification category identifiers remain unchanged.

Rendered English primary state: `Design/localization-en-candidate.png`.

## Primary interface

| Key | Russian | English |
|---|---|---|
| `main.title` | Счет и статистика | Score & statistics |
| `main.subtitle` | Все для текущего матча — на одном экране | Everything for the current match — on one screen |
| `status.accessibility` | Статус | Status |
| `score.accessibility` | Счет матча | Match score |
| `match.section` | Текущий матч | Current match |
| `match.finished` | Матч завершён | Match finished |
| `match.inProgress` | Матч продолжается | Match in progress |
| `match.tieBreak` | Тай-брейк | Tie-break |
| `score.points` | Очки | Points |
| `score.gamesFormat` | Геймы   %@ | Games   %@ |
| `score.setsFormat` | Сеты   %@ | Sets   %@ |
| `score.teams` | Мы  •  Соперники | Us  •  Opponents |
| `score.teamsWithPartnerFormat` | Мы с %@  •  Соперники | Us with %@  •  Opponents |
| `score.addOurs` | + очко нам | + point for us |
| `score.addTheirs` | + соперникам | + point for them |
| `score.finish` | Завершить матч | Finish match |
| `score.reset` | Сбросить счет | Reset score |
| `score.advantage` | БОЛ | ADV |
| `bluetooth.enable` | Табло по Bluetooth | Bluetooth scoreboard |
| `bluetooth.disable` | Отключить Bluetooth-табло | Turn off Bluetooth scoreboard |
| `notifications.action` | Напомнить о матче | Match reminder |
| `statistics.action` | Открыть статистику | Open statistics |
| `court.section` | Корт и игроки | Court & players |
| `court.find` | Найти корты рядом | Find nearby courts |
| `partner.choose` | Выбрать партнера | Choose partner |
| `tracking.action` | Оценка продвижения | Promotion measurement |
| `materials.section` | Материалы матча | Match materials |
| `photo.take` | Снять фото матча | Take match photo |
| `photo.chooseToday` | Выбрать фото за сегодня | Choose today's photo |
| `scoreCard.save` | Сохранить карточку счета | Save score card |
| `voice.record` | Записать голосовую заметку | Record voice note |
| `privacyPolicy.action` | Политика конфиденциальности | Privacy Policy |

## Feature-flag and synchronization states

| Key | Russian | English |
|---|---|---|
| `sync.available` | Синхронизация доступна | Sync available |
| `sync.disabled` | Облачная синхронизация отключена | Cloud sync is off |
| `sync.disabledLocalSaved` | Счет сохранён на устройстве • облачная синхронизация отключена | Score saved on device • cloud sync is off |
| `sync.success` | Счет синхронизирован | Score synced |
| `sync.successPushPending` | Синхронизировано • отправка push ожидает APNs-ключ | Synced • push delivery awaits an APNs key |
| `sync.offlineSaved` | Счет сохранён на устройстве • офлайн | Score saved on device • offline |
| `sync.offlineCached` | Офлайн-режим • используется сохранённая настройка | Offline • using the saved setting |
| `sync.disabledCached` | Облачная синхронизация отключена • используется сохранённая настройка | Cloud sync is off • using the saved setting |
| `sync.offlineDefault` | Офлайн-режим • используется настройка по умолчанию | Offline • using the default setting |

## Bluetooth states

| Key | Russian | English |
|---|---|---|
| `bluetooth.off` | Bluetooth-табло отключено | Bluetooth scoreboard is off |
| `bluetooth.searchingPhone` | Bluetooth: ищем iPhone с YPoints… | Bluetooth: looking for an iPhone with YPoints… |
| `bluetooth.scoreReceived` | Bluetooth: счет получен | Bluetooth: score received |
| `bluetooth.searchingScoreboard` | Bluetooth: поиск совместимого табло… | Bluetooth: looking for a compatible scoreboard… |
| `bluetooth.denied` | Bluetooth: доступ запрещён | Bluetooth: access denied |
| `bluetooth.poweredOff` | Bluetooth выключен | Bluetooth is off |
| `bluetooth.unsupported` | Bluetooth не поддерживается | Bluetooth is not supported |
| `bluetooth.unavailable` | Bluetooth пока недоступен | Bluetooth is currently unavailable |
| `bluetooth.connectingFormat` | Bluetooth: подключаем %@… | Bluetooth: connecting to %@… |
| `bluetooth.connectedFormat` | Bluetooth: %@ подключён | Bluetooth: %@ connected |
| `bluetooth.connectionFailed` | Bluetooth: подключение не удалось | Bluetooth: connection failed |
| `bluetooth.disconnectedSearching` | Bluetooth: устройство отключено, продолжаем поиск | Bluetooth: device disconnected, continuing search |
| `bluetooth.serviceUnavailable` | Bluetooth: сервис табло недоступен | Bluetooth: scoreboard service unavailable |
| `bluetooth.characteristicUnavailable` | Bluetooth: характеристика счета недоступна | Bluetooth: score characteristic unavailable |
| `bluetooth.scoreSynced` | Bluetooth: счет синхронизирован | Bluetooth: score synced |
| `bluetooth.scoreNotSent` | Bluetooth: счет не отправлен | Bluetooth: score not sent |
| `bluetooth.phoneConnected` | Bluetooth: iPhone с YPoints подключён | Bluetooth: iPhone with YPoints connected |

## Permission recovery and feature states

| Key | Russian | English |
|---|---|---|
| `faceID.fallback` | Использовать код-пароль | Use Passcode |
| `faceID.reason` | Открыть личную статистику и заметки о матчах | Open private match statistics and notes |
| `faceID.unavailable` | Face ID и код-пароль недоступны на этом устройстве. | Face ID and the passcode are unavailable on this device. |
| `faceID.locked` | Статистика осталась заблокирована | Statistics remain locked |
| `location.denied` | Разрешите геолокацию, чтобы находить корты рядом. Карту можно изучать и без текущей позиции. | Allow location access to find nearby courts. You can still browse the map without your current location. |
| `location.unknown` | Геолокация: неизвестный статус | Location: unknown status |
| `location.notAuthorized` | Геолокация не разрешена • карта доступна без текущей позиции | Location not allowed • map available without your current position |
| `location.failed` | Не удалось определить позицию • карта доступна вручную | Couldn't determine your location • map available for manual browsing |
| `map.accessibility` | Карта ближайших падел-кортов | Map of nearby padel courts |
| `map.searchQuery` | падел-корт | padel court |
| `map.defaultCourt` | Падел-корт | Padel court |
| `map.empty` | Корты не найдены — карту можно изучить вручную | No courts found — you can browse the map manually |
| `map.foundFormat` | Найдено кортов: %ld | Courts found: %ld |
| `contacts.denied` | Разрешите контакты, чтобы выбрать партнера для локального состава. | Allow Contacts access to choose a partner for the local lineup. |
| `contacts.unknown` | Контакты: неизвестный статус | Contacts: unknown status |
| `contacts.readFailed` | Не удалось прочитать разрешённые контакты | Couldn't read the allowed contacts |
| `contacts.title` | Контакты | Contacts |
| `contacts.empty` | Среди доступных контактов нет имён для выбора. | No names are available to choose from the allowed contacts. |
| `contacts.addPlayer` | Добавить игрока | Add player |
| `contacts.localOnly` | Имя останется только на этом iPhone. | The name will stay only on this iPhone. |
| `contacts.added` | Игрок добавлен в локальный состав | Player added to the local lineup |
| `tracking.enabled` | Оценка продвижения через AppMetrica включена | Promotion measurement through AppMetrica is on |
| `tracking.withoutIDFA` | AppMetrica работает без IDFA | AppMetrica is running without IDFA |
| `tracking.denied` | Отслеживание отключено. YPoints продолжает работать без IDFA. | Tracking is off. YPoints continues to work without IDFA. |
| `tracking.notDetermined` | Решение об оценке продвижения ещё не принято | Promotion measurement choice has not been made yet |
| `tracking.unknown` | ATT: неизвестный статус | ATT: unknown status |
| `camera.denied` | Разрешите камеру, чтобы снять фото матча. | Allow camera access to take a match photo. |
| `camera.unknown` | Камера: неизвестный статус | Camera: unknown status |
| `camera.simulatorUnavailable` | Камера недоступна в симуляторе. Проверьте функцию на iPhone. | The camera is unavailable in the simulator. Check this feature on an iPhone. |
| `photoRead.denied` | Разрешите просмотр Фото, чтобы выбрать снимок за день матча. | Allow Photos access to choose a picture from the match day. |
| `photoRead.unknown` | Фото: неизвестный статус | Photos: unknown status |
| `photoRead.dayTitle` | Фото за день матча | Match-day photos |
| `photoRead.availableTitle` | Доступные фото за день | Available photos from the day |
| `photoRead.empty` | Доступных снимков за этот день не найдено. | No available photos were found for this day. |
| `photoRead.addedToCard` | Фото добавлено к карточке результата | Photo added to the result card |
| `photoRead.cellAccessibility` | Фотография за день матча | Photo from the match day |

## Voice note

| Key | Russian | English |
|---|---|---|
| `voice.accessibility` | Состояние голосовой заметки | Voice note status |
| `voice.saving` | Сохраняем голосовую заметку… | Saving voice note… |
| `voice.playbackStopped` | Воспроизведение остановлено | Playback stopped |
| `voice.denied` | Разрешите микрофон, чтобы записать заметку. | Allow microphone access to record a note. |
| `voice.unknown` | Микрофон: неизвестный статус | Microphone: unknown status |
| `voice.recordingStatus` | Идёт запись • нажмите ещё раз для остановки • максимум 30 секунд | Recording • tap again to stop • 30 seconds maximum |
| `voice.recordFailed` | Не удалось начать запись | Couldn't start recording |
| `voice.recordedTitle` | Голосовая заметка записана | Voice note recorded |
| `voice.recordedMessage` | Она хранится только на этом iPhone. Можно прослушать, записать заново или удалить. | It is stored only on this iPhone. You can play, replace, or delete it. |
| `voice.play` | Прослушать | Play |
| `voice.replace` | Перезаписать | Replace |
| `voice.delete` | Удалить | Delete |
| `voice.playing` | Воспроизводим голосовую заметку | Playing voice note |
| `voice.playFailed` | Не удалось воспроизвести заметку | Couldn't play the note |
| `voice.deleted` | Голосовая заметка удалена | Voice note deleted |
| `voice.stopRecording` | Остановить запись | Stop recording |
| `voice.recordingButtonStatus` | Идёт запись • нажмите кнопку, чтобы остановить • максимум 30 секунд | Recording • tap the button to stop • 30 seconds maximum |
| `voice.stopPlayback` | Остановить воспроизведение | Stop playback |
| `voice.playingSaved` | Воспроизводим сохранённую заметку | Playing the saved note |
| `voice.manage` | Управление голосовой заметкой | Manage voice note |
| `voice.savedStatus` | Заметка сохранена • нажмите, чтобы прослушать, перезаписать или удалить | Note saved • tap to play, replace, or delete |
| `voice.emptyStatus` | Записи пока нет • максимальная длительность 30 секунд | No recording yet • 30 seconds maximum |
| `voice.savedOnDevice` | Голосовая заметка сохранена на этом iPhone | Voice note saved on this iPhone |
| `voice.interrupted` | Запись голосовой заметки прервана | Voice note recording interrupted |
| `voice.playbackFinished` | Воспроизведение завершено | Playback finished |
| `voice.playbackInterrupted` | Воспроизведение прервано | Playback interrupted |

## Score card and result

| Key | Russian | English |
|---|---|---|
| `photoAdd.denied` | Разрешите сохранение, чтобы добавить карточку счета в Фото. | Allow saving to add the score card to Photos. |
| `photoAdd.unknown` | Сохранение в Фото: неизвестный статус | Saving to Photos: unknown status |
| `scoreCard.savedStatus` | Карточка счета сохранена в Фото | Score card saved to Photos |
| `scoreCard.failedStatus` | Не удалось сохранить карточку | Couldn't save the score card |
| `scoreCard.savedTitle` | Сохранено в Фото | Saved to Photos |
| `scoreCard.savedMessage` | Карточка счёта добавлена в медиатеку. | The score card was added to your photo library. |
| `scoreCard.failedTitle` | Не удалось сохранить | Couldn't save |
| `scoreCard.failedMessage` | Карточка счёта не была добавлена в Фото. | The score card was not added to Photos. |
| `result.title` | Результат матча | Match result |
| `result.scoreAccessibility` | Итоговый счет | Final score |
| `result.photoMissing` | Фото матча не выбрано | No match photo selected |
| `result.photoAccessibility` | Фото матча | Match photo |
| `result.voiceSaved` | Голосовая заметка сохранена | Voice note saved |
| `result.noVoice` | Голосовой заметки нет | No voice note |
| `result.saveCard` | Сохранить карточку | Save card |

## Notifications

| Key | Russian | English |
|---|---|---|
| `push.denied` | Разрешите уведомления, чтобы получать события матча. | Allow notifications to receive match updates. |
| `push.unknown` | Уведомления: неизвестный статус | Notifications: unknown status |
| `push.prePermissionTitle` | Уведомления о матче | Match notifications |
| `push.prePermissionMessage` | Уведомления сообщат о приглашении, начале и результате матча. | Notifications will let you know about match invitations, starts, and results. |
| `push.notNow` | Не сейчас | Not Now |
| `push.continue` | Продолжить | Continue |
| `push.notEnabled` | Уведомления не включены | Notifications are not enabled |
| `push.finishedBodyFormat` | Матч завершен. %@ | Match finished. %@ |
| `push.inProgressBodyFormat` | Матч продолжается. %@ | Match in progress. %@ |
| `push.scheduled` | Проверочное уведомление появится через 5 секунд | A test notification will appear in 5 seconds |
| `push.scheduleFailed` | Не удалось создать уведомление | Couldn't create the notification |
| `notification.open` | Открыть | Open |
| `notification.hide` | Скрыть | Hide |
| `notification.scoreFormat` | Очки %@ • Геймы %@ • Сеты %@ | Points %@ • Games %@ • Sets %@ |
| `notification.updated` | Состояние матча обновилось. | Match status updated. |
| `notification.detailsFormat` | %@\nГеймы %@ • Сеты %@ | %@\nGames %@ • Sets %@ |

## Generic alerts and startup

| Key | Russian | English |
|---|---|---|
| `common.ok` | ОК | OK |
| `common.cancel` | Отмена | Cancel |
| `common.settings` | Настройки | Settings |
| `common.unavailableTitle` | Функция недоступна | Feature unavailable |
| `common.accessRequiredTitle` | Нужен доступ | Access required |
| `startup.accessibility` | YPoints запускается | YPoints is starting |
| `api.unknownResponse` | Сервер вернул неизвестный ответ | The server returned an unknown response |
| `api.statusFormat` | Сервер вернул код %ld | The server returned status %ld |
| `api.encodingFailed` | Не удалось подготовить данные | Couldn't prepare the data |

## Widget

| Key | Russian | English |
|---|---|---|
| `widget.finished` | Матч завершен | Match finished |
| `widget.current` | Текущий матч | Current match |
| `widget.scoreDetailsFormat` | Г %@  •  С %@ | G %@  •  S %@ |
| `widget.inactive` | Виджет сейчас неактивен | Widget is currently inactive |
| `widget.displayName` | Счет YPoints | YPoints score |
| `widget.description` | Счет и состояние матча на экране блокировки. | Match score and status on the Lock Screen. |

## Static permission copy

| Permission | Russian | English |
|---|---|---|
| Bluetooth | Bluetooth нужен, чтобы подключить находящийся рядом iPhone с YPoints и синхронизировать счёт матча. | Bluetooth is needed to connect a nearby iPhone running YPoints and synchronize the match score. |
| Camera | Камера нужна, чтобы сделать фотографию матча и добавить её к карточке результата. | Camera access is needed to take a match photo and add it to the result card. |
| Contacts | Контакты нужны, чтобы быстро добавить игроков в состав матча. | Contacts access is needed to quickly add players to the match lineup. |
| Face ID | Face ID нужен, чтобы открыть личную статистику и заметки о матчах. | Face ID is needed to open your private match statistics and notes. |
| Location | Геолокация нужна, чтобы показать ближайшие падел-корты на карте. | Location access is needed to show nearby padel courts on the map. |
| Microphone | Микрофон нужен, чтобы записать голосовую заметку к результату матча. | Microphone access is needed to record a voice note for the match result. |
| Photo Library Read | Доступ к Фото нужен, чтобы показать снимки за день матча и выбрать изображение для карточки результата. | Photo access is needed to show pictures taken on the match day and select one for the result card. |
| Photo Library Add | Доступ нужен, чтобы сохранять карточки счёта матчей в Фото. | Access is needed to save match score cards to Photos. |
| Advertising Tracking | Идентификатор устройства используется, чтобы определить источник установки и оценить эффективность продвижения YPoints. | YPoints uses your device identifier to identify the installation source and measure promotion effectiveness. |
| Push pre-permission | Уведомления сообщат о приглашении, начале и результате матча. | Notifications will let you know about match invitations, starts, and results. |

## Layout decision

- Preserve the approved Russian layout, colors, typography, controls, and section order.
- Allow the English subtitle to use its existing multiline label if needed; do not reduce the font size.
- Keep the two point buttons side by side with the exact titles `+ point for us` and `+ point for them`.
- Keep the app name `YPoints`, scores, SF Symbols, map, and icon unchanged.
- Localize text drawn into the saved score-card image as well as on-screen UIKit and extension text.
